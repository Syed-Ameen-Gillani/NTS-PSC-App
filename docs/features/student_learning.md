# Student learning implementation and validation

Updated 25 October 2026. Source plan: [student learning audit](../student_learning_audit_2026_10_25.md). Followed `memory/rules.md`, feature repositories, Riverpod, and the existing GoRouter/theme infrastructure.

## Agreed behavior

- Every published lesson, every distinct linked quiz passed, and every distinct linked assignment approved are required for completion. Course/module/lesson placements count once per assessment instance; assessment copies in other courses retain separate attempts and submissions.
- Quiz retakes are unlimited in this release. Any passing saved attempt satisfies its requirement. Each attempt retains its configured threshold; the quiz list shows the most recent result, while eligibility checks all attempts.
- Rejected staff-reviewed assignments may be revised after feedback, including after the original deadline. First submissions still close at the deadline. Pending or approved submissions cannot be overwritten. Earlier responses, attachments and reviews remain available to the teacher.
- This adapts Coursera's assessment-specific retry behavior to CBOA's MCQ and teacher-reviewed assignments. It does not claim a universal Coursera attempt limit. References: [Coursera grades](https://www.coursera.support/s/article/learner-000001563?language=en_US), [private-course assignments](https://www.coursera.support/s/article/learner-000001109?language=en_US).
- An earned completion is permanent. Later curriculum changes do not rewrite the earned name, course, instructor or completion date. Enrollment access remains `active`; `course_completions` is the achievement record, `enrollments.completed_at` is reconciled, and the teacher roster reports the completed outcome. This preserves existing media/assessment access policies.
- Lesson completion synchronizes between devices. Playback position, speed, volume, captions and personal video notes retain the existing per-device/account/media-version storage. Timed graded quizzes need connectivity to save answers and finalize a result. Offline video checkpoints retain their existing separate queue.

## Phase delivery

| Phase | Implemented outcome | Evidence |
| --- | --- | --- |
| 0: baseline and policy | Linked migration history checked; isolated test identities used; policy decisions recorded | Dry-run migration inventory and disposable live fixtures |
| 1: truthful access/results | Atomic free enrollment, guarded lesson completion, teacher-configured historical pass thresholds, return to originating learning screen | SQL authorization/idempotency tests and quiz mapper tests |
| 2: lessons/offline | Reading lessons have no missing-video panel; private account-scoped completion outbox, pending state after reopen, replay at startup/resume/periodic sync; My Learning refresh | Offline queue tests, reading player and autoplay regressions |
| 3: quiz attempts | Server start/expiry, answer saves, immutable question/review snapshots, idempotent submission, retakes, exit confirmation, server deadline reconciliation on app resume | Session SQL and controller tests, including server expiry during submission |
| 4: assignments | Private text/file drafts, three 25 MB file limit retained, submission navigation lock, request-key recovery, no destructive cleanup after ambiguous commit, retained revisions and retry after rejection | Draft persistence tests, assignment workflow tests and live RPC assertions |
| 5: completion | Server evaluates all three requirements; immutable completion identity and snapshots; concurrent final events serialized; instructor roster agrees | Completion integration test includes missing/pending requirements and teacher readback |
| 6: certificate | Authenticated on-demand CBOA PDF, English/Urdu fonts bundled, private bucket, stable object/issuance identity, short-lived viewing URL, actual PDF viewer/save/share flow | Deno renderer tests, English/Urdu visual review, authenticated live PDF download and access rejection |
| 7: integration/UX | Real My Learning search, lessons versus assessment progress wording, retry/empty states, outcome refresh through Realtime and resume, Android debug build | Focused Flutter regressions, analysis and backend smoke; device checklist below remains open |

Certificate rendering is synchronous and retryable on demand rather than a separate background job. The screen shows preparing/error/retry states; the private stored artifact is reused after successful generation. Save/share is provided through the device PDF viewer. No public verification endpoint, accreditation claim or artificial signature was introduced.

## Backend and configuration

Applied to the linked project `rgpeouxesbemysmwbzmu`:

`20261026000000_learning_integrity.sql` through `20261026090000_quiz_session_status.sql` (ten migrations). The additional concurrency migration keeps quiz parent/session lock ordering consistent and serializes completion evaluation after concurrent requirement events.

Deployed function: `course-certificate` with user authentication. It reads the caller's completion, uses its service client only after ownership validation, and stores `student-id/completion-id.pdf` in private `course-certificates` storage. URLs expire after five minutes and are refreshed before opening. No client Storage write/read policy exposes this bucket. Built-in Edge Function variables `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are reused. No new credentials or Flutter dependencies are required.

Quiz sessions, snapshots and assignment request receipts have no direct authenticated table access. Answer keys are omitted from start/resume responses. Reviews are scoped to the attempt owner. Legacy attempts keep their existing review path; new attempts use durable snapshots. Completion writes go through guarded RPCs; direct lesson-progress column writes were revoked. Realtime publishes only tables with existing scoped SELECT policies.

Assignment drafts are under application-support `assignment-drafts/user-id/assignment-id`; offline progress is under private `lesson-videos/user-id`. Neither goes to Gallery. Draft manifests commit after file bytes, and file hashes detect damage. Draft files remain local to their account until a successful submission clears them. Ambiguous server commits retain uploaded files for reconciliation; failed pre-submit uploads are cleaned up. Orphan files from prolonged ambiguous network failures may require storage maintenance; never delete attachments merely because a response was lost.

Use versioned migrations as the schema source. `docs/supabase_schema.sql` remains an explicitly marked historical prototype.

## Verification performed

- Flutter analysis of affected feature/repository/router/app code: clean.
- All 57 focused Flutter regressions passed. A further host-run navigation smoke passed for exit confirmation, answer saves, quiz results and returning to the originating screen (58 checks total). These cover drafts, account isolation, replay, quiz saves/submission recovery, configured thresholds, lesson/reading/autoplay behavior, curriculum visibility, teacher roster state, real course preview data and unchanged video controls.
- SQL integration checks ran in rolled-back transactions: enrollment idempotency, all completion requirements, pending assignment behavior, stable completion, teacher/student agreement, session resume, hidden keys, scoring, retakes, repeated submission, ownership, assignment revisions and approved-write protection.
- The older standalone teacher-roster SQL script required unavailable specifically named retained fixtures. Teacher-roster readback is instead asserted by the new self-contained completion test; its Flutter controller tests were also run.
- `deno check` of `course-certificate/index.ts` and two renderer tests passed. English and Urdu previews were rendered to images and visually checked for alignment and clipping. Noto's SIL license is included beside its bundled font data; the Latin font is the existing app Inter font.
- `tool/test_student_learning_live.ps1` passed against deployed Auth, RPC, Storage and Edge Function APIs. It created isolated teacher/student accounts, executed enrollment through final approval, downloaded a genuine PDF, confirmed stable certificate identity, rejected ineligible/cross-account calls, and removed its accounts, course, uploads and certificate.
- Android debug APK build passed. Existing Gradle/AGP/Kotlin upcoming-support warnings were observed; upgrading the Android toolchain is outside this feature scope.

The source test fixtures use synthetic lesson URLs only for database authorization/completion checks. This does not prove real streaming, background timing, native PDF handling or physical-device performance.

## Remaining device/release checks

The Pixel 5 AVD was running on `emulator-5554`. The requested `emulator-5556` was unavailable, and an isolated read-only launch on that port was rejected by the emulator's existing-instance lock. The running device was preserved. `integration_test/student_learning_smoke_test.dart` is ready for `flutter test integration_test/student_learning_smoke_test.dart -d emulator-5556` when that port is available; the shared flow passed on the host widget runner. No iOS simulator/device is available on this Windows host. These are acceptance gates, not completed native tests:

1. On Pixel 5, enroll in a real published course and confirm lesson-only completion stays ongoing until its assessments pass/are approved.
2. Change quiz answers, background and sleep the phone, kill/reopen the app, resume the same session, then verify the authoritative deadline, result and retry.
3. Submit actual text and up to three files, interrupt connectivity, reopen the draft, retry, reject and revise after the deadline. Verify teacher history and no duplicate committed revision.
4. Download and play a real lesson, enter airplane mode, mark complete, restart and confirm the pending label. Reconnect and verify confirmed progress on another device. Check revoked access/account switching.
5. Approve the final assignment on the teacher account; verify student refresh/Realtime completion and instructor roster agreement. Open the certificate in Android/iOS PDF viewers, save/share the actual PDF, and verify that another account cannot request it.
6. Check 320/390/tablet widths, large text, loading/error states, back navigation and the existing player controls on both platforms. Timed quizzes must not accept new answers after server expiry.

For future deployments, run the focused tests, `supabase db push --linked --dry-run`, apply reviewed migrations, deploy `course-certificate`, then rerun the isolated live smoke. Do not roll back by deleting attempts or completions. Roll back incompatible client behavior with a compatible application release; preserve durable learning history.
