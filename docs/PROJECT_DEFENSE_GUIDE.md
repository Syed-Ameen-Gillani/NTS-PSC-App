# NTS PSC App — Project Defense Guide

**Prepared from the repository on 31 October 2026.** This is a presentation and viva guide for the implemented project, not a promise that every screen or external integration is production ready. The code and versioned Supabase migrations are the source of truth when behavior changes.

## 1. Project identity and elevator pitch

**Repository/package:** `NTS-PSC-App` / `nts_psc_app`  
**Type:** Flutter learning platform with separate student and teacher experiences  
**Primary backend:** Supabase (Auth, PostgreSQL, Row Level Security, Storage, RPCs, Realtime, Edge Functions)  
**Supporting service:** Firebase Cloud Messaging (FCM) for push delivery  
**Primary platforms:** Flutter targets Android, iOS, web, and desktop; the most concrete native verification recorded here is Android.

**One-minute defense:** “This application helps teachers publish structured courses and helps students learn through lessons, readings, quizzes, and reviewed assignments. A teacher prepares a draft course, organizes modules and lessons, attaches media and assessments, then publishes a validated release. A student discovers and enrolls in a course, completes required activities, and receives a course completion record and certificate when the server confirms eligibility. Flutter handles the interface, Riverpod coordinates state, and Supabase enforces identity, authorization, and persistent learning rules. The app also supports account-scoped offline media, notifications, and teacher reporting. Paid checkout and some settings screens are still outside the completed release.”

### Problem and goals

The problem is fragmented course delivery: content, assessment, progress, and teacher feedback are often separated. The project combines them in a single role-based application. Its goals are to (1) let teachers author and release a real curriculum, (2) give students a clear path from discovery through completion, (3) persist progress and assessment results across devices, (4) protect private content and answer keys, and (5) make selected learning material usable offline.

### Intended users

| User | Main jobs |
| --- | --- |
| Visitor | View public course and instructor information, then register or log in. |
| Student | Browse courses, enroll in free courses, study lessons, download eligible media, take quizzes, submit assignments, review progress, and open an earned certificate. |
| Teacher | Create and publish courses, manage lessons/media/readings/assessments, review submissions, schedule linked live sessions, and view learner/quiz insights. |

## 2. Technology choices

| Layer | Implementation | Why it is used |
| --- | --- | --- |
| UI | Flutter/Dart, Material widgets, `flutter_screenutil`, shared theme/widgets | One codebase with responsive, reusable screens. |
| State and injection | `flutter_riverpod` / Riverpod providers and controllers | Async loading/error states and testable dependency injection. |
| Navigation | `go_router`, `AppRoute`, student/teacher route files | Named routes and role-aware navigation. |
| Authentication and data | `supabase_flutter`, PostgreSQL, RPCs, RLS | Durable user identity and server-enforced data access. |
| Files | Supabase Storage, `file_picker`, `image_cropper`, TUS upload | Course covers, private lesson media, assignment files and readings. |
| Video and offline | `video_player`, `background_downloader`, private local files | Streaming, playback and selected downloaded lessons. |
| Notifications | `firebase_core`, `firebase_messaging`, local notifications, Supabase outbox/Edge Function | In-app and device delivery. |
| PDF | `pdfrx`, certificate Edge Function | Reading and viewing generated certificates. |
| Tests | `flutter_test`, `integration_test`, SQL and Deno tests | UI, domain, backend contract and device validation. |

The current `pubspec.yaml` requires Dart SDK `^3.9.0`. Dependency versions are in that file and `pubspec.lock`.

## 3. Architecture and where to find code

The repository follows a **feature-first architecture**. A typical feature has `presentation` (pages, widgets, controllers), `domain` (models/contracts/rules), and `data` (repositories and platform/backend access). This is the intended pattern; older screens have some legacy shortcuts, so do not claim perfect Clean Architecture compliance.

```text
lib/
  main.dart                     startup and app-wide services
  config/routes/               GoRouter, route enum, student/teacher routes
  core/                        shared models, theme, utilities, repositories, network config
  features/
    auth/, authentication/     login, signup, recovery, auth state
    teacher/                   teacher dashboard, courses, lessons, quiz studio, reporting
    curriculum/                modules, lessons, materials, assessment placements
    home/, discover/           catalog, search, course detail, reviews
    learn/                     player, reading, offline, evidence, outcomes, certificate
    quizzes/, assignments/     assessment authoring and participation
    notifications/             inbox, preferences, push registration/navigation
    profile/, live_classes/    account settings and scheduled meeting links
supabase/
  migrations/                  versioned database schema/policies/functions
  functions/                   Edge Functions, including certificate and push
  tests/                       backend contract checks
test/                          Dart unit and widget tests
integration_test/              app/device flows
docs/                          audits and feature-specific implementation notes
```

