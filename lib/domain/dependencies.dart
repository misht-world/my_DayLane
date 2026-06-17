import '../core/date_utils.dart';
import 'models.dart';

/// Жёсткие каскадные зависимости «Начать после дела».
///
/// Связь хранится в `Task.dependsOnTaskId` (одна родительская привязка).
/// При привязке: `start(child) = end(parent) + 1`, длина сохраняется через
/// `durationDays`. Сдвиг родителя молча двигает всю цепочку. Циклы запрещены.

/// Привязка [childId] → [parentId] создаст цикл?
///
/// Идём от предполагаемого родителя вверх по его цепочке зависимостей;
/// если встретим сам child — это цикл.
bool wouldCreateCycle(
  Map<int, TaskModel> byId,
  int childId,
  int parentId,
) {
  if (childId == parentId) return true;
  var current = byId[parentId];
  final seen = <int>{};
  while (current != null && current.dependsOnTaskId != null) {
    final next = current.dependsOnTaskId!;
    if (next == childId) return true;
    if (!seen.add(next)) break; // защита от уже существующего цикла
    current = byId[next];
  }
  return false;
}

/// Дела, доступные как родитель для [child] относительно [now]:
/// многодневные и будущие однодневные дела, кроме самого себя и тех,
/// что создали бы цикл. У дела должна быть дата (у всех дел она есть).
List<TaskModel> eligibleParents(
  List<TaskModel> all,
  TaskModel child,
  DateTime now,
) {
  final today = dateOnly(now);
  final byId = {for (final t in all) if (t.id != null) t.id!: t};
  return all.where((t) {
    if (t.id == null) return false;
    if (child.id != null && t.id == child.id) return false;
    // период всегда, либо будущее однодневное
    final eligibleKind =
        t.isPeriod || !dateOnly(t.startDate).isBefore(addDays(today, 1));
    if (!eligibleKind) return false;
    if (child.id != null && wouldCreateCycle(byId, child.id!, t.id!)) {
      return false;
    }
    return true;
  }).toList();
}

/// Пересчитывает даты всех зависимых дел каскадом от их родителей.
///
/// Для каждого дела с привязкой: `start = parent.end + 1`,
/// `end = start + durationDays - 1`. Обрабатывает по топологии (родитель
/// раньше детей). Привязка на отсутствующего родителя игнорируется
/// (дело остаётся со своими текущими датами).
List<TaskModel> applyDependencyDates(List<TaskModel> tasks) {
  final result = <int, TaskModel>{
    for (final t in tasks)
      if (t.id != null) t.id!: t,
  };

  // Список детей для каждого родителя.
  final childrenOf = <int, List<int>>{};
  final roots = <int>[];
  for (final t in tasks) {
    if (t.id == null) continue;
    final parent = t.dependsOnTaskId;
    if (parent != null && result.containsKey(parent)) {
      childrenOf.putIfAbsent(parent, () => []).add(t.id!);
    } else {
      roots.add(t.id!);
    }
  }

  // BFS от корней — родитель всегда обработан раньше ребёнка.
  final queue = <int>[...roots];
  final processed = <int>{};
  while (queue.isNotEmpty) {
    final id = queue.removeAt(0);
    if (!processed.add(id)) continue; // защита от цикла (на всякий случай)
    final parent = result[id]!;
    for (final childId in childrenOf[id] ?? const <int>[]) {
      final child = result[childId]!;
      final duration = child.durationDays < 1 ? 1 : child.durationDays;
      final start = addDays(parent.endDate, 1);
      final end = addDays(start, duration - 1);
      result[childId] = child.copyWith(startDate: start, endDate: end);
      queue.add(childId);
    }
  }

  // Сохраняем исходный порядок.
  return [
    for (final t in tasks)
      if (t.id != null) result[t.id]! else t,
  ];
}

/// Снимает привязку у детей удалённого родителя [removedParentId],
/// фиксируя их текущие даты (привязка → null).
List<TaskModel> detachChildrenOf(List<TaskModel> tasks, int removedParentId) {
  return [
    for (final t in tasks)
      if (t.dependsOnTaskId == removedParentId)
        t.copyWith(dependsOnTaskId: null)
      else
        t,
  ];
}
