import 'package:daylane/domain/lanes.dart';
import 'package:daylane/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  int laneOf(List<LaneItem> items, int id) =>
      items.firstWhere((e) => e.task.id == id).lane;

  test('однодневные дела не укладываются в полосы', () {
    final items = packLanes([task(id: 1, start: d(2026, 6, 17))]);
    expect(items, isEmpty);
  });

  test('непересекающиеся периоды — одна дорожка', () {
    final items = packLanes([
      task(id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 3)),
      task(id: 2, kind: TaskKind.period, start: d(2026, 6, 5), end: d(2026, 6, 7)),
    ]);
    expect(laneCount(items), 1);
  });

  test('смежные периоды (конец/начало в соседние дни) — одна дорожка', () {
    final items = packLanes([
      task(id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 3)),
      task(id: 2, kind: TaskKind.period, start: d(2026, 6, 4), end: d(2026, 6, 6)),
    ]);
    expect(laneCount(items), 1);
  });

  test('пересекающиеся периоды — разные дорожки', () {
    final items = packLanes([
      task(id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 5)),
      task(id: 2, kind: TaskKind.period, start: d(2026, 6, 3), end: d(2026, 6, 7)),
    ]);
    expect(laneCount(items), 2);
    expect(laneOf(items, 1), isNot(laneOf(items, 2)));
  });

  test('тот же день конца и начала — пересечение, разные дорожки', () {
    final items = packLanes([
      task(id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 4)),
      task(id: 2, kind: TaskKind.period, start: d(2026, 6, 4), end: d(2026, 6, 6)),
    ]);
    expect(laneCount(items), 2);
  });

  test('жадная переукладка: раньше начавшийся — выше', () {
    final items = packLanes([
      task(id: 2, kind: TaskKind.period, start: d(2026, 6, 3), end: d(2026, 6, 9)),
      task(id: 1, kind: TaskKind.period, start: d(2026, 6, 1), end: d(2026, 6, 5)),
      task(id: 3, kind: TaskKind.period, start: d(2026, 6, 6), end: d(2026, 6, 8)),
    ]);
    // #1 (раньше всех) — дорожка 0; #2 пересекается с #1 — дорожка 1;
    // #3 начинается после конца #1 — снова дорожка 0.
    expect(laneOf(items, 1), 0);
    expect(laneOf(items, 2), 1);
    expect(laneOf(items, 3), 0);
    expect(laneCount(items), 2);
  });
}
