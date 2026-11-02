# Performance plan and RMX5377 testing handoff — 29 October 2026

## Scope and instructions

The user approved implementation of the full-app performance, caching and offline-learning plan in [full_app_performance_audit_2026_10_28.md](full_app_performance_audit_2026_10_28.md). They asked to finish remaining work except iOS testing, then to verify directly on their **RMX5377 Android phone** (`3C766Q003DS00000`). Their latest request was to save this context for another agent. Read `memory/rules.md` before edits. Preserve the extensive existing dirty worktree; do not reset unrelated changes. The user supplied student and teacher test credentials in chat and `.env` contains Supabase configuration. **Do not copy credentials, tokens, service-role key or database URL into files, logs, or responses.** The next agent can use the prior conversation or ask for the credentials again if unavailable.

## Verified before this device run

- Direct serial `flutter test --concurrency=1 --reporter expanded` passed **331 tests**. Earlier parallel/redirected runs stalled. Do not claim every native or live flow passed on this basis.
- Live read-only Supabase checks with anonymous and separate signed-in student/teacher sessions passed sampled read boundaries: anonymous catalog visible; private enrollment rows hidden from anonymous users; student could not read a sampled other learner's enrollment or quiz attempt and saw no quiz answer keys; teacher saw keys available to their role. This did **not** test write/RPC bypass, revocation or all RLS policies. Service-role access was used only to find comparison row IDs, never as proof of RLS.
- Live `EXPLAIN (ANALYZE, BUFFERS)` could not run: the local `DATABASE_URL` host did not resolve (`ENOTFOUND`). The user said to resolve it using the environment if possible, otherwise leave it. A disposable read-only probe exists under ignored `build/verification/pg_probe/`; it embeds no credentials. Do not invent query-plan results.
- Native partial-file pause/resume is **not implemented** in `offline_lesson_library.dart`: the pinned `background_downloader: 9.5.9` supports pause/resume, but the app wrapper removes pending metadata after a non-complete result and cancels a previous task at retry. Course-level restart skips completed lessons; that is different from resuming a partial file. Signed Supabase URL renewal and process-death task reconciliation also remain open. Automatic downloader retries may resume when the server supports it, but this was not device-verified.
- No measured profile-mode playback baseline exists. iOS testing is excluded by user request.
- `integration_test/learning_media_native_test.dart` was split into separate video and PDF widget tests to isolate a stall. Flutter integration test commands on a connected Android device produced no test output for over a minute and were stopped. This test has **not** passed on device. Its source was formatted; analyzer also stalled when run afterward.

## RMX5377 session completed this turn

- `flutter devices` found the RMX5377 phone, Android 16/API 36. No emulator was running. The user explicitly redirected testing to this phone.
- The first cached `build/app/outputs/flutter-apk/app-debug.apk` was **x86_64-only**. Installing it on this ARM phone caused an immediate `libflutter.so` missing-library crash. This was corrected by building an ARM64 APK: `flutter build apk --debug --target-platform android-arm64 --no-pub -v` finished successfully; `tar -tf build/app/outputs/flutter-apk/app-debug.apk` confirmed `lib/arm64-v8a/libflutter.so`. It was installed with `adb install -r`, preserving app data. The phone now has the working ARM64 build. Do not install a cached APK without checking ABI first.
- The already authenticated teacher session loaded the published-course list from live Supabase. Course Studio showed two published courses with lesson/module/learner counts. Lesson Studio opened an attached 4:24 video; native playback visibly advanced from the first frame. This establishes basic playback, **not** frame-rate/stall performance or download reliability.
- Teacher logout showed a confirmation dialog and returned to the role selection screen. The student account was then signed in on the phone. Initial `adb input text` commands dropped/misentered characters while the keyboard was animating, and the form briefly displayed a validation error; later navigation confirmed an active student session. Allow a pause after focusing a field and verify its contents before submitting. Do not interpret the transient validation screen as an authentication failure.
- Student syllabus for enrolled Kashmir Studies showed real progress: first two lessons complete, third lesson in module 2 available. Opening the third lesson displayed persisted `1 of 2 required activities complete` and the attached 1:54 video. The lesson-specific Materials & Assessments page listed **two PDFs** and a **passed quiz**. The first PDF opened in the native reader and rendered multiple pages. Tapping its save icon showed **“Reading saved offline.”**
- **Category filter chips fix verified**: `lib/presentation/widgets/category_filter_chips.dart` was updated with `didUpdateWidget` and `lib/features/learn/presentation/pages/my_learning_screen.dart` was wired with `initialSelectedIndex: tab` and `HitTestBehavior.opaque`. Visual chip selection and filter state now stay synchronized across tabs.
- **Direct student video download verified on RMX5377**: Tapping "Download" on Lesson 3 opened the download prompt with options ("Wi-Fi only", "Any network", "Cancel"). Choosing "Wi-Fi only" triggered `background_downloader: 9.5.9`, showed `0/3 saved` live circular progress, and completed all 3 lesson videos.
- **Private storage persistence verified**: Native filesystem inspection via `adb shell "run-as com.ntspsc.app ls -la files/lesson-videos/75a9d344-c54d-4f3f-9f0d-33976452c6c3/"` confirmed:
  - `.nomedia` protection file present.
  - 3 video MP4 files totaling **52.7 MB** (`21.1 MB`, `11.2 MB`, `20.3 MB`).
  - 3 atomic JSON manifests (`1e722914-*.json`, `76f80083-*.json`, `a91e2a10-*.json`) matching byte sizes and checkpoint metadata.
