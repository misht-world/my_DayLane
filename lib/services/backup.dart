import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../data/db.dart';
import '../domain/models.dart';

/// Экспорт/импорт всех данных (дела, подпункты, отметки вхождений, настройки)
/// в один JSON-файл — для резервной копии и переноса между устройствами.
class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  static const int format = 1;

  Future<String> buildJson() async {
    final tasks = await _db.select(_db.tasks).get();
    final subs = await _db.select(_db.subtasks).get();
    final dones = await _db.select(_db.recurrenceDones).get();
    final stages = await _db.select(_db.tripStages).get();
    final s = await _db.getSettings();
    int? ms(DateTime? d) => d?.millisecondsSinceEpoch;

    final map = {
      'app': 'DayLane',
      'format': format,
      'schema': _db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': [
        for (final t in tasks)
          {
            'id': t.id,
            'title': t.title,
            'kind': t.kind.index,
            'startDate': t.startDate.millisecondsSinceEpoch,
            'endDate': t.endDate.millisecondsSinceEpoch,
            'durationDays': t.durationDays,
            'dependsOnTaskId': t.dependsOnTaskId,
            'timeOfDayMinutes': t.timeOfDayMinutes,
            'reminderEnabled': t.reminderEnabled,
            'reminderRule': t.reminderRule.index,
            'reminderMinutes': t.reminderMinutes,
            'reminderDaysBefore': t.reminderDaysBefore,
            'colorId': t.colorId,
            'deferred': t.deferred,
            'isTrip': t.isTrip,
            'recurrenceType': t.recurrenceType.index,
            'recurrenceInterval': t.recurrenceInterval,
            'recurrenceAnchor': t.recurrenceAnchor,
            'note': t.note,
            'isDone': t.isDone,
            'completedAt': ms(t.completedAt),
            'carriedOver': t.carriedOver,
            'sortIndex': t.sortIndex,
            'createdAt': t.createdAt.millisecondsSinceEpoch,
            'updatedAt': t.updatedAt.millisecondsSinceEpoch,
          }
      ],
      'subtasks': [
        for (final x in subs)
          {
            'id': x.id,
            'taskId': x.taskId,
            'title': x.title,
            'isDone': x.isDone,
            'sortIndex': x.sortIndex,
          }
      ],
      'recurrenceDones': [
        for (final x in dones)
          {'id': x.id, 'taskId': x.taskId, 'date': x.date.millisecondsSinceEpoch}
      ],
      'tripStages': [
        for (final x in stages)
          {
            'id': x.id,
            'taskId': x.taskId,
            'title': x.title,
            'kind': x.kind.index,
            'startDate': x.startDate.millisecondsSinceEpoch,
            'endDate': x.endDate.millisecondsSinceEpoch,
            'placeName': x.placeName,
            'placeUrl': x.placeUrl,
            'note': x.note,
            'sortIndex': x.sortIndex,
          }
      ],
      'settings': {
        'autoCarry': s.autoCarry,
        'themeMode': s.themeMode,
        'firstWeekday': s.firstWeekday,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Пишет резервную копию во временный файл, возвращает его.
  Future<File> exportToFile() async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final name =
        'daylane-backup-${now.year}${two(now.month)}${two(now.day)}.json';
    final f = File('${dir.path}/$name');
    await f.writeAsString(await buildJson());
    return f;
  }

  /// Полностью заменяет данные содержимым [jsonStr]. Возвращает число дел.
  Future<int> import(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (data['app'] != 'DayLane') {
      throw const FormatException('Не похоже на резервную копию DayLane');
    }
    final tasks = (data['tasks'] as List).cast<Map<String, dynamic>>();
    final subs =
        (data['subtasks'] as List? ?? const []).cast<Map<String, dynamic>>();
    final dones = (data['recurrenceDones'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final stages = (data['tripStages'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final settings = data['settings'] as Map<String, dynamic>?;
    DateTime dt(Object? v) =>
        DateTime.fromMillisecondsSinceEpoch((v as num).toInt());

    await _db.transaction(() async {
      await _db.delete(_db.tripStages).go();
      await _db.delete(_db.recurrenceDones).go();
      await _db.delete(_db.subtasks).go();
      await _db.delete(_db.tasks).go();

      for (final t in tasks) {
        await _db.into(_db.tasks).insert(TasksCompanion(
              id: Value(t['id'] as int),
              title: Value(t['title'] as String),
              kind: Value(TaskKind.values[t['kind'] as int]),
              startDate: Value(dt(t['startDate'])),
              endDate: Value(dt(t['endDate'])),
              durationDays: Value(t['durationDays'] as int),
              dependsOnTaskId: Value(t['dependsOnTaskId'] as int?),
              timeOfDayMinutes: Value(t['timeOfDayMinutes'] as int?),
              reminderEnabled: Value(t['reminderEnabled'] as bool),
              reminderRule: Value(ReminderRule.values[t['reminderRule'] as int]),
              reminderMinutes: Value(t['reminderMinutes'] as int),
              reminderDaysBefore: Value(t['reminderDaysBefore'] as int? ?? 0),
              colorId: Value(t['colorId'] as int? ?? -1),
              deferred: Value(t['deferred'] as bool? ?? false),
              isTrip: Value(t['isTrip'] as bool? ?? false),
              recurrenceType: Value(
                  RecurrenceType.values[t['recurrenceType'] as int? ?? 0]),
              recurrenceInterval: Value(t['recurrenceInterval'] as int? ?? 1),
              recurrenceAnchor: Value(t['recurrenceAnchor'] as int? ?? 0),
              note: Value(t['note'] as String? ?? ''),
              isDone: Value(t['isDone'] as bool),
              completedAt: Value(
                  t['completedAt'] == null ? null : dt(t['completedAt'])),
              carriedOver: Value(t['carriedOver'] as bool? ?? false),
              sortIndex: Value(t['sortIndex'] as int? ?? 0),
              createdAt: Value(dt(t['createdAt'])),
              updatedAt: Value(dt(t['updatedAt'])),
            ));
      }
      for (final x in subs) {
        await _db.into(_db.subtasks).insert(SubtasksCompanion(
              id: Value(x['id'] as int),
              taskId: Value(x['taskId'] as int),
              title: Value(x['title'] as String),
              isDone: Value(x['isDone'] as bool),
              sortIndex: Value(x['sortIndex'] as int? ?? 0),
            ));
      }
      for (final x in dones) {
        await _db.into(_db.recurrenceDones).insert(RecurrenceDonesCompanion(
              id: Value(x['id'] as int),
              taskId: Value(x['taskId'] as int),
              date: Value(dt(x['date'])),
            ));
      }
      for (final x in stages) {
        await _db.into(_db.tripStages).insert(TripStagesCompanion(
              id: Value(x['id'] as int),
              taskId: Value(x['taskId'] as int),
              title: Value(x['title'] as String),
              kind: Value(
                  TripStageKind.values[x['kind'] as int? ?? 1]),
              startDate: Value(dt(x['startDate'])),
              endDate: Value(dt(x['endDate'])),
              placeName: Value(x['placeName'] as String? ?? ''),
              placeUrl: Value(x['placeUrl'] as String? ?? ''),
              note: Value(x['note'] as String? ?? ''),
              sortIndex: Value(x['sortIndex'] as int? ?? 0),
            ));
      }
      if (settings != null) {
        await _db.updateSettings(AppSettingsCompanion(
          autoCarry: Value(settings['autoCarry'] as bool? ?? false),
          themeMode: Value(settings['themeMode'] as int? ?? 1),
          firstWeekday: Value(settings['firstWeekday'] as int? ?? 1),
        ));
      }
    });
    return tasks.length;
  }
}
