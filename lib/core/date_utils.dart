import 'package:intl/intl.dart';

/// Утилиты работы с датами «без времени». Источник истины для домена.
///
/// Хранение даты отделено от времени дня: плановые даты нормализуются к
/// полуночи локальной зоны, время дня живёт отдельно (в минутах).

/// Отбрасывает время, оставляя только год/месяц/день в локальной зоне.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Прибавляет [n] дней к дате (нормализованной к полуночи).
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Целое число дней между датами (b - a), по датам без времени.
int daysBetween(DateTime a, DateTime b) =>
    dateOnly(b).difference(dateOnly(a)).inDays;

/// Одна и та же календарная дата.
bool isSameDate(DateTime a, DateTime b) => daysBetween(a, b) == 0;

/// Числовой ключ календарного дня (для множеств/карт): ГГГГММДД.
int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// Метка «день N из M».
String dayOfPeriodLabel(int n, int m) => 'день $n из $m';

/// «20 июня».
String formatDayMonth(DateTime d) => DateFormat('d MMMM', 'ru').format(d);

/// «среда, 17 июня».
String formatWeekdayDayMonth(DateTime d) =>
    DateFormat('EEEE, d MMMM', 'ru').format(d);

/// Диапазон периода: «20–24 июня» или «28 июня – 2 июля».
String formatDateRange(DateTime a, DateTime b) {
  if (isSameDate(a, b)) return formatDayMonth(a);
  if (a.month == b.month && a.year == b.year) {
    return '${a.day}–${DateFormat('d MMMM', 'ru').format(b)}';
  }
  return '${formatDayMonth(a)} – ${formatDayMonth(b)}';
}

/// «Июнь 2026» — месяц (именительный падеж) и год, с заглавной буквы.
String formatMonthYear(DateTime d) {
  final s = DateFormat('LLLL y', 'ru').format(d);
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Короткое название месяца: «июл». Для подписей в сетке календаря.
String monthNameShort(int month) =>
    DateFormat('LLL', 'ru').format(DateTime(2000, month)).replaceAll('.', '');

/// Прибавляет [n] месяцев к дате, сохраняя день (с поправкой на длину месяца).
DateTime addMonths(DateTime d, int n) {
  final total = d.month - 1 + n; // индекс месяца от нуля
  final year = d.year + (total / 12).floor();
  final month = total % 12 + 1; // % в Dart неотрицателен для делителя 12
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDay ? lastDay : d.day);
}

/// Время дня из минут от полуночи в «09:00».
String formatMinutesOfDay(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
