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

/// Метка «день N из M» / «day N of M». Язык — из Intl.defaultLocale
/// (работает и в фоне, для текста уведомлений).
String dayOfPeriodLabel(int n, int m) =>
    (Intl.defaultLocale ?? 'ru').startsWith('en')
        ? 'day $n of $m'
        : 'день $n из $m';

/// «20 июня» / «20 June». Локаль — глобальная (Intl.defaultLocale).
String formatDayMonth(DateTime d) => DateFormat('d MMMM').format(d);

/// «среда, 17 июня» / «Wednesday, 17 June».
String formatWeekdayDayMonth(DateTime d) =>
    DateFormat('EEEE, d MMMM').format(d);

/// Диапазон периода: «20–24 июня» или «28 июня – 2 июля».
String formatDateRange(DateTime a, DateTime b) {
  if (isSameDate(a, b)) return formatDayMonth(a);
  if (a.month == b.month && a.year == b.year) {
    return '${a.day}–${DateFormat('d MMMM').format(b)}';
  }
  return '${formatDayMonth(a)} – ${formatDayMonth(b)}';
}

/// «Июль 2026» / «July 2026» — месяц и год, с заглавной буквы.
String formatMonthYear(DateTime d) {
  final s = DateFormat('LLLL y').format(d);
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Короткое название месяца: «июл» / «Jul». Для подписей в сетке календаря.
String monthNameShort(int month) =>
    DateFormat('LLL').format(DateTime(2000, month)).replaceAll('.', '');

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
