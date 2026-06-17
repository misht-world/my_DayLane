import '../core/date_utils.dart';
import 'models.dart';

/// Жадная укладка дел-периодов в горизонтальные дорожки календаря.
///
/// Алгоритм: сортируем периоды по startDate (затем по endDate); каждый кладём
/// в первую дорожку, где он не пересекается по дням с уже лежащими; иначе
/// создаём новую дорожку. Без ручного перетаскивания.

class LaneItem {
  final TaskModel task;
  final int lane;
  const LaneItem(this.task, this.lane);
}

/// Раскладывает периоды по дорожкам. Однодневные дела игнорируются —
/// они не рисуются полосами.
List<LaneItem> packLanes(Iterable<TaskModel> tasks) {
  final periods = tasks.where((t) => t.isPeriod).toList()
    ..sort((a, b) {
      // По startDate возрастанию, затем по endDate возрастанию.
      final s = daysBetween(a.startDate, b.startDate); // >0 ⇒ a раньше
      if (s != 0) return s > 0 ? -1 : 1;
      final e = daysBetween(a.endDate, b.endDate);
      if (e != 0) return e > 0 ? -1 : 1;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });

  // Дата конца последней полосы в каждой дорожке.
  final laneEnds = <DateTime>[];
  final result = <LaneItem>[];

  for (final task in periods) {
    final start = dateOnly(task.startDate);
    var placed = -1;
    for (var i = 0; i < laneEnds.length; i++) {
      // Помещается, если начинается строго после конца занятого в дорожке.
      if (start.isAfter(laneEnds[i])) {
        placed = i;
        break;
      }
    }
    if (placed == -1) {
      placed = laneEnds.length;
      laneEnds.add(dateOnly(task.endDate));
    } else {
      laneEnds[placed] = dateOnly(task.endDate);
    }
    result.add(LaneItem(task, placed));
  }

  return result;
}

/// Сколько дорожек получилось в раскладке.
int laneCount(List<LaneItem> items) =>
    items.isEmpty ? 0 : items.map((e) => e.lane).reduce((a, b) => a > b ? a : b) + 1;
