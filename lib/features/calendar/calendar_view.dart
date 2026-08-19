import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/lanes.dart';
import '../../domain/models.dart';
import '../../domain/scheduling.dart';
import '../task_editor/task_editor_screen.dart';
import '../trips/trip_screen.dart';

/// Открывает дело: путешествие — дневником, остальное — карточкой.
void openTaskOrTrip(BuildContext context, TaskModel t) {
  if (t.isTrip && t.id != null) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TripScreen(taskId: t.id!)));
  } else {
    openTaskEditor(context, t);
  }
}

/// Сколько недель видно в окне календаря по умолчанию (у окна свой скролл).
/// На десктопе панель шире и выше — число недель задаётся через конструктор.
const int _kDefaultVisibleWeeks = 5;

/// Общий диапазон прокрутки в неделях (~11 лет вокруг «сегодня»).
const int _weeksSpan = 574;

/// Максимум видимых дорожек; остальное сворачивается в «+N».
const int _maxLanes = 3;

const double _numZone = 24;
const double _dotsZone = 13;
const double _head = _numZone + _dotsZone;
const double _laneHeight = 20;
const double _barHeight = 16;

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key, this.visibleWeeks = _kDefaultVisibleWeeks});

  /// Высота окна календаря в неделях (десктоп передаёт больше).
  final int visibleWeeks;

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  /// Короткое имя дня недели (w: 1=пн … 7=вс) на языке приложения.
  /// 2024-01-01 — понедельник, поэтому DateTime(2024,1,w) даёт нужный день.
  static String _weekdayShort(int w) =>
      DateFormat('EEE').format(DateTime(2024, 1, w)).replaceAll('.', '');

  final ScrollController _scroll = ScrollController();

  /// Месяц, к которому относится верх видимой области (для шапки и подсветки).
  DateTime? _visibleMonth;

  /// Последняя фокусная дата — чтобы прокрутить календарь при её смене в шапке.
  DateTime? _lastFocused;
  bool _didInitialJump = false;

  // Параметры прокрутки: заполняются в build, читаются в слушателе/переходах.
  DateTime _originWeek = DateTime(2020, 1, 1);
  double _rowH = 60;
  int _firstWeekday = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// По прокрутке определяем месяц верхней видимой недели и обновляем шапку.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final top = (_scroll.offset / _rowH).floor().clamp(0, _weeksSpan - 1);
    // Середина недели репрезентует её месяц (неделя может лежать на стыке).
    final mid = addDays(_originWeek, top * 7 + 3);
    final m = DateTime(mid.year, mid.month);
    if (_visibleMonth == null ||
        m.year != _visibleMonth!.year ||
        m.month != _visibleMonth!.month) {
      setState(() => _visibleMonth = m);
    }
  }

  int _weekIndex(DateTime day) =>
      (daysBetween(_originWeek, _startOfWeek(day, _firstWeekday)) ~/ 7)
          .clamp(0, _weeksSpan - 1);

  void _scrollToDate(DateTime day, {bool animate = true}) {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final off = (_weekIndex(day) * _rowH).clamp(0.0, max);
    if (animate) {
      _scroll.animateTo(off,
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(off);
    }
  }

  void _jumpMonths(int delta) {
    final DateTime base = _visibleMonth ?? ref.read(focusedDateProvider);
    _scrollToDate(DateTime(base.year, base.month + delta, 1));
  }

  /// Прокрутка календаря пальцем в центральной зоне (список сам не скроллится).
  void _dragScroll(double delta) {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo((_scroll.offset - delta).clamp(0.0, max));
  }

  /// Инерция после броска: пролистываем на расстояние по скорости жеста.
  void _flingScroll(double velocity) {
    if (!_scroll.hasClients || velocity == 0) return;
    final max = _scroll.position.maxScrollExtent;
    final target = (_scroll.offset - velocity * 0.25).clamp(0.0, max);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final today = ref.watch(todayProvider);
    final settings = ref.watch(settingsProvider).value;
    final firstWeekday = settings?.firstWeekday ?? 1;
    final tasks = ref.watch(tasksProvider).value ?? const [];
    final focused = ref.watch(focusedDateProvider);

    // Дорожки — по всем периодам (глобально), чтобы полоса лежала на одной
    // дорожке в любой прокрученной неделе.
    final lanes = packLanes(tasks.where((t) => t.isPeriod));
    final laneOf = {for (final li in lanes) li.task.id: li.lane};
    final totalLanes = laneCount(lanes);
    final visibleLanes = totalLanes < _maxLanes ? totalLanes : _maxLanes;
    final dones = ref.watch(donesMapProvider);
    final stayRanges = ref.watch(tripStayRangesProvider);
    final placeDays = ref.watch(tripPlaceDaysProvider);

    final weekdays = _orderedWeekdays(firstWeekday);
    final rowHeight = _head + visibleLanes * _laneHeight + 8;

    // Параметры прокрутки — обновляем перед построением списка.
    _firstWeekday = firstWeekday;
    _rowH = rowHeight;
    _originWeek = _startOfWeek(DateTime(today.year - 5, 1, 1), firstWeekday);
    _visibleMonth ??= DateTime(focused.year, focused.month);

    // Смена фокусной даты в шапке прокручивает календарь к ней (первый раз —
    // мгновенно, дальше — плавно). Свободная прокрутка фокус не трогает.
    if (_lastFocused == null || !isSameDate(_lastFocused!, focused)) {
      final firstTime = !_didInitialJump;
      _lastFocused = focused;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToDate(focused, animate: !firstTime);
        _didInitialJump = true;
      });
    }

    final visM = _visibleMonth ?? DateTime(focused.year, focused.month);
    final showToday = today.year != visM.year || today.month != visM.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 4, 12),
          child: Row(
            children: [
              _navArrow(context, Icons.chevron_left_rounded, () => _jumpMonths(-1)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _pickMonth(context, visM),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(formatMonthYear(visM),
                      style:
                          context.serif.copyWith(fontSize: 16, color: dl.ink)),
                ),
              ),
              _navArrow(context, Icons.chevron_right_rounded, () => _jumpMonths(1)),
              const Spacer(),
              if (showToday)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _scrollToDate(today),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restore_rounded, size: 15, color: dl.accent),
                        const SizedBox(width: 3),
                        Text(AppLocalizations.of(context).resetToday,
                            style: TextStyle(fontSize: 12, color: dl.accent)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdayShort(w),
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
        // Окно календаря со своим вертикальным скроллом — недели непрерывно.
        // Прокрутка календаря — только жестом в ЦЕНТРЕ (колонки вт…сб); по
        // краям (пн и вс) вертикальный жест уходит общей прокрутке страницы.
        // Поэтому сам список физически не скроллится (NeverScrollable), а
        // центральная зона двигает его через контроллер.
        SizedBox(
          height: rowHeight * widget.visibleWeeks,
          child: LayoutBuilder(builder: (context, c) {
            final colW = c.maxWidth / 7;
            return Stack(
              children: [
                ListView.builder(
                  controller: _scroll,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _weeksSpan,
                  itemExtent: rowHeight,
                  itemBuilder: (context, i) => _WeekRow(
                    weekStart: addDays(_originWeek, i * 7),
                    today: today,
                    focused: focused,
                    anchorMonth: visM.month,
                    colW: colW,
                    tasks: tasks,
                    laneOf: laneOf,
                    visibleLanes: visibleLanes,
                    isLastRow: false,
                    dones: dones,
                    stayRanges: stayRanges,
                    placeDays: placeDays,
                    onTapDay: _showDay,
                    onAddDay: (day) =>
                        openTaskEditor(context, null, initialDate: day),
                  ),
                ),
                // Центральная зона (без крайних колонок) ловит вертикальный
                // жест и прокручивает календарь; тапы по дням/полосам проходят
                // насквозь (translucent, без обработки тапа).
                Positioned(
                  left: colW,
                  right: colW,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (d) => _dragScroll(d.primaryDelta ?? 0),
                    onVerticalDragEnd: (d) =>
                        _flingScroll(d.primaryVelocity ?? 0),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _navArrow(BuildContext context, IconData icon, VoidCallback onTap) =>
      InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 24, color: context.dl.inkSoft),
        ),
      );

  Future<void> _pickMonth(BuildContext context, DateTime anchor) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthYearPicker(initial: anchor),
    );
    if (picked != null) _scrollToDate(picked);
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
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.weekStart,
    required this.today,
    required this.focused,
    required this.anchorMonth,
    required this.colW,
    required this.tasks,
    required this.laneOf,
    required this.visibleLanes,
    required this.isLastRow,
    required this.dones,
    required this.stayRanges,
    required this.placeDays,
    required this.onTapDay,
    required this.onAddDay,
  });

  final DateTime weekStart;
  final DateTime today;
  final DateTime focused;
  final int anchorMonth;
  final double colW;
  final List<TaskModel> tasks;
  final Map<int?, int> laneOf;
  final int visibleLanes;
  final bool isLastRow;
  final Map<int, Set<int>> dones;

  /// Отрезки жилья по поездкам: taskId → (заезд, выезд).
  final Map<int, List<({DateTime checkIn, DateTime checkOut})>> stayRanges;

  /// Дни мест-этапов по поездкам (с повторами).
  final Map<int, List<DateTime>> placeDays;
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

      // Под полосой поездки — полоса проживания: от середины дня заезда до
      // середины дня выезда. Переезд в один день стыкуется встык, а не
      // закрытая ночь остаётся видимым пропуском.
      if (t.isTrip) {
        final stays = stayRanges[t.id] ?? const [];
        final markColor = context.taskColor(t);
        final stayTop = _head + lane * _laneHeight + _barHeight + 1;
        for (final stay in stays) {
          // Середины дней в координатах колонок недели.
          final from = daysBetween(weekStart, stay.checkIn) + 0.5;
          final to = daysBetween(weekStart, stay.checkOut) + 0.5;
          // Обрезаем по видимой неделе.
          final l = from.clamp(0.0, 7.0);
          final r = to.clamp(0.0, 7.0);
          if (r <= l) continue;
          bars.add(Positioned(
            left: l * colW,
            width: (r - l) * colW,
            top: stayTop,
            height: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: markColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ));
        }
        // Вертикальные чёрточки — заезд и выезд КАЖДОГО жилья (в серединах
        // дней, как и сама линия). На стыке двух жилий чёрточки совпадают —
        // получается одна отметка смены места. Нет жилья — нет и чёрточек.
        for (final stay in stays) {
          for (final edge in [stay.checkIn, stay.checkOut]) {
            final x = (daysBetween(weekStart, edge) + 0.5) * colW;
            if (x < 0 || x > 7 * colW) continue;
            bars.add(Positioned(
              left: x - 0.8,
              top: stayTop + 1.5 - 5,
              width: 1.6,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.dl.ink,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ));
          }
        }
        // Дела (места-этапы) внутри поездки — чёрные точки по дням;
        // несколько дел в день = несколько точек рядом. В день заезда/выезда
        // середина занята чёрточкой — точки сдвигаем правее.
        final edgeDays = <int>{
          for (final st in stays) ...[
            dayKey(st.checkIn),
            dayKey(st.checkOut),
          ],
        };
        final byDay = <int, int>{};
        for (final d in placeDays[t.id] ?? const <DateTime>[]) {
          byDay[dayKey(d)] = (byDay[dayKey(d)] ?? 0) + 1;
        }
        for (var i = 0; i < 7; i++) {
          final day = addDays(weekStart, i);
          final count = byDay[dayKey(day)] ?? 0;
          if (count == 0) continue;
          const dot = 5.0, gap = 3.0;
          final totalW = count * dot + (count - 1) * gap;
          final startX = edgeDays.contains(dayKey(day))
              ? (i + 0.5) * colW + 5 // справа от чёрточки смены жилья
              : (i + 0.5) * colW - totalW / 2;
          for (var k = 0; k < count; k++) {
            bars.add(Positioned(
              left: startX + k * (dot + gap),
              top: stayTop + 1.5 - dot / 2,
              width: dot,
              height: dot,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: context.dl.ink),
              ),
            ));
          }
        }
      }
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
                      isSelected:
                          isSameDate(addDays(weekStart, i), focused),
                      inAnchorMonth:
                          addDays(weekStart, i).month == anchorMonth,
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
    required this.isSelected,
    required this.inAnchorMonth,
    required this.height,
    required this.singles,
    required this.dones,
    required this.showBottomRule,
  });
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool inAnchorMonth;
  final double height;
  final List<TaskModel> singles;
  final Map<int, Set<int>> dones;
  final bool showBottomRule;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final weekend = day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday;
    // 1-е число месяца подписываем коротким названием — чтобы в сетке,
    // охватывающей несколько месяцев, не запутаться.
    final isMonthStart = day.day == 1;
    final numColor = isToday
        ? null
        : (inAnchorMonth ? (weekend ? dl.inkFaint : dl.inkSoft) : dl.inkFaint)
            .withValues(alpha: inAnchorMonth ? 1 : 0.5);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isToday
            ? dl.accent.withValues(alpha: 0.10)
            : (inAnchorMonth ? null : dl.sunken.withValues(alpha: 0.35)),
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
                  : isSelected
                      // Выбранный день — кружок без заливки (контур).
                      ? Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: dl.accent, width: 1.5),
                          ),
                          child: Text('${day.day}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: inAnchorMonth ? dl.ink : dl.inkFaint)),
                        )
                      : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (isMonthStart) ...[
                          Text(monthNameShort(day.month),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: dl.accent)),
                          const SizedBox(width: 3),
                        ],
                        Text('${day.day}',
                            style: TextStyle(fontSize: 12.5, color: numColor)),
                      ],
                    ),
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
        onTap: () => openTaskOrTrip(context, task),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(_barHeight / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.centerLeft,
          child: showTitle
              ? Row(
                  children: [
                    if (task.isTrip) ...[
                      Icon(Icons.luggage_rounded, size: 10, color: onColor),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: onColor,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
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
                child: Text(AppLocalizations.of(context).daySheetEmpty,
                    style: TextStyle(color: dl.inkFaint)),
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
                    openTaskOrTrip(context, t);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

/// Компактный выбор месяца и года: листание года стрелками + сетка 12 месяцев.
class _MonthYearPicker extends StatefulWidget {
  const _MonthYearPicker({required this.initial});
  final DateTime initial;

  @override
  State<_MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<_MonthYearPicker> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    return Dialog(
      backgroundColor: dl.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: dl.inkSoft,
                  onPressed: () => setState(() => _year--),
                ),
                Expanded(
                  child: Center(
                    child: Text('$_year',
                        style:
                            context.serif.copyWith(fontSize: 18, color: dl.ink)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: dl.inkSoft,
                  onPressed: () => setState(() => _year++),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.1,
              children: [
                for (var m = 1; m <= 12; m++)
                  _monthCell(context, m, dl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthCell(BuildContext context, int month, DayLaneColors dl) {
    final selected =
        month == widget.initial.month && _year == widget.initial.year;
    return Material(
      color: selected ? dl.accent : dl.sunken.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.pop(context, DateTime(_year, month, 1)),
        child: Center(
          child: Text(
            monthNameShort(month),
            style: TextStyle(
              fontSize: 13,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : dl.inkSoft,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
