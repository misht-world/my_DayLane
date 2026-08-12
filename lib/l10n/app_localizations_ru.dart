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
  String get catBooks => 'Книги';

  @override
  String get catFilms => 'Фильмы и сериалы';

  @override
  String get catMusic => 'Музыка';

  @override
  String get catProjects => 'Проекты';

  @override
  String get catShopping => 'Покупки';

  @override
  String get catOther => 'Прочее';

  @override
  String get personBooks => 'Автор';

  @override
  String get personFilms => 'Режиссёр / студия';

  @override
  String get personMusic => 'Исполнитель';

  @override
  String get personShopping => 'Раздел / тема';

  @override
  String get doneBooks => 'Прочитано';

  @override
  String get doneFilms => 'Просмотрено';

  @override
  String get doneMusic => 'Прослушано';

  @override
  String get doneProjects => 'Завершён';

  @override
  String get doneShopping => 'Куплено';

  @override
  String get doneOther => 'Готово';

  @override
  String get archiveBooks => 'Прочитанные';

  @override
  String get archiveFilms => 'Просмотренные';

  @override
  String get archiveMusic => 'Прослушанные';

  @override
  String get archiveProjects => 'Завершённые';

  @override
  String get archiveShopping => 'Купленные';

  @override
  String get archiveOther => 'Готовые';

  @override
  String get hintBooks => 'Название книги';

  @override
  String get hintFilms => 'Название';

  @override
  String get hintMusic => 'Альбом / трек';

  @override
  String get hintProjects => 'Название проекта';

  @override
  String get hintShopping => 'Что купить';

  @override
  String get hintOther => 'Заметка';

  @override
  String get addBooks => 'Добавить книгу';

  @override
  String get addFilms => 'Добавить';

  @override
  String get addMusic => 'Добавить';

  @override
  String get addProjects => 'Добавить проект';

  @override
  String get addShopping => 'Добавить покупку';

  @override
  String get addOther => 'Добавить';

  @override
  String get audienceUnset => 'не указано';

  @override
  String get audienceAdults => 'взрослые';

  @override
  String get audienceKids => 'детские';

  @override
  String get headerAdults => 'Взрослые';

  @override
  String get headerKids => 'Детские';

  @override
  String get headerNoTag => 'Без пометки';

  @override
  String get noSection => 'Без раздела';

  @override
  String get noteYear => 'Год';

  @override
  String get noteFor => 'Кому';

  @override
  String get notePoints => 'Пункты';

  @override
  String get noteAddPoint => 'Добавить пункт';

  @override
  String get notePointHint => 'Пункт';

  @override
  String get noteLinksFiles => 'Ссылки и файлы';

  @override
  String get noteLinksPhotos => 'Ссылки и фото (магазин, картинка)';

  @override
  String get noteFieldNote => 'Примечание';

  @override
  String get noteFieldHint => 'Заметка';

  @override
  String get noteDoneWhenAll => 'готово, когда выполнены все пункты';

  @override
  String get noteDeleted => 'Заметка удалена';

  @override
  String get linkAdd => 'Добавить ссылку';

  @override
  String get linkFileFromPhone => 'Файл с телефона';

  @override
  String get linkDialogTitle => 'Ссылка';

  @override
  String get linkHint => 'https://… (Я.Диск, Google Drive, любая)';

  @override
  String linkAttachFailed(Object error) {
    return 'Не удалось прикрепить файл: $error';
  }

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
