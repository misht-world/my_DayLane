import 'package:drift/drift.dart' show Value;
import 'package:daylane/data/db.dart';
import 'package:daylane/domain/models.dart';
import 'package:daylane/services/sync_service.dart';
import 'package:daylane/services/sync_transport.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Фейковое хранилище: один JSON + sha, с оптимистичной блокировкой как у GitHub.
class FakeStore implements SyncStore {
  Map<String, dynamic>? json;
  int _sha = 0;

  @override
  Future<RemoteFile> pull() async =>
      RemoteFile(json, json == null ? null : '$_sha');

  @override
  Future<void> push(Map<String, dynamic> s, String? sha) async {
    final cur = json == null ? null : '$_sha';
    if (cur != sha) throw SyncConflictException();
    json = s;
    _sha++;
  }
}

TaskModel _t(String title, String uid, {DateTime? updated}) => TaskModel(
      syncUid: uid,
      title: title,
      kind: TaskKind.single,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updated ?? DateTime(2026, 1, 1),
    );

Future<int> _insert(AppDatabase db, TaskModel t) =>
    db.into(db.tasks).insert(t.toCompanion());

Future<int> _rowCount(AppDatabase db) async =>
    (await db.select(db.tasks).get()).length;

void main() {
  late AppDatabase desktop;
  late AppDatabase phone;
  late SyncService ds;
  late SyncService ps;
  late FakeStore store;

  setUp(() {
    desktop = AppDatabase.forTesting(NativeDatabase.memory());
    phone = AppDatabase.forTesting(NativeDatabase.memory());
    ds = SyncService(desktop);
    ps = SyncService(phone);
    store = FakeStore();
  });

  tearDown(() async {
    await desktop.close();
    await phone.close();
  });

  test('новое дело ПК → телефон, повторный синк не плодит дубликаты', () async {
    await _insert(desktop, _t('Kino', 'k1'));
    await ds.syncOnce(store); // push
    await ps.syncOnce(store); // pull → insert

    expect(await _rowCount(phone), 1);
    expect((await phone.readSyncState()).aggregates.keys, ['k1']);

    // Повторные синки телефона НЕ должны вставлять копии.
    await ps.syncOnce(store);
    await ps.syncOnce(store);
    expect(await _rowCount(phone), 1);
  });

  test('у каждого своё дело — объединение стабильно, без роста', () async {
    await _insert(desktop, _t('A', 'a'));
    await _insert(phone, _t('B', 'b'));

    // Несколько раундов туда-обратно.
    for (var i = 0; i < 4; i++) {
      await ds.syncOnce(store);
      await ps.syncOnce(store);
    }

    expect(await _rowCount(desktop), 2, reason: 'ПК: A+B без дублей');
    expect(await _rowCount(phone), 2, reason: 'телефон: A+B без дублей');
  });

  test('правка существующего дела доезжает, новое дело тоже; без дублей',
      () async {
    // Первый обмен: на обоих есть общее дело note (одинаковый uid).
    await _insert(desktop, _t('Note', 'n1', updated: DateTime(2026, 1, 1)));
    await ds.syncOnce(store);
    await ps.syncOnce(store);
    expect(await _rowCount(phone), 1);

    // ПК: правим note (свежий updatedAt) и добавляем новое дело temps.
    await (desktop.update(desktop.tasks)
          ..where((t) => t.syncUid.equals('n1')))
        .write(TasksCompanion(
            title: const Value('Note*'), updatedAt: Value(DateTime(2026, 1, 2))));
    await _insert(desktop, _t('temps', 't1', updated: DateTime(2026, 1, 2)));

    await ds.syncOnce(store); // push обе правки
    await ps.syncOnce(store); // телефон подтягивает

    final phoneRows = await phone.select(phone.tasks).get();
    expect(phoneRows.length, 2, reason: 'note + temps, без дублей');
    expect(phoneRows.map((r) => r.syncUid).toSet(), {'n1', 't1'});
    expect(phoneRows.firstWhere((r) => r.syncUid == 'n1').title, 'Note*');

    // Ещё раунды — счётчики не растут.
    for (var i = 0; i < 3; i++) {
      await ds.syncOnce(store);
      await ps.syncOnce(store);
    }
    expect(await _rowCount(desktop), 2);
    expect(await _rowCount(phone), 2);
  });

  test('dedupeBySyncUid оставляет самую свежую строку', () async {
    await _insert(desktop, _t('X old', 'dup', updated: DateTime(2026, 1, 1)));
    await _insert(desktop, _t('X new', 'dup', updated: DateTime(2026, 1, 5)));
    expect(await _rowCount(desktop), 2);
    await desktop.dedupeBySyncUid();
    final rows = await desktop.select(desktop.tasks).get();
    expect(rows.length, 1);
    expect(rows.single.title, 'X new');
  });

  test('удаление на ПК доезжает как надгробие', () async {
    await _insert(desktop, _t('X', 'x1'));
    await ds.syncOnce(store);
    await ps.syncOnce(store);
    expect(await _rowCount(phone), 1);

    // Удаляем на ПК с надгробием (как repository.deleteTask).
    await (desktop.delete(desktop.tasks)..where((t) => t.syncUid.equals('x1')))
        .go();
    await desktop.recordTombstone('x1', DateTime(2026, 1, 3));

    await ds.syncOnce(store);
    await ps.syncOnce(store);
    expect(await _rowCount(phone), 0, reason: 'телефон удалил по надгробию');
  });
}
