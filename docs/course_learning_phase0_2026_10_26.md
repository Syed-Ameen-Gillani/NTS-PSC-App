# Course learning — Phase 0 execution report

Date: 26 October 2026. Status: Phase 0 complete; Phase 1 not started.

Parent: [approved phased plan](course_learning_experience_plan_2026_10_26.md).

## Work performed

- Read `memory/rules.md` and the approved plan.
- Ran two read-only SQL queries against the configured Supabase project using the existing credential-redacting helper. No row mutations, DDL, deployments, test accounts, enrollments or payment transactions were performed.
- Compared migration versions, inspected live columns, RLS policies, grants, bucket visibility, access/publication/completion functions, aggregate curriculum data and preservation baselines.
- Traced course repository → public syllabus merge → mapper → syllabus, exact versus inherited assessment scopes, player routes, media signing, assignment persistence and certificate access.
- Prepared the additive migration and rollout specification below. SQL scripts are retained for repeatable checks; raw catalog output remains outside the repository in the temporary directory. No credentials or learner identities are included here.

## Deployed baseline

| Check | Result |
| --- | --- |
| Migration history | 53 local versions; same 53 deployed versions; no version-set differences |
| Selected function bodies | Eight bodies match the latest local migration definitions after whitespace normalization |
| Public tables | RLS enabled on all inspected public base tables |
| Courses | 11 published, 5 draft; all have zero price, currency PKR |
| Enrollments | 14 |
| Lesson progress | 2 rows, both completed |
| Earned course completions | 1 |
| Quiz attempts | 2 |
| Assignment submissions | 6 |
| Stored certificate files | 0; completion eligibility and stored certificate issuance are distinct |
| Cross-course lesson progress | 0 |
| Lesson link/course/module scope mismatches | 0 |
| Private storage | Videos, materials, assignment briefs/submissions and certificates |
| Public storage | Course thumbnails and profile avatars |

Compared bodies: `can_access_curriculum`, `can_access_lesson_media`, `publish_course_changes`, `record_lesson_completion`, `record_offline_lesson_completion`, `get_public_course_syllabus`, `course_requirements`, `unlink_curriculum_assessment`.

This establishes migration-version agreement and selected body agreement. It is not a complete byte-for-byte comparison of every deployed trigger, constraint and function against a rebuilt database.

Preservation fingerprints at the audit snapshot:

| Existing history | Aggregate fingerprint |
| --- | --- |
| course_completions | `6765ce4db02f7ba7bd219770d2c10fac` |
| lesson_progress | `7ec9a64b6b4c9be5d31e4d98d2298533` |
| quiz_attempts | `f80f0139942fcb1afeba06fa324e1fac` |
| assignment_submissions | `6247326ece6cd7dc5667931d4f17ca0b` |

These are preservation/change-detection baselines, not backups or cryptographic security proofs. Recalculate immediately before and after migration in a controlled window; genuine concurrent learning can legitimately change them.

## Missing-module diagnosis

Live aggregate data confirms a published course with **two modules, one released module, one published lesson and two draft assessment-only lessons**. One module containing assessment-only draft work is unreleased. The audit deliberately does not expose the course title or owner identity.

Its unreleased lesson placements include two quizzes and one assignment whose assessment records are already published. An additional quiz placement is module-scoped. All four assessment placements in the current database are unreleased.

The causal chain is:

1. `publish_course_changes` promotes draft lessons only when they have ready video, an external video URL, notes or a ready material.
2. A lesson with only linked quizzes/assignments does not satisfy that release predicate.
3. A module without a published lesson remains draft.
4. The deployed `modules_read` policy excludes that module from student/public queries.
5. `_courseSelect` therefore lacks the module. `mergePublicCourseSyllabus` only adds lessons to modules already returned and cannot restore it.
6. `course_curriculum_tab.dart` renders all returned modules; it does not truncate to the first module. Only the initial expansion is limited to the first.

This explains a live occurrence of the reported symptom. Matching it to a specific screenshot/account and exercising the student UI is still a later integration check. Do not publish draft work automatically as a diagnostic repair; the teacher must explicitly release validated changes.

### Additional live data anomaly

Six published courses have no modules. Seven enrollment rows reference those courses. Current publication validation would reject an empty curriculum, so these are pre-existing records requiring preservation and targeted review. Their origin is not established by this audit.

Do not delete them, cancel their enrollments, invent lessons, or mark them complete. Keep existing access identities, show an honest content-not-available state, and surface readiness to the owning teacher. Future publications must satisfy the corrected invariant. Any historical data correction needs a documented per-course decision.

## Access and integrity findings

