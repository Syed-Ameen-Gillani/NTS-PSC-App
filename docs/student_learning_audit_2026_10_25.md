# Student learning journey: audit and implementation plan

Date: 25 October 2026. Status: approved core implementation deployed and verified through authenticated backend/PDF checks. Android build and focused regressions are verified; device acceptance remains open. See [implementation and validation record](features/student_learning.md). Findings below preserve the original pre-implementation audit.

## Scope and evidence limits

Reviewed the student enrollment, course repository/mapping, online/offline player, curriculum resources, quiz repository/attempt/results, assignment repository/submission/review, routing, instructor insights, certificate widget, and related local SQL migrations. Followed `memory/rules.md`: Riverpod state, feature-first boundaries, repository-owned API calls, centralized routes, existing theme and responsive tokens.

This is a source and local migration audit, not a live deployment certification. No production records were changed, tests were executed, device sessions exercised, or hosted database migration/policy inventory inspected in this audit. Existing test files provide coverage candidates, not proof that the hosted system works. Statements about backend behavior describe the checked-in SQL; deployment parity must be verified in Phase 0. Prior conversation claims of live setup are not evidence of current deployed state.

Overall assessment: enrollment, media, assessment persistence, and private document storage have substantial real implementations. The complete enrollment-to-certificate journey is not production-ready. The largest gaps are authoritative completion, resumable/retry-safe attempts, consistent scope/navigation, and certificate issuance.

## Current journey and findings

### Enrollment and access

**Implemented:** `SupabaseCourseRepository.enrollInCourse` reads course status/price and inserts an enrollment for a signed-in student. `20261009000000_foundation.sql` restricts free enrollment insertion to the current student and a published free course. Paid enrollment is explicitly unavailable in `course_enroll_modal.dart`; retain that boundary because payment integration was deferred.

**E1 — P1: repeat/concurrent enrollment is not a robust transaction.** Client performs select-then-insert. Two requests can race; repository returns true only for an existing `active` enrollment, while its course loader recognizes both `active` and `completed`. Use an idempotent server enrollment operation with explicit handling for active, completed and cancelled states. Do not silently reactivate cancelled access.

**E2 — P0 dependency: completed access is inconsistent.** `can_access_lesson_media` in `20261010120000_lesson_media.sql`, `can_access_curriculum` in `20261020000000_curriculum_materials.sql`, quiz submission, assignment submission and lesson progress writes require active enrollment. Course loading and instructor count/roster SQL also recognize completed enrollment. Before adding a completed-state transition, define continued content/review access and audit every RLS/storage/RPC predicate. Otherwise completion can remove the learner's access to earned content. This is a latent integration bug, not a claim that completion currently transitions automatically.

### Lessons, reading and progress

**Implemented:** production `LessonPlayerScreen` selects `LiveLessonPlayerScreen`; hosted video retrieves authorized media/signed URLs, supports local playback fallback and real checkpoints. Notes and curriculum resource routes exist. Teacher preview has explicit restrictions on progress controls.

**L1 — P0: completion is a client-side lesson ratio.** `_loadCourses` in `supabase_course_repository.dart` derives progress from lesson IDs with non-null `completed_at`. `my_learning_controller.dart` classifies progress >= 1 as completed. No certificate eligibility or assessment requirements participate. No authoritative course-completion evaluator/issuance flow was found in repository-wide completion/certificate searches.

**L2 — P1: checkmarks are not evidence of watching/passing.** `updateLessonProgress` writes a client timestamp; RLS verifies enrollment/course membership but lets the learner mark completion. The live player allows manual completion and completes on video end. This can be valid for self-paced learning, but it must be described as lesson completion, not verified assessment mastery. Define requirements explicitly before certificates.

**L3 — P1: progress mutation and freshness gaps.** Progress uses select-then-insert/update, rather than an atomic upsert/RPC. My Learning is invalidated after completion, but Home's course list is not invalidated there. The live player also holds an incoming course snapshot plus local completed IDs. Verify return navigation, refresh and another-device edits; centralize progress updates and invalidation.

**L4 — P1: resume and offline completion are incomplete across devices.** `video_study_repository.dart` stores account/source-scoped playback position, speed and notes in app-private files. No use of server `resume_seconds`/`watched_seconds` was found in the learning flow. `offline_lesson_library.dart` queues checkpoint answers; it is not a lesson-completion queue. `OfflineLessonScreen` hosts the player without the online completion callback. Watching a download therefore cannot be treated as confirmed course progress synchronization.

