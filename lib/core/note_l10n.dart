import '../l10n/app_localizations.dart';

/// Локализованные строки категорий заметок по индексу (0..5).
/// Нетекстовые поля (иконка, цвет, hasMedia) берутся из [kNoteCategories].

String noteCatName(AppLocalizations l, int c) => switch (c) {
      0 => l.catBooks,
      1 => l.catFilms,
      2 => l.catMusic,
      3 => l.catProjects,
      4 => l.catShopping,
      _ => l.catOther,
    };

/// Подпись «автор/режиссёр/исполнитель/раздел» — null, если поля нет.
String? notePersonLabel(AppLocalizations l, int c) => switch (c) {
      0 => l.personBooks,
      1 => l.personFilms,
      2 => l.personMusic,
      4 => l.personShopping,
      _ => null,
    };

/// Есть ли у категории поля автор/год/аудитория (книги/фильмы/музыка).
bool noteHasMedia(int c) => c >= 0 && c <= 2;

String noteDoneLabel(AppLocalizations l, int c) => switch (c) {
      0 => l.doneBooks,
      1 => l.doneFilms,
      2 => l.doneMusic,
      3 => l.doneProjects,
      4 => l.doneShopping,
      _ => l.doneOther,
    };

String noteArchiveLabel(AppLocalizations l, int c) => switch (c) {
      0 => l.archiveBooks,
      1 => l.archiveFilms,
      2 => l.archiveMusic,
      3 => l.archiveProjects,
      4 => l.archiveShopping,
      _ => l.archiveOther,
    };

String noteItemHint(AppLocalizations l, int c) => switch (c) {
      0 => l.hintBooks,
      1 => l.hintFilms,
      2 => l.hintMusic,
      3 => l.hintProjects,
      4 => l.hintShopping,
      _ => l.hintOther,
    };

String noteAddLabel(AppLocalizations l, int c) => switch (c) {
      0 => l.addBooks,
      1 => l.addFilms,
      2 => l.addMusic,
      3 => l.addProjects,
      4 => l.addShopping,
      _ => l.addOther,
    };

/// Варианты сегмента «Кому» (0 = не указано, 1 = взрослые, 2 = детские).
List<String> noteAudienceOptions(AppLocalizations l) =>
    [l.audienceUnset, l.audienceAdults, l.audienceKids];
