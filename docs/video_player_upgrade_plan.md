# Shared video player upgrade

## Audit

- Hosted/private and offline lessons share `HostedLessonPlayer`, but expose only
  play/pause and an external seek slider. Transcript, downloads and checkpoint
  ownership already live there and must be preserved.
- External lessons use a separate player with minimal controls. Teacher preview
  has another minimal implementation. Legacy viewport/fullscreen code duplicates
  controllers, restarts video on fullscreen and includes simulated playback and
  nonfunctional quality choices. Several touched surfaces use `setState`.
- Existing `video_player` is the native playback engine. No replacement engine or
  new dependency is needed. Use Riverpod for new UI state and existing repositories
  for media authorization, signed URLs and offline access.

## Phase 1: Shared playback surface

Objective: consistent, restrained black video canvas, Inter controls and brand-blue
seek accents. Add play/pause/replay, +/-10s seek, buffered scrubbing, elapsed/total
time, speed choices, mute, captions when transcript data exists, contain/fit and
fullscreen. Include responsive sizing, accessible labels, focus/keyboard controls,
auto-hide while playing, buffering and short error/retry states.

Acceptance: no invented quality/CC/casting/PiP capabilities; caption content comes
from actual timestamped transcript segments. Slider seeks on release, not on every
pointer movement. Ended playback restarts deliberately rather than looping.

## Phase 2: Fullscreen and lifecycle

Dependency: shared surface. Add a typed GoRouter route carrying the existing
controller and transcript. Never create a second playback session. Restore default
orientation/system UI on exit, pause on background/inactive, and keep position,
speed and volume. Widgets must never dispose controllers owned by other layers.

Acceptance: back exits fullscreen, inline state is unchanged, unsupported restored
routes show a safe fallback, no playback continues after owner disposal.

## Phase 3: Integrate every entry point

Replace controls in hosted/offline, external student playback, teacher preview and
legacy mock viewport/fullscreen. Keep enrollment checks, offline-first playback,
answer syncing, required checkpoints, completion and downloads. Eliminate mock
fullscreen controller duplication. Refactor touched external-player state out of
`setState`; bound widget rebuilds so native playback ticks don't rebuild pages.

Acceptance: existing workflow behavior retained, no sample videos in live mode,
locked lessons cannot start, portrait content is letterboxed without distortion.

## Phase 4: Verification

Use a controller test double for deterministic control, seek, end, speed, captions,
buffering, lifecycle and shared-fullscreen tests. Exercise narrow phone, tablet
and fullscreen layouts. Run existing lesson/offline/teacher regressions and scoped
analysis; build Android. Native audio/codec, rotation, signed URL expiry and iOS
must also be checked on real devices; Windows cannot validate iOS playback.

Risks: async controller disposal, concurrent fullscreen/inline UI, seeks across
checkpoints, platform rotation restrictions and network failure. Preserve the
existing checkpoint owner while sharing only rendering/transport controls.

References: https://docs.flutter.dev/cookbook/plugins/play-video and
https://pub.dev/packages/video_player. Hardware features beyond that engine's
current capability are not represented by cosmetic controls.

## Delivery and verification

All four implementation phases are complete. Hosted, offline, external and teacher
preview entry points now use the same controls. The obsolete fullscreen player is
removed. Fullscreen retains the owner's controller, captions, speed and position;
the media repository and checkpoint/download ownership remain unchanged.

- 27 focused widget/unit and existing workflow regression tests passed.
- Scoped analysis of 19 affected source/test files passed without issues.
- Android debug APK builds successfully; existing Gradle/AGP/Kotlin deprecation
  notices are outside this change.
- Control layouts exercised at 320, 600 and 1024 logical pixels; narrow-phone
  screenshot reviewed. Controller doubles validate transport behavior, not native
  video decoding or actual network delivery.
- No additional packages, credentials or backend configuration required.

### Native manual acceptance checklist

- Stream a private enrolled lesson, play an in-app download offline, and open a
  teacher preview. Confirm audio/video, seeking, buffering and retry on reconnect.
- Enter/exit fullscreen using the button and system back. Confirm position, speed,
  captions, orientation and system bars are retained/restored appropriately.
- Trigger a required checkpoint in fullscreen and after seeking past its timestamp;
  submit, resume, and verify offline answers still sync on reconnection.
- Background/foreground the app and switch lessons rapidly; confirm playback pauses
  without orphaned audio or an old lesson's position affecting the new lesson.
- Test long/portrait videos, Urdu captions, large accessibility text, long titles,
  expired signed URLs and a lost enrollment on Android and iOS.

Native playback, codecs and device rotation are not claimed as verified by widget
tests. iOS acceptance requires a Mac/iPhone; it cannot be completed on Windows.

## Follow-up: Portrait controls and quality (2026-10-20)

- Fit/fill is visible only in landscape. Portrait always uses contain, even when
  fill was previously selected in landscape; fullscreen remains available.
- The quality menu reports the single source's actual short-edge resolution as
  Original. Selecting it preserves playback; it does not transcode the file.
- Multi-resolution switching remains unavailable: the upload pipeline stores one
  compressed file, and `lesson_media` has no encoded renditions/stream manifest.
  Real lower-resolution choices require an encoding worker/service, protected
  variant storage, and player switching that retains position and checkpoints.
  Offline playback can offer only renditions actually downloaded. Do not add
  fabricated 360p/720p/1080p or Auto choices to single-source lessons.

## Speed-change reliability (2026-10-20)

- Rate changes are guarded per native controller, shared with fullscreen. Repeated
  taps cannot overlap native speed requests, and reselecting the current rate is
  a no-op. No seek/play/pause is used to apply the speed.
- The legacy bridge no longer echoes native playback feedback or unrelated state
  updates as transport commands. Mandatory checkpoint pauses remain supported.
- 29 focused playback/resume/autoplay tests passed. The running Android emulator's
  real teacher preview was exercised at changed rates; ten runtime samples at
  1.75x showed playing=true and buffering=false. Android AudioTrack timing/underrun
  warnings were also observed; this does not establish stutter-free decoding or
  prove the originally reported native symptom is fully eliminated.
- `tool/test_video_speed_runtime.ps1` samples only playback fields from a local
  Flutter VM service. Pass its current local URL at runtime; never commit that URL
  or use the tool to inspect authentication/session objects.
