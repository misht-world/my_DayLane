part of 'db.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Stream<List<TaskModel>> watchAll() => (select(tasks)
        ..orderBy([(t) => OrderingTerm(expression: t.startDate)]))
      .watch()
      .map((rows) => rows.map((r) => r.toModel()).toList());

  Future<List<TaskModel>> getAll() async {
    final rows = await select(tasks).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<TaskModel?> getById(int id) async {
    final row =
        await (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Создаёт дело, возвращает присвоенный id.
  Future<int> insertTask(TaskModel task) =>
      into(tasks).insert(task.toCompanion());

  Future<void> updateTask(TaskModel task) =>
      update(tasks).replace(task.toCompanion());

  /// Пакетное обновление (для каскадного сдвига зависимостей).
  Future<void> updateMany(Iterable<TaskModel> items) async {
    await batch((b) {
      for (final t in items) {
        if (t.id == null) continue;
        b.replace(tasks, t.toCompanion());
      }
    });
  }

  Future<void> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Future<void> setDone(int id, bool done, DateTime now) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDone: Value(done),
        completedAt: Value(done ? now : null),
        updatedAt: Value(now),
      ),
    );
  }
}
