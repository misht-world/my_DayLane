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
  IntColumn get colorId => integer().withDefault(const Constant(0))();
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

/// Настройки приложения (одна строка, id = 1).
@DataClassName('SettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get autoCarry => boolean().withDefault(const Constant(false))();

  /// 0 = система, 1 = светлая, 2 = тёмная.
  IntColumn get themeMode => integer().withDefault(const Constant(0))();

  /// 1 = понедельник … 7 = воскресенье.
  IntColumn get firstWeekday => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Tasks, Subtasks, AppSettings],
  daos: [TaskDao, SubtaskDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(appSettings).insert(
            const AppSettingsCompanion(id: Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
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
        colorId: colorId,
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
        colorId: Value(colorId),
        note: Value(note),
        isDone: Value(isDone),
        completedAt: Value(completedAt),
        carriedOver: Value(carriedOver),
        sortIndex: Value(sortIndex),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
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
