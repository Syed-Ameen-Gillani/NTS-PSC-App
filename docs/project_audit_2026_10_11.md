# Project Audit and Implementation Plan

Date: 2026-10-11 (Asia/Karachi). Rules read first: `memory/rules.md`.

## Scope and evidence

Repository-wide inventory and static searches covered 174 Dart files, routes, feature controllers/repositories, 17 migrations, four Edge Functions, platform configuration, tests, and existing plans. Manual tracing focused on authentication, catalog/publication, quizzes, assignments, media/offline storage, community, profile, and teacher operations. This is a source audit, not a claim that every screen has been manually exercised on a device. Existing user changes and retained test data must remain intact.

Baseline: `flutter analyze --no-pub` reports 52 findings (2 warnings, 50 information-level findings). Full Flutter suite: 67 passed, 1 skipped (optional hosted test), 1 failed. The failure is the hard-coded `11 courses` expectation in `test/category_navigation_test.dart:77`. Responsive tests currently pass their existing route matrix; this does not certify all populated, modal, keyboard, error, or accessibility states.

## Prioritized findings

| ID | Priority | Finding and evidence | Impact |
|---|---|---|---|
| SEC-01 | P0 | Assignment and quiz read policies use `e.course_id = course_id` in migrations 040000:111 and 060000:140. The inner relation also has course_id. | Enrollment may authorize unrelated course assessments; qualify outer references and regression-test two courses. |
| DATA-01 | P1 | `course_community_controller.dart:46` unconditionally loads mock reviews/resources/announcements/item analysis. Mutations only update memory. | Live accounts see invented data and false success; no enrollment/owner-backed persistence. |
| DATA-02 | P1 | `payment_methods_screen.dart:49` displays invented cards/wallets. Add-card/wallet, teacher payout/scheduling/nudge paths are local demonstrations. | Financial/communication actions appear successful without provider operations. Disable live unsupported workflows before implementing them. |
| DATA-03 | P1 | `supabase_quiz_repository.dart:137` creates metadata, questions, keys and publication separately; update deletes questions before replacing them. | Partial drafts and lost question content after failure; use one transactional owner-authorized RPC. |
| AUTH-01 | P1 | Password reset sends email but no new-password callback screen exists; social login is not integrated; router trusts restoredRole for client navigation. | Recovery/OAuth incomplete; server RLS remains essential. Add auth-driven routing and callback tests. |
| AUTH-02 | P1 | `delete_account_screen.dart:138` disables live deletion. Teacher profile FKs and publication/storage guards require coordinated anonymization. | Account lifecycle incomplete. Do not implement naive auth-user cascade deletion. |
| MEDIA-01 | P1 | Checkpoint generator writes question and key separately, ignores key-insert errors; quota consumed before provider response. Feature flag currently off. | Partial checkpoints and failed-generation quota consumption; atomic generation completion/retry states required. |
| MEDIA-02 | P1 | Offline library uses expiring manifests, shared queue and account-change checks; manifest replacement deletes the previous manifest before rename. | Crash/retry/storage-full/account-switch behavior needs fault injection; browser imports of dart:io need a platform review. |
| MEDIA-03 | P2 | Transcription callback works in prior hosted smoke, but stuck provider_request_id, duplicate callback, long-running recovery, Urdu quality not certified. | Operational retries and representative Urdu corpus required. |
| TEACH-01 | P1 | Teacher live stats/roster/doubts/sessions/payouts are zeros or empty lists in teacher controller; mutations are memory-only. | Empty is safer than invented data but not a completed live feature. Need aggregate/roster API and explicit unavailable states. |
| LEARN-01 | P2 | `lesson_player_repository_provider.dart` always returns mock; live hosted path is separate. Notes/discussion/checkpoint legacy screens remain mock-backed. | Do not expose mock notes/discussion through live routes; consolidate only with migration tests. |
| UI-01 | P2 | Many `setState`/StatefulBuilder uses across auth, assessments, navigation, shared inputs, course/community, and media. | Violates Riverpod-only project rule. Convert in domain-sized increments with lifecycle tests. |
| UI-02 | P2 | Hard-coded colors/TextStyles/dimensions in 53 feature files in combined search; different font systems and large radii. | Inconsistent hierarchy and responsiveness. Use existing theme and ScreenUtil; preserve visual identity. |
| UI-03 | P2 | Course review rating summary uses all courses' reviews rather than displayed course. Route teacherManageCourse force-casts missing extra. | Incorrect ratings and deep-link crashes. |
| PROFILE-01 | P2 | Language changes only local provider; MaterialApp has no localization wiring. Profile metrics are zero placeholders, avatar is bundled teacher image. | Language success message does not correspond to translated UI. Need locale persistence, translations, truthful profile metrics/avatar. |
| PROFILE-02 | P2 | Certificates/rating/legal contact actions contain local placeholders/no-op handlers. | No issued verifiable certificate, store review integration or approved legal/support workflow. |
| ARCH-01 | P2 | Four Dart files exceed 500 lines: app_models 531, mock_data_sources 675, teacher_dashboard 595, teacher_manage_course 880. | Manage course exceeds even 700-line exception. Extract by responsibility, not arbitrary file splitting. |
| ARCH-02 | P2 | Duplicated auth/authentication login implementations; legacy route names; notification API calls in presentation provider; static AppConfig mode. | Multiple behavior sources and stale state risk. Active routes first; remove legacy only after proving no callers. |
| QA-01 | P1 | Baseline category navigation regression and no cross-course-enrolled adversary in existing assessment tests. | Existing passing owner/outsider tests miss SEC-01. |
| OPS-01 | P1 | Existing supabase.md includes historical status and architecture no longer current; prior log exposure of DB password documented there. | Rotate previously exposed credentials; distinguish local code, deployed state, verified behavior. Never bundle .env. |

