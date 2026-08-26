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

  /// No description provided for @commonReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get commonReplace;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @daysAbbrev.
  ///
  /// In en, this message translates to:
  /// **'{count} d.'**
  String daysAbbrev(int count);

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskTitle;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get taskTitleHint;

  /// No description provided for @taskDefer.
  ///
  /// In en, this message translates to:
  /// **'Defer (no date)'**
  String get taskDefer;

  /// No description provided for @taskDeferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'the task goes to \"Undated tasks\"'**
  String get taskDeferSubtitle;

  /// No description provided for @taskNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note for the task'**
  String get taskNoteHint;

  /// No description provided for @taskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get taskDelete;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @kindOneDay.
  ///
  /// In en, this message translates to:
  /// **'One day'**
  String get kindOneDay;

  /// No description provided for @kindPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get kindPeriod;

  /// No description provided for @kindTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get kindTrip;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// No description provided for @fieldTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get fieldTime;

  /// No description provided for @timeUnset.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get timeUnset;

  /// No description provided for @fieldDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get fieldDates;

  /// No description provided for @linkStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get linkStart;

  /// No description provided for @linkEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get linkEnd;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @linkedAfter.
  ///
  /// In en, this message translates to:
  /// **'after \"{title}\"  ·  {date}'**
  String linkedAfter(Object title, Object date);

  /// No description provided for @linkedBefore.
  ///
  /// In en, this message translates to:
  /// **'before \"{title}\"  ·  {date}'**
  String linkedBefore(Object title, Object date);

  /// No description provided for @linkToTask.
  ///
  /// In en, this message translates to:
  /// **'Link to a task'**
  String get linkToTask;

  /// No description provided for @linkToTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'dates shift with the linked task automatically'**
  String get linkToTaskSubtitle;

  /// No description provided for @segStartAfter.
  ///
  /// In en, this message translates to:
  /// **'Start after'**
  String get segStartAfter;

  /// No description provided for @segFinishBefore.
  ///
  /// In en, this message translates to:
  /// **'Finish before'**
  String get segFinishBefore;

  /// No description provided for @pickAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'Start after a task'**
  String get pickAfterTitle;

  /// No description provided for @pickBeforeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish before a task'**
  String get pickBeforeTitle;

  /// No description provided for @noEligibleParents.
  ///
  /// In en, this message translates to:
  /// **'No suitable tasks to link'**
  String get noEligibleParents;

  /// No description provided for @recurNone.
  ///
  /// In en, this message translates to:
  /// **'No repeat'**
  String get recurNone;

  /// No description provided for @recurDays.
  ///
  /// In en, this message translates to:
  /// **'Every day / N days'**
  String get recurDays;

  /// No description provided for @recurWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every week / N weeks'**
  String get recurWeeks;

  /// No description provided for @recurMonths.
  ///
  /// In en, this message translates to:
  /// **'Every month (by date)'**
  String get recurMonths;

  /// No description provided for @recurYears.
  ///
  /// In en, this message translates to:
  /// **'Every year (by date)'**
  String get recurYears;

  /// No description provided for @recurMonthLast.
  ///
  /// In en, this message translates to:
  /// **'Last day of the month'**
  String get recurMonthLast;

  /// No description provided for @recurMonthBeforeEnd.
  ///
  /// In en, this message translates to:
  /// **'K days before month end'**
  String get recurMonthBeforeEnd;

  /// No description provided for @recurRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recurRepeat;

  /// No description provided for @recurInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get recurInterval;

  /// No description provided for @recurEvery.
  ///
  /// In en, this message translates to:
  /// **'every {n} {unit}'**
  String recurEvery(Object n, Object unit);

  /// No description provided for @recurDaysToEnd.
  ///
  /// In en, this message translates to:
  /// **'Days before end'**
  String get recurDaysToEnd;

  /// No description provided for @unitDays.
  ///
  /// In en, this message translates to:
  /// **'d.'**
  String get unitDays;

  /// No description provided for @unitWeeks.
  ///
  /// In en, this message translates to:
  /// **'wk.'**
  String get unitWeeks;

  /// No description provided for @unitYears.
  ///
  /// In en, this message translates to:
  /// **'yr.'**
  String get unitYears;

  /// No description provided for @unitMonths.
  ///
  /// In en, this message translates to:
  /// **'mo.'**
  String get unitMonths;

  /// No description provided for @tplTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get tplTemplate;

  /// No description provided for @tplOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get tplOther;

  /// No description provided for @tplBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get tplBirthday;

  /// No description provided for @tplPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get tplPayment;

  /// No description provided for @tplWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get tplWork;

  /// No description provided for @tplShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get tplShopping;

  /// No description provided for @tplList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get tplList;

  /// No description provided for @placeTitle.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeTitle;

  /// No description provided for @placeHint.
  ///
  /// In en, this message translates to:
  /// **'Address or name'**
  String get placeHint;

  /// No description provided for @mapsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open maps'**
  String get mapsOpen;

  /// No description provided for @mapsPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste link'**
  String get mapsPaste;

  /// No description provided for @mapsSaved.
  ///
  /// In en, this message translates to:
  /// **'link saved'**
  String get mapsSaved;

  /// No description provided for @mapsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove map link'**
  String get mapsRemove;

  /// No description provided for @mapsClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No map link in the clipboard. Copy it in the maps app: Share → Copy link.'**
  String get mapsClipboardEmpty;

  /// No description provided for @mapsHelp.
  ///
  /// In en, this message translates to:
  /// **'In maps: pick a place → Share → Copy link, then come back and tap \"Paste link\".'**
  String get mapsHelp;

  /// No description provided for @colorInCalendar.
  ///
  /// In en, this message translates to:
  /// **'Color on the calendar'**
  String get colorInCalendar;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @remAtStart.
  ///
  /// In en, this message translates to:
  /// **'At start'**
  String get remAtStart;

  /// No description provided for @remEachDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get remEachDay;

  /// No description provided for @remAtEnd.
  ///
  /// In en, this message translates to:
  /// **'At end'**
  String get remAtEnd;

  /// No description provided for @remTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get remTime;

  /// No description provided for @remByTaskTime.
  ///
  /// In en, this message translates to:
  /// **'at {time} · by task time'**
  String remByTaskTime(Object time);

  /// No description provided for @remWhen.
  ///
  /// In en, this message translates to:
  /// **'When to remind'**
  String get remWhen;

  /// No description provided for @remOnDay.
  ///
  /// In en, this message translates to:
  /// **'On the day'**
  String get remOnDay;

  /// No description provided for @remDayBefore.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get remDayBefore;

  /// No description provided for @remDays2.
  ///
  /// In en, this message translates to:
  /// **'2 days before'**
  String get remDays2;

  /// No description provided for @remDays3.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get remDays3;

  /// No description provided for @remWeekBefore.
  ///
  /// In en, this message translates to:
  /// **'A week before'**
  String get remWeekBefore;

  /// No description provided for @taskSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get taskSubtasks;

  /// No description provided for @pickPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select a period'**
  String get pickPeriod;

  /// No description provided for @paymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks with the \"Payment\" template'**
  String get paymentsEmpty;

  /// No description provided for @resetToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get resetToday;

  /// No description provided for @carriedToToday.
  ///
  /// In en, this message translates to:
  /// **'Carried to today'**
  String get carriedToToday;

  /// No description provided for @carryAllToToday.
  ///
  /// In en, this message translates to:
  /// **'Carry all to today'**
  String get carryAllToToday;

  /// No description provided for @quickToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get quickToday;

  /// No description provided for @quickTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get quickTomorrow;

  /// No description provided for @onDate.
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get onDate;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {date}'**
  String scheduledFor(Object date);

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get untitled;

  /// No description provided for @daySheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'no tasks'**
  String get daySheetEmpty;

  /// No description provided for @importQuestion.
  ///
  /// In en, this message translates to:
  /// **'Import?'**
  String get importQuestion;

  /// No description provided for @importWarning.
  ///
  /// In en, this message translates to:
  /// **'All current tasks will be replaced with data from the file. This can\'t be undone.'**
  String get importWarning;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import error: {error}'**
  String importFailed(Object error);

  /// No description provided for @backupSubject.
  ///
  /// In en, this message translates to:
  /// **'DayLane — backup'**
  String get backupSubject;

  /// No description provided for @tripTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripTitle;

  /// No description provided for @tripShowInCalendar.
  ///
  /// In en, this message translates to:
  /// **'Show in calendar'**
  String get tripShowInCalendar;

  /// No description provided for @tripEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get tripEditTask;

  /// No description provided for @tripPoints.
  ///
  /// In en, this message translates to:
  /// **'Trip points'**
  String get tripPoints;

  /// No description provided for @tripStages.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get tripStages;

  /// No description provided for @tripAddStage.
  ///
  /// In en, this message translates to:
  /// **'Add stage'**
  String get tripAddStage;

  /// No description provided for @tripStagesHint.
  ///
  /// In en, this message translates to:
  /// **'Break the trip into stages: \"Stay\" — where you sleep (counted by nights, check-in→check-out), \"Place\" — where you go. Afterwards — wrap-up notes.'**
  String get tripStagesHint;

  /// No description provided for @tripTicketsBookings.
  ///
  /// In en, this message translates to:
  /// **'Tickets, bookings, documents'**
  String get tripTicketsBookings;

  /// No description provided for @tripNotes.
  ///
  /// In en, this message translates to:
  /// **'Trip notes'**
  String get tripNotes;

  /// No description provided for @tripOpenAsRoute.
  ///
  /// In en, this message translates to:
  /// **'Open as route'**
  String get tripOpenAsRoute;

  /// No description provided for @tripRouteThroughAll.
  ///
  /// In en, this message translates to:
  /// **'through all points in order'**
  String get tripRouteThroughAll;

  /// No description provided for @tripCheckInOn.
  ///
  /// In en, this message translates to:
  /// **'check-in {date}'**
  String tripCheckInOn(Object date);

  /// No description provided for @tripStaysCovered.
  ///
  /// In en, this message translates to:
  /// **'Stays cover all nights ({n})'**
  String tripStaysCovered(int n);

  /// No description provided for @tripNoStay.
  ///
  /// In en, this message translates to:
  /// **'No stay: {list}'**
  String tripNoStay(Object list);

  /// No description provided for @tripStageStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get tripStageStay;

  /// No description provided for @tripStagePlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get tripStagePlace;

  /// No description provided for @tripNewStage.
  ///
  /// In en, this message translates to:
  /// **'New stage'**
  String get tripNewStage;

  /// No description provided for @tripStage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get tripStage;

  /// No description provided for @tripStayHint.
  ///
  /// In en, this message translates to:
  /// **'Hotel, apartment…'**
  String get tripStayHint;

  /// No description provided for @tripPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Where to go: café, museum…'**
  String get tripPlaceHint;

  /// No description provided for @tripCheckInOut.
  ///
  /// In en, this message translates to:
  /// **'Check-in — check-out'**
  String get tripCheckInOut;

  /// No description provided for @tripDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get tripDays;

  /// No description provided for @tripStayNote.
  ///
  /// In en, this message translates to:
  /// **'{nights} · no night on the checkout day — so a same-day move dovetails'**
  String tripStayNote(Object nights);

  /// No description provided for @tripPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Place (hotel, museum…)'**
  String get tripPlaceLabel;

  /// No description provided for @tripPlaceOnMap.
  ///
  /// In en, this message translates to:
  /// **'place on the map'**
  String get tripPlaceOnMap;

  /// No description provided for @tripAttachments.
  ///
  /// In en, this message translates to:
  /// **'attachments: {n}'**
  String tripAttachments(int n);

  /// No description provided for @tripLinksFilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Links and files (booking, ticket, document)'**
  String get tripLinksFilesLabel;

  /// No description provided for @tripNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes (wrap-up: how it went, what you liked)'**
  String get tripNotesHint;

  /// No description provided for @tripDayN.
  ///
  /// In en, this message translates to:
  /// **'day {n}'**
  String tripDayN(int n);

  /// No description provided for @tripDaysRange.
  ///
  /// In en, this message translates to:
  /// **'days {a}–{b}'**
  String tripDaysRange(int a, int b);

  /// No description provided for @tripCheckInOutMeta.
  ///
  /// In en, this message translates to:
  /// **'check-in {a} → check-out {b} · {nights}'**
  String tripCheckInOutMeta(Object a, Object b, Object nights);

  /// No description provided for @nightsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String nightsLabel(int count);

  /// No description provided for @tripStagesCount.
  ///
  /// In en, this message translates to:
  /// **' · stages: {n}'**
  String tripStagesCount(int n);

  /// No description provided for @tripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tripsTitle;

  /// No description provided for @tripsNew.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get tripsNew;

  /// No description provided for @tripsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trips yet.\nCreate a trip — it\'s a period with a journal: stages by day, places and notes.'**
  String get tripsEmpty;

  /// No description provided for @tripsNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get tripsNow;

  /// No description provided for @tripsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tripsUpcoming;

  /// No description provided for @tripsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tripsPast;

  /// No description provided for @carriedOverChip.
  ///
  /// In en, this message translates to:
  /// **'carried'**
  String get carriedOverChip;

  /// No description provided for @chipOnMap.
  ///
  /// In en, this message translates to:
  /// **'on the map'**
  String get chipOnMap;

  /// No description provided for @moveToUndated.
  ///
  /// In en, this message translates to:
  /// **'To undated'**
  String get moveToUndated;

  /// No description provided for @moveToUndatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'remove from the day, \"waiting for its time\"'**
  String get moveToUndatedSubtitle;

  /// No description provided for @movedToUndated.
  ///
  /// In en, this message translates to:
  /// **'Moved to Undated'**
  String get movedToUndated;

  /// No description provided for @addItemShort.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get addItemShort;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get newItem;

  /// No description provided for @newItemHint.
  ///
  /// In en, this message translates to:
  /// **'What to do?'**
  String get newItemHint;

  /// No description provided for @tasksEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmptyDefault;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'no date'**
  String get noDate;

  /// No description provided for @bucketOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get bucketOverdue;

  /// No description provided for @bucketSoon.
  ///
  /// In en, this message translates to:
  /// **'Upcoming days'**
  String get bucketSoon;

  /// No description provided for @bucketLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get bucketLater;

  /// No description provided for @bucketDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get bucketDone;

  /// No description provided for @syncSection.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncSection;

  /// No description provided for @syncHint.
  ///
  /// In en, this message translates to:
  /// **'A private GitHub repo as the cloud between your devices. The token is kept in the device\'s secure store.'**
  String get syncHint;

  /// No description provided for @syncRepo.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get syncRepo;

  /// No description provided for @syncRepoHint.
  ///
  /// In en, this message translates to:
  /// **'user/daylane-sync'**
  String get syncRepoHint;

  /// No description provided for @syncToken.
  ///
  /// In en, this message translates to:
  /// **'Token (fine-grained PAT)'**
  String get syncToken;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncNow;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @syncDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get syncDisconnect;

  /// No description provided for @syncSaved.
  ///
  /// In en, this message translates to:
  /// **'Sync settings saved'**
  String get syncSaved;

  /// No description provided for @syncReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to sync'**
  String get syncReady;

  /// No description provided for @syncNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get syncNotConfigured;

  /// No description provided for @syncFillRepoToken.
  ///
  /// In en, this message translates to:
  /// **'Fill in the repository and token'**
  String get syncFillRepoToken;

  /// No description provided for @syncUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get syncUpToDate;

  /// No description provided for @syncErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'No network'**
  String get syncErrNetwork;

  /// No description provided for @syncErrAuth.
  ///
  /// In en, this message translates to:
  /// **'No access — check the token and its Contents permission'**
  String get syncErrAuth;

  /// No description provided for @syncErrRead.
  ///
  /// In en, this message translates to:
  /// **'Read error'**
  String get syncErrRead;

  /// No description provided for @syncErrWrite.
  ///
  /// In en, this message translates to:
  /// **'Write error'**
  String get syncErrWrite;

  /// No description provided for @syncErrOther.
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncErrOther;

  /// No description provided for @digestSection.
  ///
  /// In en, this message translates to:
  /// **'Telegram digest'**
  String get digestSection;

  /// No description provided for @digestEnable.
  ///
  /// In en, this message translates to:
  /// **'Send the day plan'**
  String get digestEnable;

  /// No description provided for @digestEnableSub.
  ///
  /// In en, this message translates to:
  /// **'Open tasks for today and tomorrow, in Telegram'**
  String get digestEnableSub;

  /// No description provided for @digestConfigureSyncFirst.
  ///
  /// In en, this message translates to:
  /// **'Set up sync above first'**
  String get digestConfigureSyncFirst;

  /// No description provided for @digestTime.
  ///
  /// In en, this message translates to:
  /// **'Send time'**
  String get digestTime;

  /// No description provided for @digestSaved.
  ///
  /// In en, this message translates to:
  /// **'Digest setting sent'**
  String get digestSaved;

  /// No description provided for @detailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a task or note on the left'**
  String get detailEmptyTitle;

  /// No description provided for @detailEmptySub.
  ///
  /// In en, this message translates to:
  /// **'or create a new one with +'**
  String get detailEmptySub;

  /// No description provided for @syncUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'updated at {time}'**
  String syncUpdatedAt(String time);
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
