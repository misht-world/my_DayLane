import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_utils.dart';
import '../data/db.dart';
import '../data/repository.dart';
import '../domain/models.dart';
import '../domain/scheduling.dart';

/// Единая БД на время жизни приложения.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(databaseProvider)),
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

/// Секции «Вчера/Сегодня/Завтра» относительно фокусной даты.
final sectionsProvider = Provider<DaySections?>((ref) {
  final tasks = ref.watch(tasksProvider).value;
  if (tasks == null) return null;
  return buildSections(tasks, ref.watch(focusedDateProvider));
});

/// Реальная сегодняшняя дата без времени (для просрочки и т.п.).
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

/// Режим темы из настроек.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final s = ref.watch(settingsProvider).value;
  switch (s?.themeMode ?? 0) {
    case 1:
      return ThemeMode.light;
    case 2:
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});