## Feature completeness matrix

| Domain | Real implementation | Incomplete / mock / unverified |
|---|---|---|
| Auth/onboarding | Email signup/login, roles, session load, reset email, profile update | OAuth, recovery completion, deletion/anonymization, account-switch/deep-link hardening |
| Student home/discovery | Catalog/category/enrollment/progress queries, empty states, capped previews | Pagination, recommendation ranking, synthetic biography/course-overview text |
| Teacher courses | Atomic drafts, public cover storage, readiness triggers, private video review/publish | Device interrupted uploads, replacement concurrency/orphan maintenance, edit metadata workflow |
| Quizzes | Teacher drafts, server scoring, hidden keys, saved attempts, AI function/quota | Atomic manual save/edit, server-enforced attempt timer, course-specific enrollment correlation |
| Assignments | Draft/publish, three 25 MB files, revision history, review, signed access | Course enrollment correlation, student display names, upload/retry ambiguity tests |
| Lesson media | Private upload, Deepgram callback, review, signed playback, app-private download | Checkpoint production rollout, offline crash/resume tests, captions accuracy, duplicate callbacks |
| Community | Mock UI/models | Persistent scoped reviews/helpful/replies/resources/announcements; notifications delivery |
| Teacher reporting | Course/quiz list counts; mock analytics UI | Real student roster, aggregations, nudges, live sessions and payouts |
| Profile/settings | Profile persistence, notification preferences | Avatar, localized UI, deletion, payments, real notifications, certificates/store links/legal actions |
| Infrastructure | SQL RLS, public client config separation, deployment/smoke scripts | CI, staging isolation, restore/backup drill, telemetry, rate-limit/failure monitoring |

## Ordered implementation phases

### Phase 0: Audit and baseline (P0)

Dependencies: rules and current worktree inventory. Complete before implementation.
Deliverables: this audit, evidence-based backlog, baseline test/analyzer results and configuration inventory.
Acceptance: findings identify actual paths and distinguish incomplete from mock-only; no code edits precede plan.
Status: complete; physical-device and production-provider certification explicitly excluded from static audit.

### Phase 1: Authorization and truthful live behavior (P0/P1)

