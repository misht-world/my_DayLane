import 'dart:convert';

import 'package:daylane/domain/models.dart';
import 'package:daylane/domain/sync.dart';
import 'package:daylane/domain/sync_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aggregate round-trip через JSON сохраняет все поля', () {
    final agg = TaskAggregate(
      task: TaskModel(
        id: 42, // локальный id НЕ должен переехать
        syncUid: 'uid-1',
        title: 'Поездка',
        kind: TaskKind.period,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 10),
        durationDays: 10,
        dependsOnTaskId: 7,
        dependsBefore: true,
        timeOfDayMinutes: 615,
        reminderEnabled: true,
        reminderRule: ReminderRule.eachDay,
        reminderMinutes: 480,
        reminderDaysBefore: 2,
        colorId: 3,
        iconId: 5,
        deferred: true,
        isTrip: true,
        noteCategory: 2,
        author: 'Автор',
        year: 2025,
        audience: 1,
        recurrenceType: RecurrenceType.weeks,
        recurrenceInterval: 2,
        recurrenceAnchor: 4,
        note: 'Заметка\nстрока',
        placeName: 'Рим',
        placeUrl: 'https://maps.example/rome',
        links: 'a\nb',
        isDone: true,
        completedAt: DateTime(2026, 6, 11, 9, 30),
        carriedOver: true,
        sortIndex: 8,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 6, 12),
      ),
      subtasks: const [
        SubtaskModel(taskId: 42, title: 'п1', isDone: true, sortIndex: 0),
        SubtaskModel(taskId: 42, title: 'п2', isDone: false, sortIndex: 1),
      ],
      stages: [
        TripStageModel(
          taskId: 42,
          title: 'Отель',
          kind: TripStageKind.stay,
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 4),
          placeName: 'Hotel X',
          placeUrl: 'geo:0,0',
          timeMinutes: 840,
          isDone: true,
          note: 'ок',
          links: 'l1',
          sortIndex: 2,
        ),
      ],
      recurrenceDones: [DateTime(2026, 6, 3), DateTime(2026, 6, 5)],
    );

    // Прогон через настоящую (де)сериализацию строки, как в транспорте.
    final back = aggregateFromJson(
        jsonDecode(jsonEncode(aggregateToJson(agg))) as Map<String, dynamic>);

    final a = agg.task;
    final b = back.task;
    expect(b.id, isNull); // локальный id не переносится
    expect(b.syncUid, a.syncUid);
    expect(b.title, a.title);
    expect(b.kind, a.kind);
    expect(b.startDate, a.startDate);
    expect(b.endDate, a.endDate);
    expect(b.durationDays, a.durationDays);
    expect(b.dependsOnTaskId, a.dependsOnTaskId);
    expect(b.dependsBefore, a.dependsBefore);
    expect(b.timeOfDayMinutes, a.timeOfDayMinutes);
    expect(b.reminderEnabled, a.reminderEnabled);
    expect(b.reminderRule, a.reminderRule);
    expect(b.reminderMinutes, a.reminderMinutes);
    expect(b.reminderDaysBefore, a.reminderDaysBefore);
    expect(b.colorId, a.colorId);
    expect(b.iconId, a.iconId);
    expect(b.deferred, a.deferred);
    expect(b.isTrip, a.isTrip);
    expect(b.noteCategory, a.noteCategory);
    expect(b.author, a.author);
    expect(b.year, a.year);
    expect(b.audience, a.audience);
    expect(b.recurrenceType, a.recurrenceType);
    expect(b.recurrenceInterval, a.recurrenceInterval);
    expect(b.recurrenceAnchor, a.recurrenceAnchor);
    expect(b.note, a.note);
    expect(b.placeName, a.placeName);
    expect(b.placeUrl, a.placeUrl);
    expect(b.links, a.links);
    expect(b.isDone, a.isDone);
    expect(b.completedAt, a.completedAt);
    expect(b.carriedOver, a.carriedOver);
    expect(b.sortIndex, a.sortIndex);
    expect(b.createdAt, a.createdAt);
    expect(b.updatedAt, a.updatedAt);

    expect(back.subtasks.map((s) => '${s.title}/${s.isDone}/${s.sortIndex}'),
        ['п1/true/0', 'п2/false/1']);
    final st = back.stages.single;
    expect(st.title, 'Отель');
    expect(st.kind, TripStageKind.stay);
    expect(st.startDate, DateTime(2026, 6, 1));
    expect(st.endDate, DateTime(2026, 6, 4));
    expect(st.placeName, 'Hotel X');
    expect(st.placeUrl, 'geo:0,0');
    expect(st.timeMinutes, 840);
    expect(st.isDone, true);
    expect(st.note, 'ок');
    expect(st.links, 'l1');
    expect(st.sortIndex, 2);
    expect(back.recurrenceDones, [DateTime(2026, 6, 3), DateTime(2026, 6, 5)]);
  });

  test('минимальный JSON (только обязательное) не падает', () {
    final j = {
      'task': {
        'syncUid': 'u',
        'startDate': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'endDate': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'createdAt': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'updatedAt': DateTime(2026, 1, 2).millisecondsSinceEpoch,
      },
    };
    final agg = aggregateFromJson(j);
    expect(agg.uid, 'u');
    expect(agg.task.title, '');
    expect(agg.subtasks, isEmpty);
    expect(agg.stages, isEmpty);
    expect(agg.recurrenceDones, isEmpty);
  });
}
