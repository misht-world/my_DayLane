import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../calendar/calendar_view.dart';
import '../settings/settings_screen.dart';
import '../task_editor/task_editor_screen.dart';
import 'task_row.dart';

enum _Horizon { yesterday, today, tomorrow }

/// Главный экран в стиле «Журнал»: дата-герой с навигацией по дням и
/// три выделенные сворачиваемые секции вчера/сегодня/завтра.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showYesterday = false;
  bool _showTomorrow = false;
  bool _showToday = true;

  @override
  Widget build(BuildContext context) {
    final focused = ref.watch(focusedDateProvider);
    final sections = ref.watch(sectionsProvider);

    return Scaffold(
      body: SafeArea(
        child: sections == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  _topBar(context),
                  _hero(context, focused),
                  _section(
                    kind: _Horizon.yesterday,
                    label: 'вчера',
                    day: addDays(focused, -1),
                    tasks: sections.yesterday,
                    expanded: _showYesterday,
                    onToggle: () =>
                        setState(() => _showYesterday = !_showYesterday),
                    danger: sections.yesterdayCount > 0,
                    emptyText: 'всё разобрано',
                  ),
                  _section(
                    kind: _Horizon.today,
                    label: 'сегодня',
                    day: focused,
                    tasks: sections.today,
                    expanded: _showToday,
                    onToggle: () => setState(() => _showToday = !_showToday),
                    danger: false,
                    emptyText: 'на сегодня дел нет',
                  ),
                  _section(
                    kind: _Horizon.tomorrow,
                    label: 'завтра',
                    day: addDays(focused, 1),
                    tasks: sections.tomorrow,
                    expanded: _showTomorrow,
                    onToggle: () =>
                        setState(() => _showTomorrow = !_showTomorrow),
                    danger: false,
                    emptyText: 'на завтра пусто',
                  ),
                  _calendarSection(context),
                ],
              ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final dl = context.dl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
      child: Row(
        children: [
          Text(
            'DAYLANE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2.5,
              color: dl.inkFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: dl.inkFaint),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          GestureDetector(
            onTap: () => openTaskEditor(context, null),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: dl.accent),
              child: Icon(Icons.add,
                  size: 20, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, DateTime focused) {
    final dl = context.dl;
    final realToday = ref.watch(todayProvider);
    final isToday = isSameDate(focused, realToday);
    // Родительный падеж («июня»): берём из полной даты, отбросив число.
    final month = DateFormat('d MMMM', 'ru')
        .format(focused)
        .replaceFirst('${focused.day} ', '');
    final weekday = DateFormat('EEEE', 'ru').format(focused).toUpperCase();

    void shift(int days) =>
        ref.read(focusedDateProvider.notifier).shift(days);

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 120) shift(-1);
        if (v < -120) shift(1);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dl.ink, width: 2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${focused.day}',
              style: context.serif.copyWith(
                fontSize: 54,
                height: 0.85,
                fontWeight: FontWeight.w500,
                color: dl.ink,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(month,
                      style: context.serif
                          .copyWith(fontSize: 18, color: dl.ink, height: 1)),
                  const SizedBox(height: 2),
                  Text(weekday,
                      style: TextStyle(
                          fontSize: 10, letterSpacing: 2, color: dl.inkFaint)),
                ],
              ),
            ),
            const Spacer(),
            if (!isToday)
              GestureDetector(
                onTap: () =>
                    ref.read(focusedDateProvider.notifier).set(realToday),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restore, size: 14, color: dl.accent),
                      const SizedBox(width: 3),
                      Text('сегодня',
                          style: TextStyle(fontSize: 12, color: dl.accent)),
                    ],
                  ),
                ),
              ),
            _navBtn(context, Icons.chevron_left, () => shift(-1)),
            _navBtn(context, Icons.chevron_right, () => shift(1)),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final dl = context.dl;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Icon(icon, size: 26, color: dl.inkSoft),
      ),
    );
  }

  /// Сворачиваемая секция горизонта с выделенной лентой-заголовком.
  Widget _section({
    required _Horizon kind,
    required String label,
    required DateTime day,
    required List<TaskModel> tasks,
    required bool expanded,
    required VoidCallback onToggle,
    required bool danger,
    required String emptyText,
  }) {
    final dl = context.dl;
    final isToday = kind == _Horizon.today;
    final isYesterday = kind == _Horizon.yesterday;
    final countColor = danger ? dl.danger : dl.inkFaint;
    final markerColor = isToday
        ? dl.accent
        : danger
            ? dl.danger
            : dl.lineStrong;
    final canCarry =
        isYesterday && tasks.any((t) => t.isSingle && !t.isDone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Лента-заголовок.
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              decoration: BoxDecoration(
                color: isToday ? dl.sunken : dl.sunken.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: markerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(label,
                      style: context.serif.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: isToday ? 17 : 15,
                          fontWeight: FontWeight.w500,
                          color: dl.ink)),
                  const SizedBox(width: 8),
                  Text('${tasks.length}',
                      style: TextStyle(
                          fontSize: 12,
                          color: countColor,
                          fontWeight:
                              danger ? FontWeight.w500 : FontWeight.w400)),
                  if (danger) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.keyboard_return, size: 13, color: dl.danger),
                  ],
                  const Spacer(),
                  if (kind != _Horizon.yesterday)
                    _headerAction(
                      icon: Icons.add,
                      filled: true,
                      tooltip: 'Добавить дело',
                      onTap: () =>
                          openTaskEditor(context, null, initialDate: day),
                    ),
                  const SizedBox(width: 4),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: dl.inkFaint),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              child: tasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(emptyText,
                          style: TextStyle(color: dl.inkFaint, fontSize: 14)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (canCarry)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: () => ref
                                    .read(repositoryProvider)
                                    .carryAll(tasks),
                                style: FilledButton.styleFrom(
                                  backgroundColor: dl.accent,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                icon: const Icon(
                                    Icons.subdirectory_arrow_left, size: 16),
                                label: const Text('Перенести всё на сегодня',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ),
                        for (var i = 0; i < tasks.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: dl.line),
                          TaskRow(
                            task: tasks[i],
                            day: day,
                            showCarryToToday: isYesterday,
                          ),
                        ],
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required bool filled,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final dl = context.dl;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? dl.accent : Colors.transparent,
              border: filled ? null : Border.all(color: dl.lineStrong),
            ),
            child: Icon(
              icon,
              size: filled ? 18 : 17,
              color: filled
                  ? Theme.of(context).colorScheme.onPrimary
                  : dl.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendarSection(BuildContext context) {
    final dl = context.dl;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dl.line)),
      ),
      child: const CalendarView(),
    );
  }
}
