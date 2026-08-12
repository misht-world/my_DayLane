# Changelog

All notable changes to DayLane. Format based on
[Keep a Changelog](https://keepachangelog.com/), versioning by
[SemVer](https://semver.org/).

## [1.16.0] — 2026-08-12

### Added
- **English localization of the whole app.** All remaining screens now follow
  the app language: the task card, "All tasks" / "Payments", trips (journal,
  list, stage sheet), the calendar (month name and weekday headers), task meta
  labels, and all dialogs, snackbars and the shared links widget. Dates and
  month/weekday names format per the selected language, and Russian plurals
  (nights) are handled correctly. Switch it under Settings → Language.

## [1.15.0] — 2026-08-12

### Added
- **English localization of the Notes section.** Category names, the note card
  (all fields, hints, audience segment, "Done/Read/Watched…", archive groups),
  the "Add to" picker, and the accordion sub-headers (Adults / Kids / No tag,
  section groups) now follow the app language. More screens to come.

### Changed
- The entire CHANGELOG history is now in English.

## [1.14.0] — 2026-08-12

### Added
- **App language RU / EN.** A Language setting (System / Русский / English)
  under Settings. Localization groundwork (Flutter gen_l10n + ARB) is in place;
  the first screens are localized — Settings and the home chrome (top bar,
  section headers, the Notes section, the date hero). Remaining screens are
  still Russian and will be migrated next. Default stays **Russian** so the
  current experience is unchanged; English is opt-in.

### Changed
- Repository README and description are now in English.

## [1.13.1] — 2026-08-12

### Changed
- **Dark theme is now gray** — a warm neutral gray instead of near-black.
- **Payments are no longer duplicated in "All tasks"** — they have their own
  separate list.

## [1.13.0] — 2026-08-12

### Changed
- **Notes expand right on the home screen.** A category (Books, Projects…)
  expands into a list of entries with checkboxes, like tasks. Books/films/music
  auto-group into sub-lists by audience (adults/kids); shopping groups by
  section. An entry with items expands into a nested checklist (project steps,
  etc.). Done entries move to a collapsed per-category archive. "Undated tasks"
  is an expandable group too.
- **Tighter spacing** on the home screen: sections and task/subtask lists are
  more compact.
- **Removed the "Yesterday" section** from the home screen. Overdue and
  yesterday's unfinished tasks are now in "All tasks" and the calendar.

## [1.12.0] — 2026-08-12

### Added
- **Notes section** (formerly "Deferred") with categories: Books, Films &
  Series, Music, Projects, Shopping, Other — plus "Undated tasks". On the home
  screen the section shows tiles only for categories that have unfinished
  entries (empty and fully-done ones are hidden). Add an entry or "restore" a
  category via "+".
  - Books/films/music carry author/director/artist, year, and an
    adults/kids tag so entries don't get mixed up.
  - Shopping has a section/topic (the list groups by it), links, and photos.
  - All of them have a checklist, a note, links and files.
  - Done entries move to a collapsed per-category archive ("Read", "Watched",
    "Bought", etc.).
- Fully offline, like the rest of the app. Previous deferred tasks are kept as
  "Undated tasks".

## [1.11.1] — 2026-08-11

### Changed
- **Calendar scrolls only in the center.** A vertical gesture in the center
  columns (Tue…Sat) scrolls the calendar weeks, while the edge columns (Mon and
  Sun) scroll the whole page. The calendar no longer "hijacks" page scrolling.

## [1.11.0] — 2026-08-11

### Changed
- **The calendar scrolls continuously.** Instead of paging month by month, the
  weeks now scroll vertically inside their own window; the month name in the
  header follows the scroll, the "today" button returns to the current week, and
  the arrows and month picker jump to the chosen month.

## [1.10.0] — 2026-08-11

### Added
- **"Finish before a task".** A period/trip dependency can now be set in two
  directions: "start after" (as before) and "finish before" — the task ends the
  day before the chosen one starts and silently shifts along with it (cascading).
- **Trip stops as day sub-items.** On the home screen, under a trip row, that
  day's stages (places and stays) expand with done checkboxes and times; tapping
  a stage opens the trip journal.

## [1.9.0] — 2026-08-11

### Fixed
- **Done subtasks sink to the bottom** of the list on the home screen (the order
  of unfinished ones is preserved).
- **The bottom of the card is visible with the keyboard open.** In the task card
  and the trip stage card, the note/files field no longer hides behind the
  keyboard — content scrolls above it.
- **Notes edit properly** (in tasks and stages): a tap places the cursor where
  you want instead of selecting text — the field now grows in height without
  internal scrolling.

### Changed
- **A new trip stage** defaults to today's date (if it falls within the trip
  dates) rather than always the trip start.

## [1.8.9] — 2026-07-23

### Fixed
- **"Open as route" finally builds a route through all points.** The cause was
  found by debugging on the emulator: the native Google Maps app mangles the
  official `?api=1&waypoints=…` format — it drops the destination and turns a
  waypoint into the destination ("only the 1st and 2nd place", "couldn't build a
  route"). Switched to the `/maps/dir/P1/P2/P3` path format — it correctly builds
  a multi-point route from both coordinates and names (verified on device).
- **All stages show up in "Trip points".** A stage without a set place (only a
  title) used to drop out of the list and route — now its title serves as its
  point.

## [1.8.8] — 2026-07-17

### Fixed
- **The point route actually builds from coordinates.** An expanded short link
  comes in the `/maps/search/lat,+lng` format — coordinates weren't extracted
  from it and the route fell back to names. The format was added to extraction
  (verified on a real link, covered by tests).

## [1.8.7] — 2026-07-17

### Fixed
- **The trip point route now builds from coordinates.** Mobile Google Maps short
  links (maps.app.goo.gl) contain neither a name nor coordinates — the app now
  expands them into full links (on paste and when building a route) and takes the
  coordinates from there. This required an "internet" permission — used only to
  expand such links; the app makes no other network requests.

## [1.8.6] — 2026-07-17

### Added
- In the "Trip points" list — an **"Open as route"** button (when there are ≥2
  points): a route through all points in order. Coordinates come from saved full
  links (reliable); if a link is short — by name.

## [1.8.5] — 2026-07-17

### Changed
- "All points on the map" → **"Trip points"**: opens a list of all trip places;
  tapping a point opens it in maps via the **saved link** (the exact Google
  place, no geocoding by name). The name-based route was removed — it didn't
  build from user-entered names.

## [1.8.4] — 2026-07-17

### Fixed
- "All points on the map" — moved to the official Google Maps URL format
  (origin/destination/waypoints): the point route should build.
- Trip calendar: vertical ticks are now at the check-in and check-out of **each
  stay** (at day midpoints, on the thin line); the junction dot was removed — at
  a stay change the ticks coincide into a single mark. No stay, no ticks. Stop
  dots on a stay-change day are shifted right of center (the center is taken by
  the change mark).

## [1.8.3] — 2026-07-17

### Added
- **"All points on the map"** in the trip journal — opens a route through all
  stage places (by name) in Google Maps.
- **A subtask from the home screen** — the expanded subtask list gained a
  "+ item" row (adding to a done task makes it unfinished again).

### Changed
- Trip on the calendar: the start and end are marked with vertical ticks, and
  the stops (place stages) inside are black dots by day (several stops on a day —
  several dots).

## [1.8.2] — 2026-07-17

### Added
- **Links and files for trip stages** — a stage card can attach a booking,
  ticket, or document (a link or a file). The stage card shows an attachment
  count.

## [1.8.1] — 2026-07-17

### Added
- **Links and files in trips** — the trip journal gained a "Links and files"
  section (tickets, bookings, documents): web links and files from the phone,
  like regular tasks. Multi-day (period) tasks already had the section.

## [1.8.0] — 2026-07-17

### Added
- **Links and files for a task.** The card has a "Links and files" section: add
  a web link (Yandex.Disk, Google Drive, any) or attach a file from the phone.
  Tapping opens it in an external app. An attached file is copied into the app's
  storage so the link doesn't go stale. The task list shows a paperclip mark with
  an attachment count.

## [1.7.9] — 2026-07-17

### Added
- **A place for a task** — a name and a map link (like trip stages): "Open maps"
  and "Paste link". The task list shows a place mark (tap opens maps).
- **A time for a trip place** ("from what time") — a place stage can have a time.
- **Done checkboxes for trip stages** — a stage can be marked as visited
  (struck through).
- On pasting a link, the place name is pulled from the full Google Maps link
  (`…/maps/place/…`); short links don't yield one (unreachable offline).

### Changed
- **Trip stage auto-save** — closing / swiping back saves (the button is
  "Done"); no need to press it separately.
- Long subtask text in the card wraps and is fully visible.

### Fixed
- A task with subtasks: unchecking a subtask or adding a new one makes the task
  unfinished again (previously it could stay struck through).

## [1.7.8] — 2026-07-17

### Added
- A **"Payments"** list (icon in the top bar) — all tasks with the "Payment"
  template as a separate list, like "All tasks" and "Trips".

### Changed
- **Task card auto-save.** The title/subtask/note don't need a confirm button —
  closing or swiping back saves everything (an empty title creates nothing). The
  button became "Done".
- In the subtask list on the home screen, tapping the text opens the task card —
  the subtask can be edited (previously a tap only toggled done).
- The first letter in subtasks and the note is capitalized.

## [1.7.7] — 2026-07-17

### Changed
- The trip circle (in task lists) now shows a suitcase — like the calendar bar.
- Trips were removed from "All tasks" — they have a separate full list ("Trips"
  in the top bar).

## [1.7.6] — 2026-07-17

### Added
- **Task templates.** The card lets you pick a template — an icon in the task
  circle and a default color: 🎂 Birthday, ₽ Payment, 💼 Work, 🛒 Shopping,
  ☑️ List, or "Other" (no icon). The color can still be overridden. Task circles
  are bigger — the icon is visible right in the list.

## [1.7.5] — 2026-07-17

### Added
- **Trip stages now come in two kinds: "Stay" and "Place".** A stay is counted
  by nights (check-in→check-out, no night on the checkout day), so a same-day
  move dovetails. The journal checks "is there somewhere to sleep every night":
  a "Stays cover all nights" banner or a list of uncovered nights. There can be
  any number of place activities (café, museum) on a day.
- On the calendar, under the trip bar — a half-day stay line at the edge dates,
  and a black junction dot on a transfer day (a place change is immediately
  visible).

### Changed
- Done tasks in "Deferred" no longer **disappear** — they move to the end of the
  list (struck through). The counter counts only unfinished ones. Deletion is
  manual (long-press a task); nothing is deleted automatically.

### Fixed
- **Recurring tasks are no longer carried over.** Previously auto/manual carry
  shifted a recurring task's date (e.g. anniversaries), breaking the recurrence
  anchor so the task "moved" to another day and hung as "carried over". Now only
  regular single-day tasks are carried over.
- **Unchecking a subtask makes the task unfinished again.** Previously unchecking
  a subtask of a done task could leave it done.
- Overflow of the "Check-in — check-out" row in the stay stage card.

## [1.7.4] — 2026-07-07

### Added
- Period selection on a single calendar: first tap — start, second — end, the
  range is highlighted with a bar (instead of separate "Start"/"End" fields).

### Changed
- Setting a task time **enables the reminder automatically** (it can still be
  turned off manually).

### Fixed
- **A reminder for a timed task now fires at that time.** Previously the reminder
  was scheduled for a separate "reminder time" (09:00 by default) regardless of
  the task time — and if 09:00 had already passed, the reminder didn't come at
  all. Now a single-day timed task's reminder fires at the task's time (the card
  says so: "at 16:20 · by task time").

## [1.7.3] — 2026-07-07

### Fixed
- **Critical: the app wouldn't open (black screen/logo) in 1.7.2.** In the
  release build the notification icon was stripped (resource shrinking, since it
  was referenced only by name), so notification init crashed before the UI
  started. The icon is pinned via a manifest reference; notification init was
  moved to the background and wrapped in a guard — its failure will never hang or
  crash startup again.

## [1.7.2] — 2026-07-07

### Fixed
- **Reminders finally work.** The cause: the scheduled-notification receiver
  (flutter_local_notifications, since v18) wasn't declared in the manifest — the
  alarm fired but the notification wasn't shown. Added
  `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` (the
  latter restores reminders after a reboot).
- Status-bar notification icon: the adaptive app icon was used before
  (invalid as a status-bar icon), so the system silently dropped the
  notification. A separate monochrome icon was added.
- If exact alarms are unavailable, the reminder is scheduled as inexact (not
  lost).

### Changed
- The expanded highlighter header now matches the collapsed one's intensity (a
  single stroke color).

## [1.7.1] — 2026-07-07

### Fixed
- The "Undo" snackbar now dismisses itself after a few seconds (previously, with
  device animations off/reduced, it hung until restart — a known Flutter bug,
  worked around with our own auto-hide timer).

### Added
- An **"All tasks"** screen (a list icon in the top bar) — an overview of all
  tasks in one list, grouped by proximity: overdue / today / tomorrow / upcoming
  days / later / deferred / done. A tap opens the task (a trip as a journal).
- On the calendar, under the trip bar — marks for days planned with stages: you
  can see which part of the trip is already scheduled and which isn't.

### Changed
- Section headers ("Yesterday/Today/Tomorrow/Deferred") and list group headers —
  in a highlighter style: the word is highlighted in yellow (coral for an
  "overdue" yesterday). For an expanded section the stroke runs along the whole
  row.

## [1.7.0] — 2026-07-06

### Added
- **Trips** — a trip journal: a new task kind "Trip" (a period with a journal).
  Inside — stage sub-cards for a day or a group of days: a city, a place (hotel,
  museum), and wrap-up notes. A "Trips" screen (a suitcase in the top bar): now /
  upcoming / past, jump to a date on the calendar. On the calendar the trip bar
  is marked with a suitcase; a tap opens the journal.
- **Places on maps** — a stage can save a place: "Open maps" launches an external
  maps app (search by name), and the chosen place's link can be pasted from the
  clipboard ("Share → Copy link" in maps). The app itself stays offline.
- **Undo** — an "Undo" snackbar after carrying "→ today", "carry all", assigning
  a date to a deferred task, and deleting a task (deletion is fully restored:
  subtasks, stages, recurrence marks).
- **Move back to "Deferred"** — long-press a task: "To deferred" (remove from the
  day) and "Delete", both with undo.

### Technical
- DB schema v5: an `isTrip` flag + a `trip_stages` table; stages are included in
  JSON export/import. url_launcher dependency (external intents).

## [1.6.0] — 2026-06-23

### Fixed
- **Notifications now fire.** Previously the reminder time was computed in UTC
  (the device zone wasn't detected) — reminders went to the wrong time or were
  skipped. Now the real device zone is used (flutter_timezone), and reminders are
  scheduled as exact alarms.

### Added
- The calendar follows the selected date: paging days (in the header) and paging
  the calendar are one state; crossing a month boundary flips the calendar
  automatically.
- An outlined circle on the selected day in the calendar (today is still filled).
- Tapping the big date in the header — pick any day/month/year (the calendar
  follows); "↺ today" returns to the current date.
- When adding a subtask, the cursor is placed in the new field right away.

### Technical
- USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM / RECEIVE_BOOT_COMPLETED permissions;
  requesting exact alarms; flutter_timezone ^3.0.1 dependency.

## [1.5.0] — 2026-06-19

### Added
- Calendar: page months by swiping left/right; moving to an adjacent month keeps
  one week overlapping (for continuity).
- Expanding subtasks right in the "Deferred" section.
- A black color in the task palette.

### Changed
- The app style is now called "Daybook".
- The calendar is simplified: only the "Month" mode remains ("Week"/"Two weeks"
  removed).
- A unified style for the "Yesterday/Today/Tomorrow/Deferred" sections:
  capitalized names, a gray tick for collapsed ones, an accent one for expanded;
  the icon on "Deferred" was removed.
- The task card is structured into blocks (When / Color / Subtasks / Note) with
  leading icons; the title field is made large and prominent.
- Dividers between tasks — a black line with a dot on the left, a line under the
  last task too; in subtask lists — indented lines (no dots).
- Icons unified to a single rounded set (plus, arrows, gear, checkboxes, checks).

## [1.4.0] — 2026-06-19

### Added
- Calendar navigation: ‹ › arrows and a "Month Year" header — page to any period;
  tapping the header opens a month/year picker (a 12-month grid + year) to peek a
  couple of months ahead. A "↺ today" button returns to the current date.
- Month labels in the grid: the 1st is marked with a short month name, days
  outside the selected month are dimmed — to avoid confusion at a month boundary.
- Export and import of all tasks to a JSON file (backup) in the "Data" settings
  section.

### Fixed
- The logo is centered in the circle (adaptive icon).
- The "Repeat" field icon matches the common card style.

## [1.3.0] — 2026-06-18

### Added
- A task color picker in the card (default "Auto" by kind; set your own to
  highlight a task on the calendar).
- A "Deferred" section — tasks without a date ("waiting for their time"),
  collapsed by default, with quick assignment: "today", "tomorrow", "on a date".
  A "Defer" toggle in the card.
- Black connectors between linked period tasks on the calendar (the dependency
  chain is visible), accounting for a carry to the next week.

### Technical
- DB schema v4: `colorId` (−1 = auto) + a `deferred` field; the migration resets
  old colors to "Auto".

## [1.2.0] — 2026-06-18

### Added
- Recurring events (a third color — purple): birthdays, payments, classes.
  Types: every N days/weeks/months/years, by day of month (clamped for short
  months), the last day of the month, K days before the end of the month.
- Completing recurring ones — per occurrence (a check closes a specific date).
- Reminders for recurring ones: the next 12 occurrences are scheduled.

### Technical
- DB schema v3: recurrence fields + an occurrence-marks table `recurrence_dones`.
- A `recurrence` domain module under unit tests.

## [1.1.0] — 2026-06-18

### Added
- App logo/icon (adaptive: amber background + three lanes).
- Long-press a day on the calendar — add a task on that date.
- A "how many days before to remind" choice (on the day / 1–3 days before / a
  week before).

### Changed
- By default: light theme and the "Month" calendar view.
- Multi-day bars show the title on every week (not just the first).
- The "Carry all to today" button — red, with a "down-back" arrow.

## [1.0.0] — 2026-06-17

The first v1 release (Android, local, no network).

### Added
- A "Journal"-style home screen: a date hero with day navigation (swipe/arrows,
  return to today), three highlighted collapsible **Yesterday/Today/Tomorrow**
  sections with header ribbons and colored markers.
- "+" buttons on the Today/Tomorrow sections — add a task straight to that day.
- Task card: single day / period, popover dates and time, subtasks with two-way
  sync (all subtasks ⇄ task), a note.
- Hard cascading "start after a task" dependencies with cycle prevention.
- Carry unfinished to today (manual + optional auto-carry).
- Calendar: week/two-week/month views, periods as lane bars (greedy packing, a
  lane limit + "+N"), single-day tasks as dots under the day number (+N).
- Two task colors: single-day — blue, multi-day — amber.
- Local reminders (off by default), light and dark themes, Russian localization.

### Technical
- Flutter + Drift (SQLite) + Riverpod. Domain logic (scheduling, lanes,
  dependencies, carry_over) is covered by unit tests.