**Typical request path:** widget → Riverpod controller/provider → repository → Supabase client/RPC/Storage → PostgreSQL policy/function. A returned state then rebuilds the widget. For example, `TeacherCreateLessonScreen` validates its form, calls `lessonAuthoringProvider(...).notifier.save(...)`, and reports the saved lesson or a retryable error. A client-created UUID makes a retry identifiable. The server also enforces the module's 10-lesson limit, so form validation alone is not the authority.

**Startup:** `main.dart` loads public Supabase configuration, initializes notification bootstrap and Supabase, starts the native downloader, handles local account-scoped caches, restores the signed-in role, and runs `ProviderScope` around `MaterialApp.router`. Router guards direct teacher routes and signed-in routes. Those guards improve navigation; database RLS and authorized RPCs remain the actual security boundary.

**Two login directories:** `features/auth` and `features/authentication` coexist. Explain this as a legacy organization issue, not as two separate authentication systems. Follow active routes and providers when demonstrating behavior.

## 4. End-to-end user flows

### A. Student onboarding and access

1. The visitor chooses a role and sees onboarding/welcome screens.
2. A student signs up with email/password or uses a configured social provider. Email signup requires a subsequent login. Password recovery has a reset route.
3. Supabase Auth identifies the account; its profile holds the role. The router opens the student shell with Home, Discover, Learn, Quizzes, and Profile destinations.
4. Public catalog and syllabus metadata can be shown without revealing private lesson files. The student can search courses, inspect details and instructor information, and read real course reviews.
5. The student can enroll in a **free** course through the `enroll_free_course` RPC. Paid-course pricing exists in the model and authoring UI, but paid checkout is not complete.

### B. Teacher course publication

1. The teacher creates a draft course with title, description/category, optional initial curriculum, pricing metadata and cover art.
2. Course creation is owner-authorized and uses a client-generated course UUID for idempotent retries. The create screen saves a **draft**; it does not silently publish.
3. In Course Studio, the teacher organizes modules and lessons. A module can contain at most 10 lessons. The Create Lesson form takes title, estimated duration, and optional HTTPS streaming URL; Lesson Studio then handles uploaded video, handouts/readings and assessments.
4. Uploaded lesson videos use private Storage and resumable upload infrastructure. Transcript processing/review is a separate workflow. Course cover art is a public catalog asset, not a private-document location.
5. Quizzes and assignments can be authored, linked to course/module/lesson locations, and made visible through publication rules. Required or optional lesson activities define progression.
6. Publication checks ownership, required course metadata, valid cover/content and learning readiness. A published course has a release boundary: staged teacher edits do not immediately replace the student-facing version. `Publish changes` releases the next valid version.

### C. Student learning and outcomes

1. After enrollment, the student opens the syllabus and a lesson allowed by sequential access rules.
2. The lesson can contain video, text/PDF reading, quiz, assignment, or a combination. Lesson resources are scoped to that lesson; module/course work is shown separately.
3. The student studies the required activities. Video and reading progress produce versioned evidence; the server reconciles evidence and prerequisite rules. The client cannot award completion simply by marking a box or seeking to the end of a video.
4. The student takes a timed quiz through a server session. Answer keys stay hidden until authorized review; the server scores and saves attempts. A passing saved attempt meets the linked quiz requirement. Retakes are supported.
5. The student submits an assignment (text/files) for teacher review. Drafts can persist locally. A rejected submission may be revised; pending and approved submissions are protected from overwriting.
6. Course completion requires all applicable published lesson, linked quiz and linked assignment requirements. A saved completion is durable. The student can request an authenticated PDF certificate; the server verifies completion and returns short-lived private access.

### D. Notifications and live classes

Teachers can schedule a live session with an external HTTPS meeting URL. The application stores session metadata and checks authorization/cancellation again before joining. It does **not** provide its own video-conferencing engine. Course/lesson/quiz/assignment/live events can create durable in-app notifications; eligible device pushes are queued and sent by a Supabase Edge Function through FCM. Mobile permission, token registration, local reminders, inbox, preferences and tap navigation are represented in code. Physical-device delivery still needs platform-specific acceptance checks.

