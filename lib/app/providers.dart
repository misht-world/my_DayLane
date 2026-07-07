import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_utils.dart';
import '../data/db.dart';
import '../data/repository.dart';
import '../domain/models.dart';
import '../domain/scheduling.dart';
import '../services/backup.dart';

/// Единая БД на время жизни приложения.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(databaseProvider)),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

/// Настройки приложения (одна строка).
final settingsProvider = StreamProvider<SettingsRow>(
  (ref) => ref.watch(databaseProvider).watchSettings(),
);

/// Все дела.
final tasksProvider = StreamProvider<List<TaskModel>>(
  (ref) => ref.watch(repositoryProvider).watchTasks(),
);

/// Все подпункты (для агрегатов k/n на главном экране).
final allSubtasksProvider = StreamProvider<List<SubtaskModel>>(
  (ref) => ref.watch(repositoryProvider).watchAllSubtasks(),
);

/// Подпункты конкретного дела.
final subtasksForTaskProvider =
    StreamProvider.family<List<SubtaskModel>, int>(
  (ref, taskId) => ref.watch(repositoryProvider).watchSubtasks(taskId),
);

/// Прогресс подпунктов по taskId: (выполнено, всего).
final subtaskProgressProvider =
    Provider<Map<int, (int done, int total)>>((ref) {
  final subs = ref.watch(allSubtasksProvider).value ?? const [];
  final map = <int, (int, int)>{};
  for (final s in subs) {
    final prev = map[s.taskId] ?? (0, 0);
    map[s.taskId] = (prev.$1 + (s.isDone ? 1 : 0), prev.$2 + 1);
  }
  return map;
});

/// Фокусная дата главного экрана (можно листать на другие дни).
/// По умолчанию — реальная сегодняшняя дата.
class FocusedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void set(DateTime d) => state = dateOnly(d);
  void shift(int days) => state = addDays(state, days);
}

final focusedDateProvider =
    NotifierProvider<FocusedDateNotifier, DateTime>(FocusedDateNotifier.new);

/// Отметки выполнения вхождений: taskId → множество ключей дней (ГГГГММДД).
final recurrenceDonesProvider =
    StreamProvider<List<RecurrenceDoneRow>>(
  (ref) => ref.watch(databaseProvider).watchRecurrenceDones(),
);

final donesMapProvider = Provider<Map<int, Set<int>>>((ref) {
  final list = ref.watch(recurrenceDonesProvider).value ?? const [];
  final map = <int, Set<int>>{};
  for (final r in list) {
    map.putIfAbsent(r.taskId, () => <int>{}).add(dayKey(r.date));
  }
  return map;
});

/// Выполнено ли дело в конкретный день (для повторяющихся — по вхождению).
bool isTaskDoneOn(Map<int, Set<int>> dones, TaskModel t, DateTime day) {
  if (!t.isRecurring) return t.isDone;
  return dones[t.id]?.contains(dayKey(day)) ?? false;
}

/// Секции «Вчера/Сегодня/Завтра» относительно фокусной даты.
final sectionsProvider = Provider<DaySections?>((ref) {
  final tasks = ref.watch(tasksProvider).value;
  if (tasks == null) return null;
  final dones = ref.watch(donesMapProvider);
  return buildSections(
    tasks,
    ref.watch(focusedDateProvider),
    isDoneOn: (t, day) => isTaskDoneOn(dones, t, day),
  );
});

/// Отложенные дела (без даты) — не выполненные.
final deferredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const [];
  return tasks.where((t) => t.deferred && !t.isDone).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});

/// Путешествия (дела-периоды с дневником), ближайшие сверху.
final tripsProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const [];
  return tasks.where((t) => t.isTrip && !t.deferred).toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
});

/// Этапы конкретного путешествия (по датам).
final stagesForTripProvider =
    StreamProvider.family<List<TripStageModel>, int>(
  (ref, taskId) => ref.watch(repositoryProvider).watchStages(taskId),
);

/// Число этапов по поездкам (для превью в списке путешествий).
final stageCountProvider = Provider<Map<int, int>>((ref) {
  final rows = ref.watch(_allStagesProvider).value ?? const [];
  final map = <int, int>{};
  for (final r in rows) {
    map[r.taskId] = (map[r.taskId] ?? 0) + 1;
  }
  return map;
});

final _allStagesProvider = StreamProvider<List<TripStageRow>>(
  (ref) => ref.watch(databaseProvider).watchAllStages(),
);

/// Дни, покрытые этапами, по поездкам: taskId → множество ключей дней.
/// Для календаря — показать, какая часть путешествия распланирована.
final tripStageDaysProvider = Provider<Map<int, Set<int>>>((ref) {
  final rows = ref.watch(_allStagesProvider).value ?? const [];
  final map = <int, Set<int>>{};
  for (final r in rows) {
    for (var d = dateOnly(r.startDate);
        !d.isAfter(dateOnly(r.endDate));
        d = addDays(d, 1)) {
      map.putIfAbsent(r.taskId, () => <int>{}).add(dayKey(d));
    }
  }
  return map;
});

/// Реальная сегодняшняя дата без времени (для просрочки и т.п.).
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

/// Режим темы из настроек.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final s = ref.watch(settingsProvider).value;
  switch (s?.themeMode ?? 1) {
    case 1:
      return ThemeMode.light;
    case 2:
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});
