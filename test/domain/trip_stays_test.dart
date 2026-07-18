import 'package:daylane/domain/models.dart';
import 'package:daylane/domain/trip_stays.dart';
import 'package:flutter_test/flutter_test.dart';

TaskModel trip(DateTime start, DateTime end) => TaskModel(
      title: 'Поездка',
      kind: TaskKind.period,
      isTrip: true,
      startDate: start,
      endDate: end,
      durationDays: end.difference(start).inDays + 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

TripStageModel stay(DateTime checkIn, DateTime checkOut) => TripStageModel(
      taskId: 1,
      title: 'Гостиница',
      kind: TripStageKind.stay,
      startDate: checkIn,
      endDate: checkOut,
    );

TripStageModel place(DateTime day) => TripStageModel(
      taskId: 1,
      title: 'Кафе',
      startDate: day,
      endDate: day,
    );

void main() {
  final d20 = DateTime(2026, 7, 20);
  final d23 = DateTime(2026, 7, 23);
  final d25 = DateTime(2026, 7, 25);

  group('tripNights', () {
    test('в последний день уезжаем — ночей на одну меньше, чем дней', () {
      // 20–25 июля = 6 дней, но ночуем только 20,21,22,23,24.
      final nights = tripNights(trip(d20, d25));
      expect(nights.length, 5);
      expect(nights.first, d20);
      expect(nights.last, DateTime(2026, 7, 24));
    });

    test('однодневная поездка — ночей нет', () {
      expect(tripNights(trip(d20, d20)), isEmpty);
    });
  });

  group('stayNights', () {
    test('заезд 20, выезд 23 ⇒ ночи 20,21,22 (в ночь выезда не ночуем)', () {
      expect(stayNights(stay(d20, d23)),
          [d20, DateTime(2026, 7, 21), DateTime(2026, 7, 22)]);
    });

    test('место ночей не даёт', () {
      expect(stayNights(place(d20)), isEmpty);
    });
  });

  group('uncoveredNights', () {
    test('переезд в один день стыкуется встык — дыр нет', () {
      // Выехал из A и въехал в B 23-го: A закрывает 20–22, B — 23,24.
      final gaps = uncoveredNights(trip(d20, d25), [
        stay(d20, d23),
        stay(d23, d25),
      ]);
      expect(gaps, isEmpty);
    });

    test('разрыв между жильём виден как незакрытая ночь', () {
      // A: ночи 20,21. B: ночи 23,24. Ночь 22 — жить негде.
      final gaps = uncoveredNights(trip(d20, d25), [
        stay(d20, DateTime(2026, 7, 22)),
        stay(d23, d25),
      ]);
      expect(gaps, [DateTime(2026, 7, 22)]);
    });

    test('места не закрывают ночи', () {
      final gaps = uncoveredNights(trip(d20, DateTime(2026, 7, 21)), [
        place(d20),
      ]);
      expect(gaps, [d20]);
    });

    test('жильё сверх дат поездки не мешает', () {
      final gaps = uncoveredNights(trip(d20, d23), [
        stay(DateTime(2026, 7, 18), d25),
      ]);
      expect(gaps, isEmpty);
    });
  });

  group('groupConsecutive', () {
    test('склеивает подряд идущие дни в диапазон', () {
      final groups = groupConsecutive([
        d20,
        DateTime(2026, 7, 21),
        d23,
      ]);
      expect(groups.length, 2);
      expect(groups[0].from, d20);
      expect(groups[0].to, DateTime(2026, 7, 21));
      expect(groups[1].from, d23);
      expect(groups[1].to, d23);
    });

    test('пустой список', () => expect(groupConsecutive([]), isEmpty));
  });
}
