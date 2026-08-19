import 'models.dart';
import 'sync.dart';

/// Сериализация агрегата дела в JSON и обратно — формат файла синхронизации
/// `/tasks/<syncUid>.json`. Локальные автоинкрементные `id` НЕ сохраняются
/// (на разных устройствах разные): идентичность — только по `syncUid`.
/// Дети (подпункты/этапы/отметки повторений) едут внутри и при применении
/// заменяются целиком, поэтому их локальные id тоже не нужны.

int _ms(DateTime d) => d.millisecondsSinceEpoch;
int? _msN(DateTime? d) => d?.millisecondsSinceEpoch;
DateTime _dt(Object? v) => DateTime.fromMillisecondsSinceEpoch(v as int);
DateTime? _dtN(Object? v) =>
    v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

/// Версия формата файла состояния синхронизации (`state.json` в репозитории).
const int kSyncFormat = 1;

/// Всё состояние синхронизации → JSON (единый файл `state.json`): живые агрегаты
/// по `syncUid` и надгробия. Из этого файла ПК и телефон и обмениваются.
/// [idToUid] переводит локальный id зависимости («Начать после/до дела») в
/// стабильный `syncUid` — локальные id на разных устройствах разные.
Map<String, dynamic> syncStateToJson(SyncState s,
        [Map<int, String> idToUid = const {}]) =>
    {
      'format': kSyncFormat,
      'tasks': {
        for (final e in s.aggregates.entries)
          e.key: aggregateToJson(e.value, idToUid),
      },
      'tombstones': {
        for (final e in s.tombstones.entries)
          e.key: e.value.millisecondsSinceEpoch,
      },
    };

/// [uidToId] переводит `syncUid` зависимости обратно в локальный id этого
/// устройства (null, если такой задачи локально ещё нет).
SyncState syncStateFromJson(Map<String, dynamic> j,
    [Map<String, int> uidToId = const {}]) {
  final tasks = (j['tasks'] as Map?) ?? const {};
  final tombs = (j['tombstones'] as Map?) ?? const {};
  return SyncState(
    aggregates: {
      for (final e in tasks.entries)
        e.key as String: aggregateFromJson(
            (e.value as Map).cast<String, dynamic>(), uidToId),
    },
    tombstones: {
      for (final e in tombs.entries) e.key as String: _dt(e.value),
    },
  );
}

Map<String, dynamic> aggregateToJson(TaskAggregate a,
    [Map<int, String> idToUid = const {}]) {
  final t = a.task;
  return {
    'task': {
      'syncUid': t.syncUid,
      'title': t.title,
      'kind': t.kind.index,
      'startDate': _ms(t.startDate),
      'endDate': _ms(t.endDate),
      'durationDays': t.durationDays,
      // Зависимость — по syncUid (кросс-устройственно), не по локальному id.
      'dependsOnUid':
          t.dependsOnTaskId == null ? null : idToUid[t.dependsOnTaskId],
      'dependsBefore': t.dependsBefore,
      'timeOfDayMinutes': t.timeOfDayMinutes,
      'reminderEnabled': t.reminderEnabled,
      'reminderRule': t.reminderRule.index,
      'reminderMinutes': t.reminderMinutes,
      'reminderDaysBefore': t.reminderDaysBefore,
      'colorId': t.colorId,
      'iconId': t.iconId,
      'deferred': t.deferred,
      'isTrip': t.isTrip,
      'noteCategory': t.noteCategory,
      'author': t.author,
      'year': t.year,
      'audience': t.audience,
      'recurrenceType': t.recurrenceType.index,
      'recurrenceInterval': t.recurrenceInterval,
      'recurrenceAnchor': t.recurrenceAnchor,
      'note': t.note,
      'placeName': t.placeName,
      'placeUrl': t.placeUrl,
      'links': t.links,
      'isDone': t.isDone,
      'completedAt': _msN(t.completedAt),
      'carriedOver': t.carriedOver,
      'sortIndex': t.sortIndex,
      'createdAt': _ms(t.createdAt),
      'updatedAt': _ms(t.updatedAt),
    },
    'subtasks': [
      for (final s in a.subtasks)
        {'title': s.title, 'isDone': s.isDone, 'sortIndex': s.sortIndex},
    ],
    'stages': [
      for (final s in a.stages)
        {
          'title': s.title,
          'kind': s.kind.index,
          'startDate': _ms(s.startDate),
          'endDate': _ms(s.endDate),
          'placeName': s.placeName,
          'placeUrl': s.placeUrl,
          'timeMinutes': s.timeMinutes,
          'isDone': s.isDone,
          'note': s.note,
          'links': s.links,
          'sortIndex': s.sortIndex,
        },
    ],
    'recurrenceDones': [for (final d in a.recurrenceDones) _ms(d)],
  };
}