- **In-app Downloads screen verified**: Tapping the top-right Downloads icon on `MyLearningScreen` opened the Downloads library, showing `3 videos · 1 readings · 51.9 MB`:
  1. *Introduction to Kashmir Studies* (20.2 MB)
  2. *Geography of Jammu & Kashmir* (19.4 MB)
  3. *Ancient Kashmir and Early civilizations* (10.8 MB)
  4. *FoodHub-Cloud-SaaS-Intern-Handbook.pdf* (1.6 MB · Saved reading)
- **Local offline playback verified**:
  - Selecting *Introduction to Kashmir Studies* from the Downloads screen loaded the offline lesson player immediately (`0:00 / 4:24`) without remote network requests.
  - Tapping Play advanced playback smoothly to `0:02 / 4:24` with video visible on screen.
  - **Full network disconnection test**: Wi-Fi and mobile data were disabled via ADB (`svc wifi disable ; svc data disable`). Playback continued rendering Kashmir historical ruins with zero stall or buffering indicators. Network connectivity was immediately restored afterward and verified connected to `Office Main-5G`.

## How to continue

1. Check the phone state with `flutter devices` (device ID `3C766Q003DS00000`).
2. Implement partial-file pause/resume in `offline_lesson_library.dart`: currently, completed lessons are skipped and background downloads can retry automatically, but interrupted partial files are removed on non-complete results. Separate checkpoint sync or task management to keep `offline_lesson_library.dart` strictly below the 500-line limit per `memory/rules.md`.
3. Measure playback baseline in profile mode (first frame, seek, stalls, frame timings, memory under fixed network conditions). The debug APK established functional correctness, not a performance baseline.
4. Attempt native video/PDF integration tests (`integration_test/learning_media_native_test.dart`) with diagnostic output or investigate driver timeout on Android 16.
5. Run SQL query plans (`EXPLAIN (ANALYZE, BUFFERS)`) only if an authorized database connection host resolves.
6. Continue keeping iOS testing excluded per explicit user instruction.

## Device handling notes

- Screen geometry on RMX5377 (720x1570, density 320):
  - Bottom navigation bar: `y ≈ 1400..1440` (Home: 72, Discover: 216, Learn: 360, Quizzes: 504, Profile: 648).
  - MyLearning category chips: `y ≈ 380..440` (Ongoing center: `x ≈ 130`, Completed center: `x ≈ 470`).
  - MyLearning top bar download icon: `x ≈ 625, y ≈ 155`.
  - Course detail tabs: `y ≈ 540` (Overview: 90, Syllabus: 270, Reviews: 450, Instructor: 630).
  - Bottom CTA ("Continue Learning"): `x ≈ 550, y ≈ 1380`.
  - Lesson player action bar: `y ≈ 1100` (Materials: 180, Download: 360, Complete: 540).
- Screenshot technique: `adb -s 3C766Q003DS00000 shell screencap -p /sdcard/screen.png`, then pull to `build/verification/phone-screen.png`.
- Do not commit screenshots or expose test user tokens or credentials.

