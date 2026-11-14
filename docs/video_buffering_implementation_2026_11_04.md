# Video buffering implementation — 4 November 2026

## Implemented

- Buffering no longer automatically reveals playback controls. A white circular
  indicator appears after 300 ms of continuous buffering while playback is
  requested. Brief stalls, deliberate pauses and ended videos do not display it.
- A tap still reveals controls, which can auto-hide during buffering. Native
  temporary not-playing states are distinguished from the learner's pause intent.
- After 15 seconds, a persistent stall offers connection guidance and an explicit
  retry. Recovery clears this state; ordinary buffering never recreates the player.
- Timers are cancelled on source replacement, backgrounding and disposal.
- Hosted retry captures position, speed, volume, captions and playback intent,
  revalidates access and fetches a new signed URL through the existing repository.
  Study restoration uses this snapshot instead of an older disk checkpoint.
- Removed the redundant hosted-player rebuild on each playback second. The
  existing player/controller listeners continue rendering position and controls.
- Added transition-only `CBOA.VideoPlayback` diagnostics: initialization,
  observable first playing position, buffering start/end/duration, buffer ahead,
  speed changes, native error occurrence and a session summary. They contain no
  media URLs, tokens or account information. Enabled in debug/profile; release
  requires `--dart-define=VIDEO_DIAGNOSTICS=true`.
- Existing evidence sampling, completion thresholds and durable replay remain.
  Repeated accepted-evidence lines correspond to individual queued samples; the
  log alone did not establish duplicate submission of the same sequence.

## Verification

- 42 focused automated tests passed across player controls, buffering, retry
  restoration, diagnostics, speed changes, initialization and evidence sampling.
- Native video and PDF integration tests passed on RMX5377 (Android 16).
  The first build hit a transient Google Maven DNS error; the rerun succeeded.
- Analyzer passed for the modified playback implementation and profile harness.
- Read-only delivery probe sampled one ready Supabase video using local admin
  credentials. No database records or stored media were modified. This checks
  delivery, not student RLS or enrollment authorization.
- The sampled 3,884,715-byte MP4 returned HTTP 206 and `video/mp4` for
  `Range: bytes=0-65535`. Two probes took approximately 1.0–1.33 seconds to
  receive response headers. These are desktop spot checks, not phone throughput
  benchmarks. The response did not expose a Cache-Control header.
- The sampled MP4 has `mdat` before `moov`. Range support lets a native player
  retrieve the trailing metadata, but this layout can add startup requests.
  This does not establish the cause of every buffering event.
- A second, larger ready upload (21,173,292 bytes) also returned HTTP 206 and
  `video/mp4`, and had `moov` before `mdat`. Metadata placement varies by upload.
- Profile-mode network playback passed on RMX5377 using this larger 4:24 video
  at 848×480. Native initialization took 6,296 ms; the first observed playing
  position arrived at 6,900 ms from controller attachment. Startup latency is
  still material and must not be described as solved.
- The approximately 22-second playback exercise recorded two buffering events
  coincident with explicit seeks (2,611 ms and 1,713 ms). No separate unprompted
  mid-playback stall was observed in this short sample. This does not establish
  reliability for a whole course or under poor connectivity.
- Captured timeline UI `Frame` events: 57, average 9.41 ms, p95 18.26 ms,
  maximum 19.38 ms. Raster draw events: 56, average 5.93 ms, p95 7.78 ms,
  maximum 9.28 ms. These are timeline event durations, not native decoder
  dropped-frame counts or an end-to-end screen benchmark. The harness isolates
  the player; it does not include real enrollment/progress/backend calls.
- Safe aggregates are in `build/video_playback_profile_summary.json`. The first
  profile attempt needed `--no-dds` for timeline capture. A short-file fixture
  assertion was corrected to restart playback before the rate-change stage.

## Repeatable device profiling

`tool/probe_video_delivery.py` performs a bounded 64 KB delivery probe. It reads
local environment credentials and prints only metrics. Optional
`--profile-config` writes a short-lived signed URL to ignored build output:

```powershell
python tool/probe_video_delivery.py --profile-config
flutter drive --profile --no-dds -d 3C766Q003DS00000 --driver=test_driver/video_playback_profile.dart --target=integration_test/video_playback_profile_test.dart --dart-define-from-file=build/video_profile_config.json
Remove-Item -LiteralPath build/video_profile_config.json
```

The harness exercises playback, 2x speed and seeking using the existing player.
Without a URL define it uses the bundled video fixture. Reports are written by
the integration-test driver under build output. Native initialization time and
the first observed playing position are proxies, not exact native first-frame
timestamps. Protect raw build logs: Gradle can echo encoded Dart defines.

## Remaining delivery and field validation

- Validate slow-network, disconnected/reconnected, long-paused URL expiry,
  fullscreen and background/resume behavior in actual student sessions.
- Measure several real videos and networks before setting latency targets or
  changing native buffering configuration. No before/after phone baseline was
  available from the earlier emulator logs.
- Consider lossless MP4 fast-start remuxing for future uploads after native
  compressor support is established. Do not silently re-encode or rewrite
  existing published videos to change metadata placement.
- Adaptive bitrate requires actual encoded variants and a manifest. The current
  single-file source cannot provide YouTube-like adaptive quality by changing
  client controls. No encoding service or new package was introduced.

## Rollback

Changes are confined to playback presentation, diagnostics and retry restoration,
plus test/probe tooling. There are no schema changes or data migrations. Revert
these individual hunks to roll back; preserve pre-existing worktree changes.