## 5. Feature inventory and honest status

| Area | Implemented evidence | Boundary to state in a defense |
| --- | --- | --- |
| Auth/profile | Supabase email auth, role-based startup, profile editing and avatar storage; OAuth and recovery routes/configuration | Provider credentials, redirects and actual device paths need environment-specific validation. |
| Catalog/discovery | Public course data, category/search screens, course detail, instructor profiles, real paginated reviews | Search/recommendation scale and all UI states are not fully device-certified. |
| Teacher courses | Drafts, modules/lessons, covers, staged publication and release validation | External video URL playability depends on the source; some upload interruption cases need further testing. |
| Lesson Studio | Private video upload, preview, transcript workflow, readings/handouts and activity configuration | AI captions/checkpoints need provider configuration, review and rollout control. |
| Quizzes | Manual authoring, AI generation function/UI, links, server sessions/scoring/retries, teacher analysis | AI output quality is not guaranteed; generated questions require teacher review. |
| Assignments | Authoring, attachments/links, student drafts/submissions, teacher review, revisions | Network ambiguity and native file handling require continued device testing. |
| Learning | Sequential access, video/reading evidence, server outcomes, account-scoped offline video/readings | Offline progress is provisional until synced; graded online assessments are not fully offline. |
| Certificate | Authenticated, completion-gated PDF generation/storage/viewing | This is an application completion certificate, not an accreditation or public verification service. |
| Reviews | Eligible student review, editing, real aggregates and pagination | Helpful/reply social controls are not part of the completed review feature. |
| Teacher reporting | Dashboard/roster/quiz insights and finance read models | Withdrawals and real payment settlement require PayFast or another approved provider. |
| Payments/settings | Pricing fields and UI surfaces exist | Paid checkout is deferred. Payment Methods shows hard-coded sample cards/wallets; language selection is local UI state rather than translated app content; account deletion is not a verified live end-to-end lifecycle. |
| Notifications | In-app inbox, push pipeline and preferences | Android/iOS delivery and APNs setup remain release checks. |
| Live classes | Scheduled external meeting links | No built-in conferencing or recording provider. |

## 6. Data model you should be able to explain

The database is built through `supabase/migrations/`, beginning with the foundation migration and extended by later migrations. **Use migrations, not the historical `docs/supabase_schema.sql`, as the current schema reference.** These are the principal relationships (simplified; not every column or link is shown):

```text
auth.users ── profiles (role: student/teacher)
profiles(teacher) ── courses ── course_modules ── lessons
profiles(student) ── enrollments ── courses
enrollments ── lesson_progress
lessons ── lesson_media / curriculum_materials / lesson_activity_placements
courses/modules/lessons ── curriculum_assessment_links ── quizzes / assignments
quizzes ── quiz_questions / protected answer keys / sessions / attempts
assignments ── submissions ── revisions / reviews / attachments
student + course ── course_completions ── private certificate PDF
users ── app_notifications / notification_preferences / push_devices
courses ── live_sessions / course_reviews / course_releases
```

**Why multiple assessment tables?** A quiz definition differs from a student's attempt; an assignment definition differs from a student's submission and teacher review. Keeping these separate preserves history and makes owner/enrollment checks possible. Placement/link tables let one assessment appear at the right course, module or lesson location without confusing its definition with learning progress.

**Why releases?** A teacher can prepare changes while students continue using the current published curriculum. A release manifest and version-aware learning evidence prevent a later edit from silently changing what a student previously completed.

**Why completion and enrollment are separate?** Enrollment is access; `course_completions` records an earned outcome. An earned completion and its certificate identity remain stable even when the curriculum later changes.

## 7. Security and privacy explanation

- The app ships a **public/publishable** Supabase key, loaded through Dart defines or `assets/config/supabase_public.json`. The service-role key, database password and provider secrets must never be bundled in Flutter assets.
- Supabase Auth supplies user identity. PostgreSQL RLS and guarded RPCs enforce course ownership, enrollment, quiz-key visibility, submissions and progress. A hidden button or router redirect is not a database permission check.
- Private lesson video, assignment files and certificates use scoped Storage paths and signed access. Public course covers are handled separately.
- Teacher quiz answer keys are stored separately from student-visible questions and are excluded from start/resume responses.
- Local offline files and outboxes are account-scoped. Startup/auth-change cleanup removes data belonging to another signed-in user. Offline evidence waits for server confirmation before unlocking later lessons.
- Edge Functions that need elevated access authenticate and authorize callers or use a separate worker secret. The push worker does not expose a user-callable unrestricted send endpoint.
- No biometric identity or perfect attention/anti-cheat guarantee is claimed. Playback and reading telemetry establish bounded engagement; quizzes/assignments provide the comprehension check.

