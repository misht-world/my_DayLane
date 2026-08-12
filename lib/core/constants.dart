import 'package:flutter/material.dart';

/// Имя продукта. Менять здесь — переименование тривиально.
const String kAppName = 'DayLane';

/// Версия приложения (синхронизировать с `version:` в pubspec.yaml).
const String kAppVersion = '1.13.1';

/// Фиксированная палитра цветов дел. `colorId` — индекс в этом списке.
/// Цвета подобраны так, чтобы читаться и в светлой, и в тёмной теме.
class TaskPalette {
  TaskPalette._();

  static const Color blue = Color(0xFF378ADD);
  static const Color green = Color(0xFF1D9E75);
  static const Color amber = Color(0xFFBA7517);
  static const Color purple = Color(0xFF534AB7);
  static const Color pink = Color(0xFFD4537E);
  static const Color gray = Color(0xFF888780);
  static const Color black = Color(0xFF2B2A28);

  static const List<Color> colors = [
    blue,
    green,
    amber,
    purple,
    pink,
    gray,
    black,
  ];

  static const List<String> names = [
    'Синий',
    'Зелёный',
    'Янтарный',
    'Фиолетовый',
    'Розовый',
    'Серый',
    'Чёрный',
  ];

  static const int defaultColorId = 0;

  static Color byId(int id) => colors[id % colors.length];
}

/// Встроенный шаблон дела: иконка в кружке + цвет по умолчанию.
class TaskTemplate {
  const TaskTemplate(this.name, this.icon, this.colorId);
  final String name;
  final IconData icon;

  /// Индекс цвета по умолчанию из [TaskPalette] (цвет можно переопределить).
  final int colorId;
}

/// Набор шаблонов. `iconId` дела — индекс в этом списке; -1 = «Другое»
/// (обычный кружок без иконки, цвет по типу дела).
const List<TaskTemplate> kTaskTemplates = [
  TaskTemplate('День рождения', Icons.cake_rounded, 4), // розово-красный
  TaskTemplate('Оплата', Icons.payments_rounded, 1), // зелёный
  TaskTemplate('Работа', Icons.work_outline_rounded, 6), // чёрный
  TaskTemplate('Покупки', Icons.shopping_cart_rounded, 2), // янтарный
  TaskTemplate('Список', Icons.checklist_rounded, 0), // синий
];

/// Иконка шаблона по его id (null для «Другое»/некорректного).
IconData? taskTemplateIcon(int iconId) =>
    (iconId >= 0 && iconId < kTaskTemplates.length)
        ? kTaskTemplates[iconId].icon
        : null;

/// Дефолтное время напоминания — 09:00 (в минутах от полуночи).
const int kDefaultReminderMinutes = 9 * 60;

/// Категория раздела «Заметки». Индекс в [kNoteCategories] = `noteCategory` дела.
class NoteCategory {
  const NoteCategory(
    this.name,
    this.icon,
    this.colorId, {
    this.hasMedia = false,
    this.personLabel = '',
    this.doneLabel = 'Выполнено',
    this.doneGroup = 'Выполненные',
    this.itemHint = 'Название',
    this.addLabel = 'Добавить',
  });

  /// Заголовок категории (и подпись плитки).
  final String name;
  final IconData icon;
  final int colorId;

  /// Показывать поля автор/год/аудитория (книги, фильмы, музыка).
  final bool hasMedia;

  /// Подпись поля «автор» для категории (Автор/Режиссёр/Исполнитель/Раздел).
  final String personLabel;

  /// Ярлык действия выполнения и группы выполненных.
  final String doneLabel;
  final String doneGroup;

  /// Плейсхолдер названия и подпись кнопки добавления.
  final String itemHint;
  final String addLabel;
}

/// Шесть категорий заметок. Порядок = значение `noteCategory` (0..5).
const List<NoteCategory> kNoteCategories = [
  NoteCategory('Книги', Icons.menu_book_rounded, 3,
      hasMedia: true,
      personLabel: 'Автор',
      doneLabel: 'Прочитано',
      doneGroup: 'Прочитанные',
      itemHint: 'Название книги',
      addLabel: 'Добавить книгу'),
  NoteCategory('Фильмы и сериалы', Icons.movie_outlined, 4,
      hasMedia: true,
      personLabel: 'Режиссёр / студия',
      doneLabel: 'Просмотрено',
      doneGroup: 'Просмотренные',
      itemHint: 'Название',
      addLabel: 'Добавить'),
  NoteCategory('Музыка', Icons.music_note_rounded, 0,
      hasMedia: true,
      personLabel: 'Исполнитель',
      doneLabel: 'Прослушано',
      doneGroup: 'Прослушанные',
      itemHint: 'Альбом / трек',
      addLabel: 'Добавить'),
  NoteCategory('Проекты', Icons.lightbulb_outline_rounded, 2,
      doneLabel: 'Завершён',
      doneGroup: 'Завершённые',
      itemHint: 'Название проекта',
      addLabel: 'Добавить проект'),
  NoteCategory('Покупки', Icons.shopping_bag_outlined, 1,
      personLabel: 'Раздел / тема',
      doneLabel: 'Куплено',
      doneGroup: 'Купленные',
      itemHint: 'Что купить',
      addLabel: 'Добавить покупку'),
  NoteCategory('Прочее', Icons.sticky_note_2_outlined, 5,
      doneLabel: 'Готово',
      doneGroup: 'Готовые',
      itemHint: 'Заметка',
      addLabel: 'Добавить'),
];

/// Метки аудитории заметки-медиа (`audience`: 0/1/2).
const List<String> kNoteAudienceLabels = ['не указано', 'взрослые', 'детские'];

/// Иконка категории заметки по её id (null для некорректного).
IconData? noteCategoryIcon(int id) =>
    (id >= 0 && id < kNoteCategories.length) ? kNoteCategories[id].icon : null;