**L5 — P2: reading lessons inherit video-centric presentation.** `LiveLessonPlayerScreen` displays “No video attached” for a legitimate reading-only lesson before showing notes/resources. Render a reading state with notes and files as the primary content. Preserve the existing video player and controls.

**L6 — P1: mutable curriculum has no completion-version policy.** Progress denominator follows current lessons. Adding/removing lessons can change a learner's percentage, including after apparent completion. Specify how published content changes affect existing learners and issued certificates; retain issuance history.

### Assessment discovery and scope

**Implemented:** `curriculum_assessment_links` supports course/module/lesson placement. Cross-course reuse creates separate assessment instances in `20261025000000_reuse_assessments_across_courses.sql`, preserving course-specific attempts/submissions. Direct summary and inherited-visible providers intentionally have different meanings.

**S1 — P1: scope must be explicit throughout the student journey.** Lesson, module and course resource routes/providers have different scopes. The student module action passes a module scope and the repository's exact-scope query excludes lesson links. It must not imply an aggregate of every lesson's attachments. Verify every lesson-only quiz/assignment remains discoverable through its lesson resources, and add a scope label to inherited assessments. Keep direct lesson summaries limited to that lesson. Do not repair historical links by guessing which lesson was intended.

**S2 — P1: stable destination and return context.** ID query routes exist for notifications and attempt review; many ordinary routes still pass model objects in `extra`. Quiz-result Close routes to Main, losing the originating course/lesson. Plan stable IDs plus loading/authorization gates and a return destination. Verify cold start, login redirect, resource removal, revoked enrollment and teacher-preview routes separately.

### Quizzes

**Implemented:** answer keys are separate from student-visible questions; `submit_quiz` scores on the server and checks student enrollment. `get_quiz_attempt_review` restricts review to the attempt owner. Result/review screens can reload saved attempts by ID.

**Q1 — P0: incorrect pass/fail label.** `quiz_completed_screen.dart` uses `percentage >= 60`; teachers can configure a different `passing_score`. Review/submission result payloads do not include that threshold or an authoritative passed flag. Return the threshold and pass outcome from the server, store the policy used for the attempt, and render it consistently.

**Q2 — P1: no persistent in-progress attempt/timer.** `active_quiz_screen.dart` keeps answers and remaining time in local widget state with a periodic timer. Leaving/restarting loses answers and resets timing; lifecycle suspension is not measured against a server deadline. `submit_quiz` creates an attempt only at final submission. Implement durable attempt start, answers and expiry if quizzes are timed.

**Q3 — P1: retry after ambiguous submission is not recoverable.** Server rejects any second submission for the same quiz/student. If the first request commits but its response is lost, retry receives “already submitted” rather than the saved result. Introduce an idempotent attempt identifier and recover the committed result. Do not just allow repeated inserts.

**Q4 — P1: one attempt can permanently block a required quiz.** Current server permits one submitted attempt. There is no explicit retake policy tied to course completion. Decide practice versus required assessment behavior, allowable retries and which result qualifies before enforcing assessment completion.

**Q5 — P1/P2: lifecycle and error UX.** Submission cancels the timer before the request; failure does not restore a running timer. No durable draft or explicit leave guard is present. An empty supplied quiz can reach a loading indicator indefinitely. Add unavailable/empty/retry states and submission navigation protection using Riverpod. Existing `setState` usage violates project rules.

### Assignments

**Implemented:** text and/or files, assignment instructions and optional external link, teacher brief attachments, private submission bucket, signed URLs, server submission validation, pending/approved/disapproved review, feedback and retained revisions. Student files are limited to three, each 25 MB. Server deadline and active enrollment checks exist. These are real persistence paths, not merely mock cards.

**A1 — P1: review/revision deadline dead end.** `submit_assignment` rejects submissions at/after `due_at` including revisions. A teacher can reject after the deadline, leaving the student unable to resubmit. Define a revision window or explicit extension and explain it in the UI. No unrestricted late submission is proposed.

**A2 — P1: unknown submission outcome and upload recovery.** Client uploads files before calling the RPC. If the response is lost after commit, local `committed` is still false and cleanup is attempted; storage policy may prevent deletion of retained files, but the client still reports failure. Introduce a submission request ID and query/reconcile outcome before cleanup or retry. Test that committed attachments can never be removed by retry cleanup.

