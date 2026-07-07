import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/marker_label.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../task_editor/task_editor_screen.dart';
import 'trip_screen.dart';

/// Список путешествий: сейчас / предстоящие / прошедшие. Из строки можно
/// открыть дневник поездки или перейти к её дате в календаре.
class TripsListScreen extends ConsumerWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final trips = ref.watch(tripsProvider);
    final today = ref.watch(todayProvider);

    final current = <TaskModel>[];
    final upcoming = <TaskModel>[];
    final past = <TaskModel>[];
    for (final t in trips) {
      if (t.endDate.isBefore(today)) {
        past.add(t);
      } else if (t.startDate.isAfter(today)) {
        upcoming.add(t);
      } else {
        current.add(t);
      }
    }
    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Путешествия', style: context.serif.copyWith(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Новое путешествие',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => openTaskEditor(context, null, trip: true),
          ),
        ],
      ),
      body: trips.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.luggage_rounded, size: 40, color: dl.inkFaint),
                    const SizedBox(height: 12),
                    Text(
                      'Пока нет путешествий.\nСоздайте поездку — это период '
                      'с дневником: этапы по дням, места и заметки.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: dl.inkSoft, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (current.isNotEmpty) ...[
                  _groupLabel(context, 'Сейчас'),
                  for (final t in current) _TripTile(trip: t),
                ],
                if (upcoming.isNotEmpty) ...[
                  _groupLabel(context, 'Предстоящие'),
                  for (final t in upcoming) _TripTile(trip: t),
                ],
                if (past.isNotEmpty) ...[
                  _groupLabel(context, 'Прошедшие'),
                  for (final t in past) _TripTile(trip: t),
                ],
              ],
            ),
    );
  }

  Widget _groupLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        // Row даёт метке свободную ширину — маркер обнимает только слово.
        child: Row(
          children: [MarkerLabel(text: text, fontSize: 18, alpha: 0.5)],
        ),
      );
}

class _TripTile extends ConsumerWidget {
  const _TripTile({required this.trip});
  final TaskModel trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final color = context.taskColor(trip);
    final stages = ref.watch(stageCountProvider)[trip.id] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TripScreen(taskId: trip.id!))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(
            color: dl.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dl.line),
          ),
          child: Row(
            children: [
              Icon(Icons.luggage_rounded, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.serif
                            .copyWith(fontSize: 16, color: dl.ink)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDateRange(trip.startDate, trip.endDate)}'
                      ' · ${trip.durationDays} дн.'
                      '${stages > 0 ? ' · этапов: $stages' : ''}',
                      style: TextStyle(fontSize: 12.5, color: dl.inkSoft),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Показать в календаре',
                icon: Icon(Icons.event_rounded, size: 19, color: dl.inkSoft),
                onPressed: () {
                  ref.read(focusedDateProvider.notifier).set(trip.startDate);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
