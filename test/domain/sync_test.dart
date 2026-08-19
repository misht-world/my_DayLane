import 'package:daylane/domain/models.dart';
import 'package:daylane/domain/sync.dart';
import 'package:flutter_test/flutter_test.dart';

/// Дело с заданными `syncUid` и `updatedAt` (в мс) — остальное неважно для merge.
TaskModel _task(String uid, int ms) => TaskModel(
      syncUid: uid,
      title: 'x',
      kind: TaskKind.single,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 1),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(ms),
      createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
    );

TaskAggregate _agg(String uid, int ms) => TaskAggregate(task: _task(uid, ms));
DateTime _d(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

SyncState _state({
  List<TaskAggregate> alive = const [],
  Map<String, int> dead = const {},
}) =>
    SyncState.fromLists(
      alive,
      {for (final e in dead.entries) e.key: _d(e.value)},
    );

void main() {
  group('planSync', () {
    test('новое на удалённой — применяем локально', () {
      final plan = planSync(_state(), _state(alive: [_agg('a', 100)]));
      expect(plan.applyLocally.map((a) => a.uid), ['a']);
      expect(plan.push, isEmpty);
      expect(plan.deleteLocally, isEmpty);
    });

    test('новое на локальной — выгружаем', () {
      final plan = planSync(_state(alive: [_agg('a', 100)]), _state());
      expect(plan.push.map((a) => a.uid), ['a']);
      expect(plan.applyLocally, isEmpty);
    });

    test('удалённая версия новее — применяем локально', () {
      final plan = planSync(
        _state(alive: [_agg('a', 100)]),
        _state(alive: [_agg('a', 200)]),
      );
      expect(plan.applyLocally.single.updatedAt, _d(200));
      expect(plan.push, isEmpty);
    });

    test('локальная версия новее — выгружаем', () {
      final plan = planSync(
        _state(alive: [_agg('a', 300)]),
        _state(alive: [_agg('a', 200)]),
      );
      expect(plan.push.single.updatedAt, _d(300));
      expect(plan.applyLocally, isEmpty);
    });

    test('ничья по updatedAt — no-op', () {
      final plan = planSync(
        _state(alive: [_agg('a', 200)]),
        _state(alive: [_agg('a', 200)]),
      );
      expect(plan.isEmpty, isTrue);
    });

    test('надгробие на удалённой новее живого локального — удаляем локально', () {
      final plan = planSync(
        _state(alive: [_agg('a', 100)]),
        _state(dead: {'a': 200}),
      );
      expect(plan.deleteLocally, ['a']);
      expect(plan.applyLocally, isEmpty);
      expect(plan.push, isEmpty);
    });

    test('локальное надгробие, удалённой стороны нет — выгружаем надгробие', () {
      final plan = planSync(_state(dead: {'a': 200}), _state());
      expect(plan.pushTombstones, {'a': _d(200)});
      expect(plan.push, isEmpty);
    });

    test('локальное надгробие новее живого удалённого — выгружаем надгробие', () {
      final plan = planSync(
        _state(dead: {'a': 300}),
        _state(alive: [_agg('a', 200)]),
      );
      expect(plan.pushTombstones, {'a': _d(300)});
      expect(plan.applyLocally, isEmpty);
      expect(plan.deleteLocally, isEmpty);
    });

    test('живой удалённый новее локального надгробия — воскрешаем локально', () {
      final plan = planSync(
        _state(dead: {'a': 200}),
        _state(alive: [_agg('a', 300)]),
      );
      expect(plan.applyLocally.single.updatedAt, _d(300));
      expect(plan.deleteLocally, isEmpty);
    });

    test('обе стороны удалили — no-op', () {
      final plan = planSync(_state(dead: {'a': 200}), _state(dead: {'a': 100}));
      // Локальное надгробие новее — но удалять локально нечего, а на удалёнке
      // надгробие уже есть; выгрузка более свежей метки допустима, но не обязательна.
      expect(plan.applyLocally, isEmpty);
      expect(plan.deleteLocally, isEmpty);
    });

    test('пустой syncUid в синхронизацию не попадает', () {
      final plan = planSync(_state(), _state(alive: [_agg('', 100)]));
      expect(plan.isEmpty, isTrue);
    });

    test('несколько дел разом', () {
      final plan = planSync(
        _state(alive: [_agg('keepLocal', 300), _agg('same', 100)]),
        _state(alive: [_agg('fromRemote', 100), _agg('same', 100)]),
      );
      expect(plan.push.map((a) => a.uid), ['keepLocal']);
      expect(plan.applyLocally.map((a) => a.uid), ['fromRemote']);
    });
  });
}
