import 'package:daylane/domain/carry_over.dart';
import 'package:daylane/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final now = d(2026, 6, 17);

  group('carryToToday', () {
    test('переносит однодневное на сегодня и помечает', () {
      final t = carryToToday(task(id: 1, start: d(2026, 6, 14)), now);
      expect(t.startDate, now);
      expect(t.endDate, now);
      expect(t.carriedOver, isTrue);
    });

    test('многодневное не переносит', () {
      final p = task(
          id: 1, kind: TaskKind.period, start: d(2026, 6, 14), end: d(2026, 6, 20));
      expect(carryToToday(p, now).startDate, d(2026, 6, 14));
    });

    test('повторяющееся не переносит (иначе сломается якорь повтора)', () {
      final r = task(
          id: 1,
          start: d(2026, 6, 14),
          recurrenceType: RecurrenceType.years);
      final out = carryToToday(r, now);
      expect(out.startDate, d(2026, 6, 14));
      expect(out.carriedOver, isFalse);
    });
  });

  test('carryCandidates — только прошлые невыполненные single', () {
    final tasks = [
      task(id: 1, start: d(2026, 6, 14)), // да
      task(id: 2, start: d(2026, 6, 14), isDone: true), // нет, выполнено
      task(id: 3, start: now), // нет, сегодня
      task(id: 4, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 5)), // нет, период
      task(id: 5, start: d(2026, 6, 14), recurrenceType: RecurrenceType.years), // нет, повтор
    ];
    expect(carryCandidates(tasks, now).map((t) => t.id), [1]);
  });

  test('applyAutoCarry переносит всех кандидатов', () {
    final tasks = [
      task(id: 1, start: d(2026, 6, 14)),
      task(id: 2, start: d(2026, 6, 10)),
      task(id: 3, start: now),
    ];
    final r = applyAutoCarry(tasks, now);
    expect(r.firstWhere((t) => t.id == 1).startDate, now);
    expect(r.firstWhere((t) => t.id == 2).startDate, now);
    expect(r.firstWhere((t) => t.id == 3).startDate, now); // не тронут
    expect(r.firstWhere((t) => t.id == 3).carriedOver, isFalse);
  });

  test('clearStaleCarryFlags сбрасывает старые метки', () {
    final tasks = [
      task(id: 1, start: now, carriedOver: true), // сегодня — оставить
      task(id: 2, start: d(2026, 6, 14), carriedOver: true), // не сегодня — сбросить
    ];
    final r = clearStaleCarryFlags(tasks, now);
    expect(r.firstWhere((t) => t.id == 1).carriedOver, isTrue);
    expect(r.firstWhere((t) => t.id == 2).carriedOver, isFalse);
  });
}
