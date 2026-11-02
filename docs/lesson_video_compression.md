# Lesson video compression

## Decision and research

Uploads prepare video on-device before reserving Supabase storage.
The compatibility-first profile is H.264/MP4, up to 1280x720 landscape or
720x1280 portrait. Oversized sources use duration-based size budgeting as detailed
below; other transcodes use a 2.5 Mbps ceiling capped by reported source bitrate.
Audio is retained, with a requested AAC bitrate of 192 kbps on iOS;
Android uses its encoder's default audio bitrate. The requested 30 fps cap is
honored on iOS; the plugin retains source frame rate on Android.
No trimming, upscaling, or audio stripping is used.
This is a practical mobile lecture profile, not a claim that one codec is best
for every video. Slide legibility should be reviewed with real teaching material.

Primary references:
- https://developer.android.com/media/media3/transformer
- https://pub.dev/packages/compress_video
- https://pub.dev/packages/flutter_compress
- https://pub.dev/packages/video_compress

`flutter_compress` 2.0.0 is pinned behind `LessonVideoPreparer`. It uses Media3
Transformer on Android and AVFoundation on Apple platforms, with per-job progress
and typed errors. It avoids adding an FFmpeg binary and fits the existing
Android toolchain. `compress_video` was also evaluated but declares AGP 9 and
Kotlin 2.3, beyond this project's current toolchain. This is a newer dependency:
physical-device encoder validation remains important. HEVC is deliberately not
requested for mixed-device playback. HDR compatibility depends on the native
encoder; tone mapping is not explicitly controlled by this adapter.

## Limits and recovery

### October 27 size-budget update

Sources above the upload limit now use a 23 MiB target with the plugin's 5%
container margin and a 192 kbps audio reservation. Target-size mode requests CBR
on Android when supported. Resolution caps follow available video bitrate:
720p at 1500 kbps or above, 480p at 500–1499, and 360p below 500.
Budgets below 250 kbps fail early with a split-lesson message. These thresholds
are product quality safeguards; slide readability still needs visual review.
Short clips use a smaller target to avoid wasting bitrate. Compatible H.264 MP4s
already within the size/resolution limits bypass re-encoding.

An oversized result gets one retry from the original at a 20 MiB target, then
the actual file size is validated before storage reservation. The original-file
fallback is disabled for target-size encoding. Estimates describe the budget,
not measured output; during transfer the card shows the actual output size.
Preparation cancellation reaches the native job, cleans partial output, and
prevents storage upload. Cancel is available during preparation; it disappears
when resumable transfer starts. No storage-limit or dependency changes are needed.

- Source selection: at most 250 MiB, bounded before hashing/encoding.
- Stored output: existing 25 MiB pilot limit, unchanged in Supabase.
- Videos still too large after the bounded retry receive a short error.
- Native no-savings results use the original file and MIME, subject to the same cap.
- Original files are never deleted. Compressed files stay in private application
  support storage, not the gallery.
- Validated output has a source SHA-256/profile-specific filename and a completion
  receipt with an output SHA-256. Retries reuse those exact bytes for resumable TUS.
- Partial/corrupt results are not reused. Duration and dimensions are checked
  before creating a completion receipt or making a storage reservation.
  The plugin's source metadata does not expose audio presence, so audio retention
  is configured but cannot be independently compared before/after in this adapter.
- Successful uploads remove their prepared output. Failed transfers retain it for
  retry. Abandoned preparations for other source files remain app-private until
  application data is cleared; automatic age-based cache eviction is not implemented.
- An account switch during preparation prevents upload under the new account.
- Only one native encode runs at a time, including across different lessons.
- Compression and upload progress are distinct. No new service credentials needed.

## Platform limitations and manual checks

Encoding is not a durable OS upload job. Keep the app open during preparation and
transfer. iOS may grant limited background execution but can interrupt an encode;
Android jobs are not opted into a new foreground service. Retry after interruption
or process termination. Completed preparation remains reusable when retained.

On Android and iOS check landscape/portrait, rotated MOV, H.264/HEVC input,
HDR input, WebM, silent video, Urdu speech, slide text, very short clips, files
above/below the stored cap, insufficient storage, backgrounding, account switching,
lost network during TUS, retry, successful transcript generation and offline playback.
Confirm no gallery entry appears. A native dependency requires a full rebuild,
not just hot reload. iOS must be built on macOS and physically validated there.

## Verification

Android debug APK build succeeds. Focused compression/upload recovery/model tests
and offline transfer regression tests pass. Scoped static analysis is clean.
Gradle dependency inspection confirms the existing video player resolves Media3
to 1.9.2; the compression plugin compiles against that resolved version. Its muxer
uses the no-argument factory, avoiding a duration-parameter interpretation issue.
No Android/iOS device was connected during implementation, so actual encoding,
quality, audio, orientation and playback still require native-device validation.
