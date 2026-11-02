# Learning player follow-up

## Scope and constraints

Target Coursera-style learning behavior, not a claim of identical proprietary
code, UI or unmeasured performance. Preserve current enrollment, checkpoint and
private-download security. No production backend or credentials are changed.

## Prioritized implementation

1. Fix the attached course-detail sliver geometry exception. Freeze each tab
   delegate's extent, constrain its child to that extent, and rebuild the delegate
   when tabs or geometry change. Regression: scrolling and rotation at fractional
   extents must not produce invalid SliverGeometry.
2. Persist lesson position and playback preferences in app-private storage, scoped
   to account, lesson and video revision. Restore only valid bounded positions;
   completed videos restart at zero. Serialize writes, save on pause/exit and
   throttle while playing. Disk failure must never prevent video playback.
3. Replace the fixed transcript block with searchable, timestamped transcript and
   personal notes. Notes are real user-entered data, private to this device/account,
   editable and removable, with timestamp seek. Validate malformed segments.
4. Improve captions and keyboard controls without duplicating playback sessions.
   Preserve full caption text instead of silently truncating it; keep controls
   readable at phone/tablet sizes. On video end, save completion after required
   checks. Offer opt-in autoplay; do not advance into locked lessons or when
   completion cannot be saved. Leave fullscreen safely before changing controllers.
5. Verify storage isolation, restoration, notes, transcript filtering, rotation,
   playback controls and existing lesson/download workflows. Run scoped analysis
   and Android build. Native performance and iOS remain separate device QA.

## Explicit remaining platform work

- Adaptive/multi-quality video requires a real encoding worker or managed video
  service, secured rendition/manifest storage and player integration. One MP4 is
  not a selectable quality ladder. No fake quality levels will be added.
- Device-local resume/notes are not cross-device synchronization. Server-backed
  sync requires schema/RLS, conflict handling, account-deletion policy and an
  offline queue, and must be verified before claiming parity.
- Casting, PiP and translated subtitle tracks remain unimplemented. The new
  completion/autoplay behavior requires native-device acceptance, including the
  fullscreen and offline/network-failure cases. Manual completion and server-side
  checkpoint enforcement are existing separate behavior, not a new security claim.
- Exact visual parity needs a current reference for Coursera's Android/iOS
  experience. Performance parity requires profile/release benchmarks, not debug
  emulator logs or controller doubles.

The attached bufferpool lines are Android decoder diagnostics. The actionable
Flutter exception is the course-details NestedScrollView/header geometry error;
the skipped-frames warning alone does not establish a decoder failure or leak.

## Delivered and verified

- Pinned course-detail tabs now use immutable extents, an exactly constrained
  child and correct delegate invalidation. A NestedScrollView regression covers
  fractional scroll offsets, tab switching and portrait/landscape return.
- Authenticated hosted/offline and external student videos restore device-local
  position, speed and captions, with separate account/lesson/media-revision keys.
  Completed or out-of-bounds saved positions restart at zero. Resume metadata
  writes are throttled and serialized; disposal writes merge with durable notes.
- Transcript search supports Unicode text and rejects malformed timestamp rows.
  Personal notes support timestamp seek, add, edit and delete inline. Save failure
  retains the draft. Nothing is populated with dummy notes or transcripts.
- Captions no longer silently ellipsize after three lines; long captions are
  scrollable in a bounded region. Transport touch targets are at least 44 logical
  pixels. Mute and caption keyboard shortcuts are added.
- Video end saves completion. Optional autoplay advances only to the immediate
  unlocked next lesson after a successful completion save. Hosted end handling
  resolves unanswered checks first; fullscreen exits before controller replacement.
- 46 targeted/regression tests pass, including account/revision isolation,
  concurrent writes, disk failure, notes, restore, transcript search, fullscreen
  autoplay, disabled/locked/save-failure autoplay, offline storage/downloads,
  teacher publishing and shared control layouts. Controller doubles do not test
  actual codecs, audio delivery or native frame performance.
- Scoped analysis is clean. Android debug APK builds successfully. No credentials,
  new dependencies or production schema/configuration were changed.

### Manual acceptance still required

1. Replay the reported course-details scroll/fullscreen-return sequence on the
   actual emulator/device; the exact original Flutter exception was not reproduced
   on that device in this change.
2. Verify saved timestamps after real playback, app backgrounding, process death,
   logout/account switching and a replaced video. The last few seconds may be
   lost after a hard kill because saves are throttled.
3. Confirm Urdu caption/transcript readability, keyboard/screen-reader behavior,
   and long captions/notes under large accessibility text on Android and iOS.
4. Test required checkpoints at the final timestamp and after seeks, including
   offline answers and reconnection. Completion save failure must not advance.
5. Profile startup, seek latency, frame timing, buffering, memory and battery on
   representative hardware/release builds before making performance comparisons.

References: [Flutter header geometry](https://api.flutter.dev/flutter/widgets/SliverPersistentHeaderDelegate/minExtent.html),
[delegate rebuilding](https://api.flutter.dev/flutter/widgets/SliverPersistentHeaderDelegate/shouldRebuild.html),
[Coursera transcript/notes behavior](https://blog.coursera.org/new-mobile-features-transcripts-notes-reminders/).

## Configuration-free refinement

Per the user's decision, managed encoding and self-hosted workers are deferred.
No new services, secrets, deployment steps or packages are introduced.

- Device-local lesson preferences now also retain volume, including muted state.
  Older saved files default safely to full player volume. Unmute restores the
  last audible level within the shared inline/fullscreen session, and keyboard
  up/down adjusts volume in bounded increments.
- Buffering reveals and retains controls until playback recovers; buffering
  events during scrubbing do not discard the prior play/pause intent.
- Shared native-video initialization times out after 30 seconds and begins
  teardown without blocking the retry state. Hosted lookup, checkpoint access,
  signed URL requests and teacher preview signing also have bounded waits. These
  are per-operation timeouts, not a 30-second total startup guarantee.
- Deleting a personal note offers Undo without a confirmation dialog. Restoration
  retains its original timestamp and identifier and is scoped to the same account.
- Backend-dependent multi-quality choices remain unavailable rather than showing
  fictitious resolutions. Cloud synchronization, casting/PiP and performance
  parity remain outside this refinement.

Verification: 52 targeted/regression tests passed; scoped analysis of 17 affected
source/test files is clean; Android debug APK builds successfully. Existing native
device/iOS acceptance and release-performance checks remain necessary.