Dependencies: Phase 0, configured database management access.
Implementation: qualify course-scoped RLS checks; adversarial SQL regression covering student enrolled in A trying B; stop live community fixtures and fake mutation success; prevent live collection of payment credentials before hosted checkout exists; safe missing-route-payload screen; course-scoped rating aggregation. Keep mock mode useful.
Acceptance: own/enrolled reads succeed, unrelated enrolled student fails, live mode has no fixture reviews/cards, unsupported mutations cannot report success, malformed route does not crash.
Tests: transaction-rolled-back SQL RLS test; provider mode isolation; route and empty-state widget tests; full Flutter regression.

### Phase 2: Durable assessment writes (P1)

Dependencies: Phase 1 authorization tests.
Implementation: atomic quiz save/edit/publish RPC with owner and draft locks; validate all questions before commit; stable create UUID for retry; preserve existing questions on failure; follow with transactional checkpoint persistence and server attempt timing contract.
Acceptance: failure rolls back all writes, retry does not duplicate quiz, published content cannot be edited or raced, other teacher cannot mutate; attempts remain server scored.
Tests: invalid second question rollback, duplicate create, unauthorized user, published edit, concurrent publication; mapper/controller and assessment UI regressions.

### Phase 3: Account lifecycle and persistent community (P1)

Dependencies: Phases 1-2, redirect/provider settings for auth, deletion policy already chosen (anonymize teacher, retain courses).
Implementation: recovery callback/new-password flow; auth-state-driven router; transactional anonymization plus idempotent privileged deletion job; reviews/helpfulness/replies/resource uploads/announcements tables, owner/enrollment RLS, async repositories and real empty/loading/error states; privacy-safe roster projections and reporting aggregates.
Acceptance: persistence survives restart, two users/two courses cannot cross-access, no privileged keys in Flutter, deleted teacher identity anonymized without breaking course/student records, failures never present as success.
Tests: reset expired/reused link, auth changes, retry deletion after partial external failure, community ownership/enrollment matrix and storage isolation.

### Phase 4: Media reliability and learning completion (P1/P2)

Dependencies: Phase 2 checkpoint transactions, Phase 3 account cleanup, configured AI/STT providers.
Implementation: provider job state machine/timeouts/retries, callback replay protection, deployment of amended checkpoint function, offline manifest/queue atomicity, reconnect sync, quota failure semantics, progress/notes/discussion integration, server-issued certificates only after eligibility.
Acceptance: interrupted/replaced uploads recover without losing prior media; offline account isolation; no answer-key leakage; duplicate answers/callbacks idempotent; published draft checks never exposed; verified Urdu corpus before claiming accuracy.
Tests: network loss, full disk, account switch mid-download, process kill, seven-day expiry, denied enrollment, seek/pause/resume/offline checkpoints, real Android/iOS playback.

### Phase 5: Design and architecture consistency (P2)

Dependencies: stable domain contracts from Phases 1-4; can begin isolated shared components earlier.
Implementation: remove setState by screen/domain using scoped Riverpod state; extract management/dialog components below line caps; align theme fonts/colors, typography, spacing, Material inputs, responsive constraints and empty/error components. Add locale architecture before enabling language choices; no cosmetic redesign unrelated to findings.
Acceptance: no new rule violations; scoped files under 500 lines; no clipped text or overflow with keyboard, 320px phone, landscape, tablet, desktop and 1.3x/2x text; system navigation matches actual scaffold surface; keyboard/focus/semantic labels remain usable.
Tests: existing responsive suite plus populated/empty/error/modal states, focused interaction tests and device screenshots. Migrate deprecated APIs with behavior checks, not lint suppression.

### Phase 6: External services and release gates (P1 before production)

Dependencies: prior phases and merchant/OAuth/store/push/legal configuration below.
Implementation: PayFast Pakistan hosted checkout and authenticated verified webhooks; delivery-backed sessions/announcements; OAuth, push, app-store review, approved legal/support links; CI analyzer/tests/SQL checks, staging, secret scanning, observability and recovery runbook.
Acceptance: no raw card data stored in app/database; verified idempotent payment callback grants enrollment once; sandbox provider success/failure/cancel replay tests; staging restore and device smoke pass before production flag enablement.
Tests: provider sandbox contracts, webhook tampering/replay/amount mismatch, provider outage, unauthorized actions, release builds and full regression.

## Credentials and configuration required

