# Foreground reload investigation and fix

## Confirmed cause

`learning_activity_sync.dart` invalidated seven student data providers on every
`resumed` event. Closing Android's notification shade can emit inactive/resumed,
so a focus interruption triggered course, home, learning and assessment reloads.
`lesson_access_gate.dart` independently invalidated course access on resume.
Notification lifecycle handling also invalidated permissions and reminders.

The root ProviderScope and GoRouter were not recreated by these events. The auth
listener did not sign users out or reload the app on ordinary token refresh.
Video/reading lifecycle hooks serve playback and evidence tracking and were left
unchanged.

## Implementation

- Added `BackgroundReturnObserver`: ignore inactive/resumed interruptions; act
  once after hidden/paused then resumed.
- Learning sync replays pending evidence on a real background return without
  invalidating screen data. Existing realtime, confirmed-evidence, explicit
  refresh and periodic replay paths remain.
- Removed unconditional lesson-access refresh on resume. Backend authorization,
  enrollment updates and access checks remain in place.
- Notification permission refresh updates data in place; reminders invalidate
  only when permission changes. Added disposal guards around asynchronous setup.
- Quiz deadline refresh remains on a true background return.
- Learning realtime and push registration dependencies select identity/relevant
  preference instead of recreating subscriptions on unrelated profile updates.
- Optional lifecycle/provider/route/auth-event/Firebase/request diagnostics use
  `--dart-define=LIFECYCLE_DIAGNOSTICS=true`. Disabled by default and in release;
  no credentials, request bodies, query strings or provider values are logged.

## Verification

- Focused analysis: 13 files, no issues.
- 11 tests passed across lifecycle regression, lesson access gate, quiz session
  controller and notification preferences tests.
- Regression asserts draft text and scroll retained, one initial data load,
  one realtime subscription, no shade-triggered evidence replay, one replay per
  actual background return, debounced realtime refresh, explicit refresh and
  subscription disposal. Same-user profile changes do not reconnect realtime.
- Android emulator `5554`, debug diagnostic build, existing student session:
  Home, My Learning and Assessments remained loaded after shade dismissal with
  zero extra API requests. Home/background return, switching to Android Settings
  and back, and screen lock/unlock also added zero API requests.
- One learning realtime subscription and one Firebase attachment event remained
  across those transitions. Explicit My Learning pull-to-refresh issued fresh
  requests through its existing data flow and returned to the loaded state.

## Limits

This verifies a running Android process, not OS process-death restoration. No
iOS device test, full-suite rerun, teacher-specific device walkthrough or actual
remote push delivery was performed for this fix. Legitimate server changes,
pending evidence synchronization and authentication refresh may still make
requests; they are intentionally not suppressed.