**A3 — P1: draft and in-flight UX.** Response/file selection is transient; `_saving` is a plain boolean and no page-wide PopScope/AbsorbPointer is present. Add durable local drafts as appropriate, visible busy state, disable conflicting actions, and protect navigation during submission. File errors should preserve selected valid data.

**A4 — P2: deadlines lack useful precision.** Student page displays a medium date while acceptance uses an exact timestamp. Show local date, time and timezone; use server outcome at the boundary and provide specific deadline/access errors instead of generic submission failure.

**A5 — P1 policy: grading is approval-based.** Current review is approve/reject with feedback, not a numeric grade/rubric. This is acceptable for the existing product if completion requires approval; do not describe it as scored grading or add a grading system without need. Teacher-side submission mapping uses generic “Student” for other users; provide an authorized display-name mapping for reliable review identity.

### Completion, instructor consistency and certificates

**C1 — P0: no shared authoritative completion record.** Student Completed classification derives from lesson percentage, while instructor roster reports enrollment status from the backend. These can disagree. Neither quiz result nor assignment approval currently drives a course eligibility evaluation.

**C2 — P0: certificates are not implemented end-to-end.** `course_certificate_dialog.dart` has a fixed September 19, 2026 date, name-hash ID, outdated academy branding and “VERIFIED” label. Download/share only show success toasts. Repository-wide search found no call site outside its declaration, issuance table, generator, verification endpoint or certificate route. Treat this as dormant placeholder code, not a working live certificate feature. Do not expose it as production functionality.

**C3 — P1: current model does not define required vs optional assessments.** Establish a published completion policy and distinguish formative video checkpoints from course assessments. A proposed default is completed required lessons + passed required quizzes + approved required assignments; approval is required before applying this to existing courses. Do not assume every inherited placement is a distinct requirement: repeated placement of the same assessment within one course should count once unless explicitly modeled otherwise.

### UI, state management and operational readiness

**U1 — P2: My Learning search is decorative.** `CustomSearchBar` renders an icon and Text, with no input/controller/callback; My Learning uses it directly. Implement real filtering with appropriate empty results or remove the affordance until functional.

**U2 — P2: retry/navigation/theming inconsistency.** My Learning and quiz result errors contain text without retry actions. Various student screens hardcode white surfaces. Apply existing theme tokens, concise errors, retry controls and meaningful loading/empty states. Avoid a wholesale redesign.

**U3 — P2: architecture violations.** Active quiz mutates widget state using `setState`; several curriculum/assignment/student files exceed the file-size rule and mix orchestration with rendering. Refactor touched features into controllers/components as their behavior is corrected, rather than an unrelated repository-wide cleanup.

**U4 — P1 validation: dummy code must be classified by reachability.** Mock repositories and the legacy lesson playback controller contain fixtures, simulated progress and fixed checkpoints. The production lesson entry switches to the live player. Their existence alone does not prove live data leakage. Verify production configuration and all route entry points. Public course mapping also supplies zero rating/enrollment counts; teacher counts are separately hydrated. Display unknown public metrics as unavailable or load authoritative values, rather than presenting default zeros as measured results.

**U5 — P1 integration: deployed configuration remains unverified.** Local SQL, FCM/checkpoint plumbing and storage code cannot prove hosted policies, buckets, Edge Functions or notification dispatch are current. Test notification-to-resource navigation and permission denial without making delivery a prerequisite for viewing feedback in-app.

## Prioritized implementation phases

### Phase 0 — Baseline and decisions (P0)

Objective: establish a reproducible current state and agree completion semantics before changing learner outcomes.

Components: migration inventory, RLS/storage policies, configuration, seed fixtures, this audit.

Work: compare local/hosted migrations read-only; inventory function versions, grants and bucket policies; prepare isolated teacher/student fixtures with a video lesson, reading lesson, direct/module/course assessments and a cross-course reuse. Confirm required/optional policy, retakes, rejected-after-deadline behavior, completed-user content access and curriculum versioning.

Acceptance: an evidence table maps every step to route, repository, server operation, policy and expected state; deployment differences are recorded; policy choices have explicit defaults/approval. No migration infers historical assessment placement.

Dependencies: access to the intended Supabase project and test identities. Risk: running mutable checks against real learner data; isolate fixtures and never use service-role access to simulate a student authorization test.

### Phase 1 — Access, scope and truthful outcomes (P0/P1)

Components: course/curriculum/quiz repositories, RLS/RPCs, result DTO/UI, router, learning providers.

