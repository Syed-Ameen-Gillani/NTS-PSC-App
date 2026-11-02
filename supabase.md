# Supabase Integration Plan

## 1. Purpose

This document is the implementation roadmap for replacing the NTS/PSC app's in-memory, hardcoded, and asset-backed demo data with authenticated, persistent Supabase data.

Initial product decisions: teacher signup is open, published catalog metadata is public before sign-in, and the first enrollment path is free/manual. New accounts can sign in immediately, so disable **Confirm email** in the remote Supabase Auth > Providers > Email settings (the local CLI config also disables it). Database authorization uses the persisted signup role, never the role selector in Flutter.

The migration should be incremental. Existing Flutter screens and Riverpod controllers should continue to work while repository implementations are replaced one domain at a time. Production app runs always use Supabase; mock repositories remain available only as explicit test fixtures until each phase passes its acceptance gate.

### Execution status (2026-10-10)

#### Assessment persistence verification (2026-10-24)

The configured hosted project is migrated through `20261024010000_assignment_external_links.sql`. The assignment link column and authenticated write grants are present, and the `save_teacher_quiz` RPC is available. Hosted rollback-safe quiz and assignment SQL regressions pass. An authenticated teacher API smoke test saved and reread an assignment link, private brief file, and two-question quiz with answer keys, then cleaned up its temporary records. Eighteen focused Flutter tests pass, and the app's public Supabase configuration matches the hosted project checked here. Device UI acceptance remains open. See [assessment persistence](docs/features/assessment_persistence.md).

#### Latest course-publication verification

This update supersedes the older migration-count and media-smoke-test notes below. Seventeen migrations are now applied through `20261010150000_course_publication.sql`, including checkpoint feedback/quota migrations 13 and 14. Course creation is transactional and draft-first; covers upload to an owner-controlled public artwork bucket; database publication gates require a cover and ready lessons. Published curriculum is locked until moved back to draft. The hosted upload/publication/enrollment isolation journey passes and retained MEDIA TEST data is available. Automatic transcription reached `needs_review` on a test video; representative Urdu accuracy and physical-device checks remain open. Eleven focused Flutter tests pass. See [course upload and publication plan](docs/course_upload_publish_plan.md) for evidence and outstanding operational checks. The amended checkpoint generator still needs separate redeployment before its feature flag is enabled.

#### Teacher workspace verification (2026-10-13)

Migration `20261013000000_teacher_dashboard_finance.sql` is applied to the hosted project. The teacher dashboard now loads owned enrollment totals and recent enrollment records through a privacy-safe RPC. Financial summaries and payout history use owner-readable, provider-written Supabase ledgers; authenticated clients cannot create payouts or earnings. Until PayFast is connected, the correct live state is zero balances, empty payout history, and a disabled withdrawal action. The hosted aggregate/RLS regression passed. See [teacher dashboard and profile audit](docs/teacher_dashboard_profile_audit.md).

#### Notification system verification (2026-10-14)

Migrations `20261014000000_complete_notifications.sql` and `20261014010000_notification_scheduler.sql` are applied. The app now has a durable RLS-protected inbox, FCM token lifecycle, foreground/background/terminated handling, auth-aware notification navigation, Android channels, iOS badges, and persisted live-class reminders. Supabase triggers cover announcements, live classes, assignments, quizzes, and lessons. The generalized FCM HTTP v1 worker revalidates authorization/preferences, records per-device receipts, retries bounded failures, and removes invalid tokens. The corrected worker is deployed; one Vault worker secret and two active cron jobs were verified, and the latest cron invocation returned HTTP 200. Android debug APK compilation passes. Physical notification delivery and iOS runtime acceptance remain open; APNs key/capability/provisioning setup is deferred until the Apple Developer account is available.

#### Earlier integration status (historical)