## 8. Important design decisions and tradeoffs

1. **Flutter + one codebase:** quicker shared UI, but native plugins and platform configuration still require Android/iOS testing.
2. **Riverpod and repositories:** UI consumes asynchronous state while repositories encapsulate data access. The codebase still contains legacy direct calls and some local state, so refactoring remains possible.
3. **Server-authoritative learning:** client events are evidence; the backend decides completion. This adds sync complexity but prevents simple client-side completion bypass.
4. **Draft/publish boundary:** validation and staged releases protect students from half-authored changes. It makes authoring more deliberate.
5. **Offline media with online confirmation:** students can play saved media without a network, while access and graded outcomes require later reconciliation. Interrupted partial-file resume and signed URL renewal are known reliability work.
6. **External live meeting link:** practical scheduling without building a conferencing service; call quality, recording and meeting identity belong to the external provider.
7. **Free enrollment first:** avoids implying that pricing metadata is a completed payment system. Paid entitlement must eventually come from verified provider callbacks.

## 9. Build, configuration and test instructions

### Local run

1. Install Flutter compatible with Dart `^3.9.0` and the platform toolchain.
2. Run `flutter pub get`.
3. Supply valid `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through Dart defines or the ignored/local public config expected by `AppConfig`. Use only publishable credentials in the app. The config loader validates HTTPS URL and key format.
4. Configure Firebase platform files and the Supabase backend/Edge Function secrets where notification, OAuth, transcription or AI flows are being demonstrated. iOS builds require macOS/Xcode/CocoaPods and APNs setup for push.
5. Run `flutter run -d <device-id>` for the chosen device. Use test accounts with student and teacher roles and a published course.

### Checks

```bash
flutter analyze
flutter test --concurrency=1
flutter test integration_test/<test_name>.dart -d <device-id>
```

Also inspect `supabase/tests/` for authorization/transaction assertions and Edge Function test files for certificate/reading logic. Migration deployment, hosted smoke scripts and device acceptance are separate from widget tests. Do not claim a command passed unless you actually run it for the version being defended.

### Evidence already recorded in repository docs

- `docs/features/student_learning.md` reports backend, Flutter, PDF and hosted flow checks for the October learning work, while explicitly leaving native acceptance open.
- `docs/course_learning_phases3_7_2026_10_27.md` records automatic progression, activity authoring, reviews and rollout checks, with Android/iOS acceptance boundaries.
- `docs/performance_device_testing_handoff_2026_10_29.md` records **331 Flutter tests passed** in that session and a real Android RMX5377 check of teacher/student screens, video playback, video/PDF saving and offline video playback with connectivity disabled. It also records unfinished partial-download resume, performance baseline and native integration-test work. These are historical results, not a fresh test run for this document.

## 10. Suggested live demo (8–12 minutes)

Prepare two test accounts and one draft plus one published free course before the defense. Keep a stable network connection and a video already uploaded.

| Time | Show | Explain |
| --- | --- | --- |
| 0–1 min | Welcome/login and role choice | One app, separate student/teacher experiences. |
| 1–3 min | Teacher draft/course workspace | Draft-first authoring, modules, 10-lesson guard, media/assessment links. |
| 3–4 min | Publish or show published release | Server validation and staged student-facing content. |
| 4–6 min | Student discovery, course detail, free enrollment | Public metadata versus protected content. |
| 6–8 min | Lesson player, reading/materials and quiz/assignment | Required activities and server-confirmed progress. |
| 8–9 min | Downloads/offline video | Account-scoped files and reconnect sync. |
| 9–10 min | Teacher review/roster and student completion/certificate | Assessment history and durable earned outcome. |
| 10–12 min | Architecture/data/security slide | Riverpod → repository → Supabase/RLS; honest limitations. |

If an end-to-end certificate cannot be earned during the demo, use an already completed test course. Avoid changing database records manually just to make a screen look complete.

## 11. Likely viva questions and short answers

**What makes this more than a static UI prototype?** Real repositories, migrations, authorization policies, Storage, assessment sessions, learning reconciliation, notification functions and tests are present. Some settings/payment screens remain prototypes and should be identified as such.

**Why Supabase?** It combines authentication, relational PostgreSQL data, RLS, private Storage, Realtime and Edge Functions. Relational data is useful for course/module/lesson/assessment relationships and durable results.

**What is Riverpod doing?** Providers inject repositories and expose asynchronous state. Controllers perform actions and the UI rebuilds on loading, success or error. It also permits mock repositories in isolated tests.

**Can a student open another teacher's draft or quiz answer key by calling the API directly?** The design uses RLS and guarded RPCs, not route hiding, to reject unauthorized reads/writes. Validate this with cross-user SQL/API tests for the deployed backend.

**How is completion calculated?** Published required lesson activities must be confirmed, linked quizzes passed and linked assignments approved. The server reconciles prerequisites and records the earned course outcome.

**Can the learner skip a video to 90% and complete it?** The evidence model measures unique media coverage and plausible playback time; seeking alone does not count. This is engagement evidence, not proof the human paid attention.

**What happens if the network fails?** Downloads allow eligible media playback; local evidence/drafts can be retained. Server-dependent assessment submission and final progression wait for a connection. Retried operations use stable IDs/receipts where implemented.

**How are quiz answers protected?** Questions and answer keys are separate. Student session APIs omit keys; scoring happens on the server and review access is scoped to the owner.

**How do teacher edits affect existing students?** Staged curriculum and course releases keep the old published version available until the new one validates. Earned completion is not removed by a later edit.

**Is the certificate official/accredited?** It is a completion certificate issued by this application after its own eligibility checks. It is not a claim of external accreditation.

**Are paid courses usable?** Pricing metadata and UI exist, but verified payment checkout/settlement and withdrawal flows are not complete. Do not collect or claim real payment from the demo UI.

**Does the app support multiple languages?** Some content/PDF paths consider Urdu, but the App Language screen currently changes local selection only. Full interface localization is future work.

**Does the app host live video?** No. It schedules and authorizes external HTTPS meeting links.

**What was tested?** Unit/widget, SQL/Edge Function, hosted API and selected Android device paths are documented. Device testing does not cover every screen, long-running reliability case or iOS release behavior.

## 12. Limitations and next work

1. Complete verified paid checkout, webhook-based entitlement and teacher withdrawal integration; replace sample payment-method UI.
2. Complete full localization and account deletion/data export policy and implementation.
3. Finish native reliability checks: interrupted partial-file resume, process-death recovery, expired signed URLs, real upload interruptions and iOS playback/notifications.
4. Measure performance on release/profile builds, optimize bounded catalog queries and provider invalidation based on traces, and set up CI/staging/monitoring.
5. Improve accessibility, responsive device coverage, provider-specific OAuth/AI/transcription acceptance and content quality review.

## 13. Source map for examiners and future maintainers

| Topic | Start here |
| --- | --- |
| Dependencies/startup | `pubspec.yaml`, `lib/main.dart`, `lib/core/networks/supabase_client.dart` |
| Route/role flow | `lib/config/routes/go_router.dart`, `app_routes.dart`, `student_routes.dart`, `teacher_routes.dart` |
| Teacher lesson form | `lib/features/teacher/presentation/pages/teacher_create_lesson_screen.dart`, `controllers/lesson_authoring_controller.dart` |
| Course publication | `lib/features/teacher/presentation/pages/teacher_manage_course_screen.dart`, `lib/core/repositories/supabase_course_repository.dart`, `docs/course_upload_publish_plan.md` |
| Student learning | `lib/features/learn/`, `docs/features/student_learning.md`, `docs/course_learning_phases3_7_2026_10_27.md` |
| Assessments | `lib/features/quizzes/`, `lib/features/assignments/`, `lib/features/curriculum/` |
| Database/security | `supabase/migrations/`, `supabase/tests/` |
| Edge Functions | `supabase/functions/course-certificate/`, `send-push/`, `generate-ai-quiz/`, `prepare-lesson-reading/` |
| Current testing caveats | `docs/performance_device_testing_handoff_2026_10_29.md`, `docs/integration_configuration.md` |

**Closing statement for the defense:** “The core contribution is a role-based learning workflow whose curriculum, assessments and progress are persisted and checked by the server. The demo shows the working path, while the documented boundaries identify the integrations and device checks still required for a production release.”
