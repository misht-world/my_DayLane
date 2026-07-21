import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/trip_stays.dart';
import '../../services/links.dart';
import '../../services/maps.dart';
import '../common/links_editor.dart';
import '../task_editor/task_editor_screen.dart';

/// Дневник путешествия: шапка с датами, этапы-подкарточки по дням
/// (место + заметки по итогу) и общие заметки поездки.
class TripScreen extends ConsumerWidget {
  const TripScreen({super.key, required this.taskId});
  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final tasks = ref.watch(tasksProvider).value ?? const [];
    final trip = tasks.where((t) => t.id == taskId).firstOrNull;
    if (trip == null) {
      // Поездку удалили, пока экран был открыт.
      return const Scaffold(body: SizedBox.shrink());
    }
    final stages = ref.watch(stagesForTripProvider(taskId)).value ?? const [];
    final color = context.taskColor(trip);

    return Scaffold(
      appBar: AppBar(
        title: Text('Путешествие', style: context.serif.copyWith(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Показать в календаре',
            icon: const Icon(Icons.event_rounded),
            onPressed: () {
              ref.read(focusedDateProvider.notifier).set(trip.startDate);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          IconButton(
            tooltip: 'Изменить дело',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => openTaskEditor(context, trip),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _header(context, trip, color),
          _staysBanner(context, trip, stages),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Этапы',
                  style: context.serif.copyWith(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      color: dl.ink)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _editStage(context, ref, trip, null),
                style: TextButton.styleFrom(foregroundColor: dl.accent),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Добавить этап'),
              ),
            ],
          ),
          if (stages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Разбейте поездку на этапы: «Жильё» — где ночуем (считается '
                'по ночам, заезд→выезд), «Место» — куда идём. После — заметки '
                'по итогу.',
                style: TextStyle(color: dl.inkFaint, fontSize: 13),
              ),
            )
          else
            for (final s in stages)
              _StageCard(
                trip: trip,
                stage: s,
                color: color,
                onTap: () => _editStage(context, ref, trip, s),
              ),
          const SizedBox(height: 18),
          Text('Ссылки и файлы',
              style: context.serif.copyWith(
                  fontSize: 17, fontStyle: FontStyle.italic, color: dl.ink)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: dl.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: dl.line),
            ),
            child: LinksEditor(
              label: 'Билеты, брони, документы',
              links: parseLinks(trip.links),
              onChanged: (v) => ref
                  .read(repositoryProvider)
                  .saveTask(trip.copyWith(links: joinLinks(v))),
            ),
          ),
          if (trip.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Заметки поездки',
                style: context.serif.copyWith(
                    fontSize: 17, fontStyle: FontStyle.italic, color: dl.ink)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dl.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dl.line),
              ),
              child: Text(trip.note,
                  style: TextStyle(fontSize: 14, color: dl.ink, height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }

  /// Проверка «есть ли где ночевать каждую ночь»: зелёная плашка, если все
  /// ночи закрыты, иначе — перечисление незакрытых.
  Widget _staysBanner(
      BuildContext context, TaskModel trip, List<TripStageModel> stages) {
    final dl = context.dl;
    final nights = tripNights(trip);
    if (nights.isEmpty) return const SizedBox.shrink();
    final gaps = uncoveredNights(trip, stages);
    final ok = gaps.isEmpty;
    final text = ok
        ? 'Жильё на все ночи (${nights.length}) выбрано'
        : 'Нет жилья: ${groupConsecutive(gaps).map((g) => g.from == g.to ? formatDayMonth(g.from) : formatDateRange(g.from, g.to)).join(', ')}';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (ok ? dl.accent : dl.danger).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: (ok ? dl.accent : dl.danger).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(ok ? Icons.hotel_rounded : Icons.error_outline_rounded,
                size: 18, color: ok ? dl.accent : dl.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, color: ok ? dl.inkSoft : dl.danger)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, TaskModel trip, Color color) {
    final dl = context.dl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dl.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dl.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.luggage_rounded, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(trip.title,
                    style: context.serif.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: dl.ink)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${formatDateRange(trip.startDate, trip.endDate)}'
            ' · ${trip.durationDays} дн.',
            style: TextStyle(fontSize: 13, color: dl.inkSoft),
          ),
        ],
      ),
    );
  }

  void _editStage(BuildContext context, WidgetRef ref, TaskModel trip,
      TripStageModel? stage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.dl.surface,
      showDragHandle: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StageSheet(trip: trip, existing: stage),
      ),
    );
  }
}

/// Подкарточка этапа: галочка выполнения, даты («день N–M»), место, заметки.
class _StageCard extends ConsumerWidget {
  const _StageCard({
    required this.trip,
    required this.stage,
    required this.color,
    required this.onTap,
  });

