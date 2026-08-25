# habit_app (offline MVP)

Flutter + Riverpod habit tracker. **Fully offline** - all data lives in a
local SQLite database on-device; there's no backend, no network calls, no
accounts. (The `habit-app-backend` Hono project from earlier in this build
still exists as a standalone artifact but is no longer used by this app -
see the note at the bottom.)

## This zip contains `lib/` + `pubspec.yaml` only

Platform folders (`android/`, `ios/`, `web/`, etc.) aren't included - they're
generated boilerplate, not meaningful to hand-write. To get a runnable project:

```bash
flutter create --org com.yourcompany habit_app
cd habit_app
# now copy this zip's lib/ and pubspec.yaml into that folder, overwriting the defaults
flutter pub get
```

## Running

No `--dart-define`, no backend to start first - just:

```bash
flutter run
```

## iOS setup for notifications (required, one-time)

Local notifications still need one manual Xcode step (this is unaffected by
the offline refactor - it was already required). Open
`ios/Runner/AppDelegate.swift` and make sure it matches:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Local notifications don't need the "Push Notifications" capability, an APNs
key, or any `Info.plist` usage-description string - the permission prompt is
triggered entirely by our own `requestPermissions()` call, the first time
the user flips the toggle in-app.

```bash
cd ios && pod install && cd ..
flutter run
```

**One thing I still can't verify without pub.dev/Xcode access**: the
iOS-specific permission API in `core/notifications/notification_service.dart`
resolves `IOSFlutterLocalNotificationsPlugin`. Recent versions of this
package (~v14+) may have renamed this to `DarwinFlutterLocalNotificationsPlugin`.
If `flutter analyze` or the build complains about that type not existing,
swap in `DarwinFlutterLocalNotificationsPlugin` - the rest of the call
(`.requestPermissions(alert:badge:sound:)`) should be unchanged either way.

## What changed in the offline refactor

This was a data-layer swap, not a rewrite - `application/` (Riverpod
controllers) and `presentation/` (screens) barely changed. Everything that
moved lives in `data/` and a couple of new `core/` folders:

- **`core/database/`** - `AppDatabase` (opens/creates the SQLite file via
  `sqflite` + `path_provider`), plus `HabitDao` / `HabitLogDao` for raw
  table access. Schema is a direct translation of the old backend's
  `habits` / `habit_logs` Postgres tables - see `AppDatabase`'s
  `onCreate` for the exact columns. IDs are SQLite `AUTOINCREMENT`
  integers now (converted to `String` at the model boundary) instead of
  the backend's UUIDs - nothing above the DAO layer needed to know that
  changed, since `Habit.id` was always typed as `String`.
- **`core/logic/`** - `streak_calculator.dart` and `summary_calculator.dart`
  are direct Dart ports of the backend's `streak.service.ts` and
  `summary.service.ts` - same grace-day rule, same O(days x habitCount)
  summary walk, just running on-device against local rows instead of on a
  server against Postgres rows. One real simplification: the backend did
  its day-of-week math in UTC (it didn't know the caller's timezone);
  on-device, plain local `DateTime` is actually more correct, not a
  shortcut.
- **`core/errors/app_exception.dart`** replaces the old `ApiException` -
  same role (a typed, user-facing error message), just not HTTP-specific
  anymore.
- **Every `data/*_repository.dart`** (habits, habit logs, schedule,
  summary) now reads/writes through the DAOs above instead of `Dio`. The
  business rules that used to live in the backend - today-only logging,
  scheduled-day-only logging, streak recompute-on-write - moved into these
  repositories verbatim.
- **Auth is gone entirely** (`features/auth/`, `core/api/`,
  `core/storage/token_storage.dart` deleted). There's no account to log
  into. `features/onboarding/` replaces it: a single "what's your name"
  screen shown once, purely for the home-screen greeting, backed by
  `PreferencesStorage` (the same secure-storage-backed class that already
  held the notifications-enabled flag). `ProfileGate` replaces `AuthGate`.

## A subtler offline gotcha this refactor also had to fix

