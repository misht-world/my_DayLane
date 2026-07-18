import 'package:daylane/domain/models.dart';

DateTime d(int year, int month, int day) => DateTime(year, month, day);

/// Удобный конструктор дела для тестов.
TaskModel task({
  int? id,
  String title = 'task',
  TaskKind kind = TaskKind.single,
  required DateTime start,
  DateTime? end,
  int? durationDays,
  int? dependsOnTaskId,
  int? timeOfDayMinutes,
  bool isDone = false,
  bool carriedOver = false,
  int colorId = 0,
  int sortIndex = 0,
  RecurrenceType recurrenceType = RecurrenceType.none,
}) {
  final e = end ?? start;
  final dur = durationDays ?? (kind == TaskKind.period ? e.difference(start).inDays + 1 : 1);
  final created = DateTime(2020, 1, 1).add(Duration(seconds: id ?? 0));
  return TaskModel(
    id: id,
    title: title,
    kind: kind,
    startDate: start,
    endDate: e,
    durationDays: dur,
    dependsOnTaskId: dependsOnTaskId,
    timeOfDayMinutes: timeOfDayMinutes,
    isDone: isDone,
    carriedOver: carriedOver,
    colorId: colorId,
    sortIndex: sortIndex,
    recurrenceType: recurrenceType,
    createdAt: created,
    updatedAt: created,
  );
}
