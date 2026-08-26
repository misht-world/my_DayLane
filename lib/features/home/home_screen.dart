import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/desktop_nav.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/marker_label.dart';
import '../../core/note_l10n.dart';
import '../../core/theme.dart';
import '../../core/undo_snack.dart';
import '../../domain/models.dart';
import '../../domain/scheduling.dart';
import '../../l10n/app_localizations.dart';
import '../calendar/calendar_view.dart';
import '../notes/note_editor.dart';
import '../settings/settings_screen.dart';
import '../task_editor/task_editor_screen.dart';
import '../tasks/tasks_list_screen.dart';
import '../trips/trips_list_screen.dart';
import 'task_row.dart';

enum _Horizon { yesterday, today, tomorrow }

/// Главный экран в стиле «Ежедневник»: дата-герой с навигацией по дням и
/// три выделенные сворачиваемые секции вчера/сегодня/завтра.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTomorrow = false;
  bool _showToday = true;
  bool _showDeferred = false;

  /// Ширина окна, с которой включается двух-панельная (десктопная) раскладка.
  static const double _wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final focused = ref.watch(focusedDateProvider);
    final sections = ref.watch(sectionsProvider);

    return Scaffold(
      body: SafeArea(
        child: sections == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(builder: (context, c) {
                final planner = _plannerChildren(context, focused, sections);
                if (c.maxWidth < _wideBreakpoint) {
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [...planner, _calendarSection(context)],
                  );
                }
                return _wideLayout(context, planner);
              }),
      ),
    );
  }

  /// Левая колонка планировщика (без календаря): шапка, дата-герой, секции
  /// сегодня/завтра и «Заметки». Одинакова для телефона и десктопа.
  List<Widget> _plannerChildren(
    BuildContext context,
    DateTime focused,
    DaySections sections,
  ) {
    final l = AppLocalizations.of(context);
    return [
      _topBar(context),
      _hero(context, focused),
      _section(
        kind: _Horizon.today,
        label: l.sectionToday,
        day: focused,
        tasks: sections.today,
        expanded: _showToday,
        onToggle: () => setState(() => _showToday = !_showToday),
        danger: false,
        emptyText: l.todayEmpty,
      ),
      _section(
        kind: _Horizon.tomorrow,
        label: l.sectionTomorrow,
        day: addDays(focused, 1),
        tasks: sections.tomorrow,
        expanded: _showTomorrow,
        onToggle: () => setState(() => _showTomorrow = !_showTomorrow),
        danger: false,
        emptyText: l.tomorrowEmpty,
      ),
      _notesSection(context),
    ];
  }

  /// Десктопная раскладка (master-detail): слева — колонка задач/заметок
  /// (планировщик) с небольшим календарём внизу; справа — большая панель, где
  /// открывается выбранное дело/заметка для комфортной работы с текстом.
  Widget _wideLayout(BuildContext context, List<Widget> planner) {
    final dl = context.dl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [...planner, _calendarSection(context)],
          ),
        ),
        Container(width: 1, color: dl.line),
        Expanded(child: _detailPane(context)),
      ],
    );
  }

  /// Правая панель десктопа: редактор выбранного дела/заметки или пустое
  /// состояние. Смена выбора пересоздаёт редактор (по ключу) — прежний при
  /// этом авто-сохраняется.
  Widget _detailPane(BuildContext context) {
    final req = ref.watch(detailReqProvider);
    void close() => ref.read(detailReqProvider.notifier).close();

    return switch (req) {
      null => _detailEmpty(context),
      EditExisting(:final task) => task.isNote
          ? NoteEditorScreen(
              key: ValueKey('note-${task.id}'),
              existing: task,
              category: task.noteCategory,
              onClose: close)
          : TaskEditorScreen(
              key: ValueKey('task-${task.id}'),
              existing: task,
              onClose: close),
      ComposeTask(:final initialDate, :final deferred, :final trip) =>
        TaskEditorScreen(
            key: const ValueKey('compose-task'),
            initialDate: initialDate,
            deferred: deferred,
            trip: trip,
            onClose: close),
      ComposeNote(:final category) => NoteEditorScreen(
          key: ValueKey('compose-note-$category'),
          category: category,
          onClose: close),
    };
  }

  Widget _detailEmpty(BuildContext context) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note_rounded, size: 52, color: dl.inkFaint),
          const SizedBox(height: 12),
          Text(l.detailEmptyTitle,
              style: TextStyle(fontSize: 15, color: dl.inkSoft)),
          const SizedBox(height: 4),
          Text(l.detailEmptySub,
              style: TextStyle(fontSize: 12, color: dl.inkFaint)),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
      child: Row(
        children: [
          Text(
            'DAYLANE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2.5,
              color: dl.inkFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: l.tooltipAllTasks,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.checklist_rounded, color: dl.inkFaint),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TasksListScreen()),
            ),
          ),
          IconButton(
            tooltip: l.tooltipPayments,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.payments_outlined, color: dl.inkFaint),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TasksListScreen(
                  title: l.tooltipPayments,
                  emptyText: l.paymentsEmpty,
                  // Шаблон «Оплата» — индекс 1 в kTaskTemplates.
                  filter: (t) => t.iconId == 1,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l.tooltipTrips,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.luggage_rounded, color: dl.inkFaint),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TripsListScreen()),
            ),
          ),
          IconButton(
            tooltip: l.tooltipSettings,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.settings_rounded, color: dl.inkFaint),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          GestureDetector(
            onTap: () => openTaskEditor(context, null),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: dl.accent),
              child: Icon(Icons.add_rounded,
                  size: 22, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, DateTime focused) {
    final dl = context.dl;
    final realToday = ref.watch(todayProvider);
    final isToday = isSameDate(focused, realToday);
    final loc = Localizations.localeOf(context).languageCode;
    // Родительный падеж («июня»): берём из полной даты, отбросив число.
    // Для EN это просто вычленяет название месяца («July»).
    final month = DateFormat('d MMMM', loc)
        .format(focused)
        .replaceFirst('${focused.day} ', '');
    final weekday = DateFormat('EEEE', loc).format(focused).toUpperCase();

    void shift(int days) =>
        ref.read(focusedDateProvider.notifier).shift(days);

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 120) shift(-1);
        if (v < -120) shift(1);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dl.ink, width: 2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Тап по дате — выбор любого дня/месяца/года (календарь следует).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pickHeroDate(focused),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${focused.day}',
                    style: context.serif.copyWith(
                      fontSize: 54,
                      height: 0.85,
                      fontWeight: FontWeight.w500,
                      color: dl.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(month,
                            style: context.serif.copyWith(
                                fontSize: 18, color: dl.ink, height: 1)),
                        const SizedBox(height: 2),
                        Text(weekday,
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: dl.inkFaint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!isToday)
              GestureDetector(
                onTap: () =>
                    ref.read(focusedDateProvider.notifier).set(realToday),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restore_rounded, size: 15, color: dl.accent),
                      const SizedBox(width: 3),
                      Text(AppLocalizations.of(context).resetToday,
                          style: TextStyle(fontSize: 12, color: dl.accent)),
                    ],
                  ),
                ),
              ),
            _navBtn(context, Icons.chevron_left_rounded, () => shift(-1)),
            _navBtn(context, Icons.chevron_right_rounded, () => shift(1)),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final dl = context.dl;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Icon(icon, size: 26, color: dl.inkSoft),
      ),
    );
  }

  /// Выбор произвольной даты по тапу на крупную дату в шапке.
  Future<void> _pickHeroDate(DateTime focused) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: focused,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(focusedDateProvider.notifier).set(picked);
    }
  }

  /// Сворачиваемая секция горизонта с выделенной лентой-заголовком.
  Widget _section({
    required _Horizon kind,
    required String label,
    required DateTime day,
    required List<TaskModel> tasks,
    required bool expanded,
    required VoidCallback onToggle,
    required bool danger,
    required String emptyText,
  }) {
    final dl = context.dl;
    final isYesterday = kind == _Horizon.yesterday;
    final canCarry =
        isYesterday && tasks.any((t) => t.isSingle && !t.isDone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bandHeader(
            label: label,
            count: tasks.length,
            danger: danger,
            expanded: expanded,
            onToggle: onToggle,
            addAction: isYesterday
                ? null
                : _headerAction(
                    icon: Icons.add_rounded,
                    filled: true,
                    tooltip: AppLocalizations.of(context).tooltipAddTask,
                    onTap: () =>
                        openTaskEditor(context, null, initialDate: day),
                  ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              child: tasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(emptyText,
                          style: TextStyle(color: dl.inkFaint, fontSize: 14)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (canCarry)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final undo = await ref
                                      .read(repositoryProvider)
                                      .carryAll(tasks);
                                  if (!mounted) return;
                                  showUndoSnack(context,
                                      AppLocalizations.of(context)
                                          .carriedToToday,
                                      undo);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: dl.accent,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                icon: const Icon(
                                    Icons.subdirectory_arrow_left_rounded,
                                    size: 16),
                                label: Text(
                                    AppLocalizations.of(context)
                                        .carryAllToToday,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                          ),
                        for (var i = 0; i < tasks.length; i++) ...[
                          if (i > 0) _taskDivider(),
                          TaskRow(
                            task: tasks[i],
                            day: day,
                            showCarryToToday: isYesterday,
                          ),
                        ],
                        // Линия под последним делом списка.
                        _taskDivider(),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  /// Единая лента-заголовок секций (вчера/сегодня/завтра/отложенные)
  /// в стиле «ежедневника»: название подсвечено маркером-текстовыделителем,
  /// раскрытая секция — насыщеннее, свёрнутая — бледнее.
  Widget _bandHeader({
    required String label,
    required int count,
    required bool danger,
    required bool expanded,
    required VoidCallback onToggle,
    Widget? addAction,
  }) {
    final dl = context.dl;
    // Цвет маркера: у «горящего» вчера — розово-коралловый, иначе — жёлтый.
    final marker = danger ? dl.danger : dl.marker;

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 6, 6),
        child: LayoutBuilder(builder: (context, c) {
          // Раскрыто — длинный штрих от начала строки почти до «+» (справа
          // резервируем место под «+» и шеврон). Свёрнуто — мазок по слову.
          const reserve = 92.0;
          final stretch = expanded
              ? (c.maxWidth - reserve).clamp(80.0, c.maxWidth)
              : null;
          return Row(
            children: [
              MarkerLabel(
                text: label,
                markerColor: marker,
                // Раскрытый штрих — того же цвета, что короткий (та же насыщенность).
                alpha: 0.26,
                stretchWidth: stretch,
              ),
              const SizedBox(width: 10),
              Text('$count',
                  style: TextStyle(
                      fontSize: 13,
                      color: danger ? dl.danger : dl.inkFaint,
                      fontWeight: danger ? FontWeight.w600 : FontWeight.w400)),
              if (danger) ...[
                const SizedBox(width: 3),
                Icon(Icons.keyboard_return_rounded, size: 13, color: dl.danger),
              ],
              const Spacer(),
              ?addAction,
              const SizedBox(width: 4),
              Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 22,
                  color: dl.inkFaint),
            ],
          );
        }),
      ),
    );
  }

  /// Разделитель между делами: чёрная линия с точкой-кружком в начале.
  Widget _taskDivider() {
    final dl = context.dl;
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dl.ink),
        ),
        Expanded(child: Container(height: 1, color: dl.ink)),
      ],
    );
  }

  Widget _headerAction({
    required IconData icon,
    required bool filled,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final dl = context.dl;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? dl.accent : Colors.transparent,
              border: filled ? null : Border.all(color: dl.lineStrong),
            ),
            child: Icon(
              icon,
              size: filled ? 18 : 17,
              color: filled
                  ? Theme.of(context).colorScheme.onPrimary
                  : dl.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  /// Секция «Заметки»: раскрывающиеся списки категорий (только с активными
  /// записями) плюс «Дела без даты». Категория раскрывается прямо здесь —
  /// записи с чек-боксами; пустые/выполненные категории скрыты, добавление
  /// и «возврат» категории — через «+».
  Widget _notesSection(BuildContext context) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    final counts = ref.watch(noteActiveCountsProvider);
    final undated = ref.watch(deferredTasksProvider);
    final undatedOpen = ref.watch(deferredOpenCountProvider);

    final activeCats = [
      for (var c = 0; c < kNoteCategories.length; c++)
        if ((counts[c] ?? 0) > 0) c
    ];
    final total = counts.values.fold<int>(0, (a, b) => a + b) + undatedOpen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bandHeader(
            label: l.sectionNotes,
            count: total,
            danger: false,
            expanded: _showDeferred,
            onToggle: () => setState(() => _showDeferred = !_showDeferred),
            addAction: _headerAction(
              icon: Icons.add_rounded,
              filled: true,
              tooltip: l.tooltipAddNote,
              onTap: () => _pickNoteCategory(context),
            ),
          ),
          if (_showDeferred)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
              child: (activeCats.isEmpty && undated.isEmpty)
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l.notesEmpty,
                          style: TextStyle(color: dl.inkFaint, fontSize: 14)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final c in activeCats)
                          _NoteCategoryTile(category: c),
                        if (undated.isNotEmpty) const _UndatedGroup(),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  /// Выбор, куда добавить: категория заметки или «дело без даты».
  void _pickNoteCategory(BuildContext context) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: dl.surface,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l.notesWhereToAdd,
                  style: context.serif.copyWith(fontSize: 17, color: dl.ink)),
            ),
            for (var c = 0; c < kNoteCategories.length; c++)
              ListTile(
                leading: Icon(kNoteCategories[c].icon,
                    color: TaskPalette.byId(kNoteCategories[c].colorId)),
                title: Text(noteCatName(l, c)),
                onTap: () {
                  Navigator.of(context).pop();
                  openNoteEditor(context, category: c);
                },
              ),
            Divider(height: 1, color: dl.line),
            ListTile(
              leading: Icon(Icons.schedule_rounded, color: dl.inkSoft),
              title: Text(l.notesUndated),
              onTap: () {
                Navigator.of(context).pop();
                openTaskEditor(context, null, deferred: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarSection(BuildContext context) {
    final dl = context.dl;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dl.line)),
      ),
      child: const CalendarView(),
    );
  }
}

