import 'models.dart';

/// Ядро синхронизации DayLane Connected — чистая логика двустороннего слияния
/// «last-write-wins» по агрегатам (дело + его дети) с надгробиями (tombstones).
/// Без сети и БД: на вход — снимок локального и удалённого состояния, на выход —
/// план изменений. Транспорт (git/GitHub) и применение к Drift — снаружи.

/// Агрегат синхронизации: дело целиком со своими «детьми». Ключ — [TaskModel.syncUid].
class TaskAggregate {
  const TaskAggregate({
    required this.task,
    this.subtasks = const [],
    this.stages = const [],
    this.recurrenceDones = const [],
  });

  final TaskModel task;
  final List<SubtaskModel> subtasks;
  final List<TripStageModel> stages;

  /// Отмеченные выполненными вхождения повторяющегося дела (даты без времени).
  final List<DateTime> recurrenceDones;

  String get uid => task.syncUid;
  DateTime get updatedAt => task.updatedAt;
}

/// Снимок состояния одной стороны (локальной или удалённой): живые агрегаты и
/// надгробия, оба — по `syncUid`.
class SyncState {
  const SyncState({this.aggregates = const {}, this.tombstones = const {}});

  final Map<String, TaskAggregate> aggregates;
  final Map<String, DateTime> tombstones;

  static SyncState fromLists(
    Iterable<TaskAggregate> aggregates,
    Map<String, DateTime> tombstones,
  ) =>
      SyncState(
        aggregates: {
          for (final a in aggregates)
            if (a.uid.isNotEmpty) a.uid: a,
        },
        tombstones: tombstones,
      );
}

/// План слияния: что применить/удалить локально и что выгрузить на удалённую
/// сторону. Агрегаты с пустым `syncUid` в синхронизацию не попадают.
class SyncPlan {
  const SyncPlan({
    this.applyLocally = const [],
    this.deleteLocally = const [],
    this.push = const [],
    this.pushTombstones = const {},
  });

  /// Удалённые агрегаты, которые нужно вставить/перезаписать в локальной БД.
  final List<TaskAggregate> applyLocally;

  /// `syncUid` дел, которые нужно удалить локально (надгробие на удалённой новее).
  final List<String> deleteLocally;

  /// Локальные агрегаты, которые нужно записать на удалённую сторону.
  final List<TaskAggregate> push;

  /// Надгробия, которые нужно записать на удалённую сторону.
  final Map<String, DateTime> pushTombstones;

  bool get isEmpty =>
      applyLocally.isEmpty &&
      deleteLocally.isEmpty &&
      push.isEmpty &&
      pushTombstones.isEmpty;
}

/// Последнее событие стороны по `uid`: жив ли (alive) агрегат и на какой момент.
class _Side {
  const _Side(this.ts, this.dead, this.aggregate, this.deletedAt);
  final DateTime? ts; // момент последнего события (или null, если стороны нет)
  final bool dead; // true = последнее событие — удаление
  final TaskAggregate? aggregate; // живой агрегат (если есть)
  final DateTime? deletedAt; // момент надгробия (если есть)

  bool get present => ts != null;
}

_Side _sideOf(String uid, SyncState s) {
  final agg = s.aggregates[uid];
  final tomb = s.tombstones[uid];
  if (agg == null && tomb == null) {
    return const _Side(null, false, null, null);
  }
  final aliveTs = agg?.updatedAt;
  if (agg != null && (tomb == null || !tomb.isAfter(aliveTs!))) {
    // Живой новее (или нет надгробия): последнее событие — правка.
    return _Side(aliveTs, false, agg, tomb);
  }
  // Надгробие новее (или агрегата нет): последнее событие — удаление.
  return _Side(tomb, true, agg, tomb);
}

/// Строит план слияния локального и удалённого состояния (LWW по `updatedAt` /
/// `deletedAt`; при равенстве меток — no-op, чтобы не гонять данные туда-обратно).
SyncPlan planSync(SyncState local, SyncState remote) {
  final applyLocally = <TaskAggregate>[];
  final deleteLocally = <String>[];
  final push = <TaskAggregate>[];
  final pushTombstones = <String, DateTime>{};

  final uids = <String>{
    ...local.aggregates.keys,
    ...local.tombstones.keys,
    ...remote.aggregates.keys,
    ...remote.tombstones.keys,
  }..removeWhere((u) => u.isEmpty);

  for (final uid in uids) {
    final l = _sideOf(uid, local);
    final r = _sideOf(uid, remote);

    if (!l.present && !r.present) continue;

    // Одна из сторон отсутствует — присутствующая является истиной.
    if (!r.present) {
      if (l.dead) {
        pushTombstones[uid] = l.deletedAt!;
      } else {
        push.add(l.aggregate!);
      }
      continue;
    }
    if (!l.present) {
      if (!r.dead) applyLocally.add(r.aggregate!);
      // r.dead и локально пусто — нечего удалять, надгробие не тянем.
      continue;
    }

    // Обе стороны присутствуют — сравниваем момент последнего события.
    final cmp = l.ts!.compareTo(r.ts!);
    if (cmp == 0) continue; // ничья — no-op

    if (cmp < 0) {
      // Удалённая новее.
      if (r.dead) {
        if (!l.dead) deleteLocally.add(uid);
      } else {
        applyLocally.add(r.aggregate!);
      }
    } else {
      // Локальная новее.
      if (l.dead) {
        pushTombstones[uid] = l.deletedAt!;
      } else {
        push.add(l.aggregate!);
      }
    }
  }

  return SyncPlan(
    applyLocally: applyLocally,
    deleteLocally: deleteLocally,
    push: push,
    pushTombstones: pushTombstones,
  );
}
