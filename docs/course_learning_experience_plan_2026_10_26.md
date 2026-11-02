# Course learning experience: audit and implementation plan

Date: 26 October 2026. Status: approved for execution one phase at a time. Phases 0–6 implemented; backend deployed. Phase 7 automated verification passed; native Android/iOS acceptance remains outstanding; provider-dependent checkout remains deferred. See [Phases 3–7 delivery and verification](course_learning_phases3_7_2026_10_27.md). See [Phase 0 live audit](course_learning_phase0_2026_10_26.md), [Phase 1 delivery](course_learning_phase1_2026_10_26.md) and [Phase 2 delivery and payment boundary](course_learning_phase2_2026_10_26.md).

## Evidence and boundaries

Reviewed `memory/rules.md`, course authoring/repositories/mappers, syllabus, enrollment, live/offline lesson completion, curriculum scope/providers, reviews, and the learning/publication migrations. Existing learning documentation supplies additional context, not proof that every deployed path currently works.

The initial plan was based on source and migration inspection. Phase 0 subsequently added live read-only schema, policy and aggregate data checks; its separate report records the evidence and limits. No payment transaction, device test or permission penetration test was performed for this plan. Earlier documented test results are not presented as fresh results.

Implementation follows feature-first repositories, Riverpod, typed GoRouter routes, existing theme/ScreenUtil components, and the project file-size limits. Split oversized touched components by responsibility; avoid broad unrelated refactors. Preserve the current player controls and playback appearance.

## Coursera research and product decisions

Research preceded planning. Some Help Center URLs returned a CSS error when opened; official indexed article text was available. Claims below are limited to that evidence.

