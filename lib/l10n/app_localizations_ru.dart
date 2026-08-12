// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get commonDone => 'Готово';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get tooltipAllTasks => 'Все дела';

  @override
  String get tooltipPayments => 'Оплаты';

  @override
  String get tooltipTrips => 'Путешествия';

  @override
  String get tooltipSettings => 'Настройки';

  @override
  String get tooltipAddTask => 'Добавить дело';

  @override
  String get tooltipAddNote => 'Добавить заметку';

  @override
  String get sectionToday => 'Сегодня';

  @override
  String get sectionTomorrow => 'Завтра';

  @override
  String get sectionNotes => 'Заметки';

  @override
  String get todayEmpty => 'на сегодня дел нет';

  @override
  String get tomorrowEmpty => 'на завтра пусто';

  @override
  String get notesEmpty => 'пусто — добавьте через «+»';

  @override
  String get notesWhereToAdd => 'Куда добавить';

  @override
  String get notesUndated => 'Дела без даты';

  @override
  String get undatedEmpty => 'пусто — «ждут своего часа»';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAutoCarry => 'Автоперенос невыполненного';

  @override
  String get settingsAutoCarrySubtitle =>
      'При запуске переносить просроченные однодневные дела на сегодня';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsFirstDay => 'Первый день недели';

  @override
  String get settingsMonday => 'Понедельник';

  @override
  String get settingsSunday => 'Воскресенье';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Системный';

  @override
  String get settingsLanguageRu => 'Русский';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsAllowNotifications => 'Разрешить уведомления';

  @override
  String get settingsAllowNotificationsSubtitle => 'Нужно для напоминаний';

  @override
  String get settingsData => 'Данные';

  @override
  String get settingsExport => 'Экспорт (резервная копия)';

  @override
  String get settingsExportSubtitle => 'Сохранить все дела в файл JSON';

  @override
  String get settingsImport => 'Импорт из файла';

  @override
  String get settingsImportSubtitle => 'Заменить все данные из резервной копии';

  @override
  String settingsImported(int count) {
    return 'Импортировано дел: $count';
  }
}