- Lecture-media pilot: migration `20261010120000_lesson_media.sql` is applied to the hosted project, with a private 25 MB `lesson-videos` bucket, versioned uploads, owner/enrollment policies, transcript review, separate checkpoint keys, and server-scored attempts. The teacher has a resumable TUS upload and review sheet; the live student player can stream hosted video, seek in its transcript, answer approved checks, and download an app-private copy with offline answers queued for sync. `transcribe-lesson`, `lesson-transcript-callback`, and an initial `generate-lesson-checkpoints` are deployed. Deepgram API and callback secrets are configured in hosted Edge Function secrets, but automatic Urdu transcription still needs an end-to-end teacher-video smoke test. Teachers can manually enter/correct transcripts for testing. The follow-up answer-feedback guard `20261010130000` and generation quota `20261010140000` are local only, and the amended generator must be redeployed before students use in-video checks. The hosted media smoke test remains pending.
- Product decisions: teacher signup is open; published catalog is public; enrollment begins free/manual; signup allows immediate sign-in. Gemini is the first AI provider for free-tier testing, with OpenAI retained as a fallback when only `OPENAI_API_KEY` is configured; generation is limited to five quizzes per teacher per UTC day. PayFast Pakistan is the intended paid-checkout provider (bank, JazzCash, Easypaisa, and other methods actually enabled on the merchant account). Never fabricate a successful generation or payment while credentials are absent. Assignment uploads are limited to three files of 25 MB each; rejected-submission revisions and attachments remain accessible to the owning teacher. Teacher account deletion must anonymize the teacher while retaining published courses and student learning records. The full deletion workflow and environment separation remain open.
- Fourteen migrations are applied to the configured hosted project, through `20261010120000_lesson_media.sql`. `20261010130000_lesson_checkpoint_feedback_guard.sql` and `20261010140000_lesson_checkpoint_generation_quota.sql` are pending. `supabase/seed.sql` initially inserted seven categories; the category migration adds CSS / PMS and General, for nine total. `docs/supabase_schema.sql` is a legacy reference, not a migration to run.
- Anonymous REST reads of public catalog data work; anonymous `enrollments` returns zero rows, while private `profiles` and `assignments` are denied. The read-only Flutter catalog integration test and nested course mapper test pass. `tool/test_supabase_assignments.ps1` passed on hosted Supabase with disposable teacher/student accounts: assignment draft isolation, enrollment-gated publication, private submissions, rejection/resubmission/approval, immutable submitted content, quiz draft isolation, hidden student answer keys, server scoring, published-question immutability, and teacher-only AI draft/quota RPCs. The latest RLS run may leave four `RLS TEST` Auth users plus their disposable course, quizzes, assignment, and attempt. Three additional clearly named AI smoke-test teachers were created during function verification; the successful run retained its two-question AI draft. **The user wants these test records retained; do not run `tool/cleanup_supabase_rls_tests.ps1` without a new request.** The five AI quota requests from the older RLS run were deleted before cleanup stopped. Broader cross-user RLS and course/media journeys still need tests.
- Flutter production runs now always initialize Supabase; the login data-source selector, `USE_SUPABASE` build flag, runtime provider-container switching, and Google OAuth build flag have been removed. Guest Home/Discover, teacher course create/publish/curriculum, free enrollment, lesson completion, assignment draft/edit/publish/submit/review with private file uploads, and teacher quiz create/edit/publish plus student server-scored quiz submission are wired to Supabase. Attachment-only submissions work; saved files are opened via short-lived signed URLs. Rejected-work resubmissions preserve earlier responses and files for teacher review. Student quiz status filters and weekly goal use persisted attempts. Completed quiz cards and result/review routes now carry a persisted attempt ID; `get_quiz_attempt_review` restores the student's scored answers after navigation or restart without exposing keys before submission. Notification preferences, durable inbox, fan-out, FCM delivery, local reminders, and notification navigation are implemented as described above. Live profile loading no longer substitutes a fictitious user when signed out. The live lesson player uses actual video URL and notes, without bundled demo video/checkpoints. Live AI quiz generation calls the hosted `generate-ai-quiz` Edge Function. Its deployed source prefers `GEMINI_API_KEY` with model `gemini-3.1-flash-lite`, falling back to OpenAI if only `OPENAI_API_KEY` exists. The Gemini secret name was verified in Supabase without revealing its value. A hosted teacher invocation generated and saved a two-question AI draft. Mock repositories are retained only in the test bootstrap. Server-enforced quiz timing/start, checkpoint quizzes, authorized teacher aggregates, lesson discussions, analytics, and several profile/community surfaces remain incomplete; **do not treat the overall Supabase migration as production complete**.
- The hosted Auth settings endpoint now reports `mailer_autoconfirm: true` on 2026-10-10, so **Confirm email** is disabled and the immediate-sign-in setting blocker is cleared. The actual signup/login journey still needs an authenticated end-to-end test. Disabling confirmation implicitly treats unverified addresses as confirmed; add abuse/rate-limit monitoring before public release. See [Supabase Auth configuration](https://supabase.com/docs/guides/auth/general-configuration).
- `DATABASE_URL` is configured locally. Its password contains URI-reserved characters, so migration commands encoded the password in memory. `.env` also contains anon, service-role, and management access credentials; it is ignored and untracked by Git. Never pass the whole `.env` via `--dart-define-from-file`, because that would bundle privileged credentials. The CLI dry-run printed the database password to a tool log once; rotate the database password and update `.env` after this migration work. Function deployment reads `SUPABASE_ACCESS_TOKEN_SECRET` from `.env` into the CLI's `SUPABASE_ACCESS_TOKEN` process variable without printing it.
- Normal local command: `flutter run`. It loads the ignored `assets/config/supabase_public.json` and always uses Supabase. The optional Windows helper `./tool/run_supabase.ps1` reads only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from ignored `.env` and injects those public values; it no longer selects a data mode. Neither command deploys SQL or makes incomplete domains persistent.
- Windows migration command: `./tool/push_supabase.ps1`. It percent-encodes the locally stored database password in memory and redacts command output. Put reference-data changes in a migration; changing a previously-applied seed file did not reinsert rows in the hosted project.
- Verification: read-only hosted catalog integration, assignment/quiz/AI-quota database journeys, mapper/controller, and live-player widget tests pass. Hosted SQL tests confirm the saved review RPC returns questions only to the attempt owner, notification preferences are owner-only, and attachment-only submission, revision retention, and missing-object rejection work. A retained live Storage smoke test uploaded files, submitted/revised work, confirmed teacher access to the older file and denial for another student and another teacher. Clearly named attachment test accounts and their data were retained as requested, including earlier diagnostic runs. The full Flutter suite passes (53 tests, one optional live integration test skipped). The Gemini-enabled quiz function passed a hosted teacher generation/persistence smoke test; the new lesson functions have deployed but not passed an authenticated hosted invocation. PayFast checkout cannot be verified until merchant credentials and the account-specific integration contract are available. See [PayFast API guide](https://gopayfast.com/docs/), [Supabase Edge Function secrets](https://supabase.com/docs/guides/functions/secrets), [Gemini structured outputs](https://ai.google.dev/gemini-api/docs/structured-output), and [Gemini pricing](https://ai.google.dev/gemini-api/docs/pricing).

## 2. Current Architecture

The app currently follows this broad flow:

```text
Flutter screen/widget
    -> Riverpod controller/provider
        -> repository interface (only in some features)
            -> mock in-memory implementation
```

The intended production flow is:

```text
Flutter screen/widget
    -> Riverpod controller/provider
        -> domain repository interface
            -> Supabase repository/data source
                -> Auth / Postgres / Storage / Realtime / Edge Functions
```

Relevant current boundaries:

- `lib/main.dart` starts `ProviderScope`, but does not initialize Supabase.
- `lib/core/networks/supabase_client.dart` contains placeholder URL/key values and returns mock repositories unconditionally.
- `lib/core/repositories/` already defines useful interfaces for auth, courses, quizzes, and lesson-player data; assignments have their own repository interface under `lib/features/assignments/`.
- Several controllers bypass repositories and construct demo data directly.
- `docs/supabase_schema.sql` is a useful prototype, but it covers only part of the app and its policies are not production complete.
- Shared models in `lib/core/models/` currently combine global content fields and per-user fields. These must be separated at the database level and joined into UI projections.

## 3. Complete Dummy/Non-Persistent Data Audit

### 3.1 Authentication and profiles

| Location | Current behavior | Supabase replacement |
|---|---|---|
| `lib/core/networks/mock_data_sources.dart` | `MockAuthRepository` accepts arbitrary credentials and keeps one user in memory | Supabase Auth email/password plus `profiles` row |
| `lib/core/networks/supabase_client.dart` | Credentials are placeholders and providers always return mocks | Initialize `supabase_flutter`; inject real repositories |
| `lib/features/auth/presentation/controllers/auth_controller.dart` | Reads one mock current user; selected role is local state | Observe Supabase auth events and load the authenticated profile |
| `lib/features/profile/presentation/controllers/profile_controller.dart` | Falls back to hardcoded Ahmed Ali; profile edits only update local state | Read/update authenticated `profiles` row and avatar Storage object |
| `lib/features/profile/presentation/pages/delete_account_screen.dart` | Confirmation UI does not delete data/auth user | Authenticated Edge Function or server action that deletes the auth user; cascading data policy |
| Signup/login screens | Email/password UI exists; teacher profile fields are collected | Real sign-up/sign-in, email verification policy, role validation, recovery deep links |

Important correction: role selection in the UI cannot grant teacher permissions. Database authorization must use the role stored in the authenticated user's trusted profile, with policies checking ownership and role. A user selecting the Teacher tab must not become a teacher unless their profile is a teacher.

### 3.2 Home, discover, and catalog

| Location | Dummy data | Supabase replacement |
|---|---|---|
| `home_controller.dart` | Featured courses, continue learning, categories, and new courses are constructed in `build()` | Queries/views for published featured/new courses, category counts, and authenticated enrollment progress |
| `discover_controller.dart` | Trending categories, popular teachers, top-rated and recommended courses are constructed locally | Catalog queries; aggregate views for ratings/enrollment counts; recommendation rule for MVP |
| `mock_data_sources.dart` | Canonical demo courses, modules, lessons, and categories | `courses`, `course_modules`, `lessons`, `categories` and join tables |
| `course_detail_screen.dart` | Fallback course and lesson content | Fetch by route ID; explicit loading/not-found/error states |
| `course_curriculum_tab.dart` | Fallback curriculum | Ordered module/lesson query |
| `public_teacher_profile_screen.dart` | Fallback teacher | Public teacher profile plus published courses and aggregate stats |
| `category_filter_chips.dart` | Hardcoded exam filters | Keep as app configuration initially or load active categories from DB |

### 3.3 Enrollment and learning

| Location | Dummy data/logic | Supabase replacement |
|---|---|---|
| `my_learning_controller.dart` | Hardcoded ongoing/completed courses; marking a lesson adds `0.2` progress | Enrollment query plus lesson completion rows; calculate progress from completed/available lessons |
| `course_enroll_modal.dart` | Mock payment choices; hardcoded `student_1`; local enrollment | Authenticated user ID; free enrollment RPC or verified payment webhook for paid courses |
| `lesson_player_screen.dart` | Fallback course/lesson | Route by IDs and query authorized lesson data |
| `lesson_video_viewport.dart` and full-screen player | Falls back to bundled `assets/videos/lecture.mp4` | Signed/public Storage URL or approved external video URL; bundled asset may remain for offline demo/tests |
| `lesson_playback_controller.dart` | Starts at 06:14; fixed 25-minute duration; fixed checkpoints and quiz IDs | Initialize from actual media metadata and saved `lesson_progress`; checkpoints loaded for lesson |
| `lesson_player_repository.dart` | In-memory quizzes, notes, discussions, completion set | Supabase lesson repository backed by checkpoint, note, discussion, attempt, and progress tables |
| `lesson_notes_tab.dart` | Debounced save goes to memory | Per-user upsert into `lesson_notes`; keep debounce and add retry/error state |
| `lesson_discussion_tab.dart` | Seeded discussions; posts as `Candidate (You)` | Authenticated discussion author, instructor replies, realtime refresh |

### 3.4 Quizzes

| Location | Dummy data/logic | Supabase replacement |
|---|---|---|
| `quizzes_controller.dart` | Quiz lists and score strings are hardcoded | Query available quizzes and the current user's latest/best attempt |
| `mock_data_sources.dart` | Quiz bank, generation, scoring, and creation are in memory | Quiz/question tables; secure submit RPC or Edge Function; attempts and answers tables |
| `active_quiz_screen.dart` | Client receives correct answers and calculates through mock repo | Avoid exposing answer keys before submission; score server-side and return review data afterward |
| `teacher_generate_ai_quiz_screen.dart` | Teacher-only topic, difficulty, timer, and 1-10 question controls call the mock generator | Teacher-authorized Edge Function validates the same limits, calls a provider with a server-held secret, and saves a draft quiz |
| `teacher_quiz_studio_screen.dart` | Published/draft chips use local quiz state; drafts can be edited, published quizzes cannot | Query by persisted publication state; enforce the published edit lock in the database, not only the widget |
| Quiz ready/completed/review screens | Depend on route extras and fallback questions/results | Fetch durable attempt/result by ID so refresh/deep link works |
| In-video quiz controller/repository | Fixed checkpoint quizzes and in-memory completed IDs | Lesson checkpoint questions plus per-student checkpoint attempts |

Security requirement: `correct_option_index` and explanations must not be publicly selectable before an attempt is submitted. Put answer keys in a protected table/schema or expose questions through a safe view/RPC that omits them.

The student assessment tab shows quizzes and assignments separately. Both quiz weekly goals and assignment weekly goals should be calculated from durable attempts/submissions, not saved as independent counters.

### 3.5 Course community

| Location | Dummy data/logic | Supabase replacement |
|---|---|---|
| `mock_community_data.dart` | Reviews, handouts, announcements, and item analysis | Dedicated tables and aggregate queries/views |
| `course_community_controller.dart` | All mutations update local lists only | Async repository mutations, scoped providers by `courseId`, invalidation/realtime updates |
| Review helpful toggle | `userLiked` and count live inside one review object | `review_helpful_votes` unique by review/user; count derived |
| Instructor reply | String fields updated locally | Reply row or reply fields writable only by owning course instructor |
| Resource download state | `isDownloaded` is global UI state | Resource metadata plus per-user download/bookmark record if tracking is needed |
| Resource upload | Fake `example.com` URL | Upload to private `course-resources` bucket and save object path/metadata |
| Announcements | Local prepend only | Course announcement rows; optional realtime and notification fan-out |
| Item analysis | Static percentages | Aggregate from quiz answer records; expose teacher-only view/RPC |

### 3.6 Teacher studio

| Location | Dummy data/logic | Supabase replacement |
|---|---|---|
| `teacher_controller.dart` | Uses hardcoded `teacher_1`; stats are constants; many writes are local only | Use `auth.uid()`; domain repositories/RPCs for all reads and writes |
| `mock_teacher_data.dart` | Doubts, sessions, roster, quiz results, payouts | Derived enrollment/attempt data plus doubts, sessions, nudges, payout tables |
| Create/manage course screens | Course create persists only through mock repo; modules, lessons, publish, delete are local | Transactional CRUD with ownership checks and ordered content |
| Create quiz screen | Persists through mock quiz repo | Teacher-owned quiz/question CRUD; drafts and publish status |
| Assessment Studio | Quiz and assignment tabs both distinguish published content from drafts | Teacher-scoped queries with counts by content type and publication state |
| Course Studio curriculum | Modules and lessons are appended to Riverpod state; lesson form accepts a video URL and notes | Persist ordered modules/lessons, URL or Storage path, and ownership-checked publish changes |
| Doubts | Seed data and local answer | Lesson discussion/doubt records; instructor-only reply/resolve |
| Live classes | Seed data and local schedule | `live_sessions` table, meeting URL access rules, student course enrollment visibility |
| Student roster/analytics | Entire roster and performance are static | Teacher-scoped view/RPC joining enrollments, lesson progress, attempts, and activity |
| Study nudge | Only updates `lastNudgedAt` locally | `student_nudges` record plus notification delivery job/function |
| Payouts | Static balance/history and local request | Teacher payout account/request tables; server-side validation and admin processing |

### 3.7 Settings, payments, and account data

| Location | Dummy data/logic | Supabase replacement |
|---|---|---|
| `notifications_provider.dart` | Defaults and toggles reset each app run | `user_notification_preferences`, one row per user |
| `app_language_screen.dart` | Language selection is in memory | `profiles.locale` or `user_preferences.locale` |
| `payment_methods_screen.dart` | Two cards and two wallets are hardcoded; delete only shows toast | Payment provider customer/payment method references; never store raw card number/CVV |
| `add_card_screen.dart` | Form is UI-only | Tokenize with a PCI-compliant payment provider SDK; store provider token/brand/last4/expiry only |
| `add_wallet_screen.dart` | Wallet form is UI-only | Provider-specific token/account reference and verified status |
| Course checkout | Mock sandbox | External payment gateway plus server-side webhook; webhook creates paid enrollment idempotently |

Supabase is the application backend, not the card processor. Payment secrets, verification, and webhook handling must run in an Edge Function/server environment. Raw card or wallet credentials must never enter Postgres logs or tables.

### 3.8 Assignments and submissions

| Location | Current behavior | Supabase replacement |
|---|---|---|
| `assignments_controller.dart` and `mock_assignment_repository.dart` | Assignments and review decisions exist only in memory; role checks trust the selected UI role and fallback student ID | Assignment repository scoped to the authenticated student or owning teacher, with database-enforced roles and enrollment |
| Teacher assignment list and course view | Published/draft chips, per-course counts, and pending-review counts come from local state | Owner-scoped assignments and submission aggregates; drafts stay invisible to students |
| `student_assignments_section.dart` | All/status chips, title/course search, and fixed five-per-week goal filter local lists | Published, accessible assignment query; server pagination/search when needed; current-week count from distinct submitted assignment IDs |
| `student_assignment_screen.dart` | Text or a local document/media path is submitted; rejected work may be revised before the due date | Private Storage upload, durable submission/revision, signed download, and server-checked due-date/resubmission rules |
| `teacher_review_assignment_screen.dart` | Approve or disapprove changes a local status and feedback | Owner-only review transition with reviewer ID, timestamp, feedback, and audit history |

The current UI uses **Rejected** for the persisted `disapproved` review state. The status filters are a projection of one current submission per student/assignment: not submitted, pending review, approved, or rejected. Search text and the selected chip remain local UI state. Before connecting this screen, correct the current chip label-to-index mapping so each chip filters its named status.

### 3.9 Data that should remain local/static

Not everything belongs in Supabase:

- Theme tokens, icons, navigation definitions, and generic UI copy remain in Flutter.
- Onboarding illustrations and app branding can remain bundled assets.
- Onboarding completion can be local device state unless cross-device synchronization is required.
- Video playback controls such as temporary play/pause, quality selection, and scrub position can remain local; periodically persist only resume position and completion.
- Quiz form selections remain local until submit.
- Assignment search text, selected status chip, and unfinished answer text remain local until submission. The weekly target is currently a fixed product value of five, not a database column; derive weekly progress from submission timestamps.
- Static legal text may remain bundled/versioned in the app, or move to a CMS/table only if non-release editing is required.
- Payment method labels/types can remain configuration; user-linked payment references are remote.

## 4. Target Data Model

Use UUID primary keys, `timestamptz`, database-generated timestamps, explicit foreign keys, checks/enums where stable, and indexes on every foreign key/filter used by the app. Store monetary values as integer minor units (`price_amount`, `amount_minor`) plus ISO currency (`PKR`), never formatted strings such as `Rs 2,500`.

### 4.1 Identity and preferences

- `profiles`: `id -> auth.users.id`, display name, trusted role, avatar path, teacher subject/qualification/bio, contact fields, student target exam, locale/time zone, premium/subscription status, created/updated timestamps. Never accept role or subscription status in a normal self-update.
- `user_notification_preferences`: push/email/SMS and notification category flags.
- `user_devices`: push token, platform, last-seen timestamp; needed only when push notifications are implemented.
- `account_deletion_requests`: optional audit/grace-period workflow. Immediate deletion can instead be an Edge Function.

Derived profile metrics (`courses`, `quizzes`, `avgScore`, teacher student count/rating/earnings) should be queried from source data or safe aggregate views, not editable columns on `profiles`.

### 4.2 Catalog and curriculum

- `categories`: name, unique slug, icon key, active flag, display order. Category routes should use the stable ID/slug; trending labels and course counts are projections, not separate truth.
- `courses`: instructor ID, category ID, title, description, image path, price amount/currency, draft/published status, featured flag, timestamps.
- `course_modules`: course ID, title, display order, unique `(course_id, display_order)` after reorder semantics are defined.
- `lessons`: module ID, title, duration seconds, video Storage path or validated external URL, overview/notes, preview flag, display order, publish status. The Course Studio lesson form currently records duration in minutes; convert at the repository boundary.
- `course_resources`: course/module/lesson linkage, title, object path, MIME type, byte size, display order.

Do not persist `author`, `rating`, `enrolledCount`, `progress`, `isCompleted`, or `isLocked` as mutable course/lesson truth. Author comes from the instructor profile; rating/enrollment count are aggregates; progress/completion/access are user-specific projections.

### 4.3 Enrollment and learning progress

- `enrollments`: student ID, course ID, status, payment/order ID if applicable, enrolled/completed timestamps. Unique `(student_id, course_id)`.
- `lesson_progress`: enrollment ID or `(student_id, lesson_id)`, resume seconds, watched seconds, completed flag, completed/last-viewed timestamps. Unique per student/lesson.
- `lesson_notes`: student ID, lesson ID, content, updated timestamp. Unique per student/lesson.
- `resource_downloads`: user/resource IDs and timestamp, only if product analytics or synced downloaded state is required.
- `course_certificates`: immutable certificate code, student/course, issued timestamp and verification metadata.

Course progress should be computed from published lessons completed, preferably by a view/RPC. Completion/certificate issuance should be a transactional database function to prevent client-side forgery.

### 4.4 Quizzes and knowledge checks

- `quizzes`: owner/instructor, optional course/module/lesson, category, title, type (`course`, `ai`, `checkpoint`), difficulty, duration minutes, passing percentage, draft/published status, published timestamp, created/updated timestamps. AI quizzes belong to teachers, not students.
- `quiz_questions`: quiz ID, prompt, display order, optional topic/hint.
- `quiz_question_options`: question ID, option text, display order.
- Protected `quiz_answer_keys`: question ID, correct option ID, explanation. Do not grant client select access before result authorization.
- `quiz_attempts`: quiz/student, started/submitted timestamps, score, total, percentage, passed, generation metadata.
- `quiz_attempt_answers`: attempt/question/selected option, correctness and awarded points.
- `lesson_quiz_checkpoints`: lesson ID, quiz ID, timestamp seconds, mandatory flag.
- `ai_quiz_generations`: teacher ID, quiz ID, topic, difficulty, requested question count, duration minutes, provider/model reference, status, timestamps, and error code. Keep provider secrets and raw sensitive prompts out of client-visible rows; retain only audit data needed for cost/rate limits.

Quiz submission should be one server-side RPC/Edge Function that validates ownership/access, prevents tampering, scores against protected keys, and commits attempt plus answers atomically.

The teacher's AI form permits 1-10 questions and timer choices of 5, 10, 15, 20, or 30 minutes. Validate those limits server-side. Generated quizzes start as drafts. Draft questions/options/keys may be edited by the owning teacher; publishing is a validated transition. Once published, block ordinary quiz and question updates/deletes in database policy or a guarded RPC. If corrections after publication are required later, create a new version rather than changing an assessment students may already have attempted.

### 4.5 Assignments and review

- `assignments`: course ID, teacher/owner derived through the course, title, instructions, due-at `timestamptz`, draft/published status, published/created/updated timestamps. Do not duplicate mutable `course_title` or teacher name; join them for display. Index `(course_id, status, due_at)`.
- `assignment_submissions`: assignment ID, student ID, current status (`pending`, `approved`, `disapproved`), latest response/revision reference, submitted/reviewed timestamps, reviewer ID, feedback, created/updated timestamps; unique `(assignment_id, student_id)`. Enforce status transitions and due-date rules on the server. A student may revise only a disapproved submission before the due date.
- `assignment_submission_revisions`: submission ID, revision number, response text, submitted timestamp, and immutable snapshot of the associated attempt. Unique `(submission_id, revision_number)`; preserve a rejected answer and feedback when the student resubmits rather than overwriting audit history.
- `assignment_submission_attachments`: revision ID, uploader ID, private Storage object path, original file name, MIME type, byte size, uploaded timestamp. Store metadata only after the object has been uploaded and verified; never store device-local paths or permanent signed URLs.
- `assignment_reviews`: revision ID, owning teacher/reviewer ID, decision, feedback, reviewed timestamp. One decision per submitted revision; disapproval requires feedback. The current status on `assignment_submissions` is a projection of the latest review/revision.

Treat the text response and attachments as alternatives or companions; require at least one. The teacher may read/review only submissions to their own course, while a student may read only their own. A draft or unpublished assignment must not appear in student queries or accept submissions. Define whether unpublishing is allowed after submissions exist; the safe default is to prohibit it. The five-per-week student goal is derived from distinct assignment IDs with a submission timestamp in the user's local week; rejected attempts still count as submitted, while a resubmission of the same assignment does not add a second item to the week.

### 4.6 Reviews, discussions, and announcements

- `course_reviews`: course/student, rating, comment, verified-enrollment flag, timestamps. Unique review policy per student/course unless multiple reviews are a product requirement.
- `review_helpful_votes`: review/user, unique pair.
- `review_replies`: review/instructor, body, timestamp; or constrained reply fields on review if exactly one reply is guaranteed.
- `lesson_discussions`: lesson/course, author, question/body, parent ID if threading is needed, resolved timestamp.
- `discussion_replies`: discussion, author, body, timestamp. This supports more than one reply cleanly.
- `course_announcements`: course/instructor, title, message, urgent flag, published timestamp.

Names, avatars, relative times, helpful counts, and verified status are projections from relations/timestamps rather than duplicated display strings.

### 4.7 Teacher operations

- `live_sessions`: course, instructor, title, description, start/end timestamps, provider meeting URL/reference, status, recording path.
- `student_nudges`: teacher, student, course, message, delivery status, created timestamp.
- `teacher_payout_accounts`: teacher, provider, masked account metadata, provider token/reference, verified flag.
- `payout_requests`: teacher, amount minor/currency, payout account, status, provider transaction reference, timestamps.
- Optional `teacher_earnings_ledger`: immutable credits/debits from verified purchases, refunds, and payouts.

Teacher dashboard stats, roster status, quiz breakdown, and item analysis should be safe views or RPCs. Prefer `security_invoker` views where possible; tightly review any `security definer` function and fix its `search_path`.

### 4.8 Commerce

- `orders`: student, course, amount/currency, provider, provider checkout/reference, status, timestamps, idempotency key.
- `payment_events`: provider event ID, order, event type, verified payload subset/hash, processed timestamp. Unique provider event ID prevents duplicate enrollment.
- `saved_payment_methods`: optional provider customer/payment-method reference, type, brand, last four, expiry, default flag. No sensitive card data.

For an MVP with free/manual enrollment, defer commerce tables but make `enrollments.source` and nullable `order_id` ready for future paid checkout.

## 5. Existing SQL Review

`docs/supabase_schema.sql` is a legacy prototype and must not be run on the connected project. New versioned migrations will replace it. Required changes include:

- Change course price from `TEXT` to integer minor units plus currency.
- Remove duplicated `instructor_name`; join to `profiles`.
- Add categories and explicit ordering/uniqueness constraints.
- Move per-user completion/progress out of content models into progress tables.
- Add missing CRUD policies for modules, lessons, quizzes, questions, enrollments, and submissions.
- The legacy script has no assignments, submission revisions/reviews, or private attachment metadata. Add these through migrations, not by extending the prototype script.
- Ensure teachers can only edit child rows belonging to their own courses/quizzes.
- Prevent public access to correct answers.
- Do not allow all quizzes/questions to be universally readable regardless of publication/enrollment.
- Add policies for profile self-update while preventing users from self-promoting their role.
- Add grants as well as RLS policies; policies alone do not revoke unwanted privileges.
- Add indexes for policy and query columns (`instructor_id`, `student_id`, all parent IDs, status, created timestamps).
- Add `updated_at` triggers where needed.
- Add missing domains listed in Section 4.
- Use migration files under `supabase/migrations/` and generated seed data, rather than one manually maintained monolithic script.

## 6. Authorization and RLS Matrix

Every exposed table must have RLS enabled. The Flutter app receives only a publishable client key. A service-role/secret key is server-only and must never be included in Flutter builds.

| Domain | Anonymous | Authenticated student | Owning teacher | Admin/server |
|---|---|---|---|---|
| Public profiles | Read limited public teacher fields | Read limited public fields; update own safe fields | Same | Full managed access |
| Published catalog | Read published course metadata | Read published metadata and authorized lesson content | Read own drafts and CRUD own content | Full |
| Course curriculum | Published previews only | Read lessons for enrolled courses | CRUD modules/lessons on own courses | Full |
| Enrollments | None | Read/create own where allowed | Read enrollments for owned courses | Full |
| Progress/notes | None | CRUD own | Aggregate/read only for owned courses where product permits; never read private notes | Full |
| Quiz questions | Published safe projection only | Safe projection for authorized quiz | CRUD own quiz content | Full |
| Answer keys | None | Never direct read | CRUD for own quiz; consider hiding during live assessment | Full |
| Attempts/answers | None | Create/read own through RPC | Read aggregate or attempts for owned quiz as permitted | Full |
| Assignments | None unless catalog preview is explicitly chosen | Read published assignments for enrolled courses only | CRUD own drafts; publish through validated transition; no direct update of submitted content | Full |
| Submissions/revisions | None | Create/read own through guarded submit/resubmit operation; no direct status writes | Read submissions for own courses; no editing student response/history | Full |
| Assignment reviews | None | Read decisions/feedback on own revisions | Decide pending revisions for own courses through guarded review operation | Full |
| Assignment attachments | None | Upload/read own private objects only for eligible assignments | Signed read for submissions to own courses; no student-file overwrite | Full |
| Reviews/votes | Read published | CRUD own review/vote | Reply/moderate only for owned course | Full |
| Discussions | Based on course visibility | Read/post when enrolled | Read/reply for owned course | Full |
| Resources | Metadata by access | Signed download when enrolled | Upload/manage own course | Full |
| Live sessions | None unless preview | Read for enrolled courses | CRUD own course sessions | Full |
| Payouts | None | None | Read/create own requests | Process/update |
| Orders/payments | None | Read own | Aggregates only | Full/server webhook |

Policy helpers should use `(select auth.uid())` where appropriate and policy columns must be indexed. Views must be deliberately secured; use `security_invoker = true` for client-facing Postgres views when available.

Publication and review rules need more than row ownership: use guarded database functions/triggers for draft-to-published transitions, immutable published quizzes, one current submission per student/assignment, due-date checks, and pending-to-approved/disapproved review transitions. Recheck ownership and state inside the same transaction to avoid races. Do not authorize teacher operations from a role selected in Flutter.

## 7. Storage Plan

Create separate buckets according to access rules:

- `avatars`: user-owned writes; public or transformed public reads depending on privacy decision.
- `course-thumbnails`: teacher-owned writes; public reads for published courses.
- `lesson-videos`: private; signed URLs only for course owner or enrolled student. For serious video delivery, evaluate a streaming provider rather than serving large raw files directly.
- `course-resources`: private; signed URLs for owner/enrolled students.
- `assignment-submissions`: private; objects under a student/assignment/unique-file path, with the revision association stored in `assignment_submission_attachments`. Only the submitting student can upload their own allowed files; the owning course teacher receives authorized signed reads. The current limit is three files per submission and 25 MB per file. Enforce MIME/extension and maximum size for documents, images, and videos, and clean up abandoned uploads. Do not expose local picker paths in database rows. Add a scheduled orphan cleanup and verify Storage ownership before implementing account deletion.
- `certificates`: private, with authenticated owner download and optional public verification endpoint.
- `teacher-documents`: private administrative verification documents, if introduced; never broadly client-readable.

Store object paths in tables rather than permanent signed URLs. Generate short-lived signed URLs at read time. Define file size, extension/MIME, ownership path, and deletion policies for every bucket.

## 8. Flutter Integration Design

### 8.1 Bootstrap and configuration

- Add `supabase_flutter`.
- Make `main()` async, call `WidgetsFlutterBinding.ensureInitialized()`, then initialize Supabase before `runApp`.
- Supply URL and publishable key through `--dart-define` or `--dart-define-from-file`; do not commit real credentials.
- Add a typed configuration validator that fails clearly when values are absent.
- Configure auth redirect/deep links for Android, iOS, web, and desktop platforms that are supported.
- Change routing to derive authenticated/role destination from session/profile state rather than a hardcoded initial route.

### 8.2 Data mapping

- Add `fromJson`/`toJson` mappers or dedicated DTOs for every persisted model.
- Convert timestamps to `DateTime`; format relative time only in presentation code.
- Convert money to numeric domain values; format `Rs` in presentation code.
- Replace nested course payload assumptions with repository queries that assemble ordered modules/lessons.
- Separate content entities from user projections. Examples: `CourseWithEnrollment`, `LessonWithProgress`, `ReviewWithViewerState`, `QuizWithLatestAttempt`.
- Remove fallback-to-first behavior for missing course/quiz IDs; return `null`/typed not-found errors.

### 8.3 Repository boundaries

Keep the existing interfaces, but expand them instead of calling Supabase directly from widgets:

- `SupabaseAuthRepository`: sign-up, sign-in, reset, sign-out, current profile, auth stream.
- `SupabaseProfileRepository`: profile update, preferences, avatar operations, deletion request.
- `SupabaseCourseRepository`: catalog, details, teacher CRUD, curriculum CRUD, enrollment, progress.
- `SupabaseQuizRepository`: lists, detail-safe payload, generation request, secure submission, teacher CRUD, result/review.
- `SupabaseAssignmentRepository`: published student list, teacher draft/published list, course-scoped assignments, guarded submission/resubmission, private attachment upload/download, and review history. Replace the current global unscoped `getAssignments()`/`getSubmissions()` contract with role- and course-scoped queries.
- `SupabaseLessonPlayerRepository`: checkpoints, attempts, notes, completion, discussions, resume position.
- New `CourseCommunityRepository`, `TeacherRepository`, `PaymentRepository`, and `NotificationRepository`.

Repository providers should support overrides so tests can continue using mocks/fakes. Controllers should become async where their mutations reach Supabase and should expose loading/error/retry state.

### 8.4 Realtime policy

Do not make every table realtime. Initial realtime candidates:

- Lesson discussions and instructor replies.
- Course announcements.
- Live-session status changes.
- In-app notifications.
- Optional payout status changes.

Normal catalog, profile, course, and progress screens should query/invalidate normally. For scalable database-driven realtime, prefer authorized Broadcast channels; Postgres Changes can be used initially for low-volume MVP flows.

### 8.5 Edge Functions/RPCs

Use database functions or Edge Functions for operations that must be atomic, privileged, secret-backed, or tamper-resistant:

- Create profile after auth signup (database trigger or transactional server path).
- Quiz scoring and result creation.
- Assignment submit/resubmit and teacher review transitions, including file metadata validation, due-date/enrollment checks, and immutable revision history.
- AI quiz generation and provider secret handling.
- Paid checkout creation and verified payment webhook processing.
- Enrollment/certificate issuance where eligibility must be checked.
- Account deletion.
- Push/email/SMS notification dispatch.
- Payout request validation and provider integration.
- Teacher dashboard aggregates if a single optimized RPC is preferable to multiple queries.

## 9. Phased Implementation Roadmap

### Phase 0 - Product and security decisions

Goal: remove ambiguity before creating production data contracts.

Tasks:

- Confirm supported platforms and auth redirect schemes.
- Decide whether signup requires email verification.
- Decide who can become a teacher: open signup, approval workflow, or admin invitation.
- Decide guest behavior: unauthenticated browse-only versus anonymous Supabase Auth account.
- Decide whether course catalog and teacher profiles are public before login.
- Decide free versus paid MVP enrollment and select Pakistan-compatible payment provider if paid.
- Decide whether AI quiz generation is in MVP and select its provider/budget/rate limits.
- Decide resource/video hosting and maximum upload sizes.
- Decide assignment attachment limits (including `mp4`/`mov`), allowed MIME types, retention after account/course deletion, and whether students need course enrollment before seeing assignments.
- Decide whether teachers may unpublish an assignment or quiz after students have submitted/attempted it; default to no for data integrity.
- Define data retention and account deletion behavior.
- Define development, staging, and production Supabase projects.

Exit gate: written decisions, a table ownership matrix, and no unresolved choice that changes schema security.

### Phase 1 - Supabase foundation and migrations

Goal: establish repeatable infrastructure without switching app features yet.

Tasks:

- Add Supabase CLI project layout: `supabase/config.toml`, timestamped migrations, and `seed.sql`.
- Create core identity, preferences, category, course, module, lesson, enrollment, and progress tables.
- Add constraints, indexes, timestamp triggers, grants, and RLS.
- Create development seed data corresponding to current demo courses/users without using real personal data.
- [x] Create Storage buckets and owner-scoped policies for profile avatars and
  course thumbnails; defer large video migration if necessary.
- Add automated database/RLS tests for anonymous, student, teacher-owner, other teacher, and server roles.
- Reserve a follow-up migration for assignment/review/attachment tables before the assignment UI is switched; do not force unfinished assessment policies into the initial identity/catalog migration.
- Update or supersede `docs/supabase_schema.sql` so there is one authoritative migration path.

Exit gate: a clean local/staging database can be recreated from migrations and seeds; RLS tests prove cross-user and cross-teacher isolation.

### Phase 2 - Flutter client bootstrap and authentication

Goal: real sessions and profiles drive app identity and navigation.

Tasks:

- Add and initialize `supabase_flutter` with build-time configuration.
- Implement `SupabaseAuthRepository` and profile mapping.
- Subscribe to auth state changes and restore sessions on app startup.
- Implement student/teacher signup, login, logout, password reset, and recovery redirects; email confirmation is disabled by product decision.
- Create profile row reliably on signup; handle a missing-profile recovery path.
- Replace role trust in UI with persisted role; add role-aware router redirects.
- [x] Persist profile edits and validated avatar uploads. Email and protected
  role fields remain immutable from the profile editor.
- Add typed Supabase exception mapping to user-friendly messages.
- Retain `MockAuthRepository` for unit/widget tests through provider overrides.

Exit gate: two real users can register and sign in immediately, recover access, sign in/out, restore a session, edit only their own profile, and cannot alter their protected role.

### Phase 3 - Catalog, home, discover, and course detail

Goal: all student catalog surfaces use one canonical remote dataset.

Tasks:

- Implement category/course/module/lesson DTOs and `SupabaseCourseRepository` reads.
- Replace direct demo construction in `HomeController` and `DiscoverController`.
- Query published featured/new/top-rated courses and popular teachers.
- Implement category filtering and search with pagination/debouncing.
- Load course and teacher detail by ID, not whole objects passed as route extras.
- Use aggregate views/RPCs for rating and enrollment counts.
- Resolve asset-versus-network image rendering with a shared media widget during migration.
- Add loading, empty, retry, not-found, and offline-friendly states.

Exit gate: seeded catalog data appears consistently on Home, Discover, course detail, public teacher profile, and teacher-owned listings; no screen constructs catalog demo entities.

### Phase 4 - Teacher course studio and Storage

Goal: teachers can persist and manage their own curriculum.

Tasks:

- Implement create/update/delete/publish course operations.
- Implement ordered module and lesson CRUD, including reorder support or stable append ordering.
- Add the `assignments` migration and implement course-scoped assignment draft/create/edit/publish operations. The teacher assignment chips must reflect persisted state; pending-review counts become available in Phase 5.
- Upload/replace/delete course thumbnails, videos, and resources with ownership-scoped paths.
- Use draft/published states so incomplete content is not student-visible.
- Replace hardcoded teacher ID with authenticated profile ID.
- Ensure delete behavior handles Storage objects and dependent records intentionally.
- Refactor `TeacherController` mutations to await repository writes and reconcile/invalidate state.

Exit gate: Teacher A can manage only Teacher A's courses, curriculum, and assignment drafts; Teacher B cannot read drafts or mutate them; published changes appear on eligible student surfaces.

### Phase 5 - Enrollment, lesson player, and progress

Goal: learning state persists correctly per student and device.

Tasks:

- Implement free enrollment first, or integrate verified payment flow if Phase 0 requires paid MVP.
- Replace hardcoded `student_1` with `auth.uid()` and make enrollment idempotent.
- Add submission, revision, review, and attachment migrations with owner/student RLS and a private `assignment-submissions` bucket; the course-level `assignments` table is created in Phase 4.
- Query only published assignments for eligible students; support title/course search and status filters (`not submitted`, `pending`, `approved`, `disapproved`) from the current student's submission.
- Implement text-or-attachment submit, rejected-work resubmission before due date, teacher approve/disapprove with feedback, and durable revision/review history.
- Derive the assignment weekly-goal count from distinct assignments submitted in the current local week; keep the current target of five in product configuration until goals become user-editable.
- Query My Learning from enrollments; split ongoing/completed from real progress.
- Persist lesson completion and resume position with throttled updates.
- Compute progress from lesson rows rather than adding fixed `0.2` increments.
- Serve authorized media URLs and handle expiration/refresh.
- Persist personal notes with debounced upsert and visible retry on failure.
- Add certificate eligibility/issuance after reliable completion.

Exit gate: a student's enrollment, resume position, notes, completion, course progress, assignment submission, and private attachments survive restart and are invisible to another student; owning teachers can review only their course submissions.

### Phase 6 - Quizzes and secure scoring

Goal: course and teacher quizzes are durable and cannot be scored fraudulently by the client.

Tasks:

- Create quiz/question/option/answer-key migrations and RLS.
- Implement teacher quiz draft/create/edit/publish flows.
- Enforce published-quiz immutability in the database; draft edits and the publish transition must be owner-only. AI-generated quizzes begin as drafts.
- Validate teacher-only AI generation, 1-10 questions, and the supported timer values server-side; store generation audit metadata separately from client-visible quiz content.
- Query student quiz lists with latest/best attempt projection.
- Replace route-only results with persisted attempt IDs.
- Implement atomic server-side submission/scoring and authorized post-submit review.
- Add timer/start/submission rules and define retry/attempt limits.
- Persist checkpoint quizzes and checkpoint attempts; load checkpoint timestamps from lesson data.
- Initialize playback from real lesson duration/position instead of fixed 06:14 and 25:00.
- If in scope, implement rate-limited AI generation through an Edge Function and persist provenance.

Exit gate: correct answers are not exposed before submission; attempts are durable; score/review is identical after app restart; teacher sees authorized aggregates.

### Phase 7 - Community, discussions, and announcements

Goal: replace all in-memory social/course community behavior.

Tasks:

- Implement verified enrollment reviews, update/delete policy, and rating aggregates.
- Implement normalized helpful votes and viewer-specific liked state.
- Implement instructor replies with course ownership enforcement.
- Implement lesson discussions/questions and instructor replies/resolution.
- Implement course resource metadata, private downloads, and optional per-user download records.
- Implement course announcements and enrolled-student visibility.
- Add scoped Riverpod providers keyed by course/lesson ID.
- Add realtime only for discussions, replies, and announcements where it improves UX.
- Derive quiz item analysis from actual attempt answers through teacher-only view/RPC.

Exit gate: every community mutation survives restart, updates authorized viewers, and rejects non-enrolled/non-owning actors.

### Phase 8 - Teacher analytics, live classes, nudges, and payouts

Goal: make the teacher studio operational rather than illustrative.

Tasks:

- Build teacher dashboard aggregate views/RPCs from courses, enrollments, reviews, progress, and quiz attempts.
- Replace mock roster and quiz breakdown with teacher-scoped analytics queries.
- Derive the redesigned Analytics screen's published-course count, roster count, average progress, quiz score, and learners needing attention from authorized source rows; never insert fabricated question failure rates.
- Consolidate doubts with lesson discussions or define a separate domain if workflow differs.
- Implement live-session scheduling/status/recording metadata and enrolled-student access.
- Persist nudges and connect notification delivery when available.
- Design earnings ledger and payout accounts/requests; keep processing server/admin controlled.
- Add pagination and date filtering for rosters, attempts, and payout history.

Exit gate: teacher stats reconcile with source records; all analytics are owner-scoped; financial state cannot be edited directly by a teacher client.

### Phase 9 - Preferences, notifications, account lifecycle, and commerce

Goal: complete remaining profile operations and external integrations.

Tasks:

- Persist language and notification preferences.
- Store device push tokens and implement notification fan-out if push is in scope.
- Implement secure account deletion with reauthentication/grace policy and cascading/anonymization rules.
- For teacher deletion, preserve published courses, curriculum, enrolled students' progress, and historical assessment records while replacing public and private teacher-identifying profile fields. Do not use the current `profiles.id -> auth.users.id ON DELETE CASCADE` unchanged: hard-deleting the Auth user would cascade into data that must be retained or fail on dependent teacher rows. Design and test a server-only, idempotent deletion workflow, including Storage object ownership transfer/removal, signed-in token expiry, partial-failure recovery, and role/ownership policies for the retained anonymous instructor. Supabase documents that Auth user deletion does not immediately invalidate issued JWTs and can fail if the user owns Storage objects; account for both before enabling the live delete button.
- Integrate payment-provider tokenization for saved methods; remove hardcoded methods.
- Implement checkout Edge Function and signed webhook processing with idempotency.
- Create enrollment only after verified payment success; handle failed/refunded/chargeback states.
- Implement payment/payout audit logging without storing sensitive credentials.

Exit gate: settings sync across sessions; deletion works end to end; payment retries/webhook duplicates cannot create duplicate orders or enrollments.

### Phase 10 - Hardening, observability, and mock retirement

Goal: prepare for production and remove accidental demo behavior.

Tasks:

- Add repository unit tests, Supabase integration tests, RLS tests, and end-to-end role journeys.
- Replace existing tests' implicit global mocks with explicit provider overrides/fixtures.
- Test network loss, expired sessions, deleted content, signed URL expiry, duplicate submits, and concurrent writes.
- Test interrupted/oversized attachment uploads and cleanup, duplicate review decisions, concurrent resubmissions, and publication changes after submissions/attempts exist.
- Add crash/error monitoring and structured logs with no credentials/PII leakage.
- Review query plans and indexes; add pagination to unbounded lists.
- Add rate limits/abuse controls for auth, AI generation, reviews, discussions, and notifications.
- Configure backups and perform a restore drill; remember database backups do not automatically cover Storage objects.
- Run dependency/security review and verify no service secret exists in build artifacts.
- Remove production fallback entities and artificial delays.
- Keep mock repositories only under test/dev fixtures, or delete them after equivalent tests exist.

Exit gate: production build uses no mock data paths, security tests pass, key journeys pass end to end, monitoring/backups are documented, and rollback has been rehearsed.

## 10. Testing Strategy

### Database and policy tests

- Anonymous can read only intentionally public, published data.
- Student A cannot read or mutate Student B's enrollment, notes, progress, attempts, orders, or preferences.
- Student A cannot see teacher assignment drafts, Student B's submissions or attachment objects, or submit after the due date; rejected resubmission keeps earlier revisions and reviews.
- Teacher A cannot mutate Teacher B's courses, child modules/lessons, quizzes, resources, sessions, replies, or payouts.
- Teacher A cannot read/review Teacher B's assignment submissions or attachments, and cannot rewrite a student's submitted response or an existing review.
- Published quiz/question content cannot be edited through direct table updates; AI generation rejects non-teachers and counts above ten.
- Students cannot select answer keys or financial/admin records.
- Non-enrolled users cannot access private lessons/resources/live sessions.
- Duplicate enrollment, vote, review, attempt finalization, and webhook events behave according to unique constraints/idempotency rules.

### Flutter tests

- Continue unit testing controller behavior by overriding repository providers with deterministic fakes.
- Add mapper tests for nulls, numeric conversion, timestamps, nested projections, and malformed payloads.
- Add assignment mapper and repository tests for status filtering, no-submission projections, due-date boundaries, attachment metadata, resubmission history, and local-week goal counts.
- Add auth redirect/session restoration tests.
- Update widget tests to inject fixtures rather than relying on production providers returning mocks.
- Add integration journeys for student signup/enroll/learn/quiz/review and teacher create/publish/respond/analyze.

### Migration verification

- Rebuild a clean local project solely from migrations and seeds.
- Run migration up/down strategy in staging. Supabase migrations are normally forward-only; rollback should be a tested compensating migration or deployment rollback.
- Compare seed counts and representative queries before switching a feature provider.
- Keep per-domain feature flags/provider switches only during migration, then remove them.

## 11. Operational and Security Checklist

- [ ] Separate dev, staging, and production projects and keys.
- [ ] Commit migrations and safe seed data; never commit real secrets or production exports.
- [ ] Use publishable client key in Flutter; service secret only in server/Edge Function secrets.
- [ ] Enable RLS and intentionally set grants for every exposed table/view/function.
- [ ] Index all RLS ownership and common filter columns.
- [ ] Protect answer keys, financial rows, private notes, and teacher documents.
- [ ] Protect student assignment responses, revision/review history, and private media/document attachments.
- [ ] Validate role/ownership in the database, not only in Dart.
- [ ] Use signed URLs and path ownership policies for private Storage.
- [ ] Verify file MIME, size, extension, and object path.
- [ ] Use idempotency for enrollment, checkout webhooks, quiz submission, and payout requests.
- [ ] Use database timestamps and typed date formatting instead of strings like `Just now`.
- [ ] Paginate reviews, discussions, catalog lists, students, attempts, and transactions.
- [ ] Dispose auth/realtime subscriptions and avoid duplicate channels.
- [ ] Define data deletion, anonymization, retention, and audit requirements.
- [ ] Monitor auth failures, policy denials, function errors, payment webhook failures, and storage usage.

## 12. Recommended First Implementation Slice

The lowest-risk vertical slice is:

1. Phase 0 decisions.
2. Foundation migrations for profiles, preferences, categories, courses, modules, and lessons.
3. Real email/password auth and session-aware routing.
4. Read-only catalog data on Home, Discover, course detail, and public teacher profile.
5. Teacher course CRUD.
6. Enrollment and progress.
7. Assignment publishing, private submissions, and teacher review.

This order establishes identity and ownership before writes become available. Assignments follow enrollment because submission access depends on course eligibility. Quizzes, social features, analytics, payments, and notifications then build on stable user/course/enrollment IDs instead of temporary identifiers such as `student_1` and `teacher_1`.

## 13. Definition of Done

The Supabase migration is complete when:

- No production screen depends on constructors containing demo domain data.
- No production provider returns a mock repository.
- Every user-scoped action uses the authenticated identity, never a hardcoded ID.
- Every mutation persists, reports errors, and reconciles Riverpod state.
- Refreshing/restarting/deep-linking reproduces the same durable state.
- RLS tests demonstrate cross-user and cross-teacher isolation.
- Quiz answers and privileged financial operations are enforced server-side.
- Storage objects have explicit ownership/access/deletion rules.
- Assignment drafts, submissions, reviews, revisions, and attachments survive restart with cross-user and cross-teacher isolation.
- Existing widget/unit tests use explicit mocks/fakes, and end-to-end Supabase journeys pass in staging.

## 14. Official References

- Flutter quickstart and initialization: https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Realtime overview: https://supabase.com/docs/guides/realtime
- Database change subscriptions and Broadcast guidance: https://supabase.com/docs/guides/realtime/subscribing-to-database-changes

## 15. Lecture Video, Urdu Transcripts, In-Video Checks, and Offline Viewing

This is a cross-domain implementation track, not an extension of the mock-only playback controller. The first hosted-video path is implemented in live mode alongside the older external-URL path; the acceptance gates below are not all passed. In particular, do not expose in-video checks to students until the pending feedback-guard migration is applied.

### Pilot implementation status

- Applied migration `20261010120000_lesson_media.sql` creates private versioned media, teacher-only transcript drafts, enrollment-gated active video reads, draft/approved checkpoints, protected keys, and idempotent scoring. A teacher's old playable video remains active until the new transcript is reviewed and the new version is published.
- Flutter uses `tusc` 6 MB chunks for upload (maximum 25 MB at picker, reservation, and bucket), and `background_downloader` 9.5.9 for app-private downloads because the installed Dart SDK cannot resolve 9.6.x. Android Gradle Plugin was raised to 8.9.1 to satisfy the new AndroidX AAR metadata; a debug APK build passed. Course Studio exposes upload, transcript editing, Gemini check generation, question/key editing, approval, and publish controls. The student player loads a signed URL or validated local file, pauses at approved checks, and offers timestamped transcript seeking. My Learning has a separate Downloads view that remains reachable when the online course list fails. Offline answers are queued per user and retried while the app runs.
- Deepgram Nova-3 `language=ur` asynchronous callback code is deployed but needs `DEEPGRAM_API_KEY` and `DEEPGRAM_CALLBACK_SECRET` as Supabase Function secrets; no key is bundled into Flutter or Git. Representative Urdu/English accuracy and callback behavior have **not** been validated. The manually entered transcript route is available for pilot testing.
- The 25 MB limit is currently mirrored in SQL and Dart, not generated from one shared source. Raising it requires a versioned bucket/constraint migration and a matching client release, and remains bounded by the hosting plan.
- Pending: apply `20261010130000` and `20261010140000`, redeploy the amended checkpoint generator, rerun `tool/test_supabase_lesson_media.ps1`, and verify TUS, callback, player, and downloads on Android. `LESSON_CHECKPOINTS_ENABLED` defaults to `false` in Flutter until the answer-feedback guard is applied and verified; enable it only then with a non-secret Dart define. Missing from the Coursera-like target: in-app transfer pause/resume controls, searchable transcript, durable upload resume after app restart, content hash/disk-space checks, expired URL renewal, orphan cleanup, watched-time/resume progress sync, and broader offline revocation/retention testing. The current seven-day offline lease is a pilot policy, not DRM.

### Audit continuation: 2026-10-12

- The current prioritized execution tracker is `docs/project_audit_2026_10_11.md`; integration setup steps are in `docs/integration_configuration.md`.
- Hosted notification queue hardening and `send-push` deployment are verified with rolled-back SQL tests and unauthenticated HTTP 401. Real FCM/APNs delivery remains gated on credentials and scheduler configuration.
- Manual quiz writes now use `save_teacher_quiz` as one transactional RPC (`20261012000000_atomic_quiz_save.sql`). Rollback, publication locking and unauthorized-write tests passed on hosted Supabase. Creation retry idempotency and multi-question editor navigation remain pending.
- Android auth/recovery UI smoke test passed on the emulator; this does not certify native provider login, real recovery email links, notification delivery, video/offline behavior or iOS runtime.

### Decisions and provider evaluation

- Transcript quality must be measured on representative NTS/PSC lectures containing Urdu, English, code-switching, and exam terminology. Google Cloud Speech-to-Text V2 lists `ur-PK` for Chirp 3, but its batch API requires audio in Google Cloud Storage. Deepgram Nova-3 also lists Urdu (`ur`) and can process prerecorded media from a URL, making it a simpler pilot candidate; test its accuracy and Urdu/English code-switching on actual lectures before choosing. The dedicated Gemini 3.5 Transcribe supported-language table currently does **not** list Urdu; do not assume the existing Gemini quiz key gives reliable Urdu ASR. Gemini video/audio understanding remains an experimental comparison adapter, not a silent production fallback. References: https://docs.cloud.google.com/speech-to-text/docs/speech-to-text-supported-languages, https://docs.cloud.google.com/speech-to-text/docs/quotas, https://developers.deepgram.com/docs/models-languages-overview/, https://developers.deepgram.com/docs/pre-recorded-audio, https://ai.google.dev/gemini-api/docs/transcribe, https://ai.google.dev/gemini-api/docs/audio.
- Supabase's current Free plan lists a 50 MB per-file upload maximum. A short-video pilot can stay below this cap; full-length lessons need a paid plan or a video-specific storage/transcoding service. Supabase recommends TUS/resumable upload for files above 6 MB or unstable connections. Never read a full lecture into Flutter memory with `uploadBinary`. References: https://supabase.com/pricing, https://supabase.com/docs/guides/storage/uploads/resumable-uploads.
- For offline transfers, evaluate `background_downloader` for native background, pause/resume, progress, and app-private paths on supported mobile/desktop targets. Check its platform configuration and test the app's actual target platforms before adopting it. A downloaded raw MP4 is an offline convenience, not DRM; do not promise content protection against a compromised device. Reference: https://pub.dev/packages/background_downloader.
- Product decisions: the first hosted-video test limit is 25 MB (below the current Supabase Free 50 MB hard cap), with one configurable limit shared by UI, bucket, and server validation. Use teacher-reviewed transcript and low-stakes in-video questions before student publication; AI output is never auto-published. Downloaded lessons include checkpoints, and offline answers/progress queue idempotently for sync on reconnection. This follows Coursera's public description of in-video practice/feedback and offline video and quiz sync, without copying its proprietary UI or claiming undocumented internals. References: https://blog.coursera.org/how-to-maximize-instructional-design-to-bridge-the-middle-skills-gap/, https://blog.coursera.org/mobile-offline-features/.

### Delivery phases

1. **Media foundation:** Create a private `lesson-videos` bucket or video-service adapter, immutable versioned object paths, ownership/enrollment RLS, upload session state, size/MIME/duration checks, and a teacher upload UI. The first pilot accepts at most 25 MB per video; keep the limit in one versioned policy and enforce it independently at picker, bucket, and server boundaries. Use resumable upload with progress, cancel, retry, expired-session recovery, no accidental overwrite, and orphan cleanup. Preserve the old playable version until its replacement is processed and approved. Store the Storage path, not a signed URL, in `lessons`; retain external URLs as a separate mode and do not promise transcription or offline download for arbitrary external hosts.
2. **Transcript job:** On finalized upload, enqueue an idempotent server job keyed by lesson/version/provider. Extract or register audio using a worker suitable for long-running jobs; do not block a request or Edge Function while a lecture is processed. Persist job status (`queued`, `processing`, `needs_review`, `ready`, `failed`), attempt count, diagnostic code, language, model/version, and timestamped segments. Use least-privilege server credentials, bounded retries/backoff, and no raw media/transcript in logs. Allow the teacher to correct segments and retry a failed job. Reject empty, low-confidence, out-of-range, overlapping, or malformed timestamps for checkpoint source material.
3. **Grounded check generation:** Generate a small set of draft multiple-choice questions from **bounded transcript windows**, including source segment IDs/time ranges. Validate four nonempty options, exactly one answer, a supported timestamp, and an explanation grounded in the transcript. The owning teacher can inspect/edit/approve before publication. Persist a stable schedule per lesson media version with minimum separation and no checks in the opening/closing seconds; a seeded shuffle can make placement feel varied without moving on every replay. Do not insert random popups independent of what the student has watched. Separate answer keys under the existing protected quiz pattern, and reuse server scoring where possible.
4. **Player integration:** Load the published schedule and learner checkpoint state with the lesson. On playback crossing a pending checkpoint, pause exactly once and display a low-stakes, accessible question with immediate answer-specific feedback and an option to review the relevant transcript/video moment. Seeking across multiple pending checkpoints lands at the first one; rewind/replay does not re-open completed checks. Handle seek races, speed changes, buffering, app background/foreground, lesson switching, refreshed pages, changed media versions, and quiz failure/retry. Save attempts idempotently with server-authoritative progress; never use the hardcoded `374`/`780` second checkpoints in live mode. Completion rules must distinguish watching from merely seeking. Add searchable timestamped transcript and click-to-seek/highlight where available, consistent with Coursera's public transcript features: https://blog.coursera.org/updates-to-your-learning-experience-on-coursera/.
5. **Offline library:** Download only authenticated, enrolled, downloadable hosted lessons into app-private storage with progress/pause/resume/cancel/delete and a visible storage footprint. Prefer an authenticated transfer or a renewable signed URL, and reauthorize/restart safely when tokens or URLs expire; never persist a permanent signed URL as the offline record. Use temporary files plus atomic rename, expected size/hash verification, free-space checks, and a manifest keyed by user/lesson/media version. Play with `VideoPlayerController.file` on supported platforms. Purge or block the local copy on sign-out, account switch, enrollment revocation, version change, and account deletion. Cache the published checkpoint questions with the same media version; allow offline attempts, queue immutable answers/progress, and submit once on reconnect with server-side deduplication/conflict handling. Provide a downloads manager, Wi-Fi-only setting, and stale-content cleanup. Coursera publicly describes offline video/readings, offline quiz submission on reconnect, Wi-Fi-only downloads, auto-delete, and consolidated download management: https://blog.coursera.org/mobile-offline-features/. Do not mark unsynced offline results as server-graded, and do not trust the device clock for deadlines or entitlement.

### Exit gates and edge-case tests

- The teacher can upload an allowed short test video, interrupt/resume it, see transcription status, correct an Urdu/English transcript, approve grounded checks, and replace the video without breaking an enrolled student's current lesson.
- A non-owner cannot upload/replace a teacher's video or read private transcript drafts; a non-enrolled student cannot stream/download the lesson; no client can read answer keys before submission. RLS, direct Storage requests, and deep links are tested separately.
- Zero-audio, unsupported codec, corrupt file, long/oversize file, duplicate upload notification, transcription timeout/quota/error, poor Urdu transcript, empty AI output, bad timestamps, provider retry, and teacher rejection all surface actionable status without publishing incomplete content.
- The player survives buffering, seeks, replay, speed changes, disconnect/reconnect, and app resume without missing or duplicating checks. Server attempts are idempotent and progress remains consistent across devices.
- Offline transfer survives interruption or fails cleanly, never marks partial files complete, enforces disk-space and user-scoping rules, and removes revoked/stale copies. Test Android and every other supported target; document web limitations separately.