/// Строка отложенного дела с быстрым назначением даты и раскрытием подпунктов.
class _DeferredRow extends ConsumerStatefulWidget {
  const _DeferredRow({required this.task});
  final TaskModel task;

  @override
  ConsumerState<_DeferredRow> createState() => _DeferredRowState();
}

class _DeferredRowState extends ConsumerState<_DeferredRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final dl = context.dl;
    final color = context.taskColor(task);
    final repo = ref.read(repositoryProvider);
    final today = ref.watch(todayProvider);
    final progress = ref.watch(subtaskProgressProvider)[task.id] ?? (0, 0);
    final hasSubs = progress.$2 > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => repo.toggleDone(task),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isDone ? color : Colors.transparent,
                    border: Border.all(color: color, width: 1.7),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : (() {
                          final ic = task.isTrip
                              ? Icons.luggage_rounded
                              : taskTemplateIcon(task.iconId);
                          return ic != null
                              ? Icon(ic, size: 15, color: color)
                              : null;
                        }()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => openTaskEditor(context, task),
                  // Долгий тап — удалить вручную (с отменой).
                  onLongPress: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final deleted = AppLocalizations.of(context).taskDeleted;
                    final undo = await repo.deleteTask(task.id!);
                    showUndoSnackOn(messenger, deleted, undo);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Text(task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.serif.copyWith(
                        fontSize: 16,
                        color: task.isDone ? dl.inkFaint : dl.ink,
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                      )),
                ),
              ),
              if (hasSubs)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${progress.$1}/${progress.$2}',
                            style:
                                TextStyle(fontSize: 12, color: dl.inkSoft)),
                        Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 20,
                            color: dl.inkFaint),
                      ],
                    ),
                  ),
                ),
              // У выполненного отложенного даты назначать незачем.
              if (!task.isDone) ...[
                _quick(context, AppLocalizations.of(context).quickToday,
                    () => _schedule(task, today)),
                _quick(context, AppLocalizations.of(context).quickTomorrow,
                    () => _schedule(task, addDays(today, 1))),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.event_rounded, size: 18, color: dl.inkSoft),
                  tooltip: AppLocalizations.of(context).onDate,
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: today,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) _schedule(task, picked);
                  },
                ),
              ],
            ],
          ),
        ),
        if (_expanded && hasSubs) SubtaskChecklist(taskId: task.id!),
      ],
    );
  }

  /// Назначает дату отложенному делу с возможностью отмены.
  Future<void> _schedule(TaskModel task, DateTime date) async {
    // Строка уйдёт из «Отложенных» — messenger берём заранее.
    final messenger = ScaffoldMessenger.of(context);
    final label = AppLocalizations.of(context).scheduledFor(formatDayMonth(date));
    final undo =
        await ref.read(repositoryProvider).scheduleDeferred(task, date);
    showUndoSnackOn(messenger, label, undo);
  }

  Widget _quick(BuildContext context, String label, VoidCallback onTap) {
    final dl = context.dl;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: dl.accent),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 11, color: dl.accent)),
        ),
      ),
    );
  }
}

