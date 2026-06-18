import '../core/date_utils.dart';
import 'models.dart';
import 'recurrence.dart';

/// Присутствие дела в дне и распределение по секциям «Вчера/Сегодня/Завтра».

/// Дело «присутствует» в дне [day].
bool isPresentOn(TaskModel t, DateTime day) {
  if (t.deferred) return false;
  if (t.isRecurring) return occursOn(t, day);
  final d = dateOnly(day);
  if (t.isSingle) return isSameDate(t.startDate, d);
  return !d.isBefore(dateOnly(t.startDate)) && !d.isAfter(dateOnly(t.endDate));
}

/// Номер дня периода в дне [day] (1-based). Для single всегда 1.
int dayNumberOf(TaskModel t, DateTime day) => daysBetween(t.startDate, day) + 1;

/// Дело просрочено: не выполнено и его конец строго раньше сегодня.
/// Для повторяющихся просрочка считается по конкретному вхождению в UI.
bool isOverdue(TaskModel t, DateTime today) =>
    !t.isRecurring &&
    !t.isDone &&
    dateOnly(t.endDate).isBefore(dateOnly(today));

/// Сортировка дел внутри дня: по времени дня (без времени — позже),
/// затем по sortIndex, затем по дате создания.
int compareInDay(TaskModel a, TaskModel b) {
  final at = a.timeOfDayMinutes;
  final bt = b.timeOfDayMinutes;
  if (at != bt) {
    if (at == null) return 1;
    if (bt == null) return -1;
    return at.compareTo(bt);
  }
  if (a.sortIndex != b.sortIndex) return a.sortIndex.compareTo(b.sortIndex);
  return a.createdAt.compareTo(b.createdAt);
}

/// Дела трёх горизонтов относительно [today].
class DaySections {
  /// Присутствовали вчера и НЕ выполнены (хвост невыполненного).
  final List<TaskModel> yesterday;

  /// Все, присутствующие сегодня (включая выполненные — зачёркнутыми).
  final List<TaskModel> today;

  /// Все, присутствующие завтра.
  final List<TaskModel> tomorrow;

  const DaySections({
    required this.yesterday,
    required this.today,
    required this.tomorrow,
  });

  int get yesterdayCount => yesterday.length;
  int get todayCount => today.length;
  int get tomorrowCount => tomorrow.length;
}

DaySections buildSections(
  List<TaskModel> tasks,
  DateTime now, {
  bool Function(TaskModel task, DateTime day)? isDoneOn,
}) {
  final doneOn = isDoneOn ?? (TaskModel t, DateTime d) => t.isDone;
  final today = dateOnly(now);
  final yesterday = addDays(today, -1);
  final tomorrow = addDays(today, 1);

  final y = <TaskModel>[];
  final t = <TaskModel>[];
  final tm = <TaskModel>[];

  for (final task in tasks) {
    if (isPresentOn(task, yesterday) && !doneOn(task, yesterday)) y.add(task);
    if (isPresentOn(task, today)) t.add(task);
    if (isPresentOn(task, tomorrow)) tm.add(task);
  }

  y.sort(compareInDay);
  t.sort(compareInDay);
  tm.sort(compareInDay);

  return DaySections(yesterday: y, today: t, tomorrow: tm);
}
