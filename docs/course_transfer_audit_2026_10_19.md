# Course Upload and In-App Download Audit

Date: 2026-10-19. Rules: `memory/rules.md`.

## Scope

Traced course draft creation, cover upload, curriculum management, lesson-video upload,
transcription/review, publication guards, enrollment authorization, streaming, offline
storage, download management, app startup, and account switching. Existing test data
was retained. The 25 MB per-video pilot limit remains unchanged.

## Findings and corrections

| Finding | Correction |
| --- | --- |
| Each upload retry created a fresh reservation, preventing reuse of a prior TUS session. | Pending reservations persist privately and are reused only when the selected file has the same SHA-256 fingerprint. TUS caches are isolated by teacher and media version. |
| A completed upload with a lost finalization response could remain stuck as uploading. | Teachers can recover/finalize uploaded objects without uploading again. Already-finalized objects are recognized; failed/transcribing jobs can retry transcription. |
| Teacher media management had no video preview. | Added signed, private video preview with playback and retry before publication. |
| Multiple sheets could start the same lesson upload. | Repository-level guards prevent simultaneous uploads for the same teacher/lesson. |
| Replacing downloads overwrote media and deleted the previous manifest before committing. | Each attempt uses its own filename. A flushed temporary manifest replaces the previous manifest by rename. Old media is removed after commit. |
| Failed transfers could leave an unmanaged partial video. | Uncommitted attempts clean up their own files; completed background transfers retain a recovery record until their manifest is committed. |
| A process exit could leave a completed native transfer absent from Downloads. | On reopening the library, complete pending files are checked for size and authorization age before recovery. Partial transfers are never presented as saved lessons. |
| Corrupt metadata could contain unsafe paths or future authorization timestamps. | Lesson IDs and video filenames are validated; authorization must be within the preceding seven days. |
| Offline playback treated all PostgREST errors as network failures. | Only transport failures/timeouts use the saved copy. Server authorization errors remain errors. |
| Offline cold start depended on loading a profile from Supabase. | A restored session with valid local lessons can open Downloads after a transport failure or profile-load timeout. |
| Downloads did not refresh after saving/removing a lesson or changing accounts. | Shared Riverpod download state is invalidated after mutations and observes authentication changes. |
| No course-level download action existed. | Added sequential course-lesson downloads, Wi-Fi selection, progress, cancellation, failure counts, and retry that skips valid saved lessons. External-only lessons are explicitly reported as unavailable offline. |
| Download navigation bypassed central routes. | Downloads and offline playback now use signed-in `AppRoute`/GoRouter destinations. |

## Private storage contract

- Video destination: `BaseDirectory.applicationSupport`, subdirectory `lesson-videos/<user-id>`.
- Metadata and queued checkpoint answers are in the same account-private directory.
- A `.nomedia` marker provides an additional media-scanner exclusion.
- No download is copied to shared Downloads, MediaStore, Photos, or Gallery; no public storage permission or export action is added.
- Videos play through `VideoPlayerController.file` inside the app.
- Downloaded content is subject to the existing seven-day offline authorization window. Signing out/account switching purges other users' local media.
- Android/iOS private application storage is used; this is not a DRM implementation.

## Verification

- Hosted Supabase journey `1792405112525` passed: idempotent draft creation, invalid-draft rollback, cover upload, missing-cover/media publication rejection, attached-cover deletion protection, curriculum locking, private video upload, owner isolation, transcript-draft privacy, public catalog visibility, enrolled access, outsider/other-teacher denial, and answer-key privacy.
- Clearly named MEDIA TEST accounts and uploaded files from that check were retained.
- File-store tests cover replacement, traversal rejection, authorization expiry/future clocks, completed-transfer recovery, and rejection of partial/active/corrupt recovery records.
- Upload recovery tests cover fingerprint identity, already-finalized recovery, and retrying finalization.
- Batch-download tests cover saved-lesson skipping, external-only lessons, partial failure, and retry without redownloading successful lessons.
- Existing download-manager, media-model, lesson-player, course-cover and course-mapper regressions are included in the focused test run.
- Final focused Flutter regression: 22 tests passed, including batch cancellation and existing authentication route checks. Scoped static analysis reports no issues. Android debug APK compilation succeeds.
- No Android emulator/physical Android device was connected during this audit. Android native playback, background-transfer/process-kill behavior, low-storage UI, and file-picker interactions still require device acceptance. iOS device/build acceptance requires macOS and an iPhone.

## Manual device acceptance

1. Create a draft course; upload its cover and a supported video within 25 MB.
2. Interrupt an upload and select the identical video again. Confirm the pending reservation is reused. Select a different video with the same filename/size and confirm it cannot resume the old bytes.
3. Preview the uploaded video, review the transcript, publish the lesson, then publish the course. Confirm unfinished media blocks publication.
4. Enroll a student and download one lesson, then the complete course. Check progress, Wi-Fi waiting, cancellation, retry, and unavailable external lessons.
5. Verify the files are visible only in the app's Downloads screen and absent from Gallery/Photos/shared Downloads.
6. Open a saved lesson in airplane mode, including after closing/reopening the app. Confirm video and cached transcript/checkpoints load.
7. Interrupt a replacement or fill storage; verify the previously saved lesson is retained. Restart after a background download completes and verify recovery.
8. Remove a download and verify disk storage is reclaimed. Sign out/switch users and confirm prior-account downloads are inaccessible.
9. Revoke enrollment online and confirm playback is denied. Verify stale offline authorization requires reconnecting/downloading again.

## References

- [Supabase resumable upload contract](https://supabase.com/docs/guides/storage/uploads/resumable-uploads)
- [Downloader private base-directory API](https://pub.dev/documentation/background_downloader/9.5.9/background_downloader/BaseDirectory.html)

The hosted integration check uses the Storage object API; it does not certify native TUS resumption or mobile background execution. Those remain explicit device acceptance checks above.
