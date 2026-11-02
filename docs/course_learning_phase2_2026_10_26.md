# Course learning — Phase 2 delivery report

Date: 26 October 2026. Pricing and access implementation deployed and verified. Payment-provider checkout remains deferred configuration/integration work. Phase 3 has not started.

Parent: [phased plan](course_learning_experience_plan_2026_10_26.md).

## Delivered

### Course pricing and entitlement

- Course creation now offers Free/Paid selection. Paid input accepts whole PKR from 1 to 1,000,000; Free persists zero. Server and form validation agree.
- Existing `price_amount` values retain whole-rupee semantics. No multiplication into minor units or reinterpretation of existing prices was performed.
- Added atomic, retry-safe `create_priced_course_draft`; a reused request/course ID cannot silently change a previously saved price.
- Course models retain numeric price, currency and explicit entitlement separately from display labels and progress. Course details use entitlement to decide whether the student is enrolled.
- Existing authorized active/completed enrollments remain valid regardless of current price. Free enrollment remains idempotent; cancelled access cannot be restored by repeating the free-enrollment request.
- Removed client enrollment INSERT/UPDATE/DELETE privileges. Paid enrollment cannot be forged through client state, a direct row insert or the free-enrollment endpoint.
- Added `admin_set_course_access`, executable only by a privileged backend/service role or trusted database operator. Grants/revocations require a unique request ID, operator reference and reason; replay does not duplicate operations.
- Privileged access grants use the truthful `manual` source. They do not claim a payment was verified. No payment success is accepted from Flutter.
- Enrollment busy/selection state now uses Riverpod rather than setState.

### Sequential access enforced by the backend

- A shared access evaluator derives current/completed/preview/enrollment-required/prerequisite-required/revoked/unavailable states from the active published release.
- Entitlement exposes the complete published outline immediately. Protected lesson content opens in order; completed lessons remain accessible for revision.
- Required lesson quizzes use persisted passing attempts and their saved thresholds. Required assignments need approval; pending submissions do not unlock the next lesson.
- Reading/video/material progress currently uses the existing persisted lesson-completion record. Automatic activity evidence replaces that compatibility mechanism in Phase 3.
- Module-scoped assessments gate progression to later modules. They open after the module's lesson requirements; course-scoped assessments open after preceding course requirements.
- Applied the evaluator to lesson RLS and the existing curriculum/media access helpers. Existing private-storage policies consequently deny future video/material reads and URL signing, not just screen navigation.
- Quiz and assignment row policies now require an accessible released placement. Standalone published quizzes retain their existing separate access behavior.
- Guarded quiz start/save/finish, assignment submission and online/offline completion RPCs. Renamed legacy implementations have no anonymous/authenticated EXECUTE grants.
- Assignment file uploads have an additional restrictive access policy. Protected progress writes also require an accessible lesson.
- Teacher preview remains owner-only and does not write learner progress.

### Preservation and navigation

- Captured two existing frontier waivers from genuine prior progress/completion. They do not insert fake progress, attempts or approvals.
- Publishing earlier new work preserves an established learner's frontier; a new student follows the full updated sequence. Existing completion records remain earned.
- Lesson routes rehydrate by IDs after authentication initialization. Caller-supplied course/lesson objects and a forged preview mode cannot authorize content.
- Access is rechecked on app resume. Account changes invalidate route data; repository requests reject late responses from a previous account.
- Local player selection/completion/autoplay state is scoped to account, course and preview mode.
- Autoplay rechecks the refreshed course access before opening the next lesson. Player controls and their layout were preserved.
- The syllabus distinguishes prerequisites from enrollment and permits valid non-video activities to open. Empty draft lessons remain non-interactive.

## Database delivery

Applied migrations:

1. `20261026150000_course_pricing_entitlements.sql`
2. `20261026151000_sequential_learning_access.sql`
3. `20261026152000_assessment_access_enforcement.sql`
4. `20261026153000_access_frontier_preservation.sql`

A private targeted recovery snapshot was saved outside the repository before rehearsal/deployment: 43 public tables plus function, policy, constraint, trigger, grant and migration definitions; approximately 4.5 MB. It was parsed and SHA-256 checked. This is not a full project disaster-recovery backup; auth identities and stored binary files were not changed by deployment. Keep the snapshot private.