| Official evidence | Implication for CBOA |
| --- | --- |
| [Representative course](https://www.coursera.org/learn/how-to-create-an-online-course/) publicly lists two modules containing videos, readings, assignments, and discussions. | Mixed content is appropriate. This does not establish that every course uses our exact nested lesson/activity structure. |
| [Taking assignments](https://www.coursera.support/s/article/learner-000001563?language=en_US) distinguishes graded requirements from optional practice/honors work and describes different grading and retry arrangements. | Model required/optional explicitly; preserve configured pass thresholds and teacher grading. Do not add peer grading, labs, or programming assessment systems. |
| [Course preview](https://www.coursera.support/s/article/learner-000002293?language=en_US) and the [official preview announcement](https://blog.coursera.org/introducing-courseras-new-course-preview-experience/) describe first-module preview for many courses. | First-module access can be intentional on Coursera. It must not restrict a fully entitled CBOA student to one module. “Enroll for free” does not universally mean full free certification access. |
| [Coursera Labs troubleshooting](https://www.coursera.support/s/article/learner-000001309?language=en_US) describes prerequisites in some courses and references Next/Mark as complete. | Universal strict sequencing and removal of manual completion are explicit CBOA requirements, not verified universal Coursera rules. |
| [Assessment help](https://www.coursera.support/s/learner-help-center-quizzes-assignments?language=en_US) is a reference entry point. Exact review eligibility and automatic watch/read thresholds were not verified. | Define these transparently as CBOA policy; do not claim exact Coursera parity. |

### Resolved requirements

1. **Entitlement and progression are separate.** Enrollment grants the whole purchased/free course entitlement. The published outline is visible in full; learning content opens in sequence. Completed lessons remain revisitable.
2. **Hierarchy uses existing concepts.** Module 1 → 1.1 lesson/topic → 1.1.1 activity/subtopic. Use stable IDs and teacher order; derive labels rather than storing numbering. Arbitrarily nested topics are outside this change.
3. **Only published outline is public.** Titles, types, order and estimated durations are public metadata. Drafts, protected notes, file paths, URLs, answers and submissions are not public outline fields.
4. **Required defaults preserve existing policy.** Existing lessons and graded assessments remain required. Existing supplemental handouts do not silently become new mandatory readings. Teachers explicitly designate future optional activities. Required lessons must contain a satisfiable required activity; reject an empty required lesson at publication.
5. **No forced video/transcript prerequisite.** A valid reading-only or assessment-only lesson can publish. A video must be uploaded/processable and safe to serve; transcript generation is not a universal course-release blocker. Pending transcript UI must not claim captions exist.
6. **Completion is server-derived.** Playback/reading evidence reduces casual spoofing but cannot prove human attention or comprehension. Use graded checks where comprehension must be demonstrated.
7. **Proposed video criterion:** at least 90% unique media-time coverage of the required video version, observed in plausible playback sessions. Seeking to the end does not count skipped intervals; playback speed is accounted for. Keep the threshold centrally configurable.
8. **Proposed reading criterion:** render the required text/document in-app; require end/page coverage plus foreground engagement time derived from content length. Use a configurable 200 words/minute baseline for text. Do not count background time or opening/downloading a file as completion. Unsupported/external documents remain supplemental or require an associated graded check. Provide accessible reading navigation and avoid scroll-only criteria.
9. **Assessment behavior:** preserve current unlimited quiz retakes, historical thresholds, any qualifying pass, and rejected-assignment revisions with retained history. Submitted/pending is not approved. A required assignment awaiting grading blocks the next required lesson; show this clearly. Reject prerequisite arrangements that make required work unreachable.
10. **Offline:** allow private downloads of currently accessible/completed content. Queue evidence with account, enrollment, activity version and idempotency identity. Show provisional completion offline; the next locked lesson opens after server confirmation. Do not claim trusted anti-cheat verification for arbitrary offline telemetry.
11. **Published changes:** current release remains usable while drafts are edited. Publish atomically switches the student release and refreshes clients. Completed lessons and earned certificates stay earned. New required work applies to unfinished requirements without inserting a new gate behind a learner's confirmed progress frontier; new students follow the full new sequence. Record grandfathered requirements explicitly rather than fabricating submissions.
12. **Course/module assessments:** preserve legacy placements. Show them in clearly named module/course assessment locations, never as attachments to every lesson. Required module assessments gate the next module; required course assessments gate final completion. New lesson-scoped assessments use exact placement IDs.
13. **Reviews:** proposed eligibility is an enrolled student with at least one server-confirmed lesson completed; one editable review per student/course. This is a CBOA policy. Existing instructors cannot review their own courses.
14. **Paid courses:** prior PayFast deferral remains relevant. Pricing and secure authorized enrollment can be implemented, but working consumer checkout needs an approved payment provider and deployment configuration. Never use a client success flag or mock payment as proof.

## Confirmed findings

| Priority | Finding and evidence | Required correction |
| --- | --- | --- |
| P0 | `record_lesson_completion` in `20261026000000_learning_integrity.sql` accepts a caller boolean after enrollment/publication checks. The offline RPC calls completion directly. | Replace both public completion shortcuts with evidence-based reconciliation. Audit every write path and grant. |
| P0 | `can_access_curriculum` in `20261026120000_staged_course_publication.sql` checks enrollment and release status, not preceding lesson completion. | One authoritative content-access decision across SQL, RPCs, storage signing, attempts, downloads and deep links. |
| P0 | Live/offline player code exposes manual completion; live video end invokes completion. | Remove manual controls and end-event authority; persist validated activity evidence. |
| P1 | `teacher_create_course_screen.dart` shows Price: Free in live mode; course creation payload lacks pricing. `course_enroll_modal.dart` explicitly disables paid enrollment. | Persist course type and validated price; implement a verified entitlement boundary before enabling checkout. |
| P1 | `course_curriculum_tab.dart` iterates all returned modules, but only first starts expanded. It enables navigation only for videos and describes non-video lessons as missing video. | Diagnose data visibility separately; support all valid activity combinations and accurate lock reasons. |
| P1 | `public_course_syllabus.dart` can restore metadata lessons only within module rows already returned. Public syllabus RPC exposes limited lesson metadata. | Fetch a complete published outline independent of protected-content joins. |
| P1 | Release logic accepts media, notes, external video or ready handouts, without equivalent assessment-only readiness. Module RLS depends on released state. | Include valid assessment-only lessons in release validation and inspect affected live module/lesson statuses. The exact reported course cause is not yet proven. |
| P1 | `curriculumVisibleAssessmentsProvider` inherits module/course assessments; attachment summary uses exact scopes. | Separate placement scopes and use the same exact lesson projection for counts and student lists. |
| P1 | `curriculum_resources_screen.dart` embeds `TeacherVideoPreview` and teacher media state. | Remove video from student resources; keep video in learning/teacher studio contexts. |
| P1 | Reviews tab returns FeatureUnavailable in live mode; community controller returns empty data and rejects live actions. Review sheet uses local mutation and setState. | Add real review repository, constraints/RLS, asynchronous Riverpod state and rating aggregates. |
| P1 | `course_detail_screen.dart` infers enrollment from non-null progress. | Read explicit entitlement and progress independently. |
| P1 | Durable completion currently counts published lessons and distinct linked assessments, without optional activity semantics. | Reuse durable completion/certificates, extend requirement evaluation and preserve achieved history. |
| P1 | Release markers stage additions, but do not constitute a complete revision system for all editing/deletion/link changes. | Stage every affected curriculum mutation consistently; verify unlink/delete and referenced assessment edits cannot alter the live release early. |
| P2 | Syllabus radius is 16.r with a hardcoded surface; player module card uses 8.r and theme border. | Reuse the smaller themed module-card treatment. |
| P2 | Module folder, course-cover folder and lesson resources overlap. | Define distinct routes and remove the student cover folder. |

Existing infrastructure to preserve: server quiz sessions/scoring, assignment revisions and private files, curriculum link tables, video processing, account-scoped offline storage, staged media replacement, durable course completion and certificate generation. Their existing presence does not replace integration verification.

## Implementation phases

### Phase 0 — Live baseline and migration specification (P0)

Dependencies: plan approval and existing project access.

- Compare deployed schema/functions/policies/grants with migrations; inspect anonymized counts for published modules, draft lessons, empty lessons, orphan links and existing paid values.
- Reproduce missing modules with an affected course and separate owner, anonymous and enrolled views. Trace repository response through mapper and widget.
- Inventory all content entry points: catalog joins, direct selects, storage objects, signed URLs, Edge Functions, quiz/assignment APIs, downloads, notifications and route extras.
- Capture baseline progress/certificates and publication state without printing user data or secrets. Define isolated fixture ownership and cleanup.
- Produce exact additive migration/backfill specification, indexes, rollout compatibility and rollback procedure.

Acceptance: every finding mapped to an implementation location; schema drift resolved; payment deployment dependency explicit; no data repair inferred from UI alone.

Risk: live-only inconsistencies. Mitigation: read-only diagnosis first, reviewed targeted repairs and backup before migrations.

### Phase 1 — Authoritative curriculum and release model (P0/P1)

Dependencies: Phase 0.

- Retain modules, lessons, media, materials, quizzes, assignments and their IDs.
- Introduce a thin ordered activity-placement representation only where existing tables cannot represent unified order/required criteria. Reference existing content; do not duplicate assessment questions or submissions. Use constrained typed references and validate same-course/lesson ownership.
- Add required/completion configuration and release/version identity. Enforce stable ordering with deterministic ID tiebreaks and transactional reorder operations.
- Backfill existing video/notes/material/link placements idempotently. Preserve module/course links and current 10-lesson module limit.
- Extend current release transaction for assessment-only lessons, staged edits/removals/reordering, and immutable references needed by active sessions/progress.
- Publish a metadata-only outline API with all released modules/lessons/activities; avoid per-lesson query waterfalls.

Acceptance: all requested content combinations publish; drafts never leak; old release survives abandoned editing; publish switches all affected data together; existing enrollments, IDs and attempts survive migration.

Risk: duplicate requirements and accidental publication changes. Mitigation: explicit placement identity, migration assertions, immutable assessment attempt snapshots, release diff shown to teacher.

### Phase 2 — Free/paid entitlement and secure content access (P0)

Dependencies: Phase 1; checkout activation additionally depends on payment configuration.

- Add free/paid selection and price validation to existing course form/repository/RPC. Normalize currency and amount semantics after inspecting existing values; never silently reinterpret stored rupees as minor units.
- Keep free enrollment idempotent. Paid entitlement may be granted only by verified server payment processing or an audited authorized admin operation; teachers/clients cannot self-grant it.
- For checkout, verify provider signature, merchant, order, amount, currency and final settlement state; replay-safe webhook handling, pending/cancel/refund states and reconciliation. Verify applicable Android/iOS digital-content billing requirements before enabling a payment path.
- Centralize entitlement and sequential access checks. Protect learning records, content rows, signing endpoints and future-lesson assessment starts; metadata remains public.
- Hydrate routes by stable IDs after auth initialization; validate account and access again on resume/tap. Never trust route extras as authorization.

Acceptance: all entitled students see the whole outline; only current/completed content opens; unpaid users cannot fetch content via direct requests; existing authorized enrollments remain valid; duplicate enrollment/payment events create no duplicates.

Risk: temporary signed URLs and downloaded content cannot be remotely unlearned/recalled. Mitigation: private storage, short-lived access URLs, account-scoped files and revalidation; no promise of DRM.

### Phase 3 — Activity evidence and automatic progression (P0)

Dependencies: Phases 1–2.

- Add bounded playback-session evidence: unique watched intervals, server timing plausibility, media version, session ownership and replay protection. Buffer/batch updates rather than writing on every player tick.
- Add in-app reading evidence under the agreed coverage/time rules, including lifecycle, large-text and screen-reader paths. External links are not automatic completion evidence.
- Reuse saved quiz pass outcomes and approved assignment revisions. Evaluate required placements, lesson/module gates and final course requirements on the server.
- Serialize concurrent final events and release changes; make reconciliation idempotent. Remove/restrict legacy manual and offline completion RPCs, direct write grants and UI controls.
- Refresh shared progress across player, My Learning, teacher roster and certificates. Handle pending grading, failed quiz, rejected revision, overdue first submission and unavailable required content explicitly.
- Preserve completed history and store version/grandfathering decisions. Reconcile offline evidence safely; do not unlock a future lesson on an unconfirmed client boolean.

Acceptance: seeking/end events cannot complete a video; mixed lessons wait for all required activities; optional activities do not block; teacher approval can unlock the next lesson; concurrent/device/offline retries do not duplicate achievements; issued certificates remain available.

Risk: engagement telemetry is an imperfect signal, and grading can stall progression. Mitigation: documented criteria, honest pending states, resubmission support and teacher-visible blocked learners; no fabricated completion.

### Phase 4 — Teacher activity authoring (P1)

Dependencies: Phases 1–3 contracts.

- Extend existing lesson studio to add/order supported activity references, configure required/optional state and show publication readiness.
- Support video-only, reading-only, quiz-only, video+quiz, reading+quiz, assignment+quiz and full combinations.
- Provide understandable validation for missing questions, inaccessible files, empty required lessons and impossible prerequisites. Preserve upload retry and existing file limits.
- Make exact lesson attachment counts and actual attached lists consume the same projection; retain clear module/course placement sections.
- Stage modifications to already published content; preserve teacher preview privileges without writing student progress.

Acceptance: creation and later linking produce identical student-visible placements after release; no dummy counts; failed uploads cannot masquerade as ready activities; preview causes no learner side effects.

### Phase 5 — Student curriculum, resources and navigation (P1/P2)

Dependencies: Phases 1–4.

- Render complete ordered, indexed outline from one model across syllabus and player. Expand lessons/topics to activities; persist sensible expansion/selection state.
- Use explicit available, locked, in-progress, completed, submitted, passed and failed states where meaningful; separate entitlement messaging from prerequisite messaging.
- Open reading/assessment-only lessons without a broken video placeholder. Keep existing playback controls untouched.
- Materials opens only current lesson readings/documents/resources; Assessments opens only its linked assessments. Exclude videos and drafts. Do not inherit broader links into lesson counts.
- Module folder opens ordered module structure, including explicitly scoped module work. Remove student course-cover folder. Preserve back navigation/current lesson after submissions.
- Match syllabus to the reference 8.r card/border and current theme. Use centered whole-page empty state when both resource categories are empty; omit empty sections when another contains data.

Acceptance: every published module appears for free/paid/unenrolled views with appropriate access states; counts agree with lists; deep links resolve safely; no teacher-only controls/video preview in student resources; narrow widths and large text remain usable.

### Phase 6 — Real course reviews (P1)

Dependencies: Phase 2 entitlement and Phase 3 confirmed progress.

- Add course reviews with unique (course_id, student_id), integer rating 1–5, bounded plain text, timestamps and own-review edit policy.
- Enforce eligibility/ownership on the server; derive identity from auth rather than a submitted name. Do not expose student emails.
- Add course-keyed paginated repository/providers and asynchronous submission state. Show success only after persistence; preserve input on network failure.
- Calculate aggregate rating/count from real rows; invalidate relevant course cards/details after edit. Update/delete cannot corrupt aggregates.
- Replace live unavailable UI and local review mutations; use existing centered empty state, loading and retry patterns. Do not leave helpful/reply controls pretending to persist: implement only if required by existing product behavior, otherwise hide unsupported controls.

Acceptance: eligible student posts/edits one persisted review; duplicate concurrent submits remain one; other users/instructor cannot change it; aggregates and filtered lists agree after restart.

### Phase 7 — Integration, performance and rollout (P0 release gate)

Dependencies: all enabled phases; payment path cannot be declared complete without its integration.

- Run focused existing and new contract/security/regression checks. Test isolated real Supabase fixtures without altering actual learner achievements.
- Inspect query plans/indexes for outline, access checks, review aggregation and requirement reconciliation. Batch projections; avoid N+1 media/resources queries and unbounded activity telemetry.
- Rehearse additive migrations/backfill twice, verify counts/IDs and backup recovery. Deploy compatible backend first; disable unsafe legacy endpoints with a coordinated minimum-client rollout so old clients cannot bypass progress.
- Validate Android on the specified Pixel 5/emulator-5556 when available. Native iOS acceptance requires a Mac/device; Windows inspection/build configuration alone cannot certify iOS behavior.
- Document configuration, policies, operations, migration results, remaining limitations and exact tested environments. Roll back application behavior compatibly; never delete attempts/progress to undo a release.

Acceptance: required test matrix passes; no hidden mock fallback; no loss of existing progress/certificates; permission failures produce clear UI; deployment report separates verified from pending items.

## Verification matrix

| Area | Required cases |
| --- | --- |
| Authorization | Anonymous, unenrolled, active free, verified paid, unpaid, cancelled, other student, course owner, other teacher; direct SQL/API requests and signed-file requests. |
| Progression | First/current/future/completed lesson; altered IDs; forged completion calls; parallel devices; seeking; playback speed; background time; duplicate/out-of-order evidence. |
| Activities | Every requested combination; optional work; no activities; legacy course/module links; reused assessments; inaccessible document; removed/replaced version. |
| Assessments | Failed/pass retake, expired session, duplicate submit, pending/approved/rejected assignment, revisions, deadline boundary, ownership mismatch and unavailable prerequisite. |
| Releases | Edit without publish, partial upload, failed transaction, reordered/deleted links, assessment-only release, new required work for existing learners, active playback during publish. |
| Offline | Eligible private downloads, locked downloads denied, kill/reopen, account switch, stale release, reconnection replay, expired entitlement; no gallery exposure. |
| Completion | Mixed requirements, concurrent last events, grandfathered achievements, certificate retries, ownership checks, teacher/student counts and progress agreement. |
| Reviews | Eligible/ineligible, own edit, duplicate concurrency, rating/text validation, empty/filter/pagination, timeout and retry, real aggregate refresh. |
| UI/navigation | All modules, 320-width/phone/tablet, large text/dark theme, cold deep link, auth expiry, missing IDs, deleted content, loading/empty/error, correct back stack. |
| Payments | Invalid/replayed webhook, mismatched amount/currency/order, pending/cancel/refund and crash recovery; no real charges during test. |

## Configuration and approval boundary

- Existing Supabase/storage/auth configuration should be reused; verify deployed access during Phase 0. Do not request or print secret values in chat.
- Paid checkout requires provider/store-billing selection, test merchant configuration, server credentials, webhook URL/signing secret and settlement/refund policy. Pricing can be implemented independently; checkout remains explicitly unavailable until verified.
- No new transcription, AI, DRM or transcoding service is proposed for this work.
- Proposed thresholds, review eligibility and progress-preservation policy above are part of this plan's approval. They are configurable product decisions, not claims about Coursera.
- Production migrations require a backup and controlled rollout; iOS native verification needs an available iOS environment.
- The user approved execution one phase at a time. Phases 0–6 are implemented and the backend is deployed; Phase 7 has remaining native acceptance checks. Payment-provider checkout remains deferred. The user subsequently authorized finishing the remaining phases one by one; see the phases 3–7 delivery report for implemented behavior and verification limits. The linked execution reports distinguish completed work from pending fixes.
