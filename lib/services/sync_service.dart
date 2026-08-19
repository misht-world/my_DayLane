import '../data/db.dart';
import '../domain/sync.dart';
import '../domain/sync_codec.dart';
import 'sync_transport.dart';

/// Итог одной синхронизации (для статуса в интерфейсе).
class SyncResult {
  const SyncResult({
    required this.applied,
    required this.deleted,
    required this.pushed,
    required this.pushedRemote,
  });

  final int applied; // дел применено локально из облака
  final int deleted; // дел удалено локально по надгробию из облака
  final int pushed; // дел/надгробий выгружено в облако
  final bool pushedRemote; // была ли запись в облако

  bool get changedLocally => applied > 0 || deleted > 0;
}

/// Оркестратор синхронизации: читает локальный снимок, тянет облако, сливает по
/// LWW (движок [planSync]), применяет облачные изменения в БД и выгружает свои,
/// накладывая их поверх облачного файла (чтобы не терять чужие записи).
class SyncService {
  SyncService(this._db);
  final AppDatabase _db;

  Future<SyncResult> syncOnce(SyncStore store) async {
    // Несколько попыток — если между чтением и записью облако успели изменить.
    for (var attempt = 0;; attempt++) {
      final local = await _db.readSyncState();

      // Карты перевода локальный id ↔ syncUid для зависимостей дел.
      final idToUid = <int, String>{};
      final uidToId = <String, int>{};
      for (final a in local.aggregates.values) {
        final id = a.task.id;
        if (id != null) {
          idToUid[id] = a.uid;
          uidToId[a.uid] = id;
        }
      }

      final remoteFile = await store.pull();
      final remote = remoteFile.json == null
          ? const SyncState()
          : syncStateFromJson(remoteFile.json!, uidToId);

      final plan = planSync(local, remote);

      // Облако → локальная БД.
      for (final a in plan.applyLocally) {
        await _db.applyRemoteAggregate(a);
      }
      for (final uid in plan.deleteLocally) {
        await _db.deleteBySyncUid(
            uid, remote.tombstones[uid] ?? DateTime.now());
      }

      final needPush = plan.push.isNotEmpty || plan.pushTombstones.isNotEmpty;
      if (needPush) {
        // Наложение поверх облачного файла: сохраняем чужие записи как есть,
        // переписываем только то, где локальная сторона новее.
        final tasksMap = <String, dynamic>{};
        final tombMap = <String, dynamic>{};
        final base = remoteFile.json;
        if (base != null) {
          tasksMap.addAll(
              ((base['tasks'] as Map?) ?? const {}).cast<String, dynamic>());
          tombMap.addAll(((base['tombstones'] as Map?) ?? const {})
              .cast<String, dynamic>());
        }
        for (final a in plan.push) {
          tasksMap[a.uid] = aggregateToJson(a, idToUid);
          tombMap.remove(a.uid);
        }
        plan.pushTombstones.forEach((uid, at) {
          tombMap[uid] = at.millisecondsSinceEpoch;
          tasksMap.remove(uid);
        });

        final out = {
          'format': kSyncFormat,
          'tasks': tasksMap,
          'tombstones': tombMap,
        };
        try {
          await store.push(out, remoteFile.sha);
        } on SyncConflictException {
          if (attempt < 3) continue; // перечитать и повторить
          rethrow;
        }
      }

      return SyncResult(
        applied: plan.applyLocally.length,
        deleted: plan.deleteLocally.length,
        pushed: plan.push.length + plan.pushTombstones.length,
        pushedRemote: needPush,
      );
    }
  }
}
