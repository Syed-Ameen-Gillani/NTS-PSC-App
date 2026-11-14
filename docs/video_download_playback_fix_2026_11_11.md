# Playback while downloading — November 11, 2026

## Evidence and scope

The supplied 685-line session log contains 44 buffering starts, 18 skipped-frame
warnings, two explicit AudioTrack underrun warnings, three successful native
downloads, and no HTTP/socket/ExoPlaybackException matches. Many buffering events
report 50–60 seconds of buffered media. The running emulator also showed CPU
pressure. These observations do not establish network starvation as the cause.

Gradle dependencyInsight confirmed Media3 1.9.2 at runtime, shared by
video_player_android 2.12.2 and flutter_compress 2.0.0. AndroidX issue #3210
describes audio underruns causing BUFFERING despite a healthy source buffer.
The stable 1.11 release includes a renderer grace period and a fixed 500ms PCM
buffer. References:

- https://github.com/androidx/media/issues/3210
- https://developer.android.com/jetpack/androidx/releases/media3#1.11.0
- https://docs.flutter.dev/perf/ui-performance

## Changes

- Align all Android Media3 modules to stable 1.11.1 for plugin compilation and
  app runtime. Keeping compression and playback aligned avoids mixed native APIs.
  No Flutter package replacement or cache edits are needed.
- Do not treat native buffering pauses as user pauses in StudyVideoPlayer's
  resume-position persistence. Periodic, real-pause, lifecycle and disposal saves
  remain. Learning-evidence sampling and course completion rules are untouched.
- Add an isolated same-source benchmark for streaming alone, streaming alongside
  a native background_downloader transfer, and playback of the completed file.
  It uses temporary storage and removes its download. It writes no course,
  enrollment or student progress data. Results contain no signed URLs.

No download throttling, automatic pause/resume, source switching during playback,
buffer-indicator redesign, or broad provider refactor is justified yet.

## Verification

- 42 focused tests passed: study player, professional player, course downloads,
  and study persistence. Includes repeated buffering-flap coverage and real-pause
  persistence verification.
- Targeted analysis passed for changed Dart implementation and test harnesses.
- Both native playback Java and compression Kotlin plugins compiled successfully
  against 1.11.1. dependencyInsight confirmed the runtime version.
- Read-only storage probe: HTTP 206, video/mp4, headers in 856ms, first 64KB in
  991ms. The 21,173,292-byte MP4 has moov before mdat. This is a bounded delivery
  probe, not an entitlement or full-transfer benchmark.
- Initial native test built and installed on emulator-5554, but its runner stalled
  on VM-service discovery. Do not report this attempt as a native test pass.
- The subsequent driver run with DDS disabled passed the same-source comparison
  on emulator-5554. Native logs confirm Media3 1.11.1. In approximately 15-second
  observation windows: streaming alone recorded one 65ms startup buffer event;
  streaming alongside a download recorded four events totaling 1,942ms; the
  downloaded file recorded zero buffering events. Observed positions were 10,120,
  8,058 and 14,691ms respectively. The concurrent transfer remained active through
  its playback window and subsequently completed successfully. Concurrent stalls
  still reported over 50 seconds buffered. This does not establish a network
  starvation problem or justify auto-pausing downloads.
- Sanitized results are in ignored build/video_download_contention_results.json.
  Temporary download/configuration were removed. The benchmark's overlap sample
  counter counts requested pump intervals; it is not a wall-time throughput metric.
- Normal lib/main.dart debug APK rebuilt successfully and was installed with
  adb install -r and launched on emulator-5554 after the benchmark. Existing app
  storage was preserved; the emulator is no longer running the test harness.
- These short debug/emulator runs are not a physical-device performance guarantee,
  an equivalent before/after benchmark, or a runtime compression test. Playback
  alongside downloads still shows stalls on this emulator. Representative physical
  Android profiling and a real teacher compression smoke test remain open.

## Repeatable comparison

Generate ignored build/video_profile_config.json with
`python tool/probe_video_delivery.py --profile-config`, then run:

```powershell
flutter drive --no-dds -d emulator-5554 --driver=test_driver/video_playback_profile.dart --target=integration_test/video_download_contention_test.dart --dart-define-from-file=build/video_profile_config.json
```

Use a physical Android phone and --profile for representative performance results.
Emulator debug-mode observations are functional diagnostics only. Remove the
temporary configuration after the run. Never commit or print its signed URL.

## Rollback

Remove only the Media3 resolution rule added in android/build.gradle.kts to return
to plugin-selected native versions. Remove the buffering exclusion in the study
player only if it causes a demonstrated persistence regression. Preserve unrelated
existing worktree changes. Native dependency changes require a full rebuild;
hot reload and hot restart cannot load a new Android library.

## Physical phone manual check — RMX5377, Android 16

Installed the rebuilt normal debug APK with app data preserved. Signed into the
authorized student test account and exercised the actual Kashir studies course UI,
not the integration harness. Native initialization confirmed Media3 1.11.1.

- Started the 4:24 first lesson from Continue Learning and streamed it.
- Started the course download using Wi-Fi only, then played during the download.
  UI screenshots showed Pause 9%, Pause 33%, Resume 91%, and Downloaded.
- Native logs acknowledge a paused task, resume of the same task ID, and its
  successful completion. Two transfer completions were captured after continuous
  app-only logging began; earlier log history had been evicted by system noise.
- The download confirmation dialog pauses playback when it covers the player;
  playback was explicitly resumed afterward. Initial centre taps could toggle
  playback, so those intervals were not used as playback-performance measurements.
- A controlled check using corner taps to reveal controls showed approximately
  2:59 to 3:13 over 14 seconds. A CPU snapshot showed 4.2% app CPU; this single
  sample is not a sustained CPU benchmark.
- Reopened the downloaded lesson through Continue Learning. Position restored to
  3:49; a ten-second playback check advanced it to 3:59. Left the lesson paused.
  Wi-Fi remained enabled, so this was not a network-disconnection test.
- Continuous app-native log capture contained no explicit audio-underrun warning,
  Choreographer skipped-frame warning, HttpDataSourceException, or
  ExoPlaybackException during the captured window. It did contain AudioTrack clock
  correction messages. No repeated buffering overlay was observed in the UI checks.
- The optional Flutter attach attempt did not connect; this manual check therefore
  does not provide a complete Dart buffering-event count. Evidence consists of UI
  checks, screenshot timestamps, downloader acknowledgements and native logs.

Evidence is in ignored build/phone_native_manual.log and build/phone_*.png.
This run did not reproduce the emulator's repeated buffering pattern. It is a
manual debug-build smoke test, not a profile-mode frame/audio benchmark or a
guarantee under poor connectivity. No app implementation changed for this check.
