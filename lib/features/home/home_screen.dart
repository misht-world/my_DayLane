import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/marker_label.dart';
import '../../core/theme.dart';
import '../../core/undo_snack.dart';
import '../../domain/models.dart';
import '../calendar/calendar_view.dart';
import '../notes/note_editor.dart';
import '../notes/notes_list.dart';
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
  bool _showYesterday = false;
  bool _showTomorrow = false;
  bool _showToday = true;
  bool _showDeferred = false;

  @override
  Widget build(BuildContext context) {
    final focused = ref.watch(focusedDateProvider);
    final sections = ref.watch(sectionsProvider);

    return Scaffold(
      body: SafeArea(
        child: sections == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  _topBar(context),
                  _hero(context, focused),
                  _section(
                    kind: _Horizon.yesterday,
                    label: 'Вчера',
                    day: addDays(focused, -1),
                    tasks: sections.yesterday,
                    expanded: _showYesterday,
                    onToggle: () =>
                        setState(() => _showYesterday = !_showYesterday),
                    danger: sections.yesterdayCount > 0,
                    emptyText: 'всё разобрано',
                  ),
                  _section(
                    kind: _Horizon.today,
                    label: 'Сегодня',
                    day: focused,
                    tasks: sections.today,
                    expanded: _showToday,
                    onToggle: () => setState(() => _showToday = !_showToday),
                    danger: false,
                    emptyText: 'на сегодня дел нет',
                  ),
                  _section(
                    kind: _Horizon.tomorrow,
                    label: 'Завтра',
                    day: addDays(focused, 1),
                    tasks: sections.tomorrow,
                    expanded: _showTomorrow,
                    onToggle: () =>
                        setState(() => _showTomorrow = !_showTomorrow),
                    danger: false,
                    emptyText: 'на завтра пусто',
                  ),
                  _notesSection(context),
                  _calendarSection(context),
                ],
              ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final dl = context.dl;
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
            tooltip: 'Все дела',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.checklist_rounded, color: dl.inkFaint),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TasksListScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Оплаты',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.payments_outlined, color: dl.inkFaint),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TasksListScreen(
                  title: 'Оплаты',
                  emptyText: 'Нет дел с шаблоном «Оплата»',
                  // Шаблон «Оплата» — индекс 1 в kTaskTemplates.
                  filter: (t) => t.iconId == 1,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Путешествия',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.luggage_rounded, color: dl.inkFaint),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TripsListScreen()),
            ),
          ),
          IconButton(
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
    // Родительный падеж («июня»): берём из полной даты, отбросив число.
    final month = DateFormat('d MMMM', 'ru')
        .format(focused)
        .replaceFirst('${focused.day} ', '');
    final weekday = DateFormat('EEEE', 'ru').format(focused).toUpperCase();

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
                      Text('сегодня',
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
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
                    tooltip: 'Добавить дело',
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
                                      'Перенесено на сегодня', undo);
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
                                label: const Text('Перенести всё на сегодня',
                                    style: TextStyle(fontSize: 13)),
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
        padding: const EdgeInsets.fromLTRB(4, 10, 6, 8),
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

  /// Секция «Заметки»: плитки категорий (только с активными записями) плюс
  /// «Дела без даты». Пустые/полностью выполненные категории не показываются;
  /// добавить/восстановить категорию — через «+».
  Widget _notesSection(BuildContext context) {
    final dl = context.dl;
    final counts = ref.watch(noteActiveCountsProvider);
    final undated = ref.watch(deferredTasksProvider);
    final undatedOpen = ref.watch(deferredOpenCountProvider);

    final tiles = <Widget>[];
    for (var c = 0; c < kNoteCategories.length; c++) {
      final n = counts[c] ?? 0;
      if (n == 0) continue;
      final cat = kNoteCategories[c];
      tiles.add(_noteTile(
        icon: cat.icon,
        label: cat.name,
        color: TaskPalette.byId(cat.colorId),
        count: n,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => NotesListScreen(category: c))),
      ));
    }
    if (undated.isNotEmpty) {
      tiles.add(_noteTile(
        icon: Icons.schedule_rounded,
        label: 'Дела без даты',
        color: dl.inkSoft,
        count: undatedOpen,
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const _UndatedTasksScreen())),
      ));
    }
    final total =
        counts.values.fold<int>(0, (a, b) => a + b) + undatedOpen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bandHeader(
            label: 'Заметки',
            count: total,
            danger: false,
            expanded: _showDeferred,
            onToggle: () => setState(() => _showDeferred = !_showDeferred),
            addAction: _headerAction(
              icon: Icons.add_rounded,
              filled: true,
              tooltip: 'Добавить заметку',
              onTap: () => _pickNoteCategory(context),
            ),
          ),
          if (_showDeferred)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              child: tiles.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('пусто — добавьте через «+»',
                          style: TextStyle(color: dl.inkFaint, fontSize: 14)),
                    )
                  : Wrap(spacing: 8, runSpacing: 8, children: tiles),
            ),
        ],
      ),
    );
  }

  /// Плитка категории заметок: иконка, название, бейдж со счётчиком.
  Widget _noteTile({
    required IconData icon,
    required String label,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    final dl = context.dl;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: dl.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dl.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, color: dl.ink)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  /// Выбор, куда добавить: категория заметки или «дело без даты».
  void _pickNoteCategory(BuildContext context) {
    final dl = context.dl;
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
              child: Text('Куда добавить',
                  style: context.serif.copyWith(fontSize: 17, color: dl.ink)),
            ),
            for (var c = 0; c < kNoteCategories.length; c++)
              ListTile(
                leading: Icon(kNoteCategories[c].icon,
                    color: TaskPalette.byId(kNoteCategories[c].colorId)),
                title: Text(kNoteCategories[c].name),
                onTap: () {
                  Navigator.of(context).pop();
                  openNoteEditor(context, category: c);
                },
              ),
            Divider(height: 1, color: dl.line),
            ListTile(
              leading: Icon(Icons.schedule_rounded, color: dl.inkSoft),
              title: const Text('Дело без даты'),
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
                    final undo = await repo.deleteTask(task.id!);
                    showUndoSnackOn(messenger, 'Дело удалено', undo);
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
                _quick(context, 'сегодня', () => _schedule(task, today)),
                _quick(context, 'завтра',
                    () => _schedule(task, addDays(today, 1))),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.event_rounded, size: 18, color: dl.inkSoft),
                  tooltip: 'На дату',
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
    final undo =
        await ref.read(repositoryProvider).scheduleDeferred(task, date);
    showUndoSnackOn(messenger, 'Назначено на ${formatDayMonth(date)}', undo);
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

/// Экран «Дела без даты» (бывшие «Отложенные») — открывается плиткой из
/// раздела «Заметки». Строки с быстрым назначением даты и раскрытием подпунктов.
class _UndatedTasksScreen extends ConsumerWidget {
  const _UndatedTasksScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final tasks = ref.watch(deferredTasksProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Дела без даты',
            style: context.serif.copyWith(fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTaskEditor(context, null, deferred: true),
        backgroundColor: dl.accent,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
      ),
      body: tasks.isEmpty
          ? Center(
              child: Text('пусто — «ждут своего часа»',
                  style: TextStyle(color: dl.inkFaint, fontSize: 15)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 96),
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  if (i > 0)
                    Row(children: [
                      Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: dl.ink)),
                      Expanded(child: Container(height: 1, color: dl.ink)),
                    ]),
                  _DeferredRow(task: tasks[i]),
                ],
              ],
            ),
    );
  }
}
