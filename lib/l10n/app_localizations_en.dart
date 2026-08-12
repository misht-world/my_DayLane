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
