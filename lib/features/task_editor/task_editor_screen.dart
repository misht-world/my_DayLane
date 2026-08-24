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
import '../../domain/dependencies.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
import '../../l10n/app_localizations.dart';
import '../../services/links.dart';
import '../../services/maps.dart';
import '../common/links_editor.dart';
import '../trips/trip_screen.dart';

/// Открывает карточку дела. [existing] == null — создание;
/// [initialDate] задаёт дату нового дела (по умолчанию — сегодня);
/// [trip] — сразу создать путешествие (период с дневником).
void openTaskEditor(BuildContext context, TaskModel? existing,
    {DateTime? initialDate, bool deferred = false, bool trip = false}) {
  // На широком окне (десктоп) — в правой панели, а не отдельным экраном.
  if (useDesktopDetail(context)) {
    ProviderScope.containerOf(context, listen: false)
        .read(detailReqProvider.notifier)
        .open(existing != null
            ? EditExisting(existing)
            : ComposeTask(
                initialDate: initialDate, deferred: deferred, trip: trip));
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => TaskEditorScreen(
        existing: existing,
        initialDate: initialDate,
        deferred: deferred,
        trip: trip),
  ));
}

class _SubItem {
  final TextEditingController controller;
  final FocusNode focus;
  bool isDone;
  _SubItem(String text, this.isDone)
      : controller = TextEditingController(text: text),
        focus = FocusNode();
}

