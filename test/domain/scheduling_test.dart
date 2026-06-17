import 'package:daylane/domain/models.dart';
import 'package:daylane/domain/scheduling.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('isPresentOn', () {
    test('single присутствует только в свой день', () {
      final t = task(start: d(2026, 6, 17));
      expect(isPresentOn(t, d(2026, 6, 16)), isFalse);
      expect(isPresentOn(t, d(2026, 6, 17)), isTrue);
      expect(isPresentOn(t, d(2026, 6, 18)), isFalse);
    });

    test('игнорирует время дня в day', () {
      final t = task(start: d(2026, 6, 17));
      expect(isPresentOn(t, DateTime(2026, 6, 17, 23, 59)), isTrue);
    });

    test('period присутствует в каждый день включительно', () {
      final t = task(
        kind: TaskKind.period,
        start: d(2026, 6, 17),
        end: d(2026, 6, 20),
      );
      expect(isPresentOn(t, d(2026, 6, 16)), isFalse);
      expect(isPresentOn(t, d(2026, 6, 17)), isTrue);
      expect(isPresentOn(t, d(2026, 6, 19)), isTrue);
      expect(isPresentOn(t, d(2026, 6, 20)), isTrue);
      expect(isPresentOn(t, d(2026, 6, 21)), isFalse);
    });
  });

  test('dayNumberOf — «день N из M»', () {
    final t = task(
      kind: TaskKind.period,
      start: d(2026, 6, 17),
      end: d(2026, 6, 20),
    );
    expect(dayNumberOf(t, d(2026, 6, 17)), 1);
    expect(dayNumberOf(t, d(2026, 6, 18)), 2);
    expect(dayNumberOf(t, d(2026, 6, 20)), 4);
  });

  group('isOverdue', () {
    final today = d(2026, 6, 17);
    test('невыполненное в прошлом — просрочено', () {
      expect(isOverdue(task(start: d(2026, 6, 16)), today), isTrue);
    });
    test('выполненное — не просрочено', () {
      expect(isOverdue(task(start: d(2026, 6, 16), isDone: true), today),
          isFalse);
    });
    test('сегодня/будущее — не просрочено', () {
      expect(isOverdue(task(start: today), today), isFalse);
      expect(isOverdue(task(start: d(2026, 6, 18)), today), isFalse);
    });
    test('период, кончившийся вчера — просрочен', () {
      final t = task(
          kind: TaskKind.period, start: d(2026, 6, 10), end: d(2026, 6, 16));
      expect(isOverdue(t, today), isTrue);
    });
  });

  group('buildSections', () {
    final now = d(2026, 6, 17);

    test('распределяет по горизонтам', () {
      final tasks = [
        task(id: 1, start: d(2026, 6, 16)), // вчера, не выполнено
        task(id: 2, start: d(2026, 6, 16), isDone: true), // вчера выполнено
        task(id: 3, start: d(2026, 6, 17)), // сегодня
        task(id: 4, start: d(2026, 6, 18)), // завтра
        task(
            id: 5,
            kind: TaskKind.period,
            start: d(2026, 6, 16),
            end: d(2026, 6, 18)), // во всех трёх
      ];
      final s = buildSections(tasks, now);
      expect(s.yesterday.map((t) => t.id), [1, 5]); // выполненное #2 скрыто
      expect(s.today.map((t) => t.id), containsAll([3, 5]));
      expect(s.tomorrow.map((t) => t.id), containsAll([4, 5]));
    });

    test('сегодня включает выполненные', () {
      final tasks = [task(id: 1, start: now, isDone: true)];
      expect(buildSections(tasks, now).today.map((t) => t.id), [1]);
    });

    test('сортировка по времени дня, без времени — в конце', () {
      final tasks = [
        task(id: 1, start: now, timeOfDayMinutes: null),
        task(id: 2, start: now, timeOfDayMinutes: 9 * 60),
        task(id: 3, start: now, timeOfDayMinutes: 8 * 60),
      ];
      expect(buildSections(tasks, now).today.map((t) => t.id), [3, 2, 1]);
    });
  });
}
