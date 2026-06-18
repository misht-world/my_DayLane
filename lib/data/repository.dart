import '../core/date_utils.dart';
import '../domain/carry_over.dart';
import '../domain/dependencies.dart';
import '../domain/models.dart';
import '../services/notifications.dart';
import 'db.dart';

/// Связывает DAO, доменную логику и уведомления в согласованные операции.
class TaskRepository {
  TaskRepository(this._db, {NotificationService? notifications})
      : _notifications = notifications ?? NotificationService.instance;

  final AppDatabase _db;
  final NotificationService _notifications;

  TaskDao get _tasks => _db.taskDao;
  SubtaskDao get _subtasks => _db.subtaskDao;

  Stream<List<TaskModel>> watchTasks() => _tasks.watchAll();
  Stream<List<SubtaskModel>> watchAllSubtasks() => _subtasks.watchAll();
  Stream<List<SubtaskModel>> watchSubtasks(int taskId) =>
      _subtasks.watchForTask(taskId);
  Future<List<SubtaskModel>> getSubtasks(int taskId) =>
      _subtasks.getForTask(taskId);

  /// Создаёт или обновляет дело вместе с подпунктами, затем пересчитывает
  /// зависимые даты каскадом и пере-планирует напоминания.
  Future<int> saveTask(TaskModel task, {List<SubtaskModel>? subtasks}) async {
    final now = DateTime.now();
    final toSave = task.copyWith(
      updatedAt: now,
      createdAt: task.id == null ? now : task.createdAt,
    );

    final int id;
    if (toSave.id == null) {
      id = await _tasks.insertTask(toSave);
    } else {
      id = toSave.id!;
      await _tasks.updateTask(toSave);
    }

    if (subtasks != null) {
      await _subtasks.replaceForTask(id, subtasks);
    }

    await _recomputeAndSync(touchedIds: {id});
    return id;
  }

  /// Удаляет дело: отвязывает детей (фиксируя их даты), снимает напоминания,
  /// удаляет строку (подпункты уходят каскадом).
  Future<void> deleteTask(int id) async {
    final all = await _tasks.getAll();
    final detached = detachChildrenOf(all, id)
        .where((t) => t.id != id && t.dependsOnTaskId == null)
        .toList();
    // Сохраняем только тех, у кого реально снялась привязка.
    final changed = detached
        .where((t) => all
            .firstWhere((o) => o.id == t.id)
            .dependsOnTaskId == id)
        .toList();
    if (changed.isNotEmpty) await _tasks.updateMany(changed);

    await _notifications.cancelForTask(id);
    await _tasks.deleteTask(id);

    await _recomputeAndSync(touchedIds: changed.map((t) => t.id!).toSet());
  }

  Future<void> toggleDone(TaskModel task) async {
    final now = DateTime.now();
    final next = !task.isDone;
    await _tasks.setDone(task.id!, next, now);
    // Отметка основного дела закрывает/открывает весь чек-лист.
    await _subtasks.setAllDone(task.id!, next);
    final updated = task.copyWith(
      isDone: next,
      completedAt: next ? now : null,
      updatedAt: now,
    );
    await _notifications.reschedule(updated); // отменит, если выполнено
  }

  /// Переключает подпункт и синхронизирует статус основного дела:
  /// все подпункты выполнены ⇒ дело выполнено, иначе — не выполнено.
  Future<void> setSubtaskDone(SubtaskModel sub, bool done) async {
    final now = DateTime.now();
    await _subtasks.toggleDone(sub.id!, done);
    final siblings = await _subtasks.getForTask(sub.taskId);
    final allDone = siblings.isNotEmpty && siblings.every((s) => s.isDone);
    final parent = await _tasks.getById(sub.taskId);
    if (parent != null && parent.isDone != allDone) {
      await _tasks.setDone(parent.id!, allDone, now);
      await _notifications.reschedule(
        parent.copyWith(
            isDone: allDone, completedAt: allDone ? now : null, updatedAt: now),
      );
    }
  }

  /// Отмечает/снимает выполнение конкретного вхождения повторяющегося дела.
  Future<void> toggleOccurrence(
      TaskModel task, DateTime day, bool done) async {
    await _db.setOccurrenceDone(task.id!, day, done);
  }

  /// Назначает дату отложенному делу (и снимает признак «отложено»).
  Future<void> scheduleDeferred(TaskModel task, DateTime date) async {
    final d = dateOnly(date);
    final end = task.isPeriod ? addDays(d, task.durationDays - 1) : d;
    await saveTask(task.copyWith(deferred: false, startDate: d, endDate: end));
  }

  /// Ручной перенос однодневного дела на сегодня.
  Future<void> carryToTodayTask(TaskModel task) async {
    if (task.isPeriod) return;
    final carried = carryToToday(task, DateTime.now());
    await _tasks.updateTask(carried);
    await _notifications.reschedule(carried);
  }

  /// Перенести все вчерашние невыполненные однодневные на сегодня.
  Future<void> carryAll(List<TaskModel> yesterdayTasks) async {
    final now = DateTime.now();
    final carried = yesterdayTasks
        .where((t) => t.isSingle && !t.isDone)
        .map((t) => carryToToday(t, now))
        .toList();
    if (carried.isEmpty) return;
    await _tasks.updateMany(carried);
    for (final t in carried) {
      await _notifications.reschedule(t);
    }
  }

  /// Обслуживание при старте: сброс устаревших меток «перенесено» и,
  /// если включён авто-перенос, перенос просроченных однодневных на сегодня.
  Future<void> runStartupMaintenance({required bool autoCarry}) async {
    final now = DateTime.now();
    final all = await _tasks.getAll();

    var working = clearStaleCarryFlags(all, now);
    if (autoCarry) working = applyAutoCarry(working, now);

    final changed = <TaskModel>[];
    for (final t in working) {
      final before = all.firstWhere((o) => o.id == t.id);
      if (before.startDate != t.startDate ||
          before.endDate != t.endDate ||
          before.carriedOver != t.carriedOver) {
        changed.add(t);
      }
    }
    if (changed.isNotEmpty) {
      await _tasks.updateMany(changed);
      for (final t in changed) {
        await _notifications.reschedule(t);
      }
    }
  }

  /// Пересчитывает каскад дат по всем делам и сохраняет изменившиеся,
  /// пере-планируя их напоминания.
  Future<void> _recomputeAndSync({Set<int> touchedIds = const {}}) async {
    final all = await _tasks.getAll();
    final recomputed = applyDependencyDates(all);

    final changed = <TaskModel>[];
    for (final t in recomputed) {
      if (t.id == null) continue;
      final before = all.firstWhere((o) => o.id == t.id);
      if (before.startDate != t.startDate || before.endDate != t.endDate) {
        changed.add(t);
      }
    }
    if (changed.isNotEmpty) await _tasks.updateMany(changed);

    // Пере-планируем напоминания затронутых и изменившихся дел.
    final idsToReschedule = {...touchedIds, ...changed.map((t) => t.id!)};
    for (final id in idsToReschedule) {
      final t = recomputed.where((x) => x.id == id).firstOrNull;
      if (t != null) await _notifications.reschedule(t);
    }
  }
}