/// Раскрывающаяся категория заметок на главном: заголовок с иконкой и
/// счётчиком; при раскрытии — записи с чек-боксами. Медиа-категории
/// (книги/фильмы/музыка) авто-группируются по аудитории, покупки — по разделу.
/// Выполненные уходят в свёрнутый архив внизу.
class _NoteCategoryTile extends ConsumerStatefulWidget {
  const _NoteCategoryTile({required this.category});
  final int category;

  @override
  ConsumerState<_NoteCategoryTile> createState() => _NoteCategoryTileState();
}

class _NoteCategoryTileState extends ConsumerState<_NoteCategoryTile> {
  bool _open = false;
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    final cat = kNoteCategories[widget.category];
    final color = TaskPalette.byId(cat.colorId);
    final notes = ref.watch(notesByCategoryProvider(widget.category));
    final active = notes.where((n) => !n.isDone).toList();
    final done = notes.where((n) => n.isDone).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Icon(cat.icon, size: 19, color: color),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(noteCatName(l, widget.category),
                        style: context.serif
                            .copyWith(fontSize: 16, color: dl.ink))),
                Text('${active.length}',
                    style: TextStyle(fontSize: 12, color: dl.inkSoft)),
                const SizedBox(width: 4),
                Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: dl.inkFaint),
              ],
            ),
          ),
        ),
        if (_open) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _items(context, active),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    openNoteEditor(context, category: widget.category),
                style: TextButton.styleFrom(
                    foregroundColor: dl.accent, padding: EdgeInsets.zero),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(noteAddLabel(l, widget.category),
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
          ),
          if (done.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => setState(() => _showDone = !_showDone),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                              '${noteArchiveLabel(l, widget.category)} · ${done.length}',
                              style:
                                  TextStyle(fontSize: 13, color: dl.inkSoft)),
                          const Spacer(),
                          Icon(
                              _showDone
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 18,
                              color: dl.inkFaint),
                        ],
                      ),
                    ),
                  ),
                  if (_showDone)
                    for (final n in done)
                      _NoteItemRow(note: n, category: widget.category),
                ],
              ),
            ),
        ],
      ],
    );
  }

  /// Записи категории: медиа — подсписками по аудитории, покупки — по разделу,
  /// остальные — сплошным списком. Подзаголовок показываем только если групп
  /// больше одной (иначе — лишний шум).
  List<Widget> _items(BuildContext context, List<TaskModel> items) {
    final l = AppLocalizations.of(context);
    final cat = kNoteCategories[widget.category];
    if (cat.hasMedia) {
      const order = [1, 2, 0];
      final labels = {
        1: l.headerAdults,
        2: l.headerKids,
        0: l.headerNoTag,
      };
      final groups = [
        for (final a in order)
          if (items.any((n) => n.audience == a))
            (a, items.where((n) => n.audience == a).toList())
      ];
      return _withHeaders(
          context, [for (final g in groups) (labels[g.$1]!, g.$2)]);
    }
    if (widget.category == 4) {
      final map = <String, List<TaskModel>>{};
      for (final n in items) {
        map.putIfAbsent(n.author.trim(), () => []).add(n);
      }
      final keys = map.keys.toList()
        ..sort((a, b) {
          if (a.isEmpty) return 1;
          if (b.isEmpty) return -1;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });
      return _withHeaders(context,
          [for (final k in keys) (k.isEmpty ? l.noSection : k, map[k]!)]);
    }
    return [
      for (final n in items) _NoteItemRow(note: n, category: widget.category),
    ];
  }

  List<Widget> _withHeaders(
      BuildContext context, List<(String, List<TaskModel>)> groups) {
    final dl = context.dl;
    final showHeaders = groups.length > 1;
    final out = <Widget>[];
    for (final g in groups) {
      if (showHeaders) {
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
          child: Text(g.$1.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  color: dl.inkSoft,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
        ));
      }
      for (final n in g.$2) {
        out.add(_NoteItemRow(note: n, category: widget.category));
      }
    }
    return out;
  }
}

