import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/models.dart';

part 'db.g.dart';
part 'task_dao.dart';
part 'subtask_dao.dart';

/// Дела.
@DataClassName('TaskRow')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get kind => intEnum<TaskKind>()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get durationDays => integer().withDefault(const Constant(1))();
  IntColumn get dependsOnTaskId => integer().nullable()();
  IntColumn get timeOfDayMinutes => integer().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get reminderRule =>
      intEnum<ReminderRule>().withDefault(const Constant(0))();
  IntColumn get reminderMinutes => integer().withDefault(const Constant(540))();

  /// За сколько дней до даты напоминать (0 = в день, 1 = накануне, …).
  IntColumn get reminderDaysBefore =>
      integer().withDefault(const Constant(0))();
  /// -1 = авто (по типу дела), иначе индекс палитры.
  IntColumn get colorId => integer().withDefault(const Constant(-1))();
  BoolColumn get deferred => boolean().withDefault(const Constant(false))();
  BoolColumn get isTrip => boolean().withDefault(const Constant(false))();
  IntColumn get recurrenceType =>
      intEnum<RecurrenceType>().withDefault(const Constant(0))();
  IntColumn get recurrenceInterval =>
      integer().withDefault(const Constant(1))();
  IntColumn get recurrenceAnchor => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get carriedOver =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Подпункты дел.
@DataClassName('SubtaskRow')
class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer()
      .references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
}

/// Этапы путешествий: подкарточки на день/группу дней (место, заметки).
@DataClassName('TripStageRow')
class TripStages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();

  /// 0 = жильё (по ночам), 1 = место/активность. Старые этапы → место.
  IntColumn get kind =>
      intEnum<TripStageKind>().withDefault(const Constant(1))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get placeName => text().withDefault(const Constant(''))();
  TextColumn get placeUrl => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
}

/// Отметки выполнения конкретных вхождений повторяющихся дел (taskId + дата).
@DataClassName('RecurrenceDoneRow')
class RecurrenceDones extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
}