`google_fonts` (used for the Fraunces/Plus Jakarta Sans pairing) fetches
font files over the network on first use by default and caches them after -
which is a hidden network call in a "completely offline" app, and a
guaranteed failure with no connectivity at all. `main.dart` now sets
`GoogleFonts.config.allowRuntimeFetching = false` before `runApp`, so it
never attempts a fetch - it just falls back to the platform default font
instead. The custom typography is cosmetic, not functional, so this keeps
the app fully correct offline; it does mean the intended warm/organic look
needs the actual font files bundled locally to show up. I can't download
those `.ttf` files myself (Google Fonts' CDN isn't in this sandbox's
network allowlist), so if you want the real typography:

1. Download **Fraunces** and **Plus Jakarta Sans** from fonts.google.com.
2. Add them under e.g. `assets/fonts/`, and declare them in `pubspec.yaml`'s
   `flutter: fonts:` section.
3. In `core/theme/app_theme.dart`, swap `GoogleFonts.fraunces(...)` /
   `GoogleFonts.plusJakartaSans(...)` calls for plain
   `TextStyle(fontFamily: 'Fraunces', ...)` etc.

Until then, the app runs correctly and looks fine - just with the system
font instead of the custom pairing.

## Features

- **Onboarding**: one-time name prompt, nothing else - no accounts, no
  passwords, no network dependency of any kind.
