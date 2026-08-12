import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/note_l10n.dart';
import '../../core/theme.dart';
import '../../core/undo_snack.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/links.dart';
import '../common/links_editor.dart';

/// Открывает карточку заметки. [existing] == null — создание в [category];
/// иначе редактирование (категория берётся из заметки).
void openNoteEditor(BuildContext context, {TaskModel? existing, int? category}) {
  final cat = existing?.noteCategory ?? category ?? 0;
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => NoteEditorScreen(existing: existing, category: cat),
  ));
}

class _SubItem {
  _SubItem(String text, this.isDone)
      : controller = TextEditingController(text: text),
        focus = FocusNode();
  final TextEditingController controller;
  final FocusNode focus;
  bool isDone;
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.existing, required this.category});
  final TaskModel? existing;
  final int category;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _year;
  late final TextEditingController _note;
  List<String> _links = [];
  int _audience = 0;
  bool _isDone = false;
  final List<_SubItem> _subs = [];
  bool _skipAutosave = false;

  NoteCategory get _cat => kNoteCategories[widget.category];
  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _author = TextEditingController(text: e?.author ?? '');
    _year = TextEditingController(text: e?.year?.toString() ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _links = parseLinks(e?.links ?? '');
    _audience = e?.audience ?? 0;
    _isDone = e?.isDone ?? false;
    if (_editing) {
      ref.read(repositoryProvider).getSubtasks(widget.existing!.id!).then((l) {
        if (!mounted) return;
        setState(() {
          for (final s in l) {
            _subs.add(_SubItem(s.title, s.isDone));
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _year.dispose();
    _note.dispose();
    for (final s in _subs) {
      s.controller.dispose();
      s.focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    final cat = widget.category;
    final person = notePersonLabel(l, cat);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _autosave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(noteCatName(l, cat),
              style: context.serif.copyWith(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text(l.commonDone,
                  style: TextStyle(
                      color: dl.accent, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 32 + MediaQuery.of(context).viewInsets.bottom),
          children: [
            _card(children: [
              TextField(
                controller: _title,
                style: context.serif.copyWith(
                    fontSize: 20,
                    color: dl.ink,
                    fontWeight: FontWeight.w500),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: noteItemHint(l, cat),
                  hintStyle:
                      context.serif.copyWith(fontSize: 20, color: dl.inkFaint),
                  border: InputBorder.none,
                ),
              ),
            ]),
            const SizedBox(height: 14),
            // Поля по категории: автор/год/аудитория (медиа) или раздел (покупки).
            if (_cat.hasMedia || person != null) ...[
              _card(children: [
                if (person != null)
                  TextField(
                    controller: _author,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: person,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                if (_cat.hasMedia) ...[
                  Divider(height: 1, color: dl.line),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: InputDecoration(
                            labelText: l.noteYear,
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _label(l.noteFor),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    segments: [
                      for (final (i, label)
                          in noteAudienceOptions(l).indexed)
                        ButtonSegment(value: i, label: Text(label)),
                    ],
                    selected: {_audience},
                    onSelectionChanged: (s) =>
                        setState(() => _audience = s.first),
                  ),
                ],
              ]),
              const SizedBox(height: 14),
            ],
            _card(children: [_subtaskBlock()]),
            const SizedBox(height: 14),
            _card(children: [
              LinksEditor(
                label: cat == 4 ? l.noteLinksPhotos : l.noteLinksFiles,
                links: _links,
                onChanged: (v) => setState(() => _links = v),
              ),
            ]),
            const SizedBox(height: 14),
            _card(children: [
              _label(l.noteFieldNote),
              const SizedBox(height: 2),
              TextField(
                controller: _note,
                maxLines: null,
                minLines: 2,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l.noteFieldHint,
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ]),
            const SizedBox(height: 14),
            // Отметка выполнения — уводит заметку в архив категории.
            _card(children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 20, color: dl.inkSoft),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Text(noteDoneLabel(l, cat),
                          style: TextStyle(fontSize: 15, color: dl.ink))),
                  Switch(
                    value: _isDone,
                    onChanged: _subs.isEmpty
                        ? (v) => setState(() => _isDone = v)
                        : null,
                  ),
                ],
              ),
              if (_subs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 34),
                  child: Text(l.noteDoneWhenAll,
                      style: TextStyle(fontSize: 12, color: dl.inkFaint)),
                ),
            ]),
            if (_editing) ...[
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: dl.danger),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(l.commonDelete),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final dl = context.dl;
    return Container(
      decoration: BoxDecoration(
        color: dl.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dl.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 13,
          color: context.dl.inkSoft,
          fontWeight: FontWeight.w500));

  Widget _subtaskBlock() {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l.notePoints),
        const SizedBox(height: 4),
        for (var i = 0; i < _subs.length; i++)
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _subs[i].isDone = !_subs[i].isDone),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(
                    _subs[i].isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: _subs[i].isDone ? dl.accent : dl.inkFaint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _subs[i].controller,
                  focusNode: _subs[i].focus,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: l.notePointHint,
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: dl.inkFaint),
                onPressed: () => setState(() => _subs.removeAt(i)),
              ),
            ],
          ),
        TextButton.icon(
          onPressed: () {
            final item = _SubItem('', false);
            setState(() => _subs.add(item));
            WidgetsBinding.instance
                .addPostFrameCallback((_) => item.focus.requestFocus());
          },
          style: TextButton.styleFrom(
              foregroundColor: dl.accent, padding: EdgeInsets.zero),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l.noteAddPoint),
        ),
      ],
    );
  }

  TaskModel _model() {
    final e = widget.existing;
    final now = DateTime.now();
    final today = dateOnly(now);
    return TaskModel(
      id: e?.id,
      title: _title.text.trim(),
      kind: TaskKind.single,
      startDate: e?.startDate ?? today,
      endDate: e?.endDate ?? today,
      durationDays: 1,
      deferred: true, // заметки — вне календаря и секций дня
      noteCategory: widget.category,
      author: _author.text.trim(),
      year: int.tryParse(_year.text.trim()),
      audience: _cat.hasMedia ? _audience : 0,
      colorId: _cat.colorId,
      note: _note.text.trim(),
      links: joinLinks(_links),
      isDone: _isDone,
      completedAt: e?.completedAt,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<int> _doSave() {
    final repo = ref.read(repositoryProvider);
    final subs = [
      for (final s in _subs)
        if (s.controller.text.trim().isNotEmpty)
          SubtaskModel(
            taskId: widget.existing?.id ?? 0,
            title: s.controller.text.trim(),
            isDone: s.isDone,
          ),
    ];
    return repo.saveTask(_model(), subtasks: subs);
  }

  void _autosave() {
    if (_skipAutosave || _title.text.trim().isEmpty) return;
    _doSave();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _skipAutosave = true;
    await _doSave();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    _skipAutosave = true;
    final l = AppLocalizations.of(context);
    final undo =
        await ref.read(repositoryProvider).deleteTask(widget.existing!.id!);
    if (!mounted) return;
    showUndoSnack(context, l.noteDeleted, undo);
    Navigator.of(context).pop();
  }
}
