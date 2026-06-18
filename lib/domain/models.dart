import '../core/date_utils.dart';

/// Однодневное или растянутое во времени дело.
enum TaskKind { single, period }

/// Правило напоминания (действует только при `reminderEnabled`).
enum ReminderRule { atStart, eachDay, atEnd }

/// Тип повторения дела. Якорь (день месяца, день недели, месяц/день года)
/// берётся из `startDate` — это дата первого вхождения.
enum RecurrenceType {
  none,
  days, // каждые N дней
  weeks, // каждые N недель (по дню недели startDate)
  months, // каждые N месяцев (число = startDate.day, с обрезкой)
  years, // каждые N лет (месяц/день из startDate)
  monthLastDay, // последний день месяца, каждые N месяцев
  monthBeforeEnd, // за K дней до конца месяца (K = recurrenceAnchor)
}

/// Сентинел для copyWith — позволяет отличить «не передано» от «передано null».
const Object _unset = Object();

/// Доменная модель дела. Чистая (без Flutter/Drift) — на ней строятся
/// вся бизнес-логика и юнит-тесты. DB-слой маппит строки в эту модель.
class TaskModel {
  /// null для ещё не сохранённого дела.
  final int? id;
  final String title;
  final TaskKind kind;

  /// Дата без времени. Для `single` = дата дела, для `period` = начало.
  final DateTime startDate;

  /// Дата без времени. Для `single` == startDate, для `period` = конец.
  final DateTime endDate;

  /// Длина периода в днях (≥1). Источник истины при привязке. Для single = 1.
  final int durationDays;

  /// Привязка начала к другому делу. null = нет привязки.
  final int? dependsOnTaskId;

  /// Время дня в минутах от полуночи. Разрешено только при kind == single.
  final int? timeOfDayMinutes;

  final bool reminderEnabled;
  final ReminderRule reminderRule;

  /// Время срабатывания напоминания в минутах от полуночи (по умолчанию 09:00).
  final int reminderMinutes;

  /// За сколько дней до даты напоминать (0 = в день, 1 = накануне, …).
  final int reminderDaysBefore;

  final int colorId;

  /// Повторение (для дел-«событий»: ДР, платежи, занятия).
  final RecurrenceType recurrenceType;

  /// Интервал повторения N (каждые N дней/недель/месяцев/лет). ≥1.
  final int recurrenceInterval;

  /// Доп. параметр повторения: K для `monthBeforeEnd`.
  final int recurrenceAnchor;

  final String note;

  final bool isDone;
  final DateTime? completedAt;

  /// Метка «перенесено» (подсветка «↻ перенесено» до конца дня).
  final bool carriedOver;

  final int sortIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    this.id,
    required this.title,
    required this.kind,
    required this.startDate,
    required this.endDate,
    this.durationDays = 1,
    this.dependsOnTaskId,
    this.timeOfDayMinutes,
    this.reminderEnabled = false,
    this.reminderRule = ReminderRule.atStart,
    this.reminderMinutes = 540,
    this.reminderDaysBefore = 0,
    this.colorId = 0,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceInterval = 1,
    this.recurrenceAnchor = 0,
    this.note = '',
    this.isDone = false,
    this.completedAt,
    this.carriedOver = false,
    this.sortIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPeriod => kind == TaskKind.period;
  bool get isSingle => kind == TaskKind.single;
  bool get isLinked => dependsOnTaskId != null;
  bool get isRecurring => recurrenceType != RecurrenceType.none;

  TaskModel copyWith({
    Object? id = _unset,
    String? title,
    TaskKind? kind,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    Object? dependsOnTaskId = _unset,
    Object? timeOfDayMinutes = _unset,
    bool? reminderEnabled,
    ReminderRule? reminderRule,
    int? reminderMinutes,
    int? reminderDaysBefore,
    int? colorId,
    RecurrenceType? recurrenceType,
    int? recurrenceInterval,
    int? recurrenceAnchor,
    String? note,
    bool? isDone,
    Object? completedAt = _unset,
    bool? carriedOver,
    int? sortIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: identical(id, _unset) ? this.id : id as int?,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      dependsOnTaskId: identical(dependsOnTaskId, _unset)
          ? this.dependsOnTaskId
          : dependsOnTaskId as int?,
      timeOfDayMinutes: identical(timeOfDayMinutes, _unset)
          ? this.timeOfDayMinutes
          : timeOfDayMinutes as int?,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderRule: reminderRule ?? this.reminderRule,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      colorId: colorId ?? this.colorId,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceAnchor: recurrenceAnchor ?? this.recurrenceAnchor,
      note: note ?? this.note,
      isDone: isDone ?? this.isDone,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      carriedOver: carriedOver ?? this.carriedOver,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'TaskModel(id: $id, "$title", $kind, ${formatDateRange(startDate, endDate)})';
}

/// Подпункт дела.
class SubtaskModel {
  final int? id;
  final int taskId;
  final String title;
  final bool isDone;
  final int sortIndex;

  const SubtaskModel({
    this.id,
    required this.taskId,
    required this.title,
    this.isDone = false,
    this.sortIndex = 0,
  });

  SubtaskModel copyWith({
    Object? id = _unset,
    int? taskId,
    String? title,
    bool? isDone,
    int? sortIndex,
  }) {
    return SubtaskModel(
      id: identical(id, _unset) ? this.id : id as int?,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }
}
