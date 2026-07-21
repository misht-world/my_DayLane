import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../core/undo_snack.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
import '../../domain/scheduling.dart';
import '../../services/maps.dart';
import '../task_editor/task_editor_screen.dart';
import '../trips/trip_screen.dart';

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
          onLongPress: () => _showActions(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Row(
              children: [
                _Checkbox(
                  done: done,
                  color: color,
                  // Путешествие — всегда чемоданчик, как на полосе в календаре.
                  icon: t.isTrip
                      ? Icons.luggage_rounded
                      : taskTemplateIcon(t.iconId),
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
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: dl.inkFaint,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                if (widget.showCarryToToday &&
                    t.isSingle &&
                    !t.isRecurring &&
                    !t.isDone)
                  _CarryButton(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final undo = await ref
                          .read(repositoryProvider)
                          .carryToTodayTask(t);
                      showUndoSnackOn(
                          messenger, 'Перенесено на сегодня', undo);
                    },
                  ),
              ],
            ),
          ),
        ),
        if (_expanded && hasSubs) SubtaskChecklist(taskId: t.id!),
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
    if (t.placeName.isNotEmpty || t.placeUrl.isNotEmpty) {
      chips.add(GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openInMaps(url: t.placeUrl, query: t.placeName),
        child: _chip(
            Icons.place_rounded,
            t.placeName.isNotEmpty ? t.placeName : 'на карте',
            dl.accent,
            TextStyle(fontSize: 12, color: dl.accent)),
      ));
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
    final t = widget.task;
    if (t.isTrip && t.id != null) {
      // Поездка открывается дневником; карточка — из него по кнопке «изменить».
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TripScreen(taskId: t.id!)));
    } else {
      openTaskEditor(context, t);
    }
  }

  /// Долгий тап по строке — быстрые действия: в отложенные / удалить.
  Future<void> _showActions(BuildContext context) async {
    final t = widget.task;
    final dl = context.dl;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: dl.surface,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.serif.copyWith(fontSize: 17, color: dl.ink)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.bookmark_border_rounded, color: dl.inkSoft),
              title: const Text('В отложенные'),
              subtitle: const Text('снять с дня, «ждёт своего часа»',
                  style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.of(context).pop('defer'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: dl.danger),
              title: Text('Удалить', style: TextStyle(color: dl.danger)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    // Messenger захватываем сейчас: после операции строка дела уже
    // размонтирована (дело ушло из секции), context станет недоступен.
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(repositoryProvider);
    switch (action) {
      case 'defer':
        final undo = await repo.moveToDeferred(t);
        showUndoSnackOn(messenger, 'Перенесено в «Отложенные»', undo);
      case 'delete':
        final undo = await repo.deleteTask(t.id!);
        showUndoSnackOn(messenger, 'Дело удалено', undo);
    }
  }
}

/// Круглый чекбокс под цвет дела.
class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.done,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final bool done;
  final Color color;

  /// Иконка шаблона (если задан) — показывается в кружке у невыполненного дела.
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.transparent,
          border: Border.all(color: color, width: 1.7),
        ),
        child: done
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : (icon != null ? Icon(icon, size: 15, color: color) : null),
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
      icon: const Icon(Icons.east_rounded, size: 16),
      label: const Text('сегодня', style: TextStyle(fontSize: 13)),
    );
  }
}

/// Чек-лист подпунктов дела (раскрывается под строкой дела).
class SubtaskChecklist extends ConsumerWidget {
  const SubtaskChecklist({super.key, required this.taskId});
  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final subs = ref.watch(subtasksForTaskProvider(taskId)).value ?? [];
    final tasks = ref.watch(tasksProvider).value ?? const [];
    TaskModel? task;
    for (final t in tasks) {
      if (t.id == taskId) {
        task = t;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 6),
      child: Column(
        children: [
          for (var i = 0; i < subs.length; i++) ...[
            // Линия между подпунктами: с отступом слева, без точек.
            if (i > 0) Container(height: 1, color: dl.ink),
            _subRow(context, ref, subs[i], task),
          ],
        ],
      ),
    );
  }

  /// Кружок-галочка переключает выполнение; тап по тексту открывает карточку
  /// дела — там подпункт можно отредактировать.
  Widget _subRow(
      BuildContext context, WidgetRef ref, SubtaskModel s, TaskModel? task) {
    final dl = context.dl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                ref.read(repositoryProvider).setSubtaskDone(s, !s.isDone),
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                s.isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: s.isDone ? dl.accent : dl.inkFaint,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: task == null ? null : () => openTaskEditor(context, task),
              child: Text(
                s.title,
                style: TextStyle(
                  fontSize: 14,
                  color: s.isDone ? dl.inkFaint : dl.ink,
                  decoration: s.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
