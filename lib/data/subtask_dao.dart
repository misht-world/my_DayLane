part of 'db.dart';

@DriftAccessor(tables: [Subtasks])
class SubtaskDao extends DatabaseAccessor<AppDatabase> with _$SubtaskDaoMixin {
  SubtaskDao(super.db);

  Stream<List<SubtaskModel>> watchForTask(int taskId) => (select(subtasks)
        ..where((s) => s.taskId.equals(taskId))
        ..orderBy([(s) => OrderingTerm(expression: s.sortIndex)]))
      .watch()
      .map((rows) => rows.map((r) => r.toModel()).toList());

  Future<List<SubtaskModel>> getForTask(int taskId) async {
    final rows = await (select(subtasks)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([(s) => OrderingTerm(expression: s.sortIndex)]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Все подпункты разом (для агрегатов k/n на главном экране).
  Stream<List<SubtaskModel>> watchAll() => select(subtasks)
      .watch()
      .map((rows) => rows.map((r) => r.toModel()).toList());

  Future<int> insertSubtask(SubtaskModel s) =>
      into(subtasks).insert(s.toCompanion());

  Future<void> updateSubtask(SubtaskModel s) =>
      update(subtasks).replace(s.toCompanion());

  Future<void> toggleDone(int id, bool done) async {
    await (update(subtasks)..where((s) => s.id.equals(id)))
        .write(SubtasksCompanion(isDone: Value(done)));
  }

  /// Отмечает все подпункты дела одним статусом.
  Future<void> setAllDone(int taskId, bool done) async {
    await (update(subtasks)..where((s) => s.taskId.equals(taskId)))
        .write(SubtasksCompanion(isDone: Value(done)));
  }

  Future<void> deleteSubtask(int id) =>
      (delete(subtasks)..where((s) => s.id.equals(id))).go();

  /// Заменяет весь набор подпунктов дела (используется при сохранении карточки).
  Future<void> replaceForTask(int taskId, List<SubtaskModel> items) async {
    await transaction(() async {
      await (delete(subtasks)..where((s) => s.taskId.equals(taskId))).go();
      await batch((b) {
        for (var i = 0; i < items.length; i++) {
          b.insert(
            subtasks,
            items[i].copyWith(taskId: taskId, sortIndex: i, id: null).toCompanion(),
          );
        }
      });
    });
  }
}
