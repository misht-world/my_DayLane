import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/marker_label.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
import '../../domain/scheduling.dart';
import '../calendar/calendar_view.dart';
import '../task_editor/task_editor_screen.dart';

/// Обзор всех дел одним списком в стиле «ежедневника»: сгруппированы по
/// близости (просрочено / сегодня / завтра / ближайшие / позже / отложенные /
/// выполнено). Тап открывает дело (поездку — дневником).
class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final tasks = ref.watch(tasksProvider).value ?? const [];
    final today = ref.watch(todayProvider);

    // Опорная дата дела для группировки и сортировки.
    DateTime refOf(TaskModel t) {
      if (t.isRecurring) {
        final occ = nextOccurrences(t, today, 1);
        return occ.isEmpty ? dateOnly(t.startDate) : occ.first;
      }
      if (t.isPeriod &&
          !today.isBefore(dateOnly(t.startDate)) &&
          !today.isAfter(dateOnly(t.endDate))) {
        return today;
      }
      return dateOnly(t.startDate);
    }

    const kOverdue = 0,
        kToday = 1,
        kTomorrow = 2,
        kSoon = 3,
        kLater = 4,
        kDeferred = 5,
        kDone = 6;

    int bucketOf(TaskModel t) {
      if (t.deferred) return kDeferred;
      if (!t.isRecurring && t.isDone) return kDone;
      if (isOverdue(t, today)) return kOverdue;
      final d = daysBetween(today, refOf(t));
      if (d <= 0) return kToday;
      if (d == 1) return kTomorrow;
      if (d <= 7) return kSoon;
      return kLater;
    }

    final groups = <int, List<TaskModel>>{};
    for (final t in tasks) {
      groups.putIfAbsent(bucketOf(t), () => []).add(t);
    }
    for (final list in groups.values) {
      list.sort((a, b) {
        final c = refOf(a).compareTo(refOf(b));
        return c != 0 ? c : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }

    const titles = {
      kOverdue: 'Просрочено',
      kToday: 'Сегодня',
      kTomorrow: 'Завтра',
      kSoon: 'Ближайшие дни',
      kLater: 'Позже',
      kDeferred: 'Отложенные',
      kDone: 'Выполнено',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Все дела', style: context.serif.copyWith(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Новое дело',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => openTaskEditor(context, null),
          ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.checklist_rounded, size: 40, color: dl.inkFaint),
                    const SizedBox(height: 12),
                    Text('Пока нет дел',
                        style: TextStyle(color: dl.inkSoft, fontSize: 14)),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                for (final k in const [
                  kOverdue,
                  kToday,
                  kTomorrow,
                  kSoon,
                  kLater,
                  kDeferred,
                  kDone
                ])
                  if (groups[k] != null && groups[k]!.isNotEmpty) ...[
                    _groupLabel(context, titles[k]!,
                        danger: k == kOverdue, count: groups[k]!.length),
                    for (final t in groups[k]!)
                      _TaskTile(task: t, refDate: refOf(t)),
                  ],
              ],
            ),
    );
  }

  Widget _groupLabel(BuildContext context, String text,
      {required bool danger, required int count}) {
    final dl = context.dl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Row(
        children: [
          MarkerLabel(
            text: text,
            fontSize: 18,
            markerColor: danger ? dl.danger : dl.marker,
            alpha: 0.5,
          ),
          const SizedBox(width: 10),
          Text('$count',
              style: TextStyle(
                  fontSize: 12,
                  color: danger ? dl.danger : dl.inkFaint)),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, required this.refDate});
  final TaskModel task;
  final DateTime refDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final color = context.taskColor(task);
    final progress = ref.watch(subtaskProgressProvider)[task.id] ?? (0, 0);
    final hasSubs = progress.$2 > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => openTaskOrTrip(context, task),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
          decoration: BoxDecoration(
            color: dl.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dl.line),
          ),
          child: Row(
            children: [
              if (task.isTrip)
                Icon(Icons.luggage_rounded, size: 18, color: color)
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.serif.copyWith(
                          fontSize: 16,
                          color: task.isDone ? dl.inkFaint : dl.ink,
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                        )),
                    const SizedBox(height: 2),
                    Text(_subtitle(),
                        style: TextStyle(fontSize: 12.5, color: dl.inkSoft)),
                  ],
                ),
              ),
              if (hasSubs)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('${progress.$1}/${progress.$2}',
                      style: TextStyle(fontSize: 12, color: dl.inkSoft)),
                ),
              Icon(Icons.chevron_right_rounded, size: 20, color: dl.inkFaint),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    if (task.deferred) return 'без даты';
    if (task.isRecurring) {
      return '${recurrenceSummary(task)} · ${formatDayMonth(refDate)}';
    }
    if (task.isPeriod) {
      return '${formatDateRange(task.startDate, task.endDate)}'
          ' · ${task.durationDays} дн.';
    }
    final time = task.timeOfDayMinutes;
    return time == null
        ? formatDayMonth(task.startDate)
        : '${formatDayMonth(task.startDate)} · ${formatMinutesOfDay(time)}';
  }
}
