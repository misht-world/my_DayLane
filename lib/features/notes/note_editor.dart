import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/desktop_nav.dart';
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
  // На широком окне (десктоп) — в правой панели, а не отдельным экраном.
  if (useDesktopDetail(context)) {
    ProviderScope.containerOf(context, listen: false)
        .read(detailReqProvider.notifier)
        .open(existing != null ? EditExisting(existing) : ComposeNote(cat));
    return;
  }
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
  const NoteEditorScreen(
      {super.key, this.existing, required this.category, this.onClose});
  final TaskModel? existing;
  final int category;

  /// В десктопной панели — закрыть через колбэк вместо Navigator.pop.
  final VoidCallback? onClose;

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

  /// Стабильный синк-id (см. пояснение в редакторе дела): не меняется между
  /// сохранениями, иначе заметка двоится на другом устройстве.
  late final String _syncUid;
  int? _savedId;

  /// Снимок загруженных подпунктов — чтобы не сохранять без реальных изменений
  /// (иначе «пустое» сохранение затрёт правку с другого устройства при синке).
  List<(String, bool)> _loadedSubs = const [];

  /// Дебаунс авто-сохранения в панельном (десктоп) режиме.
  Timer? _autosaveTimer;

  NoteCategory get _cat => kNoteCategories[widget.category];
  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _syncUid =
        (e != null && e.syncUid.isNotEmpty) ? e.syncUid : const Uuid().v4();
    _savedId = e?.id;
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
          _loadedSubs = [for (final s in l) (s.title, s.isDone)];
        });
      });
    }

    // В панели (десктоп) заметка может оставаться открытой — авто-сохраняем.
    if (widget.onClose != null) {
      for (final c in [_title, _author, _year, _note]) {
        c.addListener(_scheduleAutosave);
      }
    }
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _autosave();
    });
  }

  /// Закрытие: в панели — колбэк (очистить выбор), иначе — обычный pop.
  void _leave() {
    final cb = widget.onClose;
    if (cb != null) {
      cb();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    // В панели переключение на другой элемент = уход → авто-сохранение.
    if (widget.onClose != null) _autosave();
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
            onPressed: _leave,
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
      id: _savedId,
      syncUid: _syncUid,
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

  Future<int> _doSave() async {
    final repo = ref.read(repositoryProvider);
    final subs = [
      for (final s in _subs)
        if (s.controller.text.trim().isNotEmpty)
          SubtaskModel(
            taskId: _savedId ?? 0,
            title: s.controller.text.trim(),
            isDone: s.isDone,
          ),
    ];
    final id = await repo.saveTask(_model(), subtasks: subs);
    _savedId = id;
    return id;
  }

  /// Реальные ли изменения относительно загруженной заметки (см. пояснение в
  /// редакторе дела) — чтобы открытие без правок не переписывало `updatedAt`.
  bool _hasChanges() {
    final e = widget.existing;
    if (e == null) {
      return _title.text.trim().isNotEmpty ||
          _subs.any((s) => s.controller.text.trim().isNotEmpty);
    }
    final m = _model();
    final same = m.title == e.title &&
        m.author == e.author &&
        m.year == e.year &&
        m.audience == e.audience &&
        m.note == e.note &&
        m.links == e.links &&
        m.isDone == e.isDone;
    if (!same) return true;
    final cur = [
      for (final s in _subs)
        if (s.controller.text.trim().isNotEmpty)
          (s.controller.text.trim(), s.isDone)
    ];
    if (cur.length != _loadedSubs.length) return true;
    for (var i = 0; i < cur.length; i++) {
      if (cur[i].$1 != _loadedSubs[i].$1 || cur[i].$2 != _loadedSubs[i].$2) {
        return true;
      }
    }
    return false;
  }

  void _autosave() {
    if (_skipAutosave || _title.text.trim().isEmpty || !_hasChanges()) return;
    _doSave();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      _leave();
      return;
    }
    _skipAutosave = true;
    await _doSave();
    if (!mounted) return;
    _leave();
  }

  Future<void> _delete() async {
    _skipAutosave = true;
    final l = AppLocalizations.of(context);
    final undo =
        await ref.read(repositoryProvider).deleteTask(widget.existing!.id!);
    if (!mounted) return;
    showUndoSnack(context, l.noteDeleted, undo);
    _leave();
  }
}
