import 'package:daylane/domain/dependencies.dart';
import 'package:daylane/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('wouldCreateCycle', () {
    test('самопривязка — цикл', () {
      expect(wouldCreateCycle({}, 1, 1), isTrue);
    });

    test('прямой цикл A→B, B→A', () {
      final a = task(id: 1, start: d(2026, 6, 1));
      final b = task(id: 2, start: d(2026, 6, 2), dependsOnTaskId: 1);
      final byId = {1: a, 2: b};
      // привязать A к B создаст цикл (B уже зависит от A)
      expect(wouldCreateCycle(byId, 1, 2), isTrue);
    });

    test('нет цикла для независимых', () {
      final a = task(id: 1, start: d(2026, 6, 1));
      final b = task(id: 2, start: d(2026, 6, 2));
      expect(wouldCreateCycle({1: a, 2: b}, 1, 2), isFalse);
    });

    test('транзитивный цикл: цепочка c→b→a, привязать A к C', () {
      // b зависит от a, c зависит от b. Привязка A→C замкнёт цикл.
      final a = task(id: 1, start: d(2026, 6, 1));
      final b = task(id: 2, start: d(2026, 6, 2), dependsOnTaskId: 1);
      final c = task(id: 3, start: d(2026, 6, 3), dependsOnTaskId: 2);
      final byId = {1: a, 2: b, 3: c};
      expect(wouldCreateCycle(byId, 1, 3), isTrue);
      // А привязать C к A цикла НЕ создаёт (C и так зависит от A через B).
      expect(wouldCreateCycle(byId, 3, 1), isFalse);
    });
  });

  group('eligibleParents', () {
    final now = d(2026, 6, 17);
    test('исключает себя, прошлые однодневные; включает периоды и будущие', () {
      final child = task(
          id: 1, kind: TaskKind.period, start: d(2026, 6, 20), end: d(2026, 6, 22));
      final all = [
        child,
        task(id: 2, start: d(2026, 6, 10)), // прошлое однодневное — нет
        task(id: 3, start: d(2026, 6, 25)), // будущее однодневное — да
        task(id: 4, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 5)), // период — да
      ];
      final ids = eligibleParents(all, child, now).map((t) => t.id).toSet();
      expect(ids, {3, 4});
    });

    test('исключает кандидатов, создающих цикл', () {
      final a = task(id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 5));
      final b = task(
          id: 2,
          kind: TaskKind.period,
          start: d(2026, 6, 6),
          end: d(2026, 6, 8),
          dependsOnTaskId: 1);
      // для A родителем не может быть B (B зависит от A)
      final ids = eligibleParents([a, b], a, now).map((t) => t.id).toSet();
      expect(ids, isNot(contains(2)));
    });
  });

  group('applyDependencyDates', () {
    TaskModel byId(List<TaskModel> l, int id) =>
        l.firstWhere((t) => t.id == id);

    test('start ребёнка = end родителя + 1, длина сохраняется', () {
      final parent = task(
          id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 5));
      final child = task(
          id: 2,
          kind: TaskKind.period,
          start: d(2026, 1, 1),
          end: d(2026, 1, 2),
          durationDays: 3,
          dependsOnTaskId: 1);
      final r = applyDependencyDates([parent, child]);
      final c = byId(r, 2);
      expect(c.startDate, d(2026, 6, 6));
      expect(c.endDate, d(2026, 6, 8)); // 3 дня
    });

    test('каскад по цепочке A→B→C', () {
      final a = task(
          id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 3));
      final b = task(
          id: 2,
          kind: TaskKind.period,
          start: d(2020, 1, 1),
          durationDays: 2,
          dependsOnTaskId: 1);
      final c = task(
          id: 3,
          kind: TaskKind.period,
          start: d(2020, 1, 1),
          durationDays: 1,
          dependsOnTaskId: 2);
      final r = applyDependencyDates([a, b, c]);
      expect(byId(r, 2).startDate, d(2026, 6, 4));
      expect(byId(r, 2).endDate, d(2026, 6, 5));
      expect(byId(r, 3).startDate, d(2026, 6, 6));
      expect(byId(r, 3).endDate, d(2026, 6, 6));
    });

    test('привязка на отсутствующего родителя — даты не меняются', () {
      final child = task(
          id: 2,
          kind: TaskKind.period,
          start: d(2026, 6, 10),
          end: d(2026, 6, 12),
          durationDays: 3,
          dependsOnTaskId: 99);
      final r = applyDependencyDates([child]);
      expect(byId(r, 2).startDate, d(2026, 6, 10));
    });
  });

  test('detachChildrenOf снимает привязку у детей', () {
    final a = task(id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 3));
    final b = task(id: 2, kind: TaskKind.period, start: d(2026, 6, 4), dependsOnTaskId: 1);
    final r = detachChildrenOf([a, b], 1);
    expect(r.firstWhere((t) => t.id == 2).dependsOnTaskId, isNull);
  });
}