| Severity | Live/source evidence | Implementation boundary |
| --- | --- | --- |
| P0 | Authenticated users can execute completion RPCs with a boolean; offline completion delegates with true. Enrollment is checked, activity evidence is not. | Phase 3 replaces completion authority; coordinated client rollout must close both paths. |
| P0 | Curriculum/media access helpers check enrollment/publication, not earlier required work. | Phase 2 introduces shared sequential access checks and applies them to every protected entry point. |
| P0 | `assignments_teacher_delete` deparses as `s.assignment_id = s.id`, rather than comparing to the outer assignment. Authenticated DELETE is granted and submission FK uses ON DELETE CASCADE. | Correct policy and add a database guard against deleting referenced learning history in Phase 1, before broader editing work. No destructive exploit was attempted. |
| P1 | Quizzes and assignments are readable by course enrollment without checking a released placement. `start_quiz_session` checks status/enrollment, not lesson progression. | Protect assessment content/start/submit APIs as well as link visibility; standalone quizzes need a separate intentional access rule. |
| P1 | Owner unlink deletes a placement immediately; material delete is also immediately authorized. | Stage removal and changes for live courses; old published release continues until explicit publish. |
| P1 | Current requirement evaluator counts all published lessons and released linked assessments. | Add required/optional, activity and release semantics while preserving achieved completion. |
| P1 | Private video signing uses storage RLS; default client URL lifetime is one hour. Assignment file URLs are signed separately. | Enforce central access in storage and signing; recheck future-lesson downloads, not merely the screen button. |
| P1 | Route extras can contain complete course/lesson objects; notification links resolve IDs through a separate page. | Resolve authoritative learning state for both paths; stale client objects never authorize access. |
| P1 | Lesson attachment counts are exact-scope; visible assessment provider adds course/module inheritance. | One exact lesson projection for count/list; explicit separate module/course assessment destinations. |
| P1 | Live course form and persistence omit paid pricing; deployed courses are all zero-priced. | Preserve zero-price values. Add explicit type/amount contract; do not activate a pretend checkout. |
| P1 | Live review UI is unavailable and community mutations are mock-only. | Dedicated real review persistence and eligibility in Phase 6. |

RLS being enabled does not make these rules correct. Existing progress table grants allow authenticated SELECT, but no table-level INSERT/UPDATE; the exposed RPC is the currently confirmed completion shortcut. Historical write policies alone do not establish an active direct-write bypass.

## Access surface inventory

| Surface | Existing location | Required enforcement |
| --- | --- | --- |
| Catalog/outline | `supabase_course_repository.dart`, `public_course_syllabus.dart`, public syllabus RPC | Complete released metadata; exclude protected content from public projection |
| Lesson content | `lessons_read`, curriculum/media helpers | Entitlement plus current/completed lesson and release membership |
| Media URLs/downloads | `lesson_media_repository.dart`, storage video policy, offline library | Same access rule at URL/file issuance; account-scoped local files |
| Materials | `curriculum_repository.dart`, material rows and storage policy | Exact placement, released content and accessible lesson |
| Quiz content/session | `supabase_quiz_repository.dart`, quiz read/session RPC | Released placement and progression; existing snapshots/timers retained |
| Assignment brief/submission | assignment repository, assignment/brief RLS, submit RPCs | Placement access, ownership, deadline/revision rules |
| Evidence/progress | course repository, live player, offline queue | Server-derived completion; bounded idempotent evidence |
| Deep links | GoRouter lesson route, notification lesson resolver | Auth readiness, ID hydration, entitlement/progression recheck |
| Achievement/certificate | eligibility/completion functions, `course-certificate` Edge Function | Durable owner-only achievement; private signed artifact |
| Teacher preview/edit | owner checks and lesson studio | Owner preview without student evidence; draft edits cannot alter active release |

Service-role transcript/checkpoint/certificate operations bypass RLS by design; validate the authenticated caller or callback and selected record before using privileged storage/database access. Existing service operations must never become a generic client signing endpoint.

## Concrete migration specification

The following are proposed migration units, not applied SQL. Allocate the next unused migration versions when implementation begins.

### A. History safety and ordered lesson activities — Phase 1

- Fix the assignment DELETE policy with an explicitly qualified outer reference. Add a guard that refuses deletion of assessments/placements whose history must survive; prefer retirement/versioning over cascading deletion. Test direct DELETE as owner and non-owner with real isolated submissions.
- Introduce `lesson_activity_placements`: stable UUID, lesson FK, type, order, required flag, completion-rule version and constrained reference to existing media/material/quiz/assignment. Inline reading references existing lesson notes or a versioned reading payload. Exactly one valid source per placement.
- Validate referenced source ownership/course membership server-side. Prevent duplicate accidental placements; intentional reuse must be explicit. Reuse existing content/assessment/submission tables, not copied question systems.
- Keep existing course/module assessment links in their current scopes; expose them separately. Associate lesson activity placements with the exact existing lesson link identity where appropriate.
- Add unique deterministic ordering and transactionally reorder within one parent. Reordering published content is staged, not an immediate mutation.
- Backfill in batches with deterministic source keys: current lesson media/external URL, nonempty notes, ready material and exact lesson assessment links. Assessments/current lesson defaults preserve required behavior; supplemental files remain optional. No inferred placement from module/course inheritance.
- Preserve 10 lessons/module. Never mark an empty required lesson complete or fabricate a content reference.

