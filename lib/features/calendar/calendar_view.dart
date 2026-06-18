import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../domain/lanes.dart';
import '../../domain/models.dart';
import '../../domain/scheduling.dart';
import '../task_editor/task_editor_screen.dart';

enum CalendarMode { week, twoWeeks, month }

extension on CalendarMode {
  String get label => switch (this) {
        CalendarMode.week => 'Неделя',
        CalendarMode.twoWeeks => 'Две недели',
        CalendarMode.month => 'Месяц',
      };
  int get days => switch (this) {
        CalendarMode.week => 7,
        CalendarMode.twoWeeks => 14,
        CalendarMode.month => 35,
      };

  /// Максимум видимых дорожек; остальное сворачивается в «+N».
  int get maxLanes => switch (this) {
        CalendarMode.week => 5,
        CalendarMode.twoWeeks => 4,
        CalendarMode.month => 3,
      };
}

const double _numZone = 24;
const double _dotsZone = 13;
const double _head = _numZone + _dotsZone;
const double _laneHeight = 20;
const double _barHeight = 16;

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  CalendarMode _mode = CalendarMode.month;

  static const _weekdayShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final today = ref.watch(todayProvider);
    final settings = ref.watch(settingsProvider).value;
    final firstWeekday = settings?.firstWeekday ?? 1;
    final tasks = ref.watch(tasksProvider).value ?? const [];

    final start = _startOfWeek(today, firstWeekday);
    final lanes = packLanes(
      tasks.where((t) => _intersectsRange(t, start, _mode.days)),
    );
    final laneOf = {for (final li in lanes) li.task.id: li.lane};
    final totalLanes = laneCount(lanes);
    final visibleLanes =
        totalLanes < _mode.maxLanes ? totalLanes : _mode.maxLanes;
    final dones = ref.watch(donesMapProvider);

    final weekdays = _orderedWeekdays(firstWeekday);
    final rows = (_mode.days / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(
            children: [
              Text('Календарь',
                  style: context.serif.copyWith(fontSize: 16, color: dl.ink)),
              const Spacer(),
              _modeSwitcher(context),
            ],
          ),
        ),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdayShort[w - 1],
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: w == today.weekday ? dl.accent : dl.inkFaint,
                      fontWeight:
                          w == today.weekday ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, c) {
          final colW = c.maxWidth / 7;
          return Column(
            children: [
              for (var r = 0; r < rows; r++)
                _WeekRow(
                  weekStart: addDays(start, r * 7),
                  today: today,
                  colW: colW,
                  tasks: tasks,
                  laneOf: laneOf,
                  visibleLanes: visibleLanes,
                  isLastRow: r == rows - 1,
                  dones: dones,
                  onTapDay: _showDay,
                  onAddDay: (d) => openTaskEditor(context, null, initialDate: d),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _modeSwitcher(BuildContext context) {
    final dl = context.dl;
    return PopupMenuButton<CalendarMode>(
      initialValue: _mode,
      onSelected: (m) => setState(() => _mode = m),
      itemBuilder: (_) => [
        for (final m in CalendarMode.values)
          PopupMenuItem(value: m, child: Text(m.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: dl.lineStrong),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_mode.label,
                style: TextStyle(fontSize: 12, color: dl.inkSoft)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 15, color: dl.inkSoft),
          ],
        ),
      ),
    );
  }

  void _showDay(DateTime day) {
    final tasks = ref.read(tasksProvider).value ?? const [];
    final dayTasks = tasks.where((t) => isPresentOn(t, day)).toList()
      ..sort(compareInDay);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.dl.surface,
      showDragHandle: true,
      builder: (_) => _DaySheet(day: day, tasks: dayTasks),
    );
  }

  DateTime _startOfWeek(DateTime day, int firstWeekday) {
    final offset = (day.weekday - firstWeekday) % 7;
    return addDays(day, -((offset + 7) % 7));
  }

  List<int> _orderedWeekdays(int firstWeekday) =>
      [for (var i = 0; i < 7; i++) ((firstWeekday - 1 + i) % 7) + 1];

  bool _intersectsRange(TaskModel t, DateTime start, int days) {
    if (!t.isPeriod) return false;
    final end = addDays(start, days - 1);
    return !dateOnly(t.startDate).isAfter(end) &&
        !dateOnly(t.endDate).isBefore(start);
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.weekStart,
    required this.today,
    required this.colW,
    required this.tasks,
    required this.laneOf,
    required this.visibleLanes,
    required this.isLastRow,
    required this.dones,
    required this.onTapDay,
    required this.onAddDay,
  });

  final DateTime weekStart;
  final DateTime today;
  final double colW;
  final List<TaskModel> tasks;
  final Map<int?, int> laneOf;
  final int visibleLanes;
  final bool isLastRow;
  final Map<int, Set<int>> dones;
  final void Function(DateTime) onTapDay;
  final void Function(DateTime) onAddDay;

  @override
  Widget build(BuildContext context) {
    final weekEnd = addDays(weekStart, 6);
    final rowHeight = _head + visibleLanes * _laneHeight + 8;

    // Полосы периодов этой недели (только в пределах видимых дорожек).
    final bars = <Widget>[];
    var hidden = 0;
    for (final t in tasks) {
      if (!t.isPeriod) continue;
      final s = dateOnly(t.startDate);
      final e = dateOnly(t.endDate);
      if (s.isAfter(weekEnd) || e.isBefore(weekStart)) continue;
      final lane = laneOf[t.id] ?? 0;
      if (lane >= visibleLanes) {
        hidden++;
        continue;
      }
      final segStart = s.isBefore(weekStart) ? weekStart : s;
      final segEnd = e.isAfter(weekEnd) ? weekEnd : e;
      final col = daysBetween(weekStart, segStart);
      final span = daysBetween(segStart, segEnd) + 1;
      bars.add(Positioned(
        left: col * colW + 2,
        width: span * colW - 4,
        top: _head + lane * _laneHeight,
        height: _barHeight,
        // Подпись на каждом сегменте — чтобы дело было видно и на след. неделе.
        child: _Bar(task: t, showTitle: true),
      ));
    }
    if (hidden > 0) {
      bars.add(Positioned(
        right: 4,
        bottom: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: context.dl.sunken,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('+$hidden',
              style: TextStyle(fontSize: 9, color: context.dl.inkSoft)),
        ),
      ));
    }

    return SizedBox(
      height: rowHeight,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTapDay(addDays(weekStart, i)),
                    onLongPress: () => onAddDay(addDays(weekStart, i)),
                    child: _DayCell(
                      day: addDays(weekStart, i),
                      isToday: isSameDate(addDays(weekStart, i), today),
                      height: rowHeight,
                      singles: _singlesFor(addDays(weekStart, i)),
                      dones: dones,
                      showBottomRule: !isLastRow,
                    ),
                  ),
                ),
            ],
          ),
          ...bars,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConnectorPainter(
                  tasks: tasks,
                  laneOf: laneOf,
                  visibleLanes: visibleLanes,
                  weekStart: weekStart,
                  colW: colW,
                  color: context.dl.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TaskModel> _singlesFor(DateTime day) =>
      tasks.where((t) => t.isSingle && isPresentOn(t, day)).toList()
        ..sort(compareInDay);
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.height,
    required this.singles,
    required this.dones,
    required this.showBottomRule,
  });
  final DateTime day;
  final bool isToday;
  final double height;
  final List<TaskModel> singles;
  final Map<int, Set<int>> dones;
  final bool showBottomRule;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final weekend = day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isToday ? dl.accent.withValues(alpha: 0.10) : null,
        border: Border(
          left: BorderSide(color: dl.line, width: 0.5),
          bottom: showBottomRule
              ? BorderSide(color: dl.line, width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _numZone,
            child: Center(
              child: isToday
                  ? Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: dl.accent),
                      child: Text('${day.day}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary)),
                    )
                  : Text('${day.day}',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: weekend ? dl.inkFaint : dl.inkSoft)),
            ),
          ),
          SizedBox(
            height: _dotsZone,
            child: _dots(context),
          ),
        ],
      ),
    );
  }

  Widget _dots(BuildContext context) {
    if (singles.isEmpty) return const SizedBox.shrink();
    const maxDots = 4;
    final shown = singles.take(maxDots).toList();
    final extra = singles.length - shown.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final t in shown)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context
                  .taskColor(t)
                  .withValues(
                      alpha: isTaskDoneOn(dones, t, day) ? 0.35 : 1),
            ),
          ),
        if (extra > 0)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text('+$extra',
                style: TextStyle(fontSize: 9, color: context.dl.inkFaint)),
          ),
      ],
    );
  }
}