/// Строка записи-заметки: чек-бокс выполнения, название и подпись; при наличии
/// пунктов — раскрывается вложенным чек-листом (для этапов проекта и т. п.).
/// Тап по названию открывает карточку заметки.
class _NoteItemRow extends ConsumerStatefulWidget {
  const _NoteItemRow({required this.note, required this.category});
  final TaskModel note;
  final int category;

  @override
  ConsumerState<_NoteItemRow> createState() => _NoteItemRowState();
}

class _NoteItemRowState extends ConsumerState<_NoteItemRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final n = widget.note;
    final progress = ref.watch(subtaskProgressProvider)[n.id] ?? (0, 0);
    final hasSubs = progress.$2 > 0;
    final sub = _subtitle(n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(repositoryProvider).toggleDone(n),
              child: Padding(
                padding:
                    const EdgeInsets.only(right: 10, top: 4, bottom: 4),
                child: Icon(
                  n.isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: n.isDone ? dl.accent : dl.inkFaint,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => openNoteEditor(context, existing: n),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title.isEmpty
                            ? AppLocalizations.of(context).untitled
                            : n.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: n.isDone ? dl.inkFaint : dl.ink,
                          decoration:
                              n.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (sub != null)
                        Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 12, color: dl.inkFaint)),
                    ],
                  ),
                ),
              ),
            ),
            if (hasSubs) ...[
              Text('${progress.$1}/${progress.$2}',
                  style: TextStyle(fontSize: 12, color: dl.inkSoft)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: dl.inkFaint),
                onPressed: () => setState(() => _open = !_open),
              ),
            ],
          ],
        ),
        if (_open && hasSubs) SubtaskChecklist(taskId: n.id!),
      ],
    );
  }

  /// Подпись: медиа — автор · год; покупки/остальные — первая строка примечания.
  String? _subtitle(TaskModel n) {
    if (kNoteCategories[widget.category].hasMedia) {
      final parts = <String>[
        if (n.author.trim().isNotEmpty) n.author.trim(),
        if (n.year != null) '${n.year}',
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    }
    final note = n.note.trim();
    return note.isEmpty ? null : note.split('\n').first;
  }
}

/// Раскрывающаяся группа «Дела без даты» — записи с быстрым назначением даты.
class _UndatedGroup extends ConsumerStatefulWidget {
  const _UndatedGroup();

  @override
  ConsumerState<_UndatedGroup> createState() => _UndatedGroupState();
}

class _UndatedGroupState extends ConsumerState<_UndatedGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    final tasks = ref.watch(deferredTasksProvider);
    final open = ref.watch(deferredOpenCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 19, color: dl.inkSoft),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(l.notesUndated,
                        style: context.serif
                            .copyWith(fontSize: 16, color: dl.ink))),
                Text('$open',
                    style: TextStyle(fontSize: 12, color: dl.inkSoft)),
                const SizedBox(width: 4),
                Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: dl.inkFaint),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final t in tasks) _DeferredRow(task: t),
              ],
            ),
          ),
      ],
    );
  }
}
