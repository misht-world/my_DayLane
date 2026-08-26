// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonDone => 'Done';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAdd => 'Add';

  @override
  String get tooltipAllTasks => 'All tasks';

  @override
  String get tooltipPayments => 'Payments';

  @override
  String get tooltipTrips => 'Trips';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipAddTask => 'Add task';

  @override
  String get tooltipAddNote => 'Add note';

  @override
  String get sectionToday => 'Today';

  @override
  String get sectionTomorrow => 'Tomorrow';

  @override
  String get sectionNotes => 'Notes';

  @override
  String get todayEmpty => 'nothing for today';

  @override
  String get tomorrowEmpty => 'nothing for tomorrow';

  @override
  String get notesEmpty => 'empty — add via \"+\"';

  @override
  String get notesWhereToAdd => 'Add to';

  @override
  String get notesUndated => 'Undated tasks';

  @override
  String get undatedEmpty => 'empty — \"waiting for their time\"';

  @override
  String get catBooks => 'Books';

  @override
  String get catFilms => 'Films & series';

  @override
  String get catMusic => 'Music';

  @override
  String get catProjects => 'Projects';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catOther => 'Other';

  @override
  String get personBooks => 'Author';

  @override
  String get personFilms => 'Director / studio';

  @override
  String get personMusic => 'Artist';

  @override
  String get personShopping => 'Section / topic';

  @override
  String get doneBooks => 'Read';

  @override
  String get doneFilms => 'Watched';

  @override
  String get doneMusic => 'Listened';

  @override
  String get doneProjects => 'Completed';

  @override
  String get doneShopping => 'Bought';

  @override
  String get doneOther => 'Done';

  @override
  String get archiveBooks => 'Read';

  @override
  String get archiveFilms => 'Watched';

  @override
  String get archiveMusic => 'Listened';

  @override
  String get archiveProjects => 'Completed';

  @override
  String get archiveShopping => 'Bought';

  @override
  String get archiveOther => 'Done';

  @override
  String get hintBooks => 'Book title';

  @override
  String get hintFilms => 'Title';

  @override
  String get hintMusic => 'Album / track';

  @override
  String get hintProjects => 'Project name';

  @override
  String get hintShopping => 'What to buy';

  @override
  String get hintOther => 'Note';

  @override
  String get addBooks => 'Add a book';

  @override
  String get addFilms => 'Add';

  @override
  String get addMusic => 'Add';

  @override
  String get addProjects => 'Add a project';

  @override
  String get addShopping => 'Add a purchase';

  @override
  String get addOther => 'Add';

  @override
  String get audienceUnset => 'unspecified';

  @override
  String get audienceAdults => 'adults';

  @override
  String get audienceKids => 'kids';

  @override
  String get headerAdults => 'Adults';

  @override
  String get headerKids => 'Kids';

  @override
  String get headerNoTag => 'No tag';

  @override
  String get noSection => 'No section';

  @override
  String get noteYear => 'Year';

  @override
  String get noteFor => 'For';

  @override
  String get notePoints => 'Items';

  @override
  String get noteAddPoint => 'Add item';

  @override
  String get notePointHint => 'Item';

  @override
  String get noteLinksFiles => 'Links and files';

  @override
  String get noteLinksPhotos => 'Links and photos (store, image)';

  @override
  String get noteFieldNote => 'Note';

  @override
  String get noteFieldHint => 'Note';

  @override
  String get noteDoneWhenAll => 'done when all items are completed';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String get linkAdd => 'Add link';

  @override
  String get linkFileFromPhone => 'File from phone';

  @override
  String get linkDialogTitle => 'Link';

  @override
  String get linkHint => 'https://… (Yandex.Disk, Google Drive, any)';

  @override
  String linkAttachFailed(Object error) {
    return 'Couldn\'t attach the file: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAutoCarry => 'Auto-carry unfinished';

  @override
  String get settingsAutoCarrySubtitle =>
      'On launch, move overdue single-day tasks to today';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsFirstDay => 'First day of week';

  @override
  String get settingsMonday => 'Monday';

  @override
  String get settingsSunday => 'Sunday';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageRu => 'Русский';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsAllowNotifications => 'Allow notifications';

  @override
  String get settingsAllowNotificationsSubtitle => 'Needed for reminders';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsExport => 'Export (backup)';

  @override
  String get settingsExportSubtitle => 'Save all tasks to a JSON file';

  @override
  String get settingsImport => 'Import from file';

  @override
  String get settingsImportSubtitle => 'Replace all data from a backup';

  @override
  String settingsImported(int count) {
    return 'Tasks imported: $count';
  }

  @override
  String get commonReplace => 'Replace';

  @override
  String get commonUndo => 'Undo';

  @override
  String daysAbbrev(int count) {
    return '$count d.';
  }

  @override
  String get taskTitle => 'Task';

  @override
  String get taskTitleHint => 'What needs doing?';

  @override
  String get taskDefer => 'Defer (no date)';

  @override
  String get taskDeferSubtitle => 'the task goes to \"Undated tasks\"';

  @override
  String get taskNoteHint => 'Note for the task';

  @override
  String get taskDelete => 'Delete task';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get kindOneDay => 'One day';

  @override
  String get kindPeriod => 'Period';

  @override
  String get kindTrip => 'Trip';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldTime => 'Time';

  @override
  String get timeUnset => 'not set';

  @override
  String get fieldDates => 'Dates';

  @override
  String get linkStart => 'Start';

  @override
  String get linkEnd => 'End';

  @override
  String get duration => 'Duration';

  @override
  String linkedAfter(Object title, Object date) {
    return 'after \"$title\"  ·  $date';
  }

  @override
  String linkedBefore(Object title, Object date) {
    return 'before \"$title\"  ·  $date';
  }

  @override
  String get linkToTask => 'Link to a task';

  @override
  String get linkToTaskSubtitle =>
      'dates shift with the linked task automatically';

  @override
  String get segStartAfter => 'Start after';

  @override
  String get segFinishBefore => 'Finish before';

  @override
  String get pickAfterTitle => 'Start after a task';

  @override
  String get pickBeforeTitle => 'Finish before a task';

  @override
  String get noEligibleParents => 'No suitable tasks to link';

  @override
  String get recurNone => 'No repeat';

  @override
  String get recurDays => 'Every day / N days';

  @override
  String get recurWeeks => 'Every week / N weeks';

  @override
  String get recurMonths => 'Every month (by date)';

  @override
  String get recurYears => 'Every year (by date)';

  @override
  String get recurMonthLast => 'Last day of the month';

  @override
  String get recurMonthBeforeEnd => 'K days before month end';

  @override
  String get recurRepeat => 'Repeat';

  @override
  String get recurInterval => 'Interval';

  @override
  String recurEvery(Object n, Object unit) {
    return 'every $n $unit';
  }

  @override
  String get recurDaysToEnd => 'Days before end';

  @override
  String get unitDays => 'd.';

  @override
  String get unitWeeks => 'wk.';

  @override
  String get unitYears => 'yr.';

  @override
  String get unitMonths => 'mo.';

  @override
  String get tplTemplate => 'Template';

  @override
  String get tplOther => 'Other';

  @override
  String get tplBirthday => 'Birthday';

  @override
  String get tplPayment => 'Payment';

  @override
  String get tplWork => 'Work';

  @override
  String get tplShopping => 'Shopping';

  @override
  String get tplList => 'List';

  @override
  String get placeTitle => 'Place';

  @override
  String get placeHint => 'Address or name';

  @override
  String get mapsOpen => 'Open maps';

  @override
  String get mapsPaste => 'Paste link';

  @override
  String get mapsSaved => 'link saved';

  @override
  String get mapsRemove => 'Remove map link';

  @override
  String get mapsClipboardEmpty =>
      'No map link in the clipboard. Copy it in the maps app: Share → Copy link.';

  @override
  String get mapsHelp =>
      'In maps: pick a place → Share → Copy link, then come back and tap \"Paste link\".';

  @override
  String get colorInCalendar => 'Color on the calendar';

  @override
  String get reminder => 'Reminder';

  @override
  String get remAtStart => 'At start';

  @override
  String get remEachDay => 'Every day';

  @override
  String get remAtEnd => 'At end';

  @override
  String get remTime => 'Reminder time';

  @override
  String remByTaskTime(Object time) {
    return 'at $time · by task time';
  }

  @override
  String get remWhen => 'When to remind';

  @override
  String get remOnDay => 'On the day';

  @override
  String get remDayBefore => '1 day before';

  @override
  String get remDays2 => '2 days before';

  @override
  String get remDays3 => '3 days before';

  @override
  String get remWeekBefore => 'A week before';

  @override
  String get taskSubtasks => 'Subtasks';

  @override
  String get pickPeriod => 'Select a period';

  @override
  String get paymentsEmpty => 'No tasks with the \"Payment\" template';

  @override
  String get resetToday => 'today';

  @override
  String get carriedToToday => 'Carried to today';

  @override
  String get carryAllToToday => 'Carry all to today';

  @override
  String get quickToday => 'today';

  @override
  String get quickTomorrow => 'tomorrow';

  @override
  String get onDate => 'On a date';

  @override
  String scheduledFor(Object date) {
    return 'Scheduled for $date';
  }

  @override
  String get untitled => '(untitled)';

  @override
  String get daySheetEmpty => 'no tasks';

  @override
  String get importQuestion => 'Import?';

  @override
  String get importWarning =>
      'All current tasks will be replaced with data from the file. This can\'t be undone.';

  @override
  String exportFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String importFailed(Object error) {
    return 'Import error: $error';
  }

  @override
  String get backupSubject => 'DayLane — backup';

  @override
  String get tripTitle => 'Trip';

  @override
  String get tripShowInCalendar => 'Show in calendar';

  @override
  String get tripEditTask => 'Edit task';

  @override
  String get tripPoints => 'Trip points';

  @override
  String get tripStages => 'Stages';

  @override
  String get tripAddStage => 'Add stage';

  @override
  String get tripStagesHint =>
      'Break the trip into stages: \"Stay\" — where you sleep (counted by nights, check-in→check-out), \"Place\" — where you go. Afterwards — wrap-up notes.';

  @override
  String get tripTicketsBookings => 'Tickets, bookings, documents';

  @override
  String get tripNotes => 'Trip notes';

  @override
  String get tripOpenAsRoute => 'Open as route';

  @override
  String get tripRouteThroughAll => 'through all points in order';

  @override
  String tripCheckInOn(Object date) {
    return 'check-in $date';
  }

  @override
  String tripStaysCovered(int n) {
    return 'Stays cover all nights ($n)';
  }

  @override
  String tripNoStay(Object list) {
    return 'No stay: $list';
  }

  @override
  String get tripStageStay => 'Stay';

  @override
  String get tripStagePlace => 'Place';

  @override
  String get tripNewStage => 'New stage';

  @override
  String get tripStage => 'Stage';

  @override
  String get tripStayHint => 'Hotel, apartment…';

  @override
  String get tripPlaceHint => 'Where to go: café, museum…';

  @override
  String get tripCheckInOut => 'Check-in — check-out';

  @override
  String get tripDays => 'Days';

  @override
  String tripStayNote(Object nights) {
    return '$nights · no night on the checkout day — so a same-day move dovetails';
  }

  @override
  String get tripPlaceLabel => 'Place (hotel, museum…)';

  @override
  String get tripPlaceOnMap => 'place on the map';

  @override
  String tripAttachments(int n) {
    return 'attachments: $n';
  }

  @override
  String get tripLinksFilesLabel =>
      'Links and files (booking, ticket, document)';

  @override
  String get tripNotesHint => 'Notes (wrap-up: how it went, what you liked)';

  @override
  String tripDayN(int n) {
    return 'day $n';
  }

  @override
  String tripDaysRange(int a, int b) {
    return 'days $a–$b';
  }

  @override
  String tripCheckInOutMeta(Object a, Object b, Object nights) {
    return 'check-in $a → check-out $b · $nights';
  }

  @override
  String nightsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String tripStagesCount(int n) {
    return ' · stages: $n';
  }

  @override
  String get tripsTitle => 'Trips';

  @override
  String get tripsNew => 'New trip';

  @override
  String get tripsEmpty =>
      'No trips yet.\nCreate a trip — it\'s a period with a journal: stages by day, places and notes.';

  @override
  String get tripsNow => 'Now';

  @override
  String get tripsUpcoming => 'Upcoming';

  @override
  String get tripsPast => 'Past';

  @override
  String get carriedOverChip => 'carried';

  @override
  String get chipOnMap => 'on the map';

  @override
  String get moveToUndated => 'To undated';

  @override
  String get moveToUndatedSubtitle =>
      'remove from the day, \"waiting for its time\"';

  @override
  String get movedToUndated => 'Moved to Undated';

  @override
  String get addItemShort => 'item';

  @override
  String get newItem => 'New item';

  @override
  String get newItemHint => 'What to do?';

  @override
  String get tasksEmptyDefault => 'No tasks yet';

  @override
  String get noDate => 'no date';

  @override
  String get bucketOverdue => 'Overdue';

  @override
  String get bucketSoon => 'Upcoming days';

  @override
  String get bucketLater => 'Later';

  @override
  String get bucketDone => 'Done';

  @override
  String get syncSection => 'Sync';

  @override
  String get syncHint =>
      'A private GitHub repo as the cloud between your devices. The token is kept in the device\'s secure store.';

  @override
  String get syncRepo => 'Repository';

  @override
  String get syncRepoHint => 'user/daylane-sync';

  @override
  String get syncToken => 'Token (fine-grained PAT)';

  @override
  String get syncNow => 'Sync';

  @override
  String get commonSave => 'Save';

  @override
  String get syncDisconnect => 'Disconnect';

  @override
  String get syncSaved => 'Sync settings saved';

  @override
  String get syncReady => 'Ready to sync';

  @override
  String get syncNotConfigured => 'Not configured';

  @override
  String get syncFillRepoToken => 'Fill in the repository and token';

  @override
  String get syncUpToDate => 'Already up to date';

  @override
  String get syncErrNetwork => 'No network';

  @override
  String get syncErrAuth =>
      'No access — check the token and its Contents permission';

  @override
  String get syncErrRead => 'Read error';

  @override
  String get syncErrWrite => 'Write error';

  @override
  String get syncErrOther => 'Sync error';

  @override
  String get digestSection => 'Telegram digest';

  @override
  String get digestEnable => 'Send the day plan';

  @override
  String get digestEnableSub =>
      'Open tasks for today and tomorrow, in Telegram';

  @override
  String get digestConfigureSyncFirst => 'Set up sync above first';

  @override
  String get digestTime => 'Send time';

  @override
  String get digestSaved => 'Digest setting sent';

  @override
  String get detailEmptyTitle => 'Select a task or note on the left';

  @override
  String get detailEmptySub => 'or create a new one with +';

  @override
  String syncUpdatedAt(String time) {
    return 'updated at $time';
  }
}
