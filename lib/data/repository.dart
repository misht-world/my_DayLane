import '../core/date_utils.dart';
import '../domain/carry_over.dart';
import '../domain/dependencies.dart';
import '../domain/models.dart';
import '../services/notifications.dart';
import 'db.dart';

/// Отмена последней операции (перенос/удаление/отложение).
typedef UndoAction = Future<void> Function();

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
      // Дело с подпунктами выполнено ⇔ все подпункты выполнены. Иначе (добавили
      // новый / сняли галочку) дело могло остаться зачёркнутым из-за старого
      // isDone.
      if (subtasks.isNotEmpty) {
        final allDone = subtasks.every((s) => s.isDone);
        if (toSave.isDone != allDone) {
          await _tasks.setDone(id, allDone, now);
        }
      }
    }

    await _recomputeAndSync(touchedIds: {id});
    return id;
  }

  /// Удаляет дело: отвязывает детей (фиксируя их даты), снимает напоминания,
  /// удаляет строку (подпункты уходят каскадом). Возвращает отмену —
  /// восстановление дела с подпунктами и отметками вхождений.
  Future<UndoAction> deleteTask(int id) async {
    final victim = await _tasks.getById(id);
    final victimSubs = await _subtasks.getForTask(id);
    final victimDones = await _db.getOccurrenceDates(id);
    final victimStages = await _db.getStages(id);

    return _undoable(
      () async {
        final all = await _tasks.getAll();
        final detached = detachChildrenOf(all, id)
            .where((t) => t.id != id && t.dependsOnTaskId == null)
            .toList();
        // Сохраняем только тех, у кого реально снялась привязка.
        final changed = detached
            .where((t) =>
                all.firstWhere((o) => o.id == t.id).dependsOnTaskId == id)
            .toList();
        if (changed.isNotEmpty) await _tasks.updateMany(changed);

        await _notifications.cancelForTask(id);
        await _tasks.deleteTask(id);

        await _recomputeAndSync(touchedIds: changed.map((t) => t.id!).toSet());
      },
      reinsert: victim,
      reinsertSubs: victimSubs,
      reinsertDones: victimDones,
      reinsertStages: victimStages,
    );
  }

  /// Поля, которые меняют недо-/пере-носы и каскады — по ним ищем, что
  /// восстанавливать при отмене.
  static bool _differs(TaskModel a, TaskModel b) =>
      a.startDate != b.startDate ||
      a.endDate != b.endDate ||
      a.deferred != b.deferred ||
      a.carriedOver != b.carriedOver ||
      a.dependsOnTaskId != b.dependsOnTaskId ||
      a.isDone != b.isDone;

  /// Выполняет [op], предварительно сняв снимок всех дел, и возвращает
  /// отмену: вернуть изменившиеся строки к состоянию «до» (и, при удалении,
  /// вставить дело обратно с тем же id).
  Future<UndoAction> _undoable(
    Future<void> Function() op, {
    TaskModel? reinsert,
    List<SubtaskModel> reinsertSubs = const [],
    List<DateTime> reinsertDones = const [],
    List<TripStageModel> reinsertStages = const [],
  }) async {
    final before = await _tasks.getAll();
    await op();
    return () async {
      if (reinsert != null && reinsert.id != null) {
        await _tasks.insertTask(reinsert);
        await _subtasks.replaceForTask(reinsert.id!, reinsertSubs);
        for (final d in reinsertDones) {
          await _db.setOccurrenceDone(reinsert.id!, d, true);
        }
        for (final s in reinsertStages) {
          await _db.insertStage(s.copyWith(id: null));
        }
      }
      final after = await _tasks.getAll();
      final afterById = {for (final t in after) if (t.id != null) t.id!: t};
      final toRestore = <TaskModel>[
        for (final b in before)
          if (afterById[b.id] != null && _differs(afterById[b.id]!, b)) b,
      ];
      if (toRestore.isNotEmpty) await _tasks.updateMany(toRestore);
      for (final t in [...toRestore, ?reinsert]) {
        await _notifications.reschedule(t);
      }
    };
  }

  /// Возвращает дело с дня в «Отложенные» (снимает присутствие в днях).
  Future<UndoAction> moveToDeferred(TaskModel task) => _undoable(() async {
        await saveTask(task.copyWith(deferred: true, carriedOver: false));
      });

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
    // Статус переключённого подпункта берём из known-значения `done`, а не из
    // прочитанного — иначе при снятии галочки дело могло остаться выполненным
    // (гонка чтения-после-записи).
    final allDone = siblings.isNotEmpty &&
        siblings.every((s) => s.id == sub.id ? done : s.isDone);
    final parent = await _tasks.getById(sub.taskId);
    if (parent != null && parent.isDone != allDone) {
      await _tasks.setDone(parent.id!, allDone, now);
      await _notifications.reschedule(
        parent.copyWith(
            isDone: allDone, completedAt: allDone ? now : null, updatedAt: now),
      );
    }
  }

  /// Добавляет подпункт к делу (в конец). Выполненное дело при этом снова
  /// становится невыполненным — новый пункт ещё не сделан.
  Future<void> addSubtask(int taskId, String title) async {
    final siblings = await _subtasks.getForTask(taskId);
    final nextSort = siblings.isEmpty
        ? 0
        : siblings.map((s) => s.sortIndex).reduce((a, b) => a > b ? a : b) + 1;
    await _subtasks.insertSubtask(
        SubtaskModel(taskId: taskId, title: title, sortIndex: nextSort));
    final parent = await _tasks.getById(taskId);
    if (parent != null && parent.isDone && !parent.isRecurring) {
      await _tasks.setDone(taskId, false, DateTime.now());
    }
  }

  /// Отмечает/снимает выполнение конкретного вхождения повторяющегося дела.
  Future<void> toggleOccurrence(
      TaskModel task, DateTime day, bool done) async {
    await _db.setOccurrenceDone(task.id!, day, done);
  }

  // ── Этапы путешествий ─────────────────────────────────────────
  Stream<List<TripStageModel>> watchStages(int taskId) =>
      _db.watchStages(taskId);

  Future<void> saveStage(TripStageModel stage) => stage.id == null
      ? _db.insertStage(stage)
      : _db.updateStage(stage);

  Future<void> toggleStageDone(TripStageModel stage, bool done) =>
      _db.updateStage(stage.copyWith(isDone: done));

  Future<void> deleteStage(int id) => _db.deleteStage(id);

  /// Пере-планирует напоминания для всех дел (после импорта/восстановления).
  Future<void> rescheduleAll() async {
    final all = await _tasks.getAll();
    for (final t in all) {
      await _notifications.reschedule(t);
    }
  }

  /// Назначает дату отложенному делу (и снимает признак «отложено»).
  Future<UndoAction> scheduleDeferred(TaskModel task, DateTime date) =>
      _undoable(() async {
        final d = dateOnly(date);
        final end = task.isPeriod ? addDays(d, task.durationDays - 1) : d;
        await saveTask(
            task.copyWith(deferred: false, startDate: d, endDate: end));
      });

  /// Ручной перенос однодневного дела на сегодня.
  Future<UndoAction> carryToTodayTask(TaskModel task) =>
      _undoable(() async {
        // carryToToday сам возвращает дело без изменений для периода/повтора.
        final carried = carryToToday(task, DateTime.now());
        if (identical(carried, task)) return;
        await _tasks.updateTask(carried);
        await _notifications.reschedule(carried);
      });

  /// Перенести все вчерашние невыполненные однодневные на сегодня.
  Future<UndoAction> carryAll(List<TaskModel> yesterdayTasks) =>
      _undoable(() async {
        final now = DateTime.now();
        final carried = yesterdayTasks
            .where((t) => t.isSingle && !t.isRecurring && !t.isDone)
            .map((t) => carryToToday(t, now))
            .toList();
        if (carried.isEmpty) return;
        await _tasks.updateMany(carried);
        for (final t in carried) {
          await _notifications.reschedule(t);
        }
      });

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