/// Чёрные соединители между связанными полосами (зависимости).
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.tasks,
    required this.laneOf,
    required this.visibleLanes,
    required this.weekStart,
    required this.colW,
    required this.color,
  });

  final List<TaskModel> tasks;
  final Map<int?, int> laneOf;
  final int visibleLanes;
  final DateTime weekStart;
  final double colW;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color;
    final weekEnd = addDays(weekStart, 6);
    final byId = {for (final t in tasks) if (t.id != null) t.id!: t};
    double laneY(int lane) => _head + lane * _laneHeight + _barHeight / 2;

    for (final t in tasks) {
      if (!t.isPeriod || t.dependsOnTaskId == null) continue;
      final parent = byId[t.dependsOnTaskId];
      if (parent == null || !parent.isPeriod) continue;
      final cl = laneOf[t.id];
      final pl = laneOf[parent.id];
      if (cl == null || pl == null) continue;
      if (cl >= visibleLanes || pl >= visibleLanes) continue;

      final childStart = dateOnly(t.startDate);
      final parentEnd = dateOnly(parent.endDate);
      final cy = laneY(cl);
      final py = laneY(pl);

      // Ребёнок начинается на этой неделе.
      if (!childStart.isBefore(weekStart) && !childStart.isAfter(weekEnd)) {
        final col = daysBetween(weekStart, childStart);
        final x = col * colW;
        if (col >= 1 && !parentEnd.isBefore(weekStart)) {
          // Родитель закончился в этой же неделе — вертикальный соединитель.
          canvas.drawLine(Offset(x, py), Offset(x, cy), stroke);
          canvas.drawCircle(Offset(x, cy), 2, fill);
        } else {
          // Родитель — на прошлой неделе: крючок у начала ребёнка.
          canvas.drawLine(Offset(x, cy - 4), Offset(x, cy + 4), stroke);
          canvas.drawLine(Offset(x, cy), Offset(x + 6, cy), stroke);
        }
      }

      // Родитель заканчивается на этой неделе, а ребёнок — на следующей.
      if (!parentEnd.isBefore(weekStart) &&
          !parentEnd.isAfter(weekEnd) &&
          childStart.isAfter(weekEnd)) {
        final pcol = daysBetween(weekStart, parentEnd);
        final px = (pcol + 1) * colW;
        canvas.drawLine(Offset(px - 6, py), Offset(px, py), stroke);
        canvas.drawLine(Offset(px, py - 4), Offset(px, py + 4), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.tasks != tasks ||
      old.weekStart != weekStart ||
      old.colW != colW ||
      old.visibleLanes != visibleLanes;
}

class _Bar extends StatelessWidget {
  const _Bar({required this.task, required this.showTitle});
  final TaskModel task;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final fill = context.taskColor(task);
    final onColor = onColorFor(fill);
    return Opacity(
      opacity: task.isDone ? 0.45 : 1,
      child: GestureDetector(
        onTap: () => openTaskEditor(context, task),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(_barHeight / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.centerLeft,
          child: showTitle
              ? Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10.5,
                      color: onColor,
                      fontWeight: FontWeight.w500),
                )
              : null,
        ),
      ),
    );
  }
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day, required this.tasks});
  final DateTime day;
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatWeekdayDayMonth(day),
                style: context.serif.copyWith(fontSize: 18, color: dl.ink)),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('дел нет', style: TextStyle(color: dl.inkFaint)),
              )
            else
              for (final t in tasks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.taskColor(t),
                    ),
                  ),
                  title: Text(t.title,
                      style: context.serif.copyWith(
                        fontSize: 15,
                        color: dl.ink,
                        decoration:
                            t.isDone ? TextDecoration.lineThrough : null,
                      )),
                  subtitle: t.isPeriod
                      ? Text(
                          dayOfPeriodLabel(dayNumberOf(t, day), t.durationDays))
                      : (t.timeOfDayMinutes != null
                          ? Text(formatMinutesOfDay(t.timeOfDayMinutes!))
                          : null),
                  onTap: () {
                    Navigator.of(context).pop();
                    openTaskEditor(context, t);
                  },
                ),
          ],
        ),
      ),
    );
  }
}
