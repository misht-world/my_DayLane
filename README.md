# DayLane

A local, offline Android app (Flutter) for planning tasks around two near-term
horizons (**today / tomorrow**) with a visual month calendar where multi-day
tasks are drawn as bars packed into lanes. No server, no accounts, no AI, no
network — everything is stored locally on the device.

An optional **[Connected edition](#connected-edition-optional)** adds a Windows
desktop build and syncing between devices; the plain app builds without any of
it and stays fully offline.

## Features

- **Date hero** with day navigation; collapsible **Today / Tomorrow** sections.
- **Single-day tasks and periods**; hard cascading dependencies — start a task
  **after** another, or finish it **before** another (dates shift automatically).
- **Subtasks** synced with the parent's done state, notes, reminders.
- **Trips** — a period with a day-by-day journal: stays (counted by nights),
  places, times, attachments, and an "open as route" action in Google Maps.
- **Notes** section with categories — Books, Films & Series, Music, Projects,
  Shopping, Other — each opening inline lists with checkboxes. Media entries
  carry author / year / audience; shopping groups by section; done entries move
  to a per-category archive. Plus "undated tasks".
- **Continuous-scroll month calendar**: periods as lane bars, single-day tasks
  as dots; scroll the weeks in the centre, swipe the edges to scroll the page.
- **Recurring events** (birthdays, payments, classes) with per-occurrence done.
- **Local reminders** (flutter_local_notifications), off by default.
- Light and gray dark themes. **Russian and English** interface (Settings → Language).
- **JSON export / import** backup.

## Connected edition (optional)

Everything below is gated behind the `connected` build flag; the standard
offline app is unchanged.

- **Windows desktop build** with a master-detail layout: a task/notes column
  with a small side calendar, and a large pane where the selected item opens
  inline for comfortable text editing.
- **Two-way sync** between devices through a **private GitHub repository** (a
  single `state.json`, last-write-wins per task, tombstones for deletes). The
  access token is kept in the OS secure store (Windows Credential Manager /
  Android keystore). Syncs on launch, on foreground/background, shortly after a
  change, and every couple of minutes.
- **Telegram digest** (optional): a small server-side script reads the sync
  repository and sends the day's open tasks to Telegram; the app publishes the
  on/off and time settings (`digest.json`) that the script honours.

## Stack

Flutter · Drift (SQLite) · Riverpod · flutter_local_notifications · intl ·
flutter_secure_storage (connected only).

Domain logic (`lib/domain/`) is pure Dart and covered by unit tests, including a
two-database sync merge test.

## Build

```bash
flutter pub get
flutter test                 # domain + sync unit tests
flutter run                  # on a connected Android device/emulator
flutter build apk --release  # release APK (offline app)
```

Connected edition (adds sync + desktop + digest settings):

```bash
flutter build apk --release   --dart-define=connected=true
flutter build windows --release --dart-define=connected=true
```

Behaviour and data model source of truth — [`SPEC.md`](SPEC.md).
Release history and downloads — [`CHANGELOG.md`](CHANGELOG.md) and
[Releases](../../releases).
