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
}