Work: server pass/fail and threshold snapshot; atomic idempotent enrollment; consistent completed access; direct versus inherited attachment labels and navigation; explicit missing/locked/empty states; stable course/lesson/assessment IDs and return destinations. Reconcile all caches after link/unlink/progress updates.

Acceptance: configured 80% threshold fails a 70% result everywhere; repeated enrollment gives the same enrollment; unenrolled/revoked students cannot read protected content; completed learners retain agreed access; every direct lesson assessment is discoverable only under its correct lesson summary; course links do not appear as direct lesson links.

Dependencies: Phase 0 access decisions. Risk: changing RLS can accidentally widen access; SQL authorization tests must run as real scoped roles.

### Phase 2 — Reliable lesson and offline progress (P1)

Components: learning repositories/controllers, live/offline player integration, Home/My Learning refresh, progress RPCs.

Work: authoritative progress mutation with idempotency, course membership checks, timestamps and bounded positions; local completion outbox and reconnection reconciliation; account isolation; durable server resume if cross-device resume is intended; reading-specific content layout. Preserve playback controls.

Acceptance: repeated completion writes count once; another device sees confirmed progress; offline completion remains visibly pending until accepted; logout does not sync events to another account; removed lessons/media revisions follow the agreed policy; reading content has no video-error panel.

Dependencies: Phase 1. Risks: conflicting device progress and stale media; define monotonic completion and explicit reset semantics.

### Phase 3 — Reliable quiz attempts (P1)

Components: quiz attempt schema/RPCs, repository/result models, Riverpod attempt controller, active/result/review pages.

Work: create/resume attempt with immutable question/policy snapshot; persisted answers; server start/expiry; idempotent submit; configurable agreed retake policy; recover committed attempts after response loss; close confirmation and lifecycle handling.

Acceptance: kill/relaunch restores the same attempt; background time counts correctly; duplicate submit returns the same result; failures preserve answers; threshold/scoring/review match the server; no answer keys available before authorized review; a permitted retry has a separate attempt ID.

Dependencies: Phase 1 and retake policy. Risks: migrating one-attempt uniqueness and preserving historical review content; use additive migrations and test existing attempts.

### Phase 4 — Reliable assignment submission and feedback (P1)

Components: assignment submission RPC/repository, upload reservations, student form/controller, review UI and notification refresh.

Work: request-id reconciliation, retained draft, bounded/validated attachments, progress state and navigation lock, exact local deadline, extension/revision policy, review identity, notification and resume-triggered refresh.

Acceptance: lost response does not duplicate revisions or delete committed attachments; three 25 MB files are accepted and excess rejected at client/server; feedback and prior revisions remain accessible; rejected-after-deadline has an explicit permitted next action or truthful closed state; permission/network errors preserve input.

Dependencies: Phase 1 and revision policy. Risk: storage cleanup versus committed revisions; verify with attachment-retention SQL tests and failure injection.

### Phase 5 — Authoritative course completion (P0 outcome, after Phases 2–4)

Components: completion policy/version records, eligibility evaluator, enrollment/achievement records, student/instructor read models.

Work: evaluate required lessons and distinct assessment requirements server-side; return incomplete reasons; trigger/reconcile evaluation after progress, scoring and reviews; store immutable completion timestamp/policy version. Update Completed UI and instructor roster from the same result. Define treatment of later unpublishing/content updates without silently invalidating earned achievements.

Acceptance: all lessons checked with a failed required quiz remains in progress; pending assignment displays awaiting review; approval of final requirement completes exactly once; concurrent events cannot double-complete; student and instructor agree after refresh; no empty course auto-completes.

Dependencies: policy decisions plus reliable events from Phases 2–4. Risks: existing 100%-lesson courses may not meet new criteria; migration must preserve history and explicitly mark evaluation status, not fabricate eligibility.

### Phase 6 — Certificate issuance and access (P1)

Components: certificate issuance table, server generation worker/Edge Function, private artifact bucket, student certificate view and optional public verification route.

Work: idempotent issuance keyed to completion/version; actual CBOA branding, student/course/instructor snapshots and server date; generate a real PDF; authenticated view/download/share; durable issuance ID. Public verification, if approved, exposes minimal fields via an unguessable identifier. Separate eligibility, queued, generated and failed states with safe retries.

Acceptance: no artifact for an ineligible account; eligible completion yields one issuance; downloaded file is valid and matches server records; share invokes an actual action; generation failure never displays success; another student cannot fetch a private certificate; changing display names does not silently rewrite issued history.