TaskAggregate aggregateFromJson(Map<String, dynamic> j,
    [Map<String, int> uidToId = const {}]) {
  final t = j['task'] as Map<String, dynamic>;
  final depUid = t['dependsOnUid'] as String?;
  final task = TaskModel(
    syncUid: t['syncUid'] as String? ?? '',
    title: t['title'] as String? ?? '',
    kind: TaskKind.values[t['kind'] as int? ?? 0],
    startDate: _dt(t['startDate']),
    endDate: _dt(t['endDate']),
    durationDays: t['durationDays'] as int? ?? 1,
    // Переводим syncUid зависимости в локальный id (null, если её тут ещё нет).
    dependsOnTaskId: depUid == null ? null : uidToId[depUid],
    dependsBefore: t['dependsBefore'] as bool? ?? false,
    timeOfDayMinutes: t['timeOfDayMinutes'] as int?,
    reminderEnabled: t['reminderEnabled'] as bool? ?? false,
    reminderRule: ReminderRule.values[t['reminderRule'] as int? ?? 0],
    reminderMinutes: t['reminderMinutes'] as int? ?? 540,
    reminderDaysBefore: t['reminderDaysBefore'] as int? ?? 0,
    colorId: t['colorId'] as int? ?? -1,
    iconId: t['iconId'] as int? ?? -1,
    deferred: t['deferred'] as bool? ?? false,
    isTrip: t['isTrip'] as bool? ?? false,
    noteCategory: t['noteCategory'] as int? ?? -1,
    author: t['author'] as String? ?? '',
    year: t['year'] as int?,
    audience: t['audience'] as int? ?? 0,
    recurrenceType: RecurrenceType.values[t['recurrenceType'] as int? ?? 0],
    recurrenceInterval: t['recurrenceInterval'] as int? ?? 1,
    recurrenceAnchor: t['recurrenceAnchor'] as int? ?? 0,
    note: t['note'] as String? ?? '',
    placeName: t['placeName'] as String? ?? '',
    placeUrl: t['placeUrl'] as String? ?? '',
    links: t['links'] as String? ?? '',
    isDone: t['isDone'] as bool? ?? false,
    completedAt: _dtN(t['completedAt']),
    carriedOver: t['carriedOver'] as bool? ?? false,
    sortIndex: t['sortIndex'] as int? ?? 0,
    createdAt: _dt(t['createdAt']),
    updatedAt: _dt(t['updatedAt']),
  );
  return TaskAggregate(
    task: task,
    subtasks: [
      for (final s in (j['subtasks'] as List? ?? const []))
        SubtaskModel(
          taskId: 0,
          title: (s as Map)['title'] as String? ?? '',
          isDone: s['isDone'] as bool? ?? false,
          sortIndex: s['sortIndex'] as int? ?? 0,
        ),
    ],
    stages: [
      for (final s in (j['stages'] as List? ?? const []))
        TripStageModel(
          taskId: 0,
          title: (s as Map)['title'] as String? ?? '',
          kind: TripStageKind.values[s['kind'] as int? ?? 1],
          startDate: _dt(s['startDate']),
          endDate: _dt(s['endDate']),
          placeName: s['placeName'] as String? ?? '',
          placeUrl: s['placeUrl'] as String? ?? '',
          timeMinutes: s['timeMinutes'] as int?,
          isDone: s['isDone'] as bool? ?? false,
          note: s['note'] as String? ?? '',
          links: s['links'] as String? ?? '',
          sortIndex: s['sortIndex'] as int? ?? 0,
        ),
    ],
    recurrenceDones: [
      for (final d in (j['recurrenceDones'] as List? ?? const []))
        _dt(d),
    ],
  );
}
