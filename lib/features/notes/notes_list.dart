import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import 'note_editor.dart';

/// Список заметок одной категории: невыполненные (для «Покупок» — по разделам),
/// ниже — свёрнутый архив выполненных («Прочитанные»/«Просмотренные»/…).
class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key, required this.category});
  final int category;

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  bool _showDone = false;

  NoteCategory get _cat => kNoteCategories[widget.category];

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final notes = ref.watch(notesByCategoryProvider(widget.category));
    final active = notes.where((n) => !n.isDone).toList();
    final done = notes.where((n) => n.isDone).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_cat.name, style: context.serif.copyWith(fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            openNoteEditor(context, category: widget.category),
        backgroundColor: dl.accent,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(_cat.addLabel),
      ),
      body: notes.isEmpty
          ? Center(
              child: Text('пока пусто',
                  style: TextStyle(color: dl.inkFaint, fontSize: 15)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                // «Покупки» группируем по разделу/теме; остальные — плоско.
                if (widget.category == 4)
                  ..._groupedByTheme(context, active)
                else
                  for (final n in active) _tile(context, n),
                if (active.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('всё выполнено',
                        style: TextStyle(color: dl.inkFaint, fontSize: 14),
                        textAlign: TextAlign.center),
                  ),
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _showDone = !_showDone),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 10),
                      child: Row(
                        children: [
                          Text('${_cat.doneGroup} · ${done.length}',
                              style: context.serif.copyWith(
                                  fontSize: 15, color: dl.inkSoft)),
                          const Spacer(),
                          Icon(
                            _showDone
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: dl.inkFaint,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showDone)
                    for (final n in done) _tile(context, n),
                ],
              ],
            ),
    );
  }

  List<Widget> _groupedByTheme(BuildContext context, List<TaskModel> items) {
    final dl = context.dl;
    final groups = <String, List<TaskModel>>{};
    for (final n in items) {
      final key = n.author.trim().isEmpty ? '' : n.author.trim();
      groups.putIfAbsent(key, () => []).add(n);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty) return 1; // «без раздела» — в конец
        if (b.isEmpty) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return [
      for (final k in keys) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
          child: Text(k.isEmpty ? 'Без раздела' : k,
              style: TextStyle(
                  fontSize: 12,
                  color: dl.inkSoft,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
        ),
        for (final n in groups[k]!) _tile(context, n),
      ],
    ];
  }

  Widget _tile(BuildContext context, TaskModel n) {
    final dl = context.dl;
    final progress = ref.watch(subtaskProgressProvider)[n.id] ?? (0, 0);
    final hasSubs = progress.$2 > 0;
    final subtitle = _subtitle(n);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: dl.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dl.line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(10, 2, 12, 2),
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.read(repositoryProvider).toggleDone(n),
          child: Icon(
            n.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: n.isDone ? dl.accent : dl.inkFaint,
          ),
        ),
        title: Text(
          n.title.isEmpty ? '(без названия)' : n.title,
          style: context.serif.copyWith(
            fontSize: 16,
            color: n.isDone ? dl.inkFaint : dl.ink,
            decoration: n.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: dl.inkFaint)),
        trailing: hasSubs
            ? Text('${progress.$1}/${progress.$2}',
                style: TextStyle(fontSize: 12, color: dl.inkSoft))
            : null,
        onTap: () => openNoteEditor(context, existing: n),
      ),
    );
  }

  /// Подпись под названием: медиа — автор · год · аудитория; иначе — примечание.
  String? _subtitle(TaskModel n) {
    if (_cat.hasMedia) {
      final parts = <String>[
        if (n.author.trim().isNotEmpty) n.author.trim(),
        if (n.year != null) '${n.year}',
        if (n.audience > 0) kNoteAudienceLabels[n.audience],
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    }
    final note = n.note.trim();
    if (note.isEmpty) return null;
    final firstLine = note.split('\n').first;
    return firstLine;
  }
}
