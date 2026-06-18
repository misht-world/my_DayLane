import '../core/date_utils.dart';
import 'models.dart';

/// Логика повторяющихся дел. Вхождения не материализуются — вычисляются.
/// Якорь повторения берётся из `startDate` (дата первого вхождения).

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime lastDayOfMonth(DateTime d) =>
    DateTime(d.year, d.month, daysInMonth(d.year, d.month));

int _monthsBetween(DateTime a, DateTime b) =>
    (b.year - a.year) * 12 + (b.month - a.month);

/// Происходит ли вхождение повторяющегося дела в день [day].
bool occursOn(TaskModel t, DateTime day) {
  if (!t.isRecurring) return false;
  final start = dateOnly(t.startDate);
  final d = dateOnly(day);
  if (d.isBefore(start)) return false;
  final n = t.recurrenceInterval < 1 ? 1 : t.recurrenceInterval;

  switch (t.recurrenceType) {
    case RecurrenceType.none:
      return false;
    case RecurrenceType.days:
      return daysBetween(start, d) % n == 0;
    case RecurrenceType.weeks:
      if (d.weekday != start.weekday) return false;
      return (daysBetween(start, d) ~/ 7) % n == 0;
    case RecurrenceType.months:
      if (_monthsBetween(start, d) % n != 0) return false;
      final target = start.day > daysInMonth(d.year, d.month)
          ? daysInMonth(d.year, d.month)
          : start.day;
      return d.day == target;
    case RecurrenceType.years:
      if ((d.year - start.year) % n != 0) return false;
      if (d.month != start.month) return false;
      final target = start.day > daysInMonth(d.year, d.month)
          ? daysInMonth(d.year, d.month)
          : start.day;
      return d.day == target;
    case RecurrenceType.monthLastDay:
      if (_monthsBetween(start, d) % n != 0) return false;
      return d.day == daysInMonth(d.year, d.month);
    case RecurrenceType.monthBeforeEnd:
      if (_monthsBetween(start, d) % n != 0) return false;
      final last = daysInMonth(d.year, d.month);
      return d.day == last - t.recurrenceAnchor;
  }
}

/// Ближайшие [count] вхождений начиная с [from] (включительно).
List<DateTime> nextOccurrences(TaskModel t, DateTime from, int count) {
  final out = <DateTime>[];
  if (!t.isRecurring) return out;
  var d = dateOnly(from);
  final start = dateOnly(t.startDate);
  if (d.isBefore(start)) d = start;
  // Ограничение на проход, чтобы не зациклиться (~10 лет вперёд).
  for (var i = 0; i < 3700 && out.length < count; i++) {
    if (occursOn(t, d)) out.add(d);
    d = addDays(d, 1);
  }
  return out;
}

/// Человекочитаемое описание правила повторения.
String recurrenceSummary(TaskModel t) {
  final n = t.recurrenceInterval;
  String every(String unitOne, String unitFew) =>
      n == 1 ? 'каждый $unitOne' : 'каждые $n $unitFew';
  switch (t.recurrenceType) {
    case RecurrenceType.none:
      return 'не повторяется';
    case RecurrenceType.days:
      return n == 1 ? 'каждый день' : 'каждые $n дн.';
    case RecurrenceType.weeks:
      return n == 1 ? 'каждую неделю' : 'каждые $n нед.';
    case RecurrenceType.months:
      return '${every('месяц', 'мес.')}, ${t.startDate.day}-го';
    case RecurrenceType.years:
      return '${every('год', 'г.')}, ${formatDayMonth(t.startDate)}';
    case RecurrenceType.monthLastDay:
      return '${every('месяц', 'мес.')}, последний день';
    case RecurrenceType.monthBeforeEnd:
      return '${every('месяц', 'мес.')}, за ${t.recurrenceAnchor} дн. до конца';
  }
}
