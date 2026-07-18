import '../core/date_utils.dart';
import 'models.dart';

/// Покрытие поездки жильём — «есть ли где ночевать каждую ночь».
///
/// Жильё считается ПО НОЧАМ: этап с заездом 25-го и выездом 28-го закрывает
/// ночи 25, 26, 27 (в ночь выезда уже не ночуем). Поэтому выезд из одного
/// жилья и заезд в другое в один день стыкуются встык — без дыры и без
/// наложения. Ночи самой поездки: [startDate, endDate-1] — в последний день
/// уезжаем домой.

/// Ночи поездки (день = ночь, которую в этот день ночуешь).
List<DateTime> tripNights(TaskModel trip) {
  final out = <DateTime>[];
  for (var d = dateOnly(trip.startDate);
      d.isBefore(dateOnly(trip.endDate));
      d = addDays(d, 1)) {
    out.add(d);
  }
  return out;
}

/// Ночи, закрытые этапом-жильём: [заезд, выезд-1].
List<DateTime> stayNights(TripStageModel stage) {
  if (!stage.isStay) return const [];
  final out = <DateTime>[];
  for (var d = dateOnly(stage.startDate);
      d.isBefore(dateOnly(stage.endDate));
      d = addDays(d, 1)) {
    out.add(d);
  }
  return out;
}

/// Ночи поездки, на которые жильё не выбрано (в порядке возрастания).
List<DateTime> uncoveredNights(TaskModel trip, List<TripStageModel> stages) {
  final covered = <int>{};
  for (final s in stages) {
    for (final n in stayNights(s)) {
      covered.add(dayKey(n));
    }
  }
  return tripNights(trip)
      .where((n) => !covered.contains(dayKey(n)))
      .toList();
}

/// Сжимает подряд идущие ночи в диапазоны — для читаемого текста о пропусках.
List<({DateTime from, DateTime to})> groupConsecutive(List<DateTime> days) {
  if (days.isEmpty) return const [];
  final sorted = [...days]..sort();
  final out = <({DateTime from, DateTime to})>[];
  var from = sorted.first;
  var prev = sorted.first;
  for (final d in sorted.skip(1)) {
    if (daysBetween(prev, d) == 1) {
      prev = d;
      continue;
    }
    out.add((from: from, to: prev));
    from = d;
    prev = d;
  }
  out.add((from: from, to: prev));
  return out;
}
