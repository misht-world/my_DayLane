import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @tooltipAllTasks.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get tooltipAllTasks;

  /// No description provided for @tooltipPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get tooltipPayments;

  /// No description provided for @tooltipTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tooltipTrips;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @tooltipAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get tooltipAddTask;

  /// No description provided for @tooltipAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get tooltipAddNote;

  /// No description provided for @sectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sectionToday;

  /// No description provided for @sectionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get sectionTomorrow;

  /// No description provided for @sectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get sectionNotes;

  /// No description provided for @todayEmpty.
  ///
  /// In en, this message translates to:
  /// **'nothing for today'**
  String get todayEmpty;

  /// No description provided for @tomorrowEmpty.
  ///
  /// In en, this message translates to:
  /// **'nothing for tomorrow'**
  String get tomorrowEmpty;

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'empty — add via \"+\"'**
  String get notesEmpty;

  /// No description provided for @notesWhereToAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to'**
  String get notesWhereToAdd;

  /// No description provided for @notesUndated.
  ///
  /// In en, this message translates to:
  /// **'Undated tasks'**
  String get notesUndated;

  /// No description provided for @undatedEmpty.
  ///
  /// In en, this message translates to:
  /// **'empty — \"waiting for their time\"'**
  String get undatedEmpty;

  /// No description provided for @catBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get catBooks;

  /// No description provided for @catFilms.
  ///
  /// In en, this message translates to:
  /// **'Films & series'**
  String get catFilms;

  /// No description provided for @catMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get catMusic;

  /// No description provided for @catProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get catProjects;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @personBooks.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get personBooks;

  /// No description provided for @personFilms.
  ///
  /// In en, this message translates to:
  /// **'Director / studio'**
  String get personFilms;

  /// No description provided for @personMusic.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get personMusic;

  /// No description provided for @personShopping.
  ///
  /// In en, this message translates to:
  /// **'Section / topic'**
  String get personShopping;

  /// No description provided for @doneBooks.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get doneBooks;

  /// No description provided for @doneFilms.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get doneFilms;

  /// No description provided for @doneMusic.
  ///
  /// In en, this message translates to:
  /// **'Listened'**
  String get doneMusic;

  /// No description provided for @doneProjects.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get doneProjects;

  /// No description provided for @doneShopping.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get doneShopping;

  /// No description provided for @doneOther.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneOther;

  /// No description provided for @archiveBooks.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get archiveBooks;

  /// No description provided for @archiveFilms.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get archiveFilms;

  /// No description provided for @archiveMusic.
  ///
  /// In en, this message translates to:
  /// **'Listened'**
  String get archiveMusic;

  /// No description provided for @archiveProjects.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get archiveProjects;

  /// No description provided for @archiveShopping.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get archiveShopping;

  /// No description provided for @archiveOther.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get archiveOther;

  /// No description provided for @hintBooks.
  ///
  /// In en, this message translates to:
  /// **'Book title'**
  String get hintBooks;

  /// No description provided for @hintFilms.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get hintFilms;

  /// No description provided for @hintMusic.
  ///
  /// In en, this message translates to:
  /// **'Album / track'**
  String get hintMusic;

  /// No description provided for @hintProjects.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get hintProjects;

  /// No description provided for @hintShopping.
  ///
  /// In en, this message translates to:
  /// **'What to buy'**
  String get hintShopping;

  /// No description provided for @hintOther.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get hintOther;

  /// No description provided for @addBooks.
  ///
  /// In en, this message translates to:
  /// **'Add a book'**
  String get addBooks;

  /// No description provided for @addFilms.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFilms;

  /// No description provided for @addMusic.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addMusic;

  /// No description provided for @addProjects.
  ///
  /// In en, this message translates to:
  /// **'Add a project'**
  String get addProjects;

  /// No description provided for @addShopping.
  ///
  /// In en, this message translates to:
  /// **'Add a purchase'**
  String get addShopping;

  /// No description provided for @addOther.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addOther;

  /// No description provided for @audienceUnset.
  ///
  /// In en, this message translates to:
  /// **'unspecified'**
  String get audienceUnset;

  /// No description provided for @audienceAdults.
  ///
  /// In en, this message translates to:
  /// **'adults'**
  String get audienceAdults;

  /// No description provided for @audienceKids.
  ///
  /// In en, this message translates to:
  /// **'kids'**
  String get audienceKids;

  /// No description provided for @headerAdults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get headerAdults;

  /// No description provided for @headerKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get headerKids;

  /// No description provided for @headerNoTag.
  ///
  /// In en, this message translates to:
  /// **'No tag'**
  String get headerNoTag;

  /// No description provided for @noSection.
  ///
  /// In en, this message translates to:
  /// **'No section'**
  String get noSection;

  /// No description provided for @noteYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get noteYear;

  /// No description provided for @noteFor.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get noteFor;

  /// No description provided for @notePoints.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get notePoints;

  /// No description provided for @noteAddPoint.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get noteAddPoint;

  /// No description provided for @notePointHint.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get notePointHint;

  /// No description provided for @noteLinksFiles.
  ///
  /// In en, this message translates to:
  /// **'Links and files'**
  String get noteLinksFiles;

  /// No description provided for @noteLinksPhotos.
  ///
  /// In en, this message translates to:
  /// **'Links and photos (store, image)'**
  String get noteLinksPhotos;

  /// No description provided for @noteFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteFieldNote;

  /// No description provided for @noteFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteFieldHint;

  /// No description provided for @noteDoneWhenAll.
  ///
  /// In en, this message translates to:
  /// **'done when all items are completed'**
  String get noteDoneWhenAll;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @linkAdd.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get linkAdd;

  /// No description provided for @linkFileFromPhone.
  ///
  /// In en, this message translates to:
  /// **'File from phone'**
  String get linkFileFromPhone;

  /// No description provided for @linkDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkDialogTitle;

  /// No description provided for @linkHint.
  ///
  /// In en, this message translates to:
  /// **'https://… (Yandex.Disk, Google Drive, any)'**
  String get linkHint;

  /// No description provided for @linkAttachFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t attach the file: {error}'**
  String linkAttachFailed(Object error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAutoCarry.
  ///
  /// In en, this message translates to:
  /// **'Auto-carry unfinished'**
  String get settingsAutoCarry;

  /// No description provided for @settingsAutoCarrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'On launch, move overdue single-day tasks to today'**
  String get settingsAutoCarrySubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsFirstDay.
  ///
  /// In en, this message translates to:
  /// **'First day of week'**
  String get settingsFirstDay;

  /// No description provided for @settingsMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get settingsMonday;

  /// No description provided for @settingsSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get settingsSunday;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get settingsLanguageRu;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsAllowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get settingsAllowNotifications;

  /// No description provided for @settingsAllowNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Needed for reminders'**
  String get settingsAllowNotificationsSubtitle;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export (backup)'**
  String get settingsExport;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all tasks to a JSON file'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get settingsImport;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data from a backup'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsImported.
  ///
  /// In en, this message translates to:
  /// **'Tasks imported: {count}'**
  String settingsImported(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