### B. Release manifest and metadata projection — Phase 1

- Add course release identity and immutable published manifest entries referencing activity/content versions. Maintain a single active release pointer and draft edits. A manifest snapshots placement/order/requirements without duplicating quiz attempts, files or enrollments.
- Bootstrap the initial manifest from currently released data only. Preserve draft additions and unresolved historical empty courses. Do not backfill published status merely because an assessment exists.
- Stage title/notes/order/link additions/removals and source replacement for published courses. Protect referenced media and assignment history from eager cleanup.
- Publish under a course lock: validate all included required activities, references and reachable gates; build manifest; atomically switch active release. Valid assessment-only lessons qualify. No transcript requirement for a reading/quiz-only lesson.
- Add `get_public_course_outline` with course/module/lesson/activity IDs, safe titles/types/order/duration and release ID; return modules independently of protected-content joins. Include only active release metadata.
- Keep the old syllabus endpoint compatible during transition; new client repository consumes the full outline and reconciles by ID.

### C. Entitlement, pricing and access — Phase 2

- Preserve existing `price_amount=0` and PKR interpretation. Establish explicit monetary units, range and rounding before paid persistence; no historical positive values currently require conversion.
- Reuse enrollments; restrict financial state changes to verified server operations. Add provider/order/event ledger only when an approved payment integration is selected.
- Add a single access evaluator returning reason/state for course, lesson and placement. Owner preview is separate from student learning access. Course/module assessment gates have explicit scope.
- Apply evaluator to row policies, storage policies, URL issuance, attempts/submissions and offline downloads. Do not rely on hidden buttons. Prevent a broad alternative RLS policy from reopening protected reads.

### D. Evidence, requirements and preservation — Phase 3

- Add bounded session/evidence and activity-progress records keyed by enrollment, placement and content version, with unique request identity and replay handling.
- Add explicit requirement-policy/release association and grandfathered frontier records. Preserve completed lessons and immutable `course_completions`; no synthetic quiz passes or assignment approvals.
- Update reconciliation to compute lesson/module/course requirements and serialize concurrent final events with existing enrollment/completion locking.
- Restrict/remove the two boolean completion RPC paths once the compatible client is deployed. Direct progress writes stay closed. Old clients must receive a clear update-required response rather than retaining an unsafe bypass.
- Use additive schema and compatible reads first; delay destructive column/function removal until minimum-client rollout is complete.

### E. Reviews — Phase 6

- Add unique course/student review rows with rating/text constraints and server-enforced eligibility. RLS permits public course review reading and only eligible own writes; no student email projection.
- Derive aggregates from persisted data and add course/student indexes. Reuse current review UI vocabulary with asynchronous Riverpod state; remove unsupported mock-only actions.

## Verification and rollout contract

1. Before migrations: take a recoverable database backup using the project's available backup/export method; capture fresh counts/fingerprints and current release data. A fingerprint is insufficient for recovery. Confirm backup availability before any live mutation.
2. Build isolated fixtures with explicit ownership: two students, owner and unrelated teacher, free/paid courses, every activity combination and course/module/lesson placements. Mark fixture IDs for cleanup; never select real users as test actors.
3. Rehearse migration/backfill twice in an isolated database; prove idempotency, unique constraints, content access and unchanged historic IDs. Verify existing course completion remains earned.
4. Test RLS using actual anonymous/student/owner JWT contexts and direct API requests. The Phase 0 catalog inspection used privileged read-only access and does not substitute for these authorization tests.
5. Run a controlled live smoke only after relevant implementation, using fixture data; retain results and remove only explicitly created fixtures. No real payments or production learner resets.
6. Deploy compatible backend first, then client; coordinate disabling legacy completion APIs. Exercise teacher release while an existing student is learning.
7. Roll back client behavior compatibly or switch back to a validated prior manifest. Preserve evidence, submissions, attempt snapshots and earned achievements. Avoid destructive down migrations after new writes.

## Configuration and next phase

No new credentials are required to begin Phase 1; existing configured database access worked. Payment integration configuration remains a later dependency. iOS native verification remains dependent on an iOS environment.

Phase 1 starts with the assignment-history guard, activity schema/backfill and release/outline contracts. It must not auto-publish existing draft assessments or alter the six historical empty courses by assumption.

Completed checks: both live read-only audit queries; local/deployed migration version comparison; eight selected function-body comparisons; scope/progress integrity aggregates; bucket visibility and history baseline.

Not performed: application changes, schema migrations, data repair, role-based live mutation tests, device tests or payment tests. These belong to the appropriate implementation phase. Phase 0 is complete on its audit/specification criteria; no subsequent phase has started.
