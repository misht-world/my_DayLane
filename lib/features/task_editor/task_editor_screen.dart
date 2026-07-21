import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../core/undo_snack.dart';
import '../../domain/dependencies.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
import '../../services/links.dart';
import '../../services/maps.dart';
import '../trips/trip_screen.dart';

/// Открывает карточку дела. [existing] == null — создание;
/// [initialDate] задаёт дату нового дела (по умолчанию — сегодня);
/// [trip] — сразу создать путешествие (период с дневником).
void openTaskEditor(BuildContext context, TaskModel? existing,
    {DateTime? initialDate, bool deferred = false, bool trip = false}) {
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
      this.trip = false});
  final TaskModel? existing;
  final DateTime? initialDate;
  final bool deferred;
  final bool trip;

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

  /// Не авто-сохранять при закрытии (после удаления или явного «Готово»).
  bool _skipAutosave = false;

  bool get _editing => widget.existing != null;
  bool get _linked => _dependsOn != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
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
  }

  @override
  void dispose() {
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Дело', style: context.serif.copyWith(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Готово',
                style: TextStyle(
                    color: dl.accent, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _titleField(),
          const SizedBox(height: 14),
          _kindSegment(),
          const SizedBox(height: 14),
          // Карточка «Когда»: отложить, дата/период, повторение, напоминание.
          _card(children: [
            _switchTile(
              Icons.bookmark_border_rounded,
              'Отложить (без даты)',
              'дело попадёт в раздел «Отложенные»',
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
          _card(children: [_linksBlock()]),
          const SizedBox(height: 14),
          _card(children: [_subtaskBlock()]),
          const SizedBox(height: 14),
          _card(children: [
            _label('Примечание'),
            const SizedBox(height: 2),
            TextField(
              controller: _note,
              maxLines: null,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Заметка к делу',
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
                label: const Text('Удалить дело'),
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
          hintText: 'Что нужно сделать?',
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
      segments: const [
        ButtonSegment(value: 0, label: Text('Один день')),
        ButtonSegment(value: 1, label: Text('Период')),
        ButtonSegment(value: 2, label: Text('Путешествие')),
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
        'Дата',
        _pillButton(formatDayMonth(_start), () async {
          final picked = await _pickDate(_start);
          if (picked != null) setState(() => _start = _end = picked);
        }),
      ),
      Divider(height: 1, color: dl.line),
      _iconRow(
        Icons.schedule_rounded,
        'Время',
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pillButton(
              _timeMinutes == null ? 'не указано' : formatMinutesOfDay(_timeMinutes!),
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
      _start = addDays(parent.endDate, 1);
      _end = addDays(_start, _duration - 1);
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
                    child: Text('Даты',
                        style: TextStyle(fontSize: 15, color: dl.ink))),
                Flexible(
                  child: Text(
                    '${formatDateRange(_start, _end)} · $_duration дн.',
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
        _row('Начало',
            Text('после «${parent?.title ?? '—'}»  ·  ${formatDayMonth(_start)}',
                style: TextStyle(color: dl.inkSoft, fontSize: 14))),
        const SizedBox(height: 10),
        _row(
          'Длительность',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepBtn(Icons.remove_rounded, () {
                if (_duration > 1) setState(() => _duration--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_duration дн.',
                    style: const TextStyle(fontSize: 15)),
              ),
              _stepBtn(Icons.add_rounded, () => setState(() => _duration++)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _row('Конец',
            Text(formatDayMonth(_end),
                style: TextStyle(color: dl.inkSoft, fontSize: 14))),
      ],
      Divider(height: 1, color: dl.line),
      _switchTile(
        Icons.link_rounded,
        'Начать после дела',
        'даты сдвигаются за родителем автоматически',
        _linked,
        (v) {
          if (v) {
            _pickParent();
          } else {
            setState(() => _dependsOn = null);
          }
        },
      ),
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
    const labels = {
      RecurrenceType.none: 'Без повторения',
      RecurrenceType.days: 'Каждый день / N дней',
      RecurrenceType.weeks: 'Каждую неделю / N недель',
      RecurrenceType.months: 'Каждый месяц (по числу)',
      RecurrenceType.years: 'Каждый год (по дате)',
      RecurrenceType.monthLastDay: 'Последний день месяца',
      RecurrenceType.monthBeforeEnd: 'За K дней до конца месяца',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.repeat_rounded, size: 20, color: dl.inkSoft),
            const SizedBox(width: 14),
            Text('Повторение',
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
            'Интервал',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepBtn(Icons.remove_rounded, () {
                  if (_recurInterval > 1) setState(() => _recurInterval--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('каждые $_recurInterval ${_recurUnit()}',
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
              'Дней до конца',
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
        RecurrenceType.days => 'дн.',
        RecurrenceType.weeks => 'нед.',
        RecurrenceType.years => 'г.',
        _ => 'мес.',
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
        _label('Шаблон'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            cell(
              selected: _iconId < 0,
              label: 'Другое',
              onTap: () => setState(() => _iconId = -1),
              child: Icon(Icons.circle_outlined,
                  size: 20, color: _iconId < 0 ? dl.ink : dl.inkFaint),
            ),
            for (var i = 0; i < kTaskTemplates.length; i++)
              cell(
                selected: _iconId == i,
                label: kTaskTemplates[i].name,
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
        _label('Место'),
        const SizedBox(height: 2),
        TextField(
          controller: _place,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Адрес или название',
            border: InputBorder.none,
            isDense: true,
            suffixIcon: _placeUrl.isNotEmpty
                ? IconButton(
                    tooltip: 'Убрать ссылку на карты',
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
              label: const Text('Открыть карты',
                  style: TextStyle(fontSize: 13)),
            ),
            OutlinedButton.icon(
              onPressed: _pastePlaceLink,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dl.lineStrong),
                foregroundColor: dl.ink,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.content_paste_rounded, size: 16),
              label: const Text('Вставить ссылку',
                  style: TextStyle(fontSize: 13)),
            ),
            if (_placeUrl.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.link_rounded, size: 14, color: dl.accent),
                const SizedBox(width: 3),
                Text('ссылка сохранена',
                    style: TextStyle(fontSize: 12, color: dl.accent)),
              ]),
          ],
        ),
      ],
    );
  }

  /// Ссылки и файлы дела: список записей + добавить ссылку / файл.
  Widget _linksBlock() {
    final dl = context.dl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Ссылки и файлы'),
        const SizedBox(height: 4),
        for (var i = 0; i < _links.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(isWebLink(_links[i]) ? Icons.link_rounded : Icons.insert_drive_file_outlined,
                    size: 18, color: dl.inkSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => openLink(_links[i]),
                    child: Text(linkLabel(_links[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: dl.accent,
                            decoration: TextDecoration.underline,
                            decorationColor: dl.accent)),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: dl.inkFaint),
                  onPressed: () => setState(() => _links.removeAt(i)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _addLink,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dl.lineStrong),
                foregroundColor: dl.ink,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add_link_rounded, size: 16),
              label: const Text('Добавить ссылку',
                  style: TextStyle(fontSize: 13)),
            ),
            OutlinedButton.icon(
              onPressed: _addFile,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dl.lineStrong),
                foregroundColor: dl.ink,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('Файл с телефона',
                  style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addLink() async {
    final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (!mounted) return;
    final ctrl = TextEditingController(
        text: (clip != null && isWebLink(clip)) ? clip : '');
    final url = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ссылка'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
              hintText: 'https://… (Я.Диск, Google Drive, любая)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Добавить')),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      setState(() => _links.add(url));
    }
  }

  Future<void> _addFile() async {
    final res = await FilePicker.platform.pickFiles();
    final path = res?.files.single.path;
    if (path == null) return;
    // Копируем в постоянную папку приложения, чтобы ссылка не протухла.
    try {
      final stored = await importFileToAppStorage(path);
      if (mounted) setState(() => _links.add(stored));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось прикрепить файл: $e')));
      }
    }
  }

  Future<void> _pastePlaceLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (looksLikeMapsLink(text)) {
      setState(() {
        _placeUrl = text;
        // Если название пустое — пробуем достать из полной ссылки.
        if (_place.text.trim().isEmpty) {
          final name = placeNameFromUrl(text);
          if (name != null) _place.text = name;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('В буфере нет ссылки на карты. Скопируйте её в '
              'приложении карт: Поделиться → Копировать ссылку.')));
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
        _label('Цвет в календаре'),
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
          'Напоминание',
          null,
          _reminderEnabled,
          (v) => setState(() => _reminderEnabled = v),
        ),
        if (_reminderEnabled) ...[
          if (_kind == TaskKind.period)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SegmentedButton<ReminderRule>(
                segments: const [
                  ButtonSegment(value: ReminderRule.atStart, label: Text('В начале')),
                  ButtonSegment(value: ReminderRule.eachDay, label: Text('Каждый день')),
                  ButtonSegment(value: ReminderRule.atEnd, label: Text('В конце')),
                ],
                selected: {_reminderRule},
                onSelectionChanged: (s) =>
                    setState(() => _reminderRule = s.first),
              ),
            ),
          if (_kind == TaskKind.single && _timeMinutes != null)
            // Дело со временем — напоминание приходит в это же время.
            _row(
              'Время напоминания',
              Text('в ${formatMinutesOfDay(_timeMinutes!)} · по времени дела',
                  style: TextStyle(fontSize: 14, color: context.dl.inkSoft)),
            )
          else
            _row(
              'Время напоминания',
              _pillButton(formatMinutesOfDay(_reminderMinutes), () async {
                final picked = await _pickTimeOfDay(_reminderMinutes);
                if (picked != null) setState(() => _reminderMinutes = picked);
              }),
            ),
          const SizedBox(height: 10),
          _label('Когда напомнить'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final opt in const [
                (0, 'В день'),
                (1, 'За день'),
                (2, 'За 2 дня'),
                (3, 'За 3 дня'),
                (7, 'За неделю'),
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
        _label('Подпункты'),
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
                  decoration: const InputDecoration(
                    hintText: 'Пункт',
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
          label: const Text('Добавить пункт'),
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
      helpText: 'Выберите период',
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
        const SnackBar(content: Text('Нет подходящих дел для привязки')),
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
              child: Text('Начать после дела',
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
      id: e?.id,
      title: _title.text.trim(),
      kind: _kind,
      startDate: _start,
      endDate: end,
      durationDays: duration,
      dependsOnTaskId: _kind == TaskKind.period ? _dependsOn : null,
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
  Future<int> _doSave() {
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
    return repo.saveTask(model, subtasks: subs);
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
      Navigator.of(context).pop(); // пустое — просто закрыть, ничего не создаём
      return;
    }
    _skipAutosave = true; // сохраняем здесь, чтобы не сохранять повторно при pop
    final id = await _doSave();
    if (!mounted) return;
    if (_kind == TaskKind.period &&
        _isTrip &&
        !_deferred &&
        widget.existing == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => TripScreen(taskId: id)));
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    _skipAutosave = true; // не воскрешать удалённое дело авто-сохранением
    final undo =
        await ref.read(repositoryProvider).deleteTask(widget.existing!.id!);
    if (!mounted) return;
    // Messenger общий на всё приложение — плашка переживёт закрытие карточки.
    showUndoSnack(context, 'Дело удалено', undo);
    Navigator.of(context).pop();
  }
}
