import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../domain/dependencies.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';

/// Открывает карточку дела. [existing] == null — создание;
/// [initialDate] задаёт дату нового дела (по умолчанию — сегодня).
void openTaskEditor(BuildContext context, TaskModel? existing,
    {DateTime? initialDate, bool deferred = false}) {
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => TaskEditorScreen(
        existing: existing, initialDate: initialDate, deferred: deferred),
  ));
}

class _SubItem {
  final TextEditingController controller;
  bool isDone;
  _SubItem(String text, this.isDone)
      : controller = TextEditingController(text: text);
}

class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen(
      {super.key, this.existing, this.initialDate, this.deferred = false});
  final TaskModel? existing;
  final DateTime? initialDate;
  final bool deferred;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _note;

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

  RecurrenceType _recurrence = RecurrenceType.none;
  int _recurInterval = 1;
  int _recurAnchor = 2; // K для monthBeforeEnd
  bool _deferred = false;

  final List<_SubItem> _subs = [];

  bool get _editing => widget.existing != null;
  bool get _linked => _dependsOn != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final today = dateOnly(widget.initialDate ?? DateTime.now());
    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _kind = e?.kind ?? TaskKind.single;
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
    for (final s in _subs) {
      s.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Дело', style: context.serif.copyWith(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Сохранить',
                style: TextStyle(
                    color: dl.accent, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          TextField(
            controller: _title,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Что нужно сделать?',
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          _kindSegment(),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Отложить (без даты)'),
            subtitle: Text('дело попадёт в раздел «Отложенные»',
                style: TextStyle(fontSize: 12, color: dl.inkFaint)),
            value: _deferred,
            onChanged: (v) => setState(() => _deferred = v),
          ),
          if (!_deferred) ...[
            const SizedBox(height: 8),
            if (_kind == TaskKind.single)
              ..._singleFields()
            else
              ..._periodFields(),
            if (_kind == TaskKind.single) ...[
              const SizedBox(height: 18),
              _recurrenceBlock(),
            ],
            const SizedBox(height: 18),
            _reminderBlock(),
          ],
          const SizedBox(height: 18),
          _colorBlock(),
          const SizedBox(height: 18),
          _subtaskBlock(),
          const SizedBox(height: 18),
          _label('Примечание'),
          TextField(
            controller: _note,
            maxLines: null,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: 'Заметка к делу',
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: 28),
            Center(
              child: TextButton.icon(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: dl.danger),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Удалить дело'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kindSegment() {
    return SegmentedButton<TaskKind>(
      segments: const [
        ButtonSegment(value: TaskKind.single, label: Text('Один день')),
        ButtonSegment(value: TaskKind.period, label: Text('Период')),
      ],
      selected: {_kind},
      onSelectionChanged: (s) {
        setState(() {
          _kind = s.first;
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
      _row(
        'Дата',
        _pillButton(formatDayMonth(_start), () async {
          final picked = await _pickDate(_start);
          if (picked != null) setState(() => _start = _end = picked);
        }),
      ),
      const SizedBox(height: 10),
      _row(
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
                icon: Icon(Icons.clear, size: 18, color: dl.inkFaint),
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
        _row(
          'Начало',
          _pillButton(formatDayMonth(_start), () async {
            final picked = await _pickDate(_start);
            if (picked != null) {
              setState(() {
                _start = picked;
                if (_end.isBefore(_start)) _end = _start;
                _duration = daysBetween(_start, _end) + 1;
              });
            }
          }),
        ),
        const SizedBox(height: 10),
        _row(
          'Конец',
          _pillButton(formatDayMonth(_end), () async {
            final picked = await _pickDate(_end, first: _start);
            if (picked != null) {
              setState(() {
                _end = picked.isBefore(_start) ? _start : picked;
                _duration = daysBetween(_start, _end) + 1;
              });
            }
          }),
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
              _stepBtn(Icons.remove, () {
                if (_duration > 1) setState(() => _duration--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_duration дн.',
                    style: const TextStyle(fontSize: 15)),
              ),
              _stepBtn(Icons.add, () => setState(() => _duration++)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _row('Конец',
            Text(formatDayMonth(_end),
                style: TextStyle(color: dl.inkSoft, fontSize: 14))),
      ],
      const SizedBox(height: 14),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Начать после дела'),
        subtitle: Text('даты сдвигаются за родителем автоматически',
            style: TextStyle(fontSize: 12, color: dl.inkFaint)),
        value: _linked,
        onChanged: (v) {
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
                icon: Icon(Icons.close, size: 18, color: dl.inkFaint),
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
        Row(
          children: [
            Icon(Icons.repeat, size: 18, color: dl.taskRecurring),
            const SizedBox(width: 8),
            _label('Повторение'),
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
                _stepBtn(Icons.remove, () {
                  if (_recurInterval > 1) setState(() => _recurInterval--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('каждые $_recurInterval ${_recurUnit()}',
                      style: const TextStyle(fontSize: 15)),
                ),
                _stepBtn(Icons.add, () => setState(() => _recurInterval++)),
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
                  _stepBtn(Icons.remove, () {
                    if (_recurAnchor > 0) setState(() => _recurAnchor--);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$_recurAnchor',
                        style: const TextStyle(fontSize: 15)),
                  ),
                  _stepBtn(Icons.add, () => setState(() => _recurAnchor++)),
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
              ? Icon(Icons.brightness_auto,
                  size: 17, color: selected ? dl.ink : dl.inkSoft)
              : (selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Напоминание'),
          value: _reminderEnabled,
          onChanged: (v) => setState(() => _reminderEnabled = v),
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
              Checkbox(
                value: _subs[i].isDone,
                onChanged: (v) => setState(() => _subs[i].isDone = v ?? false),
              ),
              Expanded(
                child: TextField(
                  controller: _subs[i].controller,
                  decoration: const InputDecoration(
                    hintText: 'Пункт',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: dl.inkFaint),
                onPressed: () => setState(() => _subs.removeAt(i)),
              ),
            ],
          ),
        TextButton.icon(
          onPressed: () =>
              setState(() => _subs.add(_SubItem('', false))),
          style: TextButton.styleFrom(
              foregroundColor: dl.accent, padding: EdgeInsets.zero),
          icon: const Icon(Icons.add, size: 18),
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
    if (picked != null) setState(() => _timeMinutes = picked);
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
      reminderMinutes: _reminderMinutes,
      reminderDaysBefore: _reminderDaysBefore,
      colorId: _colorId,
      deferred: _deferred,
      recurrenceType: (_kind == TaskKind.single && !_deferred)
          ? _recurrence
          : RecurrenceType.none,
      recurrenceInterval: _recurInterval < 1 ? 1 : _recurInterval,
      recurrenceAnchor: _recurrence == RecurrenceType.monthBeforeEnd
          ? _recurAnchor
          : 0,
      note: _note.text.trim(),
      isDone: e?.isDone ?? false,
      completedAt: e?.completedAt,
      carriedOver: e?.carriedOver ?? false,
      sortIndex: e?.sortIndex ?? 0,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите заголовок дела')),
      );
      return;
    }
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
    await ref.read(repositoryProvider).saveTask(model, subtasks: subs);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить дело?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Удалить',
                  style: TextStyle(color: context.dl.danger))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).deleteTask(widget.existing!.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