Post-deployment checks:

| Check | Result |
| --- | --- |
| Phase 2 migrations | 4 applied |
| Existing courses | 16; all existing prices remain zero PKR |
| Enrollments / earned completions | 14 / 1, unchanged |
| Existing progress, quiz attempts, assignment submissions and completion fingerprints | Unchanged |
| Frontier preservation records | 2; no fabricated progress |
| Real privileged grants/revocations during deployment | 0 |
| Client enrollment INSERT/UPDATE | Denied |
| Anonymous/authenticated privileged access-grant EXECUTE | Denied |
| Authenticated legacy completion implementation EXECUTE | Denied |
| Synthetic test identities remaining | 0 |

## Verification performed

- Rehearsed migrations and isolated tests inside rollback-only transactions before deployment, then reran against the deployed functions.
- SQL tests used synthetic teacher/student identities and actual database role/JWT-claim contexts. Fixtures included free/paid courses, module quizzes, quiz-only lessons, mixed reading/video/assignment work, protected material/video objects and revocation.
- Checked price boundaries/units, save/enrollment retries, forged paid enrollment, attempted teacher access grants, full outline visibility, future content/storage reads, premature quiz/submission/completion calls, private legacy RPC denial, module passing, assignment approval, release frontier preservation and admin request replay.
- Reran Phase 1 publication/history/privacy regression checks with the student positioned at the current module.
- Anonymous REST checks passed: outline remains readable; five private tables deny access. The real Flutter catalog integration passed against the new access API.
- Flutter pricing, metadata, deep-link, preview, autoplay and account-switch checks passed. The broader course-cover, publication, quiz-navigation, download, assignment and resources regression run passed 36 tests.
- Pricing layout was checked at 320 and 768 widths. Final account/player checks and scoped analysis passed; no analyzer issues remained.
- No Android/iOS native-device session or payment transaction was run in this phase. SQL video fixtures contain storage metadata, not playable uploaded bytes.

Repeatable checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/test_course_access_phase2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tool/test_public_course_outline.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tool/query_supabase.ps1 -File tool/learning_phase2_health.sql
```

The access test helper includes the publication regression suite. All synthetic fixtures roll back. `-RehearseMigrations` is for a database before these Phase 2 migrations are installed.

## Payment integration dependency

Paid courses can be authored, priced and accessed through an authorized audited enrollment. Consumer checkout remains unavailable. No gateway adapter, settlement verification, webhook handler, refund processor or fake payment credentials were introduced.

Before enabling checkout, choose the supported distribution/payment route and provide its test configuration: merchant or store products mapped to courses, server verification credentials, webhook/event verification configuration and refund/revocation policy. Credentials stay on the backend.

Review the applicable storefront/program rules before choosing the mobile purchase flow: [Apple App Review Guidelines, payments](https://developer.apple.com/app-store/review/guidelines/#payments) and [Google Play Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en). Their digital-content billing requirements and exceptions depend on distribution and program eligibility; a generic external checkout should not be assumed suitable for both stores.

Once chosen, the provider adapter must verify signature, merchant/order, course, amount/currency and final settlement; handle duplicate/out-of-order events; and record revocation safely. Those provider-dependent checks have not been implemented or tested and are not represented as complete.

## Remaining boundaries

- **Phase 3:** remove manual completion controls and replace the current lesson's compatibility completion boolean with validated playback/reading evidence. The boolean cannot currently complete a locked future lesson, but it still does not prove engagement in the current one.
- Signed URLs already issued and files already downloaded cannot be recalled instantly. Account-scoped in-app storage and the existing offline authorization lifetime remain in force. Public third-party URLs cannot gain private-host authorization from Supabase; private uploads should be used for restricted files. This is not DRM.
- Phase 4 still supplies full teacher activity-order/required controls. Phase 5 completes selected-lesson Materials/Assessment presentation and syllabus styling. Reviews remain Phase 6.
- Historical empty courses and real assessment drafts were preserved; nothing was silently published to repair their data.
- Native iOS verification and configured checkout remain deployment dependencies. The next independent implementation phase is Phase 3.

Roll forward with compatible fixes if needed; preserve enrollment audit, progress, assessment history, waivers and earned certificates. Do not undo deployment by deleting learner records or re-enabling unguarded legacy entry points.