Dependencies: Phase 5, approved certificate wording/branding and artifact runtime. Risk: placeholder replacement must not be mistaken for accreditation. No payment, Apple/APNs or managed video vendor dependency is required for core certificate delivery.

### Phase 7 — Integrated validation and focused UX polish (P1/P2)

Components: all affected student routes and read models, existing design system, documentation and observability.

Work: functional My Learning search; consistent typography, loading/empty/retry states, scope labels and progress explanations; responsive reading/results/forms; verify complete journey and document deployment/rollback. Reuse current components. External design references are optional inspiration only; no redesign is justified until workflow failures are resolved.

Acceptance: one student can enroll, resume lessons, attempt quizzes, submit/revise assignments, receive feedback, complete and access a real certificate; teacher sees matching status. Each failure has a useful recovery path. No mock success toasts, fake certificate claims or decorative search remain in that journey.

Dependencies: Phases 1–6. Risks: excessive UI scope; limit changes to documented usability issues.

## Validation strategy for implementation

No tests were run during this audit. Existing tests to reuse include `public_course_syllabus_test.dart`, `live_lesson_player_test.dart`, `lesson_autoplay_test.dart`, `video_study_repository_test.dart`, `offline_file_store_test.dart`, `supabase_quiz_mapper_test.dart`, `student_assignment_filters_test.dart`, `assignment_workflow_test.dart`, `curriculum_visible_assessments_test.dart` and Supabase quiz-review/attachment-retention SQL tests. They do not currently prove a full certificate journey.

For each implementation phase: analyze touched code; run targeted unit/widget and SQL authorization tests; then perform a scoped integration scenario. Broad regression runs belong after integrated changes, not repeated after cosmetic edits. Use emulator-5556/Pixel 5 for Android when available. iOS runtime checks remain pending until an iOS device/simulator and signing environment exist; static review cannot certify iOS operation.

Manual/integration matrix:

| Area | Required cases |
| --- | --- |
| Identity/access | guest, unenrolled, active, completed, cancelled, wrong student, instructor preview, expired session, account switch |
| Enrollment | free, paid unavailable, double tap, concurrent requests, unpublished course, lost response |
| Lessons | video, reading-only, missing file, locked lesson, long title, large text, 320/390/tablet widths, light/dark theme |
| Progress | repeat mark, final lesson, failed required quiz, pending assignment, two devices, removed/added lesson, changed media |
| Offline | download in app-private storage, airplane mode, app kill, pending checkpoints/completion, reconnect, revoked access, logout |
| Quiz | teacher threshold other than 60%, unanswered/invalid answers, empty quiz, background timer, kill/resume, deadline, lost response, allowed/exhausted retry, own/other attempt review |
| Assignment | text-only, files-only, invalid/oversized/fourth file, interrupted upload, duplicate request, exact deadline, rejection after deadline, approved/pending revision guard, preserved prior files |
| Navigation | catalog → enrollment → lesson → assessment → result → originating lesson; notification cold start; missing/deleted ID; authentication redirect |
| Completion | requirements pending, final event, concurrent final events, policy changes, consistent student/instructor status |
| Certificate | unauthorized/ineligible, queued generation, generation failure/retry, one issuance, actual PDF, actual share, historical data snapshot |

Capture request IDs, persisted row IDs, scope IDs, timestamps and UI screenshots as evidence, never tokens or answer keys in logs. Before release, verify migrations and policies against the deployed project and retain an additive rollback/feature-disable plan.

## Configuration and decisions needed before implementation

- Supabase project/environment confirmation and authorized test accounts/fixtures for live verification. Do not paste service credentials into chat or embed them in Flutter.
- Approval of required/optional assessment policy, quiz retries, revision window, completed content access and handling of curriculum changes for existing learners.
- CBOA certificate wording, issuer/signature identity, whether public verification is desired, and desired name-correction policy. Existing app branding can be reused.
- Server deployment permission and storage configuration for a private certificate bucket and generation worker; actual environment-variable names depend on the selected implementation and should be documented when concrete.
- Android emulator for interactive validation. iOS configuration/runtime validation remains a separate release gate; it does not block implementing platform-neutral logic.
- Existing FCM configuration is reused for feedback/completion notifications; notification permission denial must never block accessing results. Paid enrollment remains deferred as requested.

No new credentials are needed to review this plan or begin local implementation after approval. Live verification and certificate deployment require the environment access described above.