  final TaskModel trip;
  final TripStageModel stage;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final done = stage.isDone;
    final String meta;
    if (stage.isStay) {
      // Жильё — заезд→выезд и число ночей.
      meta = 'заезд ${formatDayMonth(stage.startDate)} → выезд '
          '${formatDayMonth(stage.endDate)} · '
          '${_StageSheetState._nightsLabel(stage.nights)}';
    } else {
      final d1 = daysBetween(trip.startDate, stage.startDate) + 1;
      final d2 = daysBetween(trip.startDate, stage.endDate) + 1;
      final dayLabel = d1 == d2 ? 'день $d1' : 'дни $d1–$d2';
      final time =
          stage.timeMinutes == null ? '' : ' · ${formatMinutesOfDay(stage.timeMinutes!)}';
      meta =
          '${formatDateRange(stage.startDate, stage.endDate)} · $dayLabel$time';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: dl.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dl.line),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(3)),
                  ),
                ),
                // Галочка «этап пройден».
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 12),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref
                        .read(repositoryProvider)
                        .toggleStageDone(stage, !done),
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? color : Colors.transparent,
                        border: Border.all(color: color, width: 1.6),
                      ),
                      child: done
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta,
                          style: context.serif.copyWith(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: color),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                                stage.isStay
                                    ? Icons.hotel_rounded
                                    : Icons.place_rounded,
                                size: 15,
                                color: dl.inkSoft),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(stage.title,
                                  style: context.serif.copyWith(
                                      fontSize: 16,
                                      color: done ? dl.inkFaint : dl.ink,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null)),
                            ),
                          ],
                        ),
                        if (stage.hasPlace)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => openInMaps(
                                  url: stage.placeUrl,
                                  query: stage.placeName),
                              child: Row(
                                children: [
                                  Icon(Icons.place_rounded,
                                      size: 15, color: dl.accent),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      stage.placeName.isNotEmpty
                                          ? stage.placeName
                                          : 'место на карте',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: dl.accent,
                                          decoration:
                                              TextDecoration.underline,
                                          decorationColor: dl.accent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (stage.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(stage.note,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: dl.inkSoft,
                                    height: 1.35)),
                          ),
                        if (parseLinks(stage.links).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.attach_file_rounded,
                                    size: 14, color: dl.inkSoft),
                                const SizedBox(width: 4),
                                Text('вложений: ${parseLinks(stage.links).length}',
                                    style: TextStyle(
                                        fontSize: 12, color: dl.inkSoft)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 8),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 20, color: dl.inkFaint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Редактор этапа: название, дни, место (карты + вставка ссылки), заметки.
class StageSheet extends ConsumerStatefulWidget {
  const StageSheet({super.key, required this.trip, this.existing});
  final TaskModel trip;
  final TripStageModel? existing;

  @override
  ConsumerState<StageSheet> createState() => _StageSheetState();
}

class _StageSheetState extends ConsumerState<StageSheet> {
  late final TextEditingController _title;
  late final TextEditingController _place;
  late final TextEditingController _note;
  late DateTime _start;
  late DateTime _end;
  late TripStageKind _kind;
  String _placeUrl = '';
  int? _time;
  List<String> _links = [];
  bool _skipAutosave = false;

  bool get _isStay => _kind == TripStageKind.stay;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _place = TextEditingController(text: e?.placeName ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _kind = e?.kind ?? TripStageKind.place;
    _start = e?.startDate ?? widget.trip.startDate;
    // У жилья endDate — день выезда (минимум одна ночь).
    _end = e?.endDate ?? (_isStay ? addDays(_start, 1) : _start);
    _placeUrl = e?.placeUrl ?? '';
    _time = e?.timeMinutes;
    _links = parseLinks(e?.links ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _autosave();
      },
      child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? 'Новый этап' : 'Этап',
                style: context.serif.copyWith(fontSize: 18, color: dl.ink)),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              autofocus: widget.existing == null,
              style: context.serif.copyWith(fontSize: 17, color: dl.ink),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _isStay
                    ? 'Гостиница, квартира…'
                    : 'Куда идём: кафе, музей…',
                hintStyle:
                    context.serif.copyWith(fontSize: 17, color: dl.inkFaint),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<TripStageKind>(
              segments: const [
                ButtonSegment(
                    value: TripStageKind.stay,
                    icon: Icon(Icons.hotel_rounded, size: 16),
                    label: Text('Жильё')),
                ButtonSegment(
                    value: TripStageKind.place,
                    icon: Icon(Icons.place_rounded, size: 16),
                    label: Text('Место')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                // Жильё — минимум одна ночь; место — обычно один день.
                if (_isStay && !_end.isAfter(_start)) {
                  _end = addDays(_start, 1);
                } else if (!_isStay && _end.isAfter(_start)) {
                  _end = _start;
                }
              }),
            ),
            const SizedBox(height: 12),
            Text(_isStay ? 'Заезд — выезд' : 'Дни',
                style: TextStyle(fontSize: 14, color: dl.inkSoft)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _datePill(_start, (d) {
                    setState(() {
                      _start = d;
                      // У жилья выезд строго позже заезда (минимум ночь).
                      if (_isStay && !_end.isAfter(_start)) {
                        _end = addDays(_start, 1);
                      } else if (!_isStay && _end.isBefore(_start)) {
                        _end = _start;
                      }
                    });
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—',
                      style: TextStyle(color: dl.inkFaint, fontSize: 14)),
                ),
                Expanded(
                  child: _datePill(_end, (d) {
                    setState(() {
                      if (_isStay) {
                        _end = d.isAfter(_start) ? d : addDays(_start, 1);
                      } else {
                        _end = d.isBefore(_start) ? _start : d;
                      }
                    });
                  }),
                ),
              ],
            ),
            if (_isStay)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_nightsLabel(daysBetween(_start, _end))} · в ночь выезда '
                  'уже не ночуем — поэтому переезд в один день стыкуется',
                  style: TextStyle(fontSize: 11.5, color: dl.inkFaint),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _place,
              decoration: InputDecoration(
                labelText: 'Место (гостиница, музей…)',
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
                  onPressed: () => openInMaps(
                      url: _placeUrl, query: _place.text),
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
                  onPressed: _pasteLink,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_rounded, size: 14, color: dl.accent),
                      const SizedBox(width: 3),
                      Text('ссылка сохранена',
                          style: TextStyle(fontSize: 12, color: dl.accent)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'В картах: выберите место → Поделиться → Копировать ссылку, '
              'затем вернитесь и нажмите «Вставить ссылку».',
              style: TextStyle(fontSize: 11.5, color: dl.inkFaint),
            ),
            if (!_isStay) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Время',
                      style: TextStyle(fontSize: 14, color: dl.inkSoft)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _pickTime,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: dl.lineStrong),
                      foregroundColor: dl.ink,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                        _time == null
                            ? 'не указано'
                            : formatMinutesOfDay(_time!),
                        style: const TextStyle(fontSize: 13)),
                  ),
                  if (_time != null)
                    IconButton(
                      icon: Icon(Icons.clear_rounded,
                          size: 18, color: dl.inkFaint),
                      onPressed: () => setState(() => _time = null),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 4,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Заметки (по итогу: как было, что понравилось)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            LinksEditor(
              label: 'Ссылки и файлы (бронь, билет, документ)',
              links: _links,
              onChanged: (v) => setState(() => _links = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: dl.danger),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Удалить'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: dl.accent,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary),
                  child: const Text('Готово'),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// «1 ночь / 2 ночи / 5 ночей».
  static String _nightsLabel(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return '$n ночь';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$n ночи';
    }
    return '$n ночей';
  }

  Widget _datePill(DateTime value, ValueChanged<DateTime> onPicked) {
    final dl = context.dl;
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: widget.trip.startDate,
          lastDate: widget.trip.endDate,
        );
        if (picked != null) onPicked(dateOnly(picked));
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: dl.lineStrong),
        foregroundColor: dl.ink,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(formatDayMonth(value), style: const TextStyle(fontSize: 13)),
    );
  }

  Future<void> _pickTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: (_time ?? 12 * 60) ~/ 60, minute: (_time ?? 0) % 60),
    );
    if (res != null) setState(() => _time = res.hour * 60 + res.minute);
  }

  Future<void> _pasteLink() async {
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
          content: Text('В буфере нет ссылки на карты. Скопируйте её '
              'в приложении карт: Поделиться → Копировать ссылку.')));
    }
  }

  TripStageModel _model() => TripStageModel(
        id: widget.existing?.id,
        taskId: widget.trip.id!,
        title: _title.text.trim(),
        kind: _kind,
        startDate: _start,
        endDate: _end,
        placeName: _place.text.trim(),
        placeUrl: _placeUrl,
        timeMinutes: _isStay ? null : _time,
        isDone: widget.existing?.isDone ?? false,
        note: _note.text.trim(),
        links: joinLinks(_links),
        sortIndex: widget.existing?.sortIndex ?? 0,
      );

  /// Авто-сохранение при закрытии/свайпе: без названия — не создаём.
  void _autosave() {
    if (_skipAutosave || _title.text.trim().isEmpty) return;
    ref.read(repositoryProvider).saveStage(_model());
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _skipAutosave = true;
    await ref.read(repositoryProvider).saveStage(_model());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    _skipAutosave = true;
    await ref.read(repositoryProvider).deleteStage(widget.existing!.id!);
    if (mounted) Navigator.of(context).pop();
  }
}
