import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
import '../../domain/scheduling.dart';
import '../task_editor/task_editor_screen.dart';

/// Строка дела на главном экране: круглый чекбокс под цвет дела, заголовок,
/// мета-чипы (время, период, напоминание, прогресс подпунктов), раскрытие
/// чек-листа подпунктов и кнопка «→ сегодня» (для вчерашних однодневных).
class TaskRow extends ConsumerStatefulWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.day,
    this.showCarryToToday = false,
  });

  final TaskModel task;

  /// День, в контексте которого показывается строка (для «день N из M»).
  final DateTime day;

  final bool showCarryToToday;

  @override
  ConsumerState<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<TaskRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final dl = context.dl;
    final color = context.taskColor(t);
    final today = ref.watch(todayProvider);
    final dones = ref.watch(donesMapProvider);
    final done = isTaskDoneOn(dones, t, widget.day);
    final overdue = t.isRecurring
        ? (!done && dateOnly(widget.day).isBefore(today))
        : isOverdue(t, today);
    final progress = ref.watch(subtaskProgressProvider)[t.id] ?? (0, 0);
    final hasSubs = progress.$2 > 0;

    final titleColor = done
        ? dl.inkFaint
        : overdue
            ? dl.danger
            : dl.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _openEditor(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Row(
              children: [
                _Checkbox(
                  done: done,
                  color: color,
                  onTap: () {
                    final repo = ref.read(repositoryProvider);
                    if (t.isRecurring) {
                      repo.toggleOccurrence(t, widget.day, !done);
                    } else {
                      repo.toggleDone(t);
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: context.serif.copyWith(
                          fontSize: 16,
                          color: titleColor,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (_metaChips(context).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: _metaChips(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasSubs)
                  Text('${progress.$1}/${progress.$2}',
                      style: TextStyle(fontSize: 12, color: dl.inkSoft)),
                if (hasSubs)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: dl.inkFaint,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                if (widget.showCarryToToday && t.isSingle && !t.isDone)
                  _CarryButton(
                    onTap: () =>
                        ref.read(repositoryProvider).carryToTodayTask(t),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded && hasSubs) _SubtaskList(taskId: t.id!),
      ],
    );
  }

  List<Widget> _metaChips(BuildContext context) {
    final t = widget.task;
    final dl = context.dl;
    final chips = <Widget>[];
    final muted = TextStyle(fontSize: 12, color: dl.inkSoft);

    if (!t.isPeriod && t.timeOfDayMinutes != null) {
      chips.add(_chip(Icons.schedule, formatMinutesOfDay(t.timeOfDayMinutes!),
          dl.inkSoft, muted));
    }
    final c = context.taskColor(t);
    if (t.isRecurring) {
      chips.add(_chip(Icons.repeat, recurrenceSummary(t), c,
          TextStyle(fontSize: 11, color: c)));
    }
    if (t.isPeriod) {
      final n = dayNumberOf(t, widget.day);
      chips.add(Text(
        dayOfPeriodLabel(n, t.durationDays),
        style: context.serif.copyWith(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: c,
        ),
      ));
    }
    if (t.reminderEnabled) {
      chips.add(Icon(Icons.notifications_none, size: 14, color: dl.accent));
    }
    if (t.carriedOver) {
      chips.add(_chip(Icons.autorenew, 'перенесено', dl.accent,
          TextStyle(fontSize: 12, color: dl.accent)));
    }
    return chips;
  }

  Widget _chip(IconData icon, String text, Color iconColor, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 3),
        Text(text, style: style),
      ],
    );
  }

  void _openEditor(BuildContext context) {
    openTaskEditor(context, widget.task);
  }
}

/// Круглый чекбокс под цвет дела.
class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.done,
    required this.color,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.transparent,
          border: Border.all(color: color, width: 1.6),
        ),
        child: done
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

class _CarryButton extends StatelessWidget {
  const _CarryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: dl.accent,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      icon: const Icon(Icons.east, size: 16),
      label: const Text('сегодня', style: TextStyle(fontSize: 13)),
    );
  }
}

class _SubtaskList extends ConsumerWidget {
  const _SubtaskList({required this.taskId});
  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final subs = ref.watch(subtasksForTaskProvider(taskId)).value ?? [];
    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 6),
      child: Column(
        children: [
          for (final s in subs)
            InkWell(
              onTap: () => ref
                  .read(repositoryProvider)
                  .setSubtaskDone(s, !s.isDone),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      s.isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 17,
                      color: s.isDone ? dl.accent : dl.inkFaint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: s.isDone ? dl.inkFaint : dl.ink,
                          decoration:
                              s.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