- Local presence confirmed without printing values: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, DATABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ACCESS_TOKEN_SECRET, DEEPGRAM_API_KEY, DEEPGRAM_CALLBACK_SECRET. Presence is not proof of validity. Management secrets stay server/tool-only.
- GEMINI_API_KEY / GEMINI_QUIZ_MODEL are not in the local inventory; previous hosted quiz success suggests hosted secrets may exist. Verify hosted availability without revealing values. Do not overwrite hosted secrets with empty/mock values.
- PayFast Pakistan merchant sandbox credentials, merchant-enabled payment methods and account-specific signed callback contract; production approval later. Variable names depend on the confirmed integration, not guessed credentials.
- Google OAuth configuration in Google Cloud and Supabase was confirmed complete by the user on 2026-10-12; end-to-end Android sign-in still requires runtime verification. Apple OAuth identifiers/credentials, Apple capabilities, confirmed Apple redirect configuration, password-recovery redirect scheme/domain and SMTP sender configuration remain required.
- Push provider project/configuration and APNs capability if delivery is required; live-session provider decision or approved external meeting-link workflow.
- App Store/Play listing IDs, support URL/email, approved terms/privacy content, Urdu translation/content review, representative Urdu lecture sample and Android/iOS devices for acceptance.
- Staging project/CI permissions and monitoring destination. Prior documented database-password exposure requires rotation outside logs and updating ignored .env.
- No additional credentials are required for the initial local safety/consistency changes. Do not paste secrets into chat or source control.

## Testing and change discipline

Small additive migrations; never rewrite already applied migrations or delete retained data. Run cross-user SQL assertions inside rolled-back transactions. Tests must check positive and negative access, not only empty outsiders. Retain intentional mock fixtures only behind mock mode. Unit tests cover pure validation/aggregation; widget tests cover all async states and navigation; integration tests exercise actual storage/RPCs; device tests validate video and native picker behavior. After each phase rerun affected tests; before closure run analyzer and full regression, explicitly listing failures/skips and unfinished phases. Never equate deployment with production acceptance.

## Execution log

### Confirmed integration decisions (2026-10-11)

- Use external HTTPS meeting links for course-scoped live classes.
- Implement FCM device tokens and Supabase Edge Function delivery. Keep delivery disabled until genuine Firebase/APNs configuration exists; mock credentials must never produce fake success.
- Implement Google and Apple OAuth now, configure providers later. Apple sign-in and APNs are independent configurations.
- Android emulator is the current device acceptance target. No iOS runtime is available: static configuration review is not iOS certification.
- PayFast is deferred. Store/release requirements remain documented, not part of this pass.
- Use Coursera as a reference for uncertain learning flows while retaining the current app design and explicit product decisions; do not invent Coursera's internal security or payment behavior.

- Audit/plan completed before implementation. Implementation results are appended with exact scope and remaining gates; no phase is complete solely because a placeholder/disabled state was added.

### Verified continuation (2026-10-12)

- Applied `20261011020000_push_delivery_hardening.sql` and deployed the updated `send-push` worker. Jobs without a delivery are `skipped`, not `sent`; expired leases retry and exhausted leases become failed. Hosted rolled-back queue tests passed, including denial of authenticated client queue claims. The public endpoint returned HTTP 401 without the worker secret. Actual FCM delivery remains unverified and disabled pending credentials/scheduler setup.
- Android emulator `Pixel_5` / `emulator-5554`: built, installed and passed `integration_test/android_smoke_test.dart` while Supabase was still selected with `USE_SUPABASE=true`. It verifies login social-button visibility and recovery form validation, not an end-to-end OAuth/email/FCM flow. No iOS build/device test was performed.
- Applied `20261012000000_atomic_quiz_save.sql`. Manual quiz creation, draft replacement, answer keys and optional publication now run in one caller-authorized transaction. Hosted tests passed for failed-create rollback, failed-edit restoration, multi-question replacement, publication locking and student denial. Client question validation rejects blank/invalid options before writing.
- Fixed the legacy single-question editor so editing the first question retains other questions and draft metadata. The dedicated widget regression passed. Full multi-question editing/navigation is still pending; this is a data-loss fix, not a complete editor redesign.
- Final full Flutter regression: 73 passed / 1 skipped, including the new editor-preservation and payload tests. The skipped hosted catalog test requires its explicit opt-in environment. Scoped integration/repository/test analysis passes with no issues. Full-project analysis remains at the 52 baseline findings (2 unused imports and 50 informational findings). `git diff --check` reports pre-existing trailing whitespace in `teacher_courses_screen.dart:37`, outside this scoped change.
- Configuration instructions are in `docs/integration_configuration.md`. OAuth provider enablement, real email recovery round trips, Firebase/APNs delivery, foreground/tap notification handling and cold-start auth callback verification remain acceptance gates. PayFast and store release setup remain deferred by user decision.
- Remaining audit work includes community persistence, atomic checkpoint generation, quiz retry idempotency/concurrent edit conflicts, media/offline edge cases, full multi-question editor, teacher analytics/roster data, localization and existing UI/rules violations. The overall audit plan is not complete.

