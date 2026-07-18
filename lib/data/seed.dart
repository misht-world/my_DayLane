import '../core/date_utils.dart';
import '../domain/models.dart';
import 'db.dart';
import 'repository.dart';

/// Наполняет БД демонстрационными делами — только для отладки и только если
/// список дел пуст. В release не вызывается.
Future<void> seedIfEmpty(AppDatabase db, TaskRepository repo) async {
  final existing = await db.taskDao.getAll();
  if (existing.isNotEmpty) return;

  final today = dateOnly(DateTime.now());

  TaskModel single(
    String title,
    int dayOffset, {
    int colorId = 0,
    int? timeMinutes,
    bool done = false,
  }) {
    final d = addDays(today, dayOffset);
    return TaskModel(
      title: title,
      kind: TaskKind.single,
      startDate: d,
      endDate: d,
      durationDays: 1,
      colorId: colorId,
      timeOfDayMinutes: timeMinutes,
      isDone: done,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  TaskModel period(String title, int startOffset, int endOffset, int colorId) {
    final s = addDays(today, startOffset);
    final e = addDays(today, endOffset);
    return TaskModel(
      title: title,
      kind: TaskKind.period,
      startDate: s,
      endDate: e,
      durationDays: daysBetween(s, e) + 1,
      colorId: colorId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ── Сегодня (однодневные) ────────────────────────────────────────
  await repo.saveTask(single('Позвонить в банк', 0, colorId: 0, timeMinutes: 14 * 60));
  final groceries = await repo.saveTask(single('Купить продукты', 0, colorId: 2));
  await db.subtaskDao.replaceForTask(groceries, const [
    SubtaskModel(taskId: 0, title: 'Молоко', isDone: true),
    SubtaskModel(taskId: 0, title: 'Хлеб'),
    SubtaskModel(taskId: 0, title: 'Кофе'),
  ]);
  await repo.saveTask(single('Утренняя пробежка', 0, colorId: 4, done: true));

  // ── Вчера (хвост невыполненного) ─────────────────────────────────
  await repo.saveTask(single('Отправить отчёт', -1, colorId: 3));
  await repo.saveTask(single('Оплатить интернет', -1, colorId: 5));

  // ── Однодневные дела по ближайшим дням (для точек в календаре) ────
  await repo.saveTask(single('Встреча с Анной', 1, colorId: 0, timeMinutes: 11 * 60));
  await repo.saveTask(single('Записаться к врачу', 2, colorId: 4));
  await repo.saveTask(
      single('День рождения мамы', 3, colorId: 4).copyWith(iconId: 0));
  await repo.saveTask(single('Сдать книги в библиотеку', 5, colorId: 5));
  await repo.saveTask(single('Техосмотр авто', 7, colorId: 0));
  await repo.saveTask(
      single('Оплатить аренду', 9, colorId: 1).copyWith(iconId: 1));

  // ── Повторяющиеся (события: ДР, платежи, занятия) ────────────────
  TaskModel recurring(
    String title,
    int startOffset,
    RecurrenceType type, {
    int interval = 1,
    int anchor = 0,
    int? timeMinutes,
  }) {
    final d = addDays(today, startOffset);
    return TaskModel(
      title: title,
      kind: TaskKind.single,
      startDate: d,
      endDate: d,
      durationDays: 1,
      recurrenceType: type,
      recurrenceInterval: interval,
      recurrenceAnchor: anchor,
      timeOfDayMinutes: timeMinutes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  await repo.saveTask(recurring('Оплата подписки', 0, RecurrenceType.months));
  await repo.saveTask(recurring('Тренировка', 1, RecurrenceType.weeks,
      timeMinutes: 19 * 60));
  await repo.saveTask(recurring('День рождения друга', 4, RecurrenceType.years));
  await repo.saveTask(
      recurring('Свести бюджет', 0, RecurrenceType.monthLastDay));

  // ── Отложенные (без даты) ────────────────────────────────────────
  TaskModel deferred(String title) => TaskModel(
        title: title,
        kind: TaskKind.single,
        startDate: today,
        endDate: today,
        deferred: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
  await repo.saveTask(deferred('Прочитать книгу по Flutter'));
  await repo.saveTask(deferred('Разобрать гараж'));

  // ── Периоды (полосы и дорожки; есть пересечение → 2 дорожки) ──────
  await repo.saveTask(period('Ремонт кухни', -1, 2, 1));
  await repo.saveTask(period('Командировка', 4, 8, 3));
  await repo.saveTask(period('Курс по дизайну', 6, 11, 4)); // пересекает командировку
  await repo.saveTask(period('Отпуск', 13, 18, 0));

  // ── Путешествие с этапами-подкарточками (дневник поездки) ─────────
  final trip = await repo.saveTask(TaskModel(
    title: 'Поездка в Питер',
    kind: TaskKind.period,
    isTrip: true,
    startDate: addDays(today, 20),
    endDate: addDays(today, 25),
    durationDays: 6,
    colorId: 1,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));
  // Жильё считается по ночам: выезд 23-го и заезд 23-го стыкуются встык,
  // все ночи поездки (+20…+24) закрыты.
  await repo.saveStage(TripStageModel(
    taskId: trip,
    title: 'Гостиница «Октябрьская»',
    kind: TripStageKind.stay,
    startDate: addDays(today, 20),
    endDate: addDays(today, 23),
    placeName: 'Гостиница «Октябрьская»',
  ));
  await repo.saveStage(TripStageModel(
    taskId: trip,
    title: 'Апартаменты на Невском',
    kind: TripStageKind.stay,
    startDate: addDays(today, 23),
    endDate: addDays(today, 25),
    placeName: 'Невский проспект',
  ));
  await repo.saveStage(TripStageModel(
    taskId: trip,
    title: 'Эрмитаж',
    startDate: addDays(today, 21),
    endDate: addDays(today, 21),
    placeName: 'Эрмитаж',
  ));
  await repo.saveStage(TripStageModel(
    taskId: trip,
    title: 'Петергоф',
    startDate: addDays(today, 23),
    endDate: addDays(today, 23),
  ));

  // Зависимая цепочка (для соединителей в календаре).
  final stage1 = await repo.saveTask(period('Проект: этап 1', 1, 3, 3));
  await repo.saveTask(TaskModel(
    title: 'Проект: этап 2',
    kind: TaskKind.period,
    startDate: addDays(today, 4),
    endDate: addDays(today, 6),
    durationDays: 3,
    dependsOnTaskId: stage1,
    colorId: 3,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));
}
