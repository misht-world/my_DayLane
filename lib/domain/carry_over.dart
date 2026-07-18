import '../core/date_utils.dart';
import 'models.dart';

/// Перенос невыполненного на сегодня — ручной и автоматический.

/// Можно ли переносить дело: только обычное однодневное. Многодневные
/// продолжаются по периоду; повторяющиеся живут по своим вхождениям, и сдвиг
/// их `startDate` сломал бы якорь повтора (напр. годовщина «переехала» бы
/// на другое число).
bool _carryable(TaskModel t) => t.isSingle && !t.isRecurring;

/// Переносит однодневное дело на сегодня и помечает «перенесено».
/// Для непереносимых (период/повтор) возвращает дело без изменений.
TaskModel carryToToday(TaskModel t, DateTime now) {
  if (!_carryable(t)) return t;
  final today = dateOnly(now);
  return t.copyWith(
    startDate: today,
    endDate: today,
    carriedOver: true,
    updatedAt: now,
  );
}

/// Кандидаты на (авто)перенос: обычные однодневные, не выполненные,
/// с датой в прошлом.
List<TaskModel> carryCandidates(List<TaskModel> tasks, DateTime now) {
  final today = dateOnly(now);
  return tasks
      .where((t) =>
          _carryable(t) &&
          !t.isDone &&
          dateOnly(t.startDate).isBefore(today))
      .toList();
}

/// Применяет авто-перенос ко всем кандидатам, возвращая обновлённый список.
List<TaskModel> applyAutoCarry(List<TaskModel> tasks, DateTime now) {
  final today = dateOnly(now);
  return [
    for (final t in tasks)
      if (_carryable(t) && !t.isDone && dateOnly(t.startDate).isBefore(today))
        carryToToday(t, now)
      else
        t,
  ];
}

/// Сбрасывает метку «перенесено» у дел, перенесённых не сегодня
/// (значок «↻ перенесено» живёт только до конца дня).
List<TaskModel> clearStaleCarryFlags(List<TaskModel> tasks, DateTime now) {
  final today = dateOnly(now);
  return [
    for (final t in tasks)
      if (t.carriedOver && !isSameDate(t.startDate, today))
        t.copyWith(carriedOver: false)
      else
        t,
  ];
}