/// Настройки приложения (одна строка, id = 1).
@DataClassName('SettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get autoCarry => boolean().withDefault(const Constant(false))();

  /// 0 = система, 1 = светлая, 2 = тёмная. По умолчанию — светлая.
  IntColumn get themeMode => integer().withDefault(const Constant(1))();

  /// 1 = понедельник … 7 = воскресенье.
  IntColumn get firstWeekday => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Tasks, Subtasks, AppSettings, RecurrenceDones, TripStages],
  daos: [TaskDao, SubtaskDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(appSettings).insert(
            const AppSettingsCompanion(id: Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.reminderDaysBefore);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.recurrenceType);
            await m.addColumn(tasks, tasks.recurrenceInterval);
            await m.addColumn(tasks, tasks.recurrenceAnchor);
            await m.createTable(recurrenceDones);
          }
          if (from < 4) {
            await m.addColumn(tasks, tasks.deferred);
            // Сброс старых цветов: до v4 цвет не выбирался → авто (-1).
            await customStatement('UPDATE tasks SET color_id = -1');
          }
          if (from < 5) {
            await m.addColumn(tasks, tasks.isTrip);
            await m.createTable(tripStages);
          }
          if (from < 6) {
            // Существующие этапы становятся «местами»: они задавались днями,
            // а жильё теперь считается по ночам — молча менять смысл нельзя.
            await m.addColumn(tripStages, tripStages.kind);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Гарантируем строку настроек.
          await into(appSettings).insert(
            const AppSettingsCompanion(id: Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
        },
      );

  // ── Настройки ──────────────────────────────────────────────────
  Stream<SettingsRow> watchSettings() =>
      (select(appSettings)..where((t) => t.id.equals(1))).watchSingle();

  Future<SettingsRow> getSettings() =>
      (select(appSettings)..where((t) => t.id.equals(1))).getSingle();

  Future<void> updateSettings(AppSettingsCompanion patch) async {
    await (update(appSettings)..where((t) => t.id.equals(1)))
        .write(patch);
  }

  // ── Отметки вхождений повторяющихся дел ──────────────────────────
  Stream<List<RecurrenceDoneRow>> watchRecurrenceDones() =>
      select(recurrenceDones).watch();

  /// Даты выполненных вхождений дела (для восстановления при отмене удаления).
  Future<List<DateTime>> getOccurrenceDates(int taskId) async {
    final rows = await (select(recurrenceDones)
          ..where((r) => r.taskId.equals(taskId)))
        .get();
    return rows.map((r) => r.date).toList();
  }

  Future<void> setOccurrenceDone(int taskId, DateTime date, bool done) async {
    final d = DateTime(date.year, date.month, date.day);
    if (done) {
      await into(recurrenceDones)
          .insert(RecurrenceDonesCompanion.insert(taskId: taskId, date: d));
    } else {
      await (delete(recurrenceDones)
            ..where((r) => r.taskId.equals(taskId) & r.date.equals(d)))
          .go();
    }
  }

  // ── Этапы путешествий ─────────────────────────────────────────
  Stream<List<TripStageModel>> watchStages(int taskId) => (select(tripStages)
        ..where((s) => s.taskId.equals(taskId))
        ..orderBy([
          (s) => OrderingTerm(expression: s.startDate),
          (s) => OrderingTerm(expression: s.sortIndex),
        ]))
      .watch()
      .map((rows) => rows.map((r) => r.toModel()).toList());

  Future<List<TripStageModel>> getStages(int taskId) async {
    final rows = await (select(tripStages)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([
            (s) => OrderingTerm(expression: s.startDate),
            (s) => OrderingTerm(expression: s.sortIndex),
          ]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Число этапов по поездкам (для превью в списке путешествий).
  Stream<List<TripStageRow>> watchAllStages() => select(tripStages).watch();

  Future<int> insertStage(TripStageModel s) =>
      into(tripStages).insert(s.toCompanion());

  Future<void> updateStage(TripStageModel s) =>
      update(tripStages).replace(s.toCompanion());

  Future<void> deleteStage(int id) =>
      (delete(tripStages)..where((s) => s.id.equals(id))).go();

  static QueryExecutor _open() =>
      driftDatabase(name: 'daylane');
}

/// Маппинг строки БД в доменную модель.
extension TaskRowMapper on TaskRow {
  TaskModel toModel() => TaskModel(
        id: id,
        title: title,
        kind: kind,
        startDate: startDate,
        endDate: endDate,
        durationDays: durationDays,
        dependsOnTaskId: dependsOnTaskId,
        timeOfDayMinutes: timeOfDayMinutes,
        reminderEnabled: reminderEnabled,
        reminderRule: reminderRule,
        reminderMinutes: reminderMinutes,
        reminderDaysBefore: reminderDaysBefore,
        colorId: colorId,
        deferred: deferred,
        isTrip: isTrip,
        recurrenceType: recurrenceType,
        recurrenceInterval: recurrenceInterval,
        recurrenceAnchor: recurrenceAnchor,
        note: note,
        isDone: isDone,
        completedAt: completedAt,
        carriedOver: carriedOver,
        sortIndex: sortIndex,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension SubtaskRowMapper on SubtaskRow {
  SubtaskModel toModel() => SubtaskModel(
        id: id,
        taskId: taskId,
        title: title,
        isDone: isDone,
        sortIndex: sortIndex,
      );
}

/// Доменная модель → companion для вставки/обновления.
extension TaskModelMapper on TaskModel {
  TasksCompanion toCompanion() => TasksCompanion(
        id: id == null ? const Value.absent() : Value(id!),
        title: Value(title),
        kind: Value(kind),
        startDate: Value(startDate),
        endDate: Value(endDate),
        durationDays: Value(durationDays),
        dependsOnTaskId: Value(dependsOnTaskId),
        timeOfDayMinutes: Value(timeOfDayMinutes),
        reminderEnabled: Value(reminderEnabled),
        reminderRule: Value(reminderRule),
        reminderMinutes: Value(reminderMinutes),
        reminderDaysBefore: Value(reminderDaysBefore),
        colorId: Value(colorId),
        deferred: Value(deferred),
        isTrip: Value(isTrip),
        recurrenceType: Value(recurrenceType),
        recurrenceInterval: Value(recurrenceInterval),
        recurrenceAnchor: Value(recurrenceAnchor),
        note: Value(note),
        isDone: Value(isDone),
        completedAt: Value(completedAt),
        carriedOver: Value(carriedOver),
        sortIndex: Value(sortIndex),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension TripStageRowMapper on TripStageRow {
  TripStageModel toModel() => TripStageModel(
        id: id,
        taskId: taskId,
        title: title,
        kind: kind,
        startDate: startDate,
        endDate: endDate,
        placeName: placeName,
        placeUrl: placeUrl,
        note: note,
        sortIndex: sortIndex,
      );
}

extension TripStageModelMapper on TripStageModel {
  TripStagesCompanion toCompanion() => TripStagesCompanion(
        id: id == null ? const Value.absent() : Value(id!),
        taskId: Value(taskId),
        title: Value(title),
        kind: Value(kind),
        startDate: Value(startDate),
        endDate: Value(endDate),
        placeName: Value(placeName),
        placeUrl: Value(placeUrl),
        note: Value(note),
        sortIndex: Value(sortIndex),
      );
}

extension SubtaskModelMapper on SubtaskModel {
  SubtasksCompanion toCompanion() => SubtasksCompanion(
        id: id == null ? const Value.absent() : Value(id!),
        taskId: Value(taskId),
        title: Value(title),
        isDone: Value(isDone),
        sortIndex: Value(sortIndex),
      );
}