### Configuration update (2026-10-12)

- User confirmed Google Sign-In configuration is complete in Google Cloud and Supabase. Do not recreate or replace those OAuth credentials. Runtime sign-in success, cancellation, wrong-role handling and callback recovery remain acceptance tests.
- Firebase account/project selected by the user: `nts-psc-mobile`. Android and iOS app registrations use `com.ntspsc.app`; local FlutterFire/Android configuration was generated before the user requested a configuration-only pause. No additional implementation or delivery test was completed after that pause.
- Manual Firebase work still required: generate a dedicated server service-account key for FCM HTTP v1, install it only as the Supabase `FCM_SERVICE_ACCOUNT_JSON` Edge Function secret, set a separate high-entropy `NOTIFICATION_WORKER_SECRET`, configure the trusted scheduler, and later upload the APNs authentication key after the Apple developer account is available. Never commit or paste the service-account JSON into source control or chat.
- User confirmed on 2026-10-12 that FCM HTTP v1 is enabled and the Firebase Admin SDK private-key JSON has been generated. The key has not been inspected or moved by the agent. Remaining push gates are installing it as the Supabase `FCM_SERVICE_ACCOUNT_JSON` secret, creating `NOTIFICATION_WORKER_SECRET`, configuring the scheduler, and verifying delivery on a real Android device; APNs remains deferred.
- User confirmed on 2026-10-12 that a cryptographically generated `NOTIFICATION_WORKER_SECRET` has been installed in Supabase Edge Function Secrets. Its value was not shared with or inspected by the agent. Pending: install `FCM_SERVICE_ACCOUNT_JSON`, store the same worker secret in Supabase Vault for the scheduler, create/verify the cron job, and perform real Android delivery testing.
- Runtime data-source update (2026-10-12): production now always initializes and uses Supabase. The login Mock/Supabase selector, `USE_SUPABASE` build flag, provider-container mode switching and Google OAuth build flag were removed. Mock repositories remain only as explicit test fixtures. Startup now fails clearly when the local public Supabase configuration is absent or invalid instead of silently entering mock mode.

### Notification implementation (2026-10-14)

- Implemented the notification domain/data/presentation layers: typed versioned payloads, RLS-backed inbox, read/unread state, permission UX, FCM device registration/refresh/revocation, foreground display, background/terminated taps, delayed auth-aware navigation, safe unavailable-resource screens, iOS badges, Android channels, and persisted local live-class reminders.
- Applied the notification inbox/fan-out and scheduler migrations. Event coverage includes announcements, live-class changes, assignment lifecycle/due reminders, quiz publication, and lesson publication. Delivery revalidates current authorization and preferences, excludes private content from payloads, uses bounded retry plus per-device receipts, and cleans invalid tokens.
- Deployed the generalized `send-push` worker. Hosted health verification reports one Vault worker secret, two active notification cron jobs, and HTTP 200 from the latest worker invocation. Android debug APK compilation succeeds after enabling core library desugaring.
- No automated tests were run in this pass by user request. Physical Android delivery remains manual acceptance. iOS implementation is source-complete, but APNs key upload, Apple capability/provisioning setup, macOS build, and physical-iPhone delivery must be completed when the Apple Developer account is available.