class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen(
      {super.key,
      this.existing,
      this.initialDate,
      this.deferred = false,
      this.trip = false,
      this.onClose});
  final TaskModel? existing;
  final DateTime? initialDate;
  final bool deferred;
  final bool trip;

  /// В десктопной панели — закрыть/сохранить через колбэк (очистить выбор),
  /// а не Navigator.pop. null — обычный полноэкранный режим.
  final VoidCallback? onClose;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _place;
  String _placeUrl = '';
  List<String> _links = [];

  late TaskKind _kind;
  late DateTime _start;
  late DateTime _end;
  late int _duration;
  int? _timeMinutes;
  int? _dependsOn;
  bool _dependsBefore = false;

  bool _reminderEnabled = false;
  ReminderRule _reminderRule = ReminderRule.atStart;
  int _reminderMinutes = kDefaultReminderMinutes;
  int _reminderDaysBefore = 0;
  int _colorId = 0;
  int _iconId = -1;

  RecurrenceType _recurrence = RecurrenceType.none;
  int _recurInterval = 1;
  int _recurAnchor = 2; // K для monthBeforeEnd
  bool _deferred = false;
  bool _isTrip = false;

  final List<_SubItem> _subs = [];

  /// Стабильный синк-id карточки. Для существующего дела — его же uid; для
  /// нового — генерируется один раз здесь, чтобы повторные сохранения (авто-
  /// сохранение при закрытии/переключении) НЕ плодили новый uid каждый раз
  /// (иначе на другом устройстве дело двоится при каждой правке).
  late final String _syncUid;

  /// id сохранённой строки — чтобы повторные сохранения обновляли её, а не
  /// вставляли копию.
  int? _savedId;

  /// Не авто-сохранять при закрытии (после удаления или явного «Готово»).
  bool _skipAutosave = false;

  /// Дебаунс авто-сохранения в панельном (десктоп) режиме.
  Timer? _autosaveTimer;

  bool get _editing => widget.existing != null;
  bool get _linked => _dependsOn != null;
  AppLocalizations get _l => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _syncUid =
        (e != null && e.syncUid.isNotEmpty) ? e.syncUid : const Uuid().v4();
    _savedId = e?.id;
    final today = dateOnly(widget.initialDate ?? DateTime.now());
    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _place = TextEditingController(text: e?.placeName ?? '');
    _placeUrl = e?.placeUrl ?? '';
    _links = parseLinks(e?.links ?? '');
    _isTrip = e?.isTrip ?? widget.trip;
    _kind = e?.kind ?? (widget.trip ? TaskKind.period : TaskKind.single);
    _start = e?.startDate ?? today;
    _end = e?.endDate ?? today;
    _duration = e?.durationDays ?? 1;
    _timeMinutes = e?.timeOfDayMinutes;
    _dependsOn = e?.dependsOnTaskId;
    _dependsBefore = e?.dependsBefore ?? false;
    _reminderEnabled = e?.reminderEnabled ?? false;
    _reminderRule = e?.reminderRule ?? ReminderRule.atStart;
    _reminderMinutes = e?.reminderMinutes ?? kDefaultReminderMinutes;
    _reminderDaysBefore = e?.reminderDaysBefore ?? 0;
    _colorId = e?.colorId ?? 0;
    _iconId = e?.iconId ?? -1;
    _recurrence = e?.recurrenceType ?? RecurrenceType.none;
    _recurInterval = e?.recurrenceInterval ?? 1;
    _recurAnchor = (e?.recurrenceType == RecurrenceType.monthBeforeEnd)
        ? (e?.recurrenceAnchor ?? 2)
        : 2;
    _deferred = e?.deferred ?? widget.deferred;

    if (_editing) {
      ref
          .read(repositoryProvider)
          .getSubtasks(widget.existing!.id!)
          .then((list) {
        if (!mounted) return;
        setState(() {
          for (final s in list) {
            _subs.add(_SubItem(s.title, s.isDone));
          }
        });
      });
    }

    // В панели (десктоп) карточка может оставаться открытой — авто-сохраняем
    // изменения текста с задержкой, чтобы дело не потерялось, если не закрыть.
    if (widget.onClose != null) {
      for (final c in [_title, _note, _place]) {
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
    // В панели переключение на другой элемент = уход с карточки → авто-сохранение.
    if (widget.onClose != null) _autosave();
    _title.dispose();
    _note.dispose();
    _place.dispose();
    for (final s in _subs) {
      s.controller.dispose();
      s.focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final divider = Divider(height: 1, color: dl.line);
    // Авто-сохранение: закрытие/свайп назад сохраняет дело (если есть заголовок),
    // отдельно жать «Готово» не обязательно.
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
        title: Text(_l.taskTitle, style: context.serif.copyWith(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(_l.commonDone,
                style: TextStyle(
                    color: dl.accent, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: ListView(
        // Низ прокручивается над клавиатурой (иначе примечание/файлы не видны).
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 32 + MediaQuery.of(context).viewInsets.bottom),
        children: [
          _titleField(),
          const SizedBox(height: 14),
          _kindSegment(),
          const SizedBox(height: 14),
          // Карточка «Когда»: отложить, дата/период, повторение, напоминание.
          _card(children: [
            _switchTile(
              Icons.bookmark_border_rounded,
              _l.taskDefer,
              _l.taskDeferSubtitle,
              _deferred,
              (v) => setState(() => _deferred = v),
            ),
            if (!_deferred) ...[
              divider,
              if (_kind == TaskKind.single) ...[
                ..._singleFields(),
                divider,
                _recurrenceBlock(),
              ] else
                ..._periodFields(),
              divider,
              _reminderBlock(),
            ],
          ]),
          const SizedBox(height: 14),
          _card(children: [_templateBlock()]),
          const SizedBox(height: 14),
          _card(children: [_colorBlock()]),
          const SizedBox(height: 14),
          _card(children: [_placeBlock()]),
          const SizedBox(height: 14),
          _card(children: [
            LinksEditor(
              links: _links,
              onChanged: (v) => setState(() => _links = v),
            ),
          ]),
          const SizedBox(height: 14),
          _card(children: [_subtaskBlock()]),
          const SizedBox(height: 14),
          _card(children: [
            _label(_l.noteFieldNote),
            const SizedBox(height: 2),
            TextField(
              controller: _note,
              maxLines: null,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _l.taskNoteHint,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ]),
          if (_editing) ...[
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: dl.danger),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(_l.taskDelete),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  // ── Карточки и контейнеры ─────────────────────────────────────
  Widget _card({required List<Widget> children}) {
    final dl = context.dl;
    return Container(
      decoration: BoxDecoration(
        color: dl.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dl.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _titleField() {
    final dl = context.dl;
    return Container(
      decoration: BoxDecoration(
        color: dl.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dl.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _title,
        style: context.serif
            .copyWith(fontSize: 20, color: dl.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: _l.taskTitleHint,
          hintStyle: context.serif.copyWith(fontSize: 20, color: dl.inkFaint),
          border: InputBorder.none,
        ),
        textCapitalization: TextCapitalization.sentences,
        minLines: 1,
        maxLines: 3,
      ),
    );
  }

  /// Строка-переключатель с ведущей иконкой (для карточек).
  Widget _switchTile(IconData icon, String title, String? subtitle, bool value,
      ValueChanged<bool> onChanged) {
    final dl = context.dl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: dl.inkSoft),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, color: dl.ink)),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: dl.inkFaint)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  /// Строка с ведущей иконкой, подписью и трейлингом (Дата/Время и т.п.).
  Widget _iconRow(IconData icon, String label, Widget trailing) {
    final dl = context.dl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: dl.inkSoft),
          const SizedBox(width: 14),
          Expanded(
              child:
                  Text(label, style: TextStyle(fontSize: 15, color: dl.ink))),
          trailing,
        ],
      ),
    );
  }

  Widget _kindSegment() {
    // 0 — один день, 1 — период, 2 — путешествие (период с дневником).
    final selected = _kind == TaskKind.single ? 0 : (_isTrip ? 2 : 1);
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 0, label: Text(_l.kindOneDay)),
        ButtonSegment(value: 1, label: Text(_l.kindPeriod)),
        ButtonSegment(value: 2, label: Text(_l.kindTrip)),
      ],
      selected: {selected},
      onSelectionChanged: (s) {
        setState(() {
          final v = s.first;
          _isTrip = v == 2;
          _kind = v == 0 ? TaskKind.single : TaskKind.period;
          if (_kind == TaskKind.single) {
            _end = _start;
            _duration = 1;
            _dependsOn = null;
          } else {
            _timeMinutes = null;
            if (_end.isBefore(_start)) _end = _start;
            _duration = daysBetween(_start, _end) + 1;
          }
        });
      },
    );
  }

  List<Widget> _singleFields() {
    final dl = context.dl;
    return [
      _iconRow(
        Icons.event_rounded,
        _l.fieldDate,
        _pillButton(formatDayMonth(_start), () async {
          final picked = await _pickDate(_start);
          if (picked != null) setState(() => _start = _end = picked);
        }),
      ),
      Divider(height: 1, color: dl.line),
      _iconRow(
        Icons.schedule_rounded,
        _l.fieldTime,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pillButton(
              _timeMinutes == null ? _l.timeUnset : formatMinutesOfDay(_timeMinutes!),
              _pickTime,
            ),
            if (_timeMinutes != null)
              IconButton(
                icon: Icon(Icons.clear_rounded, size: 18, color: dl.inkFaint),
                onPressed: () => setState(() => _timeMinutes = null),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _periodFields() {
    final dl = context.dl;
    final tasks = ref.watch(tasksProvider).value ?? const [];
    final parent =
        _dependsOn == null ? null : tasks.where((t) => t.id == _dependsOn).firstOrNull;

    // Для привязанного дела start/end вычисляются от родителя.
    if (_linked && parent != null) {
      if (_dependsBefore) {
        // «Закончить до дела»: конец за день до начала родителя.
        _end = addDays(parent.startDate, -1);
        _start = addDays(_end, -(_duration - 1));
      } else {
        // «Начать после дела»: старт на следующий день после конца родителя.
        _start = addDays(parent.endDate, 1);
        _end = addDays(_start, _duration - 1);
      }
    }

    return [
      if (!_linked) ...[
        // Единый выбор диапазона на календаре: первый тап — начало,
        // второй — конец; диапазон подсвечивается полосой.
        InkWell(
          onTap: _pickRange,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.date_range_rounded, size: 20, color: dl.inkSoft),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(_l.fieldDates,
                        style: TextStyle(fontSize: 15, color: dl.ink))),
                Flexible(
                  child: Text(
                    '${formatDateRange(_start, _end)} · ${_l.daysAbbrev(_duration)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14, color: dl.inkSoft),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: dl.inkFaint),
              ],
            ),
          ),
        ),
      ] else ...[
        _row(
            _l.linkStart,
            Text(
                _dependsBefore
                    ? formatDayMonth(_start)
                    : _l.linkedAfter(parent?.title ?? '—', formatDayMonth(_start)),
                style: TextStyle(color: dl.inkSoft, fontSize: 14))),
        const SizedBox(height: 10),
        _row(
          _l.duration,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepBtn(Icons.remove_rounded, () {
                if (_duration > 1) setState(() => _duration--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(_l.daysAbbrev(_duration),
                    style: const TextStyle(fontSize: 15)),
              ),
              _stepBtn(Icons.add_rounded, () => setState(() => _duration++)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _row(
            _l.linkEnd,
            Text(
                _dependsBefore
                    ? _l.linkedBefore(parent?.title ?? '—', formatDayMonth(_end))
                    : formatDayMonth(_end),
                style: TextStyle(color: dl.inkSoft, fontSize: 14))),
      ],
      Divider(height: 1, color: dl.line),
      _switchTile(
        Icons.link_rounded,
        _l.linkToTask,
        _l.linkToTaskSubtitle,
        _linked,
        (v) {
          if (v) {
            _pickParent();
          } else {
            setState(() => _dependsOn = null);
          }
        },
      ),
      if (_linked) ...[
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(_l.segStartAfter)),
            ButtonSegment(value: true, label: Text(_l.segFinishBefore)),
          ],
          selected: {_dependsBefore},
          onSelectionChanged: (s) => setState(() => _dependsBefore = s.first),
        ),
        const SizedBox(height: 8),
      ],
      if (_linked && parent != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: dl.sunken,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: dl.line),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TaskPalette.byId(parent.colorId)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(parent.title)),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: dl.inkFaint),
                onPressed: () => setState(() => _dependsOn = null),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _recurrenceBlock() {
    final dl = context.dl;
    final labels = {
      RecurrenceType.none: _l.recurNone,
      RecurrenceType.days: _l.recurDays,
      RecurrenceType.weeks: _l.recurWeeks,
      RecurrenceType.months: _l.recurMonths,
      RecurrenceType.years: _l.recurYears,
      RecurrenceType.monthLastDay: _l.recurMonthLast,
      RecurrenceType.monthBeforeEnd: _l.recurMonthBeforeEnd,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.repeat_rounded, size: 20, color: dl.inkSoft),
            const SizedBox(width: 14),
            Text(_l.recurRepeat,
                style: TextStyle(fontSize: 15, color: dl.ink)),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButton<RecurrenceType>(
          value: _recurrence,
          isExpanded: true,
          underline: Container(height: 1, color: dl.line),
          items: [
            for (final e in labels.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) =>
              setState(() => _recurrence = v ?? RecurrenceType.none),
        ),
        if (_recurrence != RecurrenceType.none) ...[
          const SizedBox(height: 10),
          _row(
            _l.recurInterval,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepBtn(Icons.remove_rounded, () {
                  if (_recurInterval > 1) setState(() => _recurInterval--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(_l.recurEvery('$_recurInterval', _recurUnit()),
                      style: const TextStyle(fontSize: 15)),
                ),
                _stepBtn(
                    Icons.add_rounded, () => setState(() => _recurInterval++)),
              ],
            ),
          ),
          if (_recurrence == RecurrenceType.monthBeforeEnd) ...[
            const SizedBox(height: 10),
            _row(
              _l.recurDaysToEnd,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _stepBtn(Icons.remove_rounded, () {
                    if (_recurAnchor > 0) setState(() => _recurAnchor--);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$_recurAnchor',
                        style: const TextStyle(fontSize: 15)),
                  ),
                  _stepBtn(
                      Icons.add_rounded, () => setState(() => _recurAnchor++)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(recurrenceSummary(_currentModel()),
              style: context.serif.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: dl.taskRecurring)),
        ],
      ],
    );
  }

  String _recurUnit() => switch (_recurrence) {
        RecurrenceType.days => _l.unitDays,
        RecurrenceType.weeks => _l.unitWeeks,
        RecurrenceType.years => _l.unitYears,
        _ => _l.unitMonths,
      };

  /// Выбор шаблона: иконка в кружке + цвет по умолчанию (цвет ниже можно
  /// переопределить). «Другое» — без иконки.
  Widget _templateBlock() {
    final dl = context.dl;

    Widget cell({
      required bool selected,
      required VoidCallback onTap,
      required Widget child,
      required String label,
      Color? color,
    }) {
      final c = color ?? dl.inkSoft;
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? c.withValues(alpha: 0.14) : Colors.transparent,
                border: Border.all(
                    color: selected ? c : dl.lineStrong,
                    width: selected ? 2 : 1),
              ),
              child: child,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: selected ? dl.ink : dl.inkFaint)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_l.tplTemplate),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            cell(
              selected: _iconId < 0,
              label: _l.tplOther,
              onTap: () => setState(() => _iconId = -1),
              child: Icon(Icons.circle_outlined,
                  size: 20, color: _iconId < 0 ? dl.ink : dl.inkFaint),
            ),
            for (var i = 0; i < kTaskTemplates.length; i++)
              cell(
                selected: _iconId == i,
                label: taskTemplateName(_l, i),
                color: TaskPalette.byId(kTaskTemplates[i].colorId),
                onTap: () => setState(() {
                  _iconId = i;
                  // Шаблон задаёт цвет по умолчанию (ниже можно переопределить).
                  _colorId = kTaskTemplates[i].colorId;
                }),
                child: Icon(kTaskTemplates[i].icon,
                    size: 22,
                    color: TaskPalette.byId(kTaskTemplates[i].colorId)),
              ),
          ],
        ),
      ],
    );
  }

  /// Место дела: название + ссылка на карты (открыть / вставить из буфера).
  Widget _placeBlock() {
    final dl = context.dl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_l.placeTitle),
        const SizedBox(height: 2),
        TextField(
          controller: _place,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: _l.placeHint,
            border: InputBorder.none,
            isDense: true,
            suffixIcon: _placeUrl.isNotEmpty
                ? IconButton(
                    tooltip: _l.mapsRemove,
                    icon: Icon(Icons.link_off_rounded,
                        size: 18, color: dl.inkFaint),
                    onPressed: () => setState(() => _placeUrl = ''),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  openInMaps(url: _placeUrl, query: _place.text),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dl.lineStrong),
                foregroundColor: dl.ink,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.map_rounded, size: 16),
              label: Text(_l.mapsOpen, style: const TextStyle(fontSize: 13)),
            ),
            OutlinedButton.icon(
              onPressed: _pastePlaceLink,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dl.lineStrong),
                foregroundColor: dl.ink,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.content_paste_rounded, size: 16),
              label: Text(_l.mapsPaste, style: const TextStyle(fontSize: 13)),
            ),
            if (_placeUrl.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.link_rounded, size: 14, color: dl.accent),
                const SizedBox(width: 3),
                Text(_l.mapsSaved,
                    style: TextStyle(fontSize: 12, color: dl.accent)),
              ]),
          ],
        ),
      ],
    );
  }

  Future<void> _pastePlaceLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (looksLikeMapsLink(text)) {
      // Короткую ссылку разворачиваем в полную (в ней координаты и название).
      var stored = text;
      if (isShortMapsLink(text)) {
        final full = await resolveMapsShortLink(text);
        if (full != null && looksLikeMapsLink(full)) stored = full;
      }
      if (!mounted) return;
      setState(() {
        _placeUrl = stored;
        // Если название пустое — пробуем достать из полной ссылки.
        if (_place.text.trim().isEmpty) {
          final name = placeNameFromUrl(stored);
          if (name != null) _place.text = name;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l.mapsClipboardEmpty)));
    }
  }

  Widget _colorBlock() {
    final dl = context.dl;
    Widget dot({
      required bool selected,
      required VoidCallback onTap,
      Color? color,
      bool auto = false,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.transparent,
            border: Border.all(
              color: selected ? dl.ink : (auto ? dl.lineStrong : Colors.transparent),
              width: selected ? 2 : 1,
            ),
          ),
          child: auto
              ? Icon(Icons.brightness_auto_rounded,
                  size: 17, color: selected ? dl.ink : dl.inkSoft)
              : (selected
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_l.colorInCalendar),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            dot(
              auto: true,
              selected: _colorId < 0,
              onTap: () => setState(() => _colorId = -1),
            ),
            for (var i = 0; i < TaskPalette.colors.length; i++)
              dot(
                color: TaskPalette.colors[i],
                selected: _colorId == i,
                onTap: () => setState(() => _colorId = i),
              ),
          ],
        ),
      ],
    );
  }

  Widget _reminderBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _switchTile(
          Icons.notifications_none_rounded,
          _l.reminder,
          null,
          _reminderEnabled,
          (v) => setState(() => _reminderEnabled = v),
        ),
        if (_reminderEnabled) ...[
          if (_kind == TaskKind.period)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SegmentedButton<ReminderRule>(
                segments: [
                  ButtonSegment(value: ReminderRule.atStart, label: Text(_l.remAtStart)),
                  ButtonSegment(value: ReminderRule.eachDay, label: Text(_l.remEachDay)),
                  ButtonSegment(value: ReminderRule.atEnd, label: Text(_l.remAtEnd)),
                ],
                selected: {_reminderRule},
                onSelectionChanged: (s) =>
                    setState(() => _reminderRule = s.first),
              ),
            ),
          if (_kind == TaskKind.single && _timeMinutes != null)
            // Дело со временем — напоминание приходит в это же время.
            _row(
              _l.remTime,
              Text(_l.remByTaskTime(formatMinutesOfDay(_timeMinutes!)),
                  style: TextStyle(fontSize: 14, color: context.dl.inkSoft)),
            )
          else
            _row(
              _l.remTime,
              _pillButton(formatMinutesOfDay(_reminderMinutes), () async {
                final picked = await _pickTimeOfDay(_reminderMinutes);
                if (picked != null) setState(() => _reminderMinutes = picked);
              }),
            ),
          const SizedBox(height: 10),
          _label(_l.remWhen),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final opt in [
                (0, _l.remOnDay),
                (1, _l.remDayBefore),
                (2, _l.remDays2),
                (3, _l.remDays3),
                (7, _l.remWeekBefore),
              ])
                ChoiceChip(
                  label: Text(opt.$2),
                  selected: _reminderDaysBefore == opt.$1,
                  onSelected: (_) =>
                      setState(() => _reminderDaysBefore = opt.$1),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _subtaskBlock() {
    final dl = context.dl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_l.taskSubtasks),
        const SizedBox(height: 4),
        for (var i = 0; i < _subs.length; i++)
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => _subs[i].isDone = !_subs[i].isDone),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 8),
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
                  // Длинный текст подпункта переносится, виден полностью.
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: _l.notePointHint,
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
            // Сразу ставим курсор в новый пункт.
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => item.focus.requestFocus());
          },
          style: TextButton.styleFrom(
              foregroundColor: dl.accent, padding: EdgeInsets.zero),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(_l.noteAddPoint),
        ),
      ],
    );
  }

  // ── Хелперы UI ────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 13, color: context.dl.inkSoft, fontWeight: FontWeight.w500));

  Widget _row(String label, Widget trailing) => Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 15, color: context.dl.ink))),
          trailing,
        ],
      );

  Widget _pillButton(String text, VoidCallback onTap) {
    final dl = context.dl;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: dl.lineStrong),
        foregroundColor: dl.ink,
        visualDensity: VisualDensity.compact,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    final dl = context.dl;
    return InkResponse(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: dl.lineStrong),
        ),
        child: Icon(icon, size: 18, color: dl.ink),
      ),
    );
  }

  // ── Пикеры ────────────────────────────────────────────────────
  /// Выбор диапазона дат периода на одном календаре (тап начало → тап конец).
  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _start, end: _end),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: _l.pickPeriod,
    );
    if (range != null) {
      setState(() {
        _start = dateOnly(range.start);
        _end = dateOnly(range.end);
        _duration = daysBetween(_start, _end) + 1;
      });
    }
  }

  Future<DateTime?> _pickDate(DateTime initial, {DateTime? first}) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _pickTime() async {
    final picked = await _pickTimeOfDay(_timeMinutes ?? 9 * 60);
    if (picked != null) {
      setState(() {
        _timeMinutes = picked;
        // Указано время — включаем напоминание (его можно выключить вручную).
        _reminderEnabled = true;
      });
    }
  }

  Future<int?> _pickTimeOfDay(int initialMinutes) async {
    final res = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: initialMinutes ~/ 60, minute: initialMinutes % 60),
    );
    return res == null ? null : res.hour * 60 + res.minute;
  }

  Future<void> _pickParent() async {
    final tasks = ref.read(tasksProvider).value ?? const [];
    final draft = _currentModel();
    final candidates = eligibleParents(tasks, draft, DateTime.now());
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l.noEligibleParents)),
      );
      return;
    }
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.dl.surface,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_dependsBefore ? _l.pickBeforeTitle : _l.pickAfterTitle,
                  style: context.serif.copyWith(fontSize: 17)),
            ),
            for (final t in candidates)
              ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TaskPalette.byId(t.colorId)),
                ),
                title: Text(t.title),
                subtitle: Text(formatDateRange(t.startDate, t.endDate)),
                onTap: () => Navigator.of(context).pop(t.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _dependsOn = picked);
  }

  TaskModel _currentModel() {
    final now = DateTime.now();
    final e = widget.existing;
    final end = _kind == TaskKind.single
        ? _start
        : (_linked ? addDays(_start, _duration - 1) : _end);
    final duration =
        _kind == TaskKind.single ? 1 : daysBetween(_start, end) + 1;
    return TaskModel(
      id: _savedId,
      syncUid: _syncUid,
      title: _title.text.trim(),
      kind: _kind,
      startDate: _start,
      endDate: end,
      durationDays: duration,
      dependsOnTaskId: _kind == TaskKind.period ? _dependsOn : null,
      dependsBefore: _kind == TaskKind.period && _dependsBefore,
      timeOfDayMinutes: _kind == TaskKind.single ? _timeMinutes : null,
      reminderEnabled: _deferred ? false : _reminderEnabled,
      reminderRule: _reminderRule,
      // У однодневного дела со временем напоминание приходит в это же время.
      reminderMinutes: (_kind == TaskKind.single && _timeMinutes != null)
          ? _timeMinutes!
          : _reminderMinutes,
      reminderDaysBefore: _reminderDaysBefore,
      colorId: _colorId,
      iconId: _iconId,
      deferred: _deferred,
      isTrip: _kind == TaskKind.period && _isTrip,
      recurrenceType: (_kind == TaskKind.single && !_deferred)
          ? _recurrence
          : RecurrenceType.none,
      recurrenceInterval: _recurInterval < 1 ? 1 : _recurInterval,
      recurrenceAnchor: _recurrence == RecurrenceType.monthBeforeEnd
          ? _recurAnchor
          : 0,
      note: _note.text.trim(),
      placeName: _place.text.trim(),
      placeUrl: _placeUrl,
      links: joinLinks(_links),
      isDone: e?.isDone ?? false,
      completedAt: e?.completedAt,
      carriedOver: e?.carriedOver ?? false,
      sortIndex: e?.sortIndex ?? 0,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Собственно сохранение. Все чтения контроллеров — синхронно (до await),
  /// поэтому безопасно вызывать даже при закрытии карточки. Возвращает id.
  Future<int> _doSave() async {
    final repo = ref.read(repositoryProvider);
    final model = _currentModel();
    final subs = [
      for (final s in _subs)
        if (s.controller.text.trim().isNotEmpty)
          SubtaskModel(
            taskId: model.id ?? 0,
            title: s.controller.text.trim(),
            isDone: s.isDone,
          ),
    ];
    final id = await repo.saveTask(model, subtasks: subs);
    // Запоминаем id — следующее авто-сохранение обновит ту же строку.
    _savedId = id;
    return id;
  }

  /// Авто-сохранение при закрытии/свайпе назад: пустое (без заголовка) —
  /// не создаём. Fire-and-forget: сохранение доживает даже после закрытия.
  void _autosave() {
    if (_skipAutosave || _title.text.trim().isEmpty) return;
    _doSave();
  }

  /// Кнопка «Готово»: сохранить и закрыть (новую поездку — открыть дневником).
  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      _leave(); // пустое — просто закрыть, ничего не создаём
      return;
    }
    _skipAutosave = true; // сохраняем здесь, чтобы не сохранять повторно при pop
    final id = await _doSave();
    if (!mounted) return;
    // Новую поездку открываем дневником только в полноэкранном режиме; в
    // десктопной панели просто закрываем — дневник откроется по клику.
    if (_kind == TaskKind.period &&
        _isTrip &&
        !_deferred &&
        widget.existing == null &&
        widget.onClose == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => TripScreen(taskId: id)));
    } else {
      _leave();
    }
  }

  Future<void> _delete() async {
    _skipAutosave = true; // не воскрешать удалённое дело авто-сохранением
    final undo =
        await ref.read(repositoryProvider).deleteTask(widget.existing!.id!);
    if (!mounted) return;
    // Messenger общий на всё приложение — плашка переживёт закрытие карточки.
    showUndoSnack(context, _l.taskDeleted, undo);
    _leave();
  }
}