- **Habits**: list (with today's status per habit), create (name, simple
  check-off vs. numeric target, preferred time of day, optional "which
  days" picker).
- **Habit editing**: a pencil icon in the log sheet (tap any habit tile)
  opens the same create form pre-filled, now saving in place via
  `HabitsController.updateHabit` instead of creating a new record -
  `HabitFormScreen` handles both create and edit, so there's one form to
  maintain, not two. Fixing a typo or adjusting a target no longer means
  archiving and recreating. Also added an actual "Archive this habit"
  button on the edit screen while I was in there - `archiveHabit` has
  existed in the controller/repository since early on, but nothing in the
  UI ever called it until now. Notifications are re-synced automatically
  after any edit that could affect scheduling (time of day, which days,
  or the reminder date/time itself).
- **Icon prediction**: each habit gets an icon automatically, predicted
  once from its name at creation time (`HabitIconPredictor`, in
  `features/habit_prediction/`) - never recomputed when a tile renders.
  That's deliberate, not an optimization: a display-time prediction would
  silently reshuffle every existing habit's icon whenever the keyword
  dictionary changes later, which nobody asked for. Rule-based (phrase and
  keyword matching against `icon_dictionary.dart`, 27 definitions across
  all 15 real `HabitIcon` categories), with a confidence score that isn't
  currently surfaced anywhere but is there if a "not quite right? tap to
  change" affordance gets built later. I found and fixed two real bugs in
  the predictor while wiring it in - see `habit_icon_predictor.dart`'s
  comments: the scoring loop was returning whichever icon happened to be
  last in the results map rather than the highest-scoring one, and
  multiple dictionary entries for the same icon overwrote each other's
  score instead of adding together (which the 2-entries-per-category
  expansion would have made worse, not better, if left unfixed).
- **Reminders**: same create screen, same "New" action - no separate
  button or type picker. Setting a specific date & time (instead of the
  time-of-day chips + which-days picker) is what makes an entry a one-off
  reminder rather than a recurring habit; see `Habit.isReminder` (true
  whenever `reminderAt` is non-null) and `AddHabitScreen`. Reminders have
  no streak (that's a recurring-habit concept), are excluded from the
  Insights summary, only appear on the Schedule screen on their exact
  date, and are visually distinct everywhere they appear - a dedicated
  cool slate-blue accent, an alarm icon, and an explicit "Reminder" text
  badge (never color alone) on both the home screen and schedule tiles.
- **Logging**: tap any habit to log today - boolean habits get on
  time/a bit late/skipped; numeric habits get a number entry with a "hit
  goal" shortcut. A skip (or partial/zero numeric entry) reveals optional,
  low-friction reason chips, never forced. Logging is today-only and
  restricted to a habit's scheduled days - enforced in
  `HabitLogRepository`, same rule the backend used to enforce server-side.
- **Home screen**: today's scheduled habits only. Completed ones stay
  visible (still tappable to correct a mislog) but get a distinct
  green-tinted, checked-off, struck-through style and sink to the bottom.
- **Schedule screen**: day-by-day browsing (past and upcoming) of what's
  scheduled, with each habit's logged status for that day. Read-only -
  logging stays today-only.
- **Insights screen**: 7/30/90-day report - overall completion rate, a
  daily completion bar chart, and a per-habit breakdown with completion %
  and best streak. All computed on-device by `summary_calculator.dart`.
- **Notifications (iOS)**: per-habit local reminders at a fixed time based
  on preferred time of day. Intensity varies by tenure/streak (see
  `core/notifications/nudge_intensity.dart`) - new or currently-streak-broken
  habits get a same-day follow-up nudge if not yet logged; established
  habits (streak >= 7) get a single, terser reminder. One-off reminders
  (see above) skip all of that tiering and just get a single exact-time
  notification at `reminderAt`, cancelled automatically if the reminder is
  marked done before it fires. Settings screen (bell icon on Home) has the
  toggle plus manual test tools - see `NOTIFICATION_TEST_PLAN.md`.
- **Suggestion engine**: the original headline idea from planning, finally
  built. Two rule-based pattern types mined from data the app has been
  collecting since it was first built but never analyzed - `loggedAtLocalTime`
  and `skipReason` (see `core/logic/suggestion_engine.dart`):
  - **Time-shift**: if a habit is consistently completed at a different
    time of day than it's scheduled for (60%+ of logs in one bucket, after
    14+ days of tenure and 8+ completed logs - both gates exist so it
    doesn't guess from thin data), it proposes switching. The "Shift it"
    button actually applies the change and reschedules that habit's
    notification.
  - **Skip-pattern**: if the same skip reason comes up 3+ times in 30 days,
    it surfaces the pattern - schedule-related reasons ("not free",
    "another habit") suggest reconsidering timing; motivational ones
    ("forgot", "didn't feel like it") are just a gentle observation, no
    forced action, since a time change wouldn't fix those anyway.
  - Shows as at most one banner on the Home screen (same purple/lightbulb
    visual language as the very first mockup from planning), silently
    absent for most users most of the time. "Maybe later" persists for 7
    days via a new `suggestion_dismissals` table, not just for the session.
  - Deliberately does NOT suggest anything for reminders (one-off, no
    pattern to learn from) or fire before a habit has enough history -
    see the thresholds in `suggestion_engine.dart` if you want to tune them.
- **Backup & Restore** (Settings -> Backup & Restore): full JSON export of
  every habit, reminder, and log - built by `core/backup/backup_service.dart`,
  handed to the OS share sheet via `share_plus` so it can be saved to
  Files, iCloud Drive, emailed to yourself, whatever. Import picks a
  `.json` file (`file_picker`), validates it's actually a backup, and
  inserts everything as new records - streaks are recomputed from the
  imported logs rather than trusting a cached number in the file. Import
  is additive, not a merge: it never tries to match against habits already
  on the device, so importing the same backup twice creates duplicates -
  the screen warns about this before you confirm. This was the single
  biggest release-blocking gap (an offline app with zero backup means
  losing your phone permanently loses every streak) and is now closed.
- **Settings hub**: Home's app bar now links to one `SettingsScreen`
  (Notifications, Backup & Restore) instead of jumping straight to
  notifications - small IA change, but it gives backup (and anything
  added later) a sensible home instead of accumulating one icon per
  feature on Home's app bar.
- **Bottom nav**: Home / Schedule / Insights, via `RootShell`.
- **Theme**: warm & organic palette/type system in `core/theme/` (see the
  font-bundling note above for the one thing that needs a manual step to
  look exactly as designed).

## Not in this pass

- **Android notifications** - same caveat as before this refactor: the
  service is cross-platform-shaped but nothing Android-specific has been
  set up or tested (manifest permissions, Android 13+ runtime permission
  request, notification channel verification, exact-alarm handling). This
  is explicitly the next thing, not dropped - just intentionally deferred
  per how this round was scoped.
- **Backup import is additive-only, not a smart merge** - it can't detect
  "I already restored this" and will happily create duplicates if you
  import the same file twice. The screen warns about this before
  confirming; there's no dedupe logic behind that warning.
- **No automatic/scheduled backups** - export is a manual, on-demand
  action. Someone who forgets to ever tap "Export backup" has the exact
  same risk profile as before this pass. A "remind me to back up
  periodically" nudge (using the same notification infrastructure that
  already exists) would be a natural, cheap follow-up.
- **Habit-type conversion via edit isn't blocked** - editing a recurring
  habit into a reminder (or back) is allowed, since the underlying form
  control already supports it either direction and it's not actually
  harmful (a converted habit's streak fields just stop being relevant).
  Worth knowing in case that surprises anyone, though - it's a permissive
  default, not a validated workflow.
- The third nudge signal from the original notification design (app
  engagement/usage frequency) - only tenure and streak-consistency are
  wired in.
- The suggestion engine doesn't look at day-of-week patterns (only time-
  of-day and skip-reason) - a habit that's reliably skipped on Mondays
  specifically isn't something it currently notices.
- No way to manually override a predicted icon if it guesses wrong - the
  confidence score `IconPrediction` returns isn't surfaced in the UI at
  all yet. A low-confidence prediction (or the `defaultIcon` fallback when
  nothing matches) just silently is what it is.

## A note on verification

I don't have Flutter SDK, Xcode, or pub.dev access in this environment, so
none of this has been run - no `flutter pub get`, no `flutter analyze`, no
real build. I checked every relative import resolves, grepped the whole
project for stale references to everything that got deleted (auth, the old
Dio client, `ApiException`, `.userId`), and hand-traced the SQLite row <->
model conversions, but please run `flutter analyze` after copying this in.
Most likely spots for a small fix, beyond the iOS plugin-naming question
above:

1. `sqflite` / `path_provider` / `path` / `share_plus` / `file_picker`
   version pins in `pubspec.yaml` - if `flutter pub get` can't resolve
   them, relax the `^` constraints to whatever your Flutter SDK's
   resolver picks. `share_plus` and `file_picker` are both very widely
   used with long-stable core APIs (`Share.shareXFiles`,
   `FilePicker.platform.pickFiles`), so the risk here is a version number,
   not the calls themselves being wrong.
2. `file_picker` on iOS may need `LSSupportsOpeningDocumentsInPlace` /
   `UIFileSharingEnabled` entries in `Info.plist` depending on which
   document-provider sources you want available (iCloud Drive should work
   without any changes; some third-party providers may not). I can't
   verify the exact current requirement without Xcode - if the picker
   comes up empty or can't reach a source you expect, that's the first
   thing to check.
3. SQLite's `active_days` column is stored as a comma-separated string
   (`"0,1,2,3,4,5,6"`) rather than a real array - Postgres could do arrays
   natively, SQLite can't. If you ever want to query "habits scheduled on
   day X" directly in SQL rather than filtering in Dart, this column would
   need to move to a join table instead.
4. The database schema is now at version 4 (`AppDatabase`'s `onUpgrade`
   adds a `reminder_at` column for reminders, a `suggestion_dismissals`
   table for the suggestion engine, then an `icon` column for icon
   prediction). If you're updating an existing install that already has an
   older database file, these migrations run automatically on next launch -
   existing habits are unaffected, though ones created before this pass
   backfill to `defaultIcon` (there's no name-at-creation-time to predict
   from retroactively - see the icon prediction section above). Worth
   confirming once on a device that already has data, since I can't test a
   real upgrade path myself.
5. Backup export/import touches real file I/O (`path_provider`,
   `share_plus`, `file_picker`) that I've never been able to exercise -
   this is the single most important thing to manually test before
   relying on it, more so than anything else in this pass.

## About the backend project

`habit-app-backend` (the Hono/TypeORM/Postgres project from earlier) is
untouched - still there as a standalone deliverable, still typechecks. This
app just doesn't call it anymore. If a cloud-sync/multi-device story ever
becomes a goal, that backend is a reasonable starting point to sync
*against* rather than be the sole source of truth - but that's a design
decision worth having explicitly, not something to back into.
