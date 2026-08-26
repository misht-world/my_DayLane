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

  @override
  String get commonReplace => 'Заменить';

  @override
  String get commonUndo => 'Отменить';

  @override
  String daysAbbrev(int count) {
    return '$count дн.';
  }

  @override
  String get taskTitle => 'Дело';

  @override
  String get taskTitleHint => 'Что нужно сделать?';

  @override
  String get taskDefer => 'Отложить (без даты)';

  @override
  String get taskDeferSubtitle => 'дело попадёт в «Дела без даты»';

  @override
  String get taskNoteHint => 'Заметка к делу';

  @override
  String get taskDelete => 'Удалить дело';

  @override
  String get taskDeleted => 'Дело удалено';

  @override
  String get kindOneDay => 'Один день';

  @override
  String get kindPeriod => 'Период';

  @override
  String get kindTrip => 'Путешествие';

  @override
  String get fieldDate => 'Дата';

  @override
  String get fieldTime => 'Время';

  @override
  String get timeUnset => 'не указано';

  @override
  String get fieldDates => 'Даты';

  @override
  String get linkStart => 'Начало';

  @override
  String get linkEnd => 'Конец';

  @override
  String get duration => 'Длительность';

  @override
  String linkedAfter(Object title, Object date) {
    return 'после «$title»  ·  $date';
  }

  @override
  String linkedBefore(Object title, Object date) {
    return 'до «$title»  ·  $date';
  }

  @override
  String get linkToTask => 'Привязать к делу';

  @override
  String get linkToTaskSubtitle =>
      'даты сдвигаются за связанным делом автоматически';

  @override
  String get segStartAfter => 'Начать после';

  @override
  String get segFinishBefore => 'Закончить до';

  @override
  String get pickAfterTitle => 'Начать после дела';

  @override
  String get pickBeforeTitle => 'Закончить до дела';

  @override
  String get noEligibleParents => 'Нет подходящих дел для привязки';

  @override
  String get recurNone => 'Без повторения';

  @override
  String get recurDays => 'Каждый день / N дней';

  @override
  String get recurWeeks => 'Каждую неделю / N недель';

  @override
  String get recurMonths => 'Каждый месяц (по числу)';

  @override
  String get recurYears => 'Каждый год (по дате)';

  @override
  String get recurMonthLast => 'Последний день месяца';

  @override
  String get recurMonthBeforeEnd => 'За K дней до конца месяца';

  @override
  String get recurRepeat => 'Повторение';

  @override
  String get recurInterval => 'Интервал';

  @override
  String recurEvery(Object n, Object unit) {
    return 'каждые $n $unit';
  }

  @override
  String get recurDaysToEnd => 'Дней до конца';

  @override
  String get unitDays => 'дн.';

  @override
  String get unitWeeks => 'нед.';

  @override
  String get unitYears => 'г.';

  @override
  String get unitMonths => 'мес.';

  @override
  String get tplTemplate => 'Шаблон';

  @override
  String get tplOther => 'Другое';

  @override
  String get tplBirthday => 'День рождения';

  @override
  String get tplPayment => 'Оплата';

  @override
  String get tplWork => 'Работа';

  @override
  String get tplShopping => 'Покупки';

  @override
  String get tplList => 'Список';

  @override
  String get placeTitle => 'Место';

  @override
  String get placeHint => 'Адрес или название';

  @override
  String get mapsOpen => 'Открыть карты';

  @override
  String get mapsPaste => 'Вставить ссылку';

  @override
  String get mapsSaved => 'ссылка сохранена';

  @override
  String get mapsRemove => 'Убрать ссылку на карты';

  @override
  String get mapsClipboardEmpty =>
      'В буфере нет ссылки на карты. Скопируйте её в приложении карт: Поделиться → Копировать ссылку.';

  @override
  String get mapsHelp =>
      'В картах: выберите место → Поделиться → Копировать ссылку, затем вернитесь и нажмите «Вставить ссылку».';

  @override
  String get colorInCalendar => 'Цвет в календаре';

  @override
  String get reminder => 'Напоминание';

  @override
  String get remAtStart => 'В начале';

  @override
  String get remEachDay => 'Каждый день';

  @override
  String get remAtEnd => 'В конце';

  @override
  String get remTime => 'Время напоминания';

  @override
  String remByTaskTime(Object time) {
    return 'в $time · по времени дела';
  }

  @override
  String get remWhen => 'Когда напомнить';

  @override
  String get remOnDay => 'В день';

  @override
  String get remDayBefore => 'За день';

  @override
  String get remDays2 => 'За 2 дня';

  @override
  String get remDays3 => 'За 3 дня';

  @override
  String get remWeekBefore => 'За неделю';

  @override
  String get taskSubtasks => 'Подпункты';

  @override
  String get pickPeriod => 'Выберите период';

  @override
  String get paymentsEmpty => 'Нет дел с шаблоном «Оплата»';

  @override
  String get resetToday => 'сегодня';

  @override
  String get carriedToToday => 'Перенесено на сегодня';

  @override
  String get carryAllToToday => 'Перенести всё на сегодня';

  @override
  String get quickToday => 'сегодня';

  @override
  String get quickTomorrow => 'завтра';

  @override
  String get onDate => 'На дату';

  @override
  String scheduledFor(Object date) {
    return 'Назначено на $date';
  }

  @override
  String get untitled => '(без названия)';

  @override
  String get daySheetEmpty => 'дел нет';

  @override
  String get importQuestion => 'Импортировать?';

  @override
  String get importWarning =>
      'Все текущие дела будут заменены данными из файла. Действие нельзя отменить.';

  @override
  String exportFailed(Object error) {
    return 'Не удалось: $error';
  }

  @override
  String importFailed(Object error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String get backupSubject => 'DayLane — резервная копия';

  @override
  String get tripTitle => 'Путешествие';

  @override
  String get tripShowInCalendar => 'Показать в календаре';

  @override
  String get tripEditTask => 'Изменить дело';

  @override
  String get tripPoints => 'Точки поездки';

  @override
  String get tripStages => 'Этапы';

  @override
  String get tripAddStage => 'Добавить этап';

  @override
  String get tripStagesHint =>
      'Разбейте поездку на этапы: «Жильё» — где ночуем (считается по ночам, заезд→выезд), «Место» — куда идём. После — заметки по итогу.';

  @override
  String get tripTicketsBookings => 'Билеты, брони, документы';

  @override
  String get tripNotes => 'Заметки поездки';

  @override
  String get tripOpenAsRoute => 'Открыть как маршрут';

  @override
  String get tripRouteThroughAll => 'через все точки по порядку';

  @override
  String tripCheckInOn(Object date) {
    return 'заезд $date';
  }

  @override
  String tripStaysCovered(int n) {
    return 'Жильё на все ночи ($n) выбрано';
  }

  @override
  String tripNoStay(Object list) {
    return 'Нет жилья: $list';
  }

  @override
  String get tripStageStay => 'Жильё';

  @override
  String get tripStagePlace => 'Место';

  @override
  String get tripNewStage => 'Новый этап';

  @override
  String get tripStage => 'Этап';

  @override
  String get tripStayHint => 'Гостиница, квартира…';

  @override
  String get tripPlaceHint => 'Куда идём: кафе, музей…';

  @override
  String get tripCheckInOut => 'Заезд — выезд';

  @override
  String get tripDays => 'Дни';

  @override
  String tripStayNote(Object nights) {
    return '$nights · в ночь выезда уже не ночуем — поэтому переезд в один день стыкуется';
  }

  @override
  String get tripPlaceLabel => 'Место (гостиница, музей…)';

  @override
  String get tripPlaceOnMap => 'место на карте';

  @override
  String tripAttachments(int n) {
    return 'вложений: $n';
  }

  @override
  String get tripLinksFilesLabel => 'Ссылки и файлы (бронь, билет, документ)';

  @override
  String get tripNotesHint => 'Заметки (по итогу: как было, что понравилось)';

  @override
  String tripDayN(int n) {
    return 'день $n';
  }

  @override
  String tripDaysRange(int a, int b) {
    return 'дни $a–$b';
  }

  @override
  String tripCheckInOutMeta(Object a, Object b, Object nights) {
    return 'заезд $a → выезд $b · $nights';
  }

  @override
  String nightsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ночи',
      many: '$count ночей',
      few: '$count ночи',
      one: '$count ночь',
    );
    return '$_temp0';
  }

  @override
  String tripStagesCount(int n) {
    return ' · этапов: $n';
  }

  @override
  String get tripsTitle => 'Путешествия';

  @override
  String get tripsNew => 'Новое путешествие';

  @override
  String get tripsEmpty =>
      'Пока нет путешествий.\nСоздайте поездку — это период с дневником: этапы по дням, места и заметки.';

  @override
  String get tripsNow => 'Сейчас';

  @override
  String get tripsUpcoming => 'Предстоящие';

  @override
  String get tripsPast => 'Прошедшие';

  @override
  String get carriedOverChip => 'перенесено';

  @override
  String get chipOnMap => 'на карте';

  @override
  String get moveToUndated => 'В «Дела без даты»';

  @override
  String get moveToUndatedSubtitle => 'снять с дня, «ждёт своего часа»';

  @override
  String get movedToUndated => 'Перенесено в «Дела без даты»';

  @override
  String get addItemShort => 'пункт';

  @override
  String get newItem => 'Новый пункт';

  @override
  String get newItemHint => 'Что сделать?';

  @override
  String get tasksEmptyDefault => 'Пока нет дел';

  @override
  String get noDate => 'без даты';

  @override
  String get bucketOverdue => 'Просрочено';

  @override
  String get bucketSoon => 'Ближайшие дни';

  @override
  String get bucketLater => 'Позже';

  @override
  String get bucketDone => 'Выполнено';

  @override
  String get syncSection => 'Синхронизация';

  @override
  String get syncHint =>
      'Приватный GitHub-репозиторий как «облако» между устройствами. Токен хранится в защищённом хранилище устройства.';

  @override
  String get syncRepo => 'Репозиторий';

  @override
  String get syncRepoHint => 'логин/daylane-sync';

  @override
  String get syncToken => 'Токен (fine-grained PAT)';

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get syncDisconnect => 'Отключить';

  @override
  String get syncSaved => 'Настройки синхронизации сохранены';

  @override
  String get syncReady => 'Готово к синхронизации';

  @override
  String get syncNotConfigured => 'Не настроено';

  @override
  String get syncFillRepoToken => 'Заполните репозиторий и токен';

  @override
  String get syncUpToDate => 'Уже синхронизировано';

  @override
  String get syncErrNetwork => 'Нет сети';

  @override
  String get syncErrAuth => 'Нет доступа — проверьте токен и права (Contents)';

  @override
  String get syncErrRead => 'Ошибка чтения';

  @override
  String get syncErrWrite => 'Ошибка записи';

  @override
  String get syncErrOther => 'Ошибка синхронизации';

  @override
  String get digestSection => 'Телеграм-дайджест';

  @override
  String get digestEnable => 'Присылать план на день';

  @override
  String get digestEnableSub =>
      'Невыполненные дела на сегодня и завтра — в Телеграм';

  @override
  String get digestConfigureSyncFirst => 'Сначала настройте синхронизацию выше';

  @override
  String get digestTime => 'Время рассылки';

  @override
  String get digestSaved => 'Настройка дайджеста отправлена';

  @override
  String get detailEmptyTitle => 'Выберите дело или заметку слева';

  @override
  String get detailEmptySub => 'или создайте новое кнопкой +';

  @override
  String syncUpdatedAt(String time) {
    return 'обновлено в $time';
  }
}
