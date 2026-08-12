# DayLane

A local, offline Android app (Flutter) for planning tasks around two near-term
horizons (**today / tomorrow**) with a visual month calendar where multi-day
tasks are drawn as bars packed into lanes. No server, no accounts, no AI, no
network — everything is stored locally on the device.

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
- Light and **gray** dark themes. Russian interface (localization in progress).
- **JSON export / import** backup.

## Stack

Flutter · Drift (SQLite) · Riverpod · flutter_local_notifications · intl.

Domain logic (`lib/domain/`) is pure Dart and covered by unit tests.

## Build

```bash
flutter pub get
flutter test                 # domain unit tests
flutter run                  # on a connected Android device/emulator
flutter build apk --release  # release APK
```

Behaviour and data model source of truth — [`SPEC.md`](SPEC.md).
Release history — [`CHANGELOG.md`](CHANGELOG.md).
