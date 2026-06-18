import 'package:daylane/domain/models.dart';
import 'package:daylane/domain/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

TaskModel rec(
  DateTime start,
  RecurrenceType type, {
  int interval = 1,
  int anchor = 0,
}) {
  final created = DateTime(2020, 1, 1);
  return TaskModel(
    title: 'r',
    kind: TaskKind.single,
    startDate: start,
    endDate: start,
    recurrenceType: type,
    recurrenceInterval: interval,
    recurrenceAnchor: anchor,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  test('до даты старта — не происходит', () {
    final t = rec(d(2026, 6, 10), RecurrenceType.days);
    expect(occursOn(t, d(2026, 6, 9)), isFalse);
    expect(occursOn(t, d(2026, 6, 10)), isTrue);
  });

  test('каждые N дней', () {
    final t = rec(d(2026, 6, 1), RecurrenceType.days, interval: 3);
    expect(occursOn(t, d(2026, 6, 1)), isTrue);
    expect(occursOn(t, d(2026, 6, 2)), isFalse);
    expect(occursOn(t, d(2026, 6, 4)), isTrue);
    expect(occursOn(t, d(2026, 6, 7)), isTrue);
  });

  test('каждые N недель по дню недели', () {
    final t = rec(d(2026, 6, 1), RecurrenceType.weeks, interval: 2); // пн
    expect(occursOn(t, d(2026, 6, 1)), isTrue);
    expect(occursOn(t, d(2026, 6, 8)), isFalse); // через 1 неделю
    expect(occursOn(t, d(2026, 6, 15)), isTrue); // через 2
    expect(occursOn(t, d(2026, 6, 16)), isFalse); // вторник
  });

  test('каждый месяц по числу', () {
    final t = rec(d(2026, 1, 15), RecurrenceType.months);
    expect(occursOn(t, d(2026, 2, 15)), isTrue);
    expect(occursOn(t, d(2026, 3, 15)), isTrue);
    expect(occursOn(t, d(2026, 3, 16)), isFalse);
  });

  test('месяц по числу 31 — обрезка до последнего дня короткого месяца', () {
    final t = rec(d(2026, 1, 31), RecurrenceType.months);
    expect(occursOn(t, d(2026, 2, 28)), isTrue); // февраль обрезан
    expect(occursOn(t, d(2026, 3, 31)), isTrue);
    expect(occursOn(t, d(2026, 4, 30)), isTrue); // апрель обрезан
  });

  test('каждый год (ДР)', () {
    final t = rec(d(2026, 3, 20), RecurrenceType.years);
    expect(occursOn(t, d(2027, 3, 20)), isTrue);
    expect(occursOn(t, d(2028, 3, 20)), isTrue);
    expect(occursOn(t, d(2027, 3, 21)), isFalse);
  });

  test('последний день месяца', () {
    final t = rec(d(2026, 1, 31), RecurrenceType.monthLastDay);
    expect(occursOn(t, d(2026, 2, 28)), isTrue);
    expect(occursOn(t, d(2026, 4, 30)), isTrue);
    expect(occursOn(t, d(2026, 4, 29)), isFalse);
  });

  test('за K дней до конца месяца', () {
    final t = rec(d(2026, 1, 1), RecurrenceType.monthBeforeEnd, anchor: 2);
    expect(occursOn(t, d(2026, 1, 29)), isTrue); // 31 - 2
    expect(occursOn(t, d(2026, 2, 26)), isTrue); // 28 - 2
    expect(occursOn(t, d(2026, 4, 28)), isTrue); // 30 - 2
  });

  test('nextOccurrences возвращает ближайшие вхождения', () {
    final t = rec(d(2026, 6, 1), RecurrenceType.days, interval: 7);
    final occ = nextOccurrences(t, d(2026, 6, 3), 3);
    expect(occ, [d(2026, 6, 8), d(2026, 6, 15), d(2026, 6, 22)]);
  });
}
