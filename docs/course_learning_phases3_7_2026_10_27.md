# Course learning delivery: phases 3–7

Date: 27 October 2026. Scope: the approved course-learning plan. The separate full-app performance/caching audit is deferred at the user's request. PayFast checkout remains deferred.

## Delivery status

| Phase | Delivered | Acceptance boundary |
| --- | --- | --- |
| 3 — Automatic progression | Versioned video/text/PDF evidence, server reconciliation, required activity gates, durable account-scoped evidence replay. Manual completion endpoints and direct progress writes are blocked. | Backend fixtures cover enrollment through certificate eligibility. Native playback/reader acceptance still requires a working device test. |
| 4 — Activity authoring | Existing Lesson Studio links to ordered required/optional activity configuration, reading readiness and publication validation. Uses existing media/material/assessment identities. | Required PDF/TXT readings must be prepared before publication; unsupported documents remain supplemental. |
| 5 — Student experience | Complete indexed syllabus, smaller themed module cards, exact lesson resources, separate module/course work, reading route and passive progress. Student resources exclude video and drafts. | Native responsive and accessibility inspection remains part of device acceptance. Player appearance/controls are preserved. |
| 6 — Reviews | Real paginated reviews, eligibility, authenticated upsert/edit, unique student/course association, live rating aggregates and centered empty states. | Server authorization and client loading/retry flows are tested. Account changes hide unfinished review text. |
| 7 — Integration/rollout | Additive migrations and reading Edge Function deployed; bounded evidence batches/receipts, cleanup job, contract/security/regression checks and Android build validation. | Release gate remains open for successful Android emulator and iOS runtime acceptance. It is not a claim of full native certification. |

## Implemented behavior

### Automatic learning evidence

- Video requires 90% unique media coverage of the published source/version. Seeking or an end callback cannot complete it. Sessions accept plausible elapsed playback at 0.5–2x; background time is excluded.
- Text is shown in accessible navigable sections of 80 words, with full section coverage and engagement at 200 words/minute (minimum five seconds). PDF uses actual page count, page coverage and 30 seconds/page. Opening or downloading a document alone earns nothing.
- Evidence sessions last up to seven days. Client outboxes allocate the sample sequence and persist the event atomically in account-private app storage. Lost responses retry the same identities. Expired, changed, rejected and conflicting samples do not become optimistic completion.
- Required mixed lessons wait for every configured activity. A passing saved quiz and an approved saved assignment count; a failed quiz or pending/rejected submission does not. Existing retakes and assignment revision history remain in the original systems.
- Reconciliation checks preceding lessons/module work before creating a completed lesson, including when the same quiz is used in multiple lessons. Course-level requirements remain reachable through a separate course-work entry.
- Existing completed lessons and durable course achievements survive later releases. Access waivers remain distinct from completed lessons and grades. New requirements behind an established access frontier are explicitly waived by placement; new students must complete them. New final course assessments can still apply to unfinished courses.
- A course release evaluates the previous frontier before switching its active manifest. Removing an activity cannot make that evaluation resolve against the wrong version. Teachers can continue staging edits while students use the prior release.

Telemetry establishes bounded playback/reading evidence, not proof of human attention. Graded assessments remain the comprehension check. Arbitrary offline client telemetry cannot provide strong anti-cheat guarantees.

### Authoring, resources and playback

- Video-only, reading-only, assessment-only and mixed lessons use the existing ordered placements. At least one satisfiable required activity is necessary; optional work does not block progress.
- A validated uploaded video can be included in a course release without waiting for AI transcript review. Unreviewed captions are not exposed to learners or labeled available. Existing transcript processing continues independently.
- Teachers can prepare required PDF/TXT readings in activity configuration. Malformed, empty, oversized or unsupported required readings fail clearly. The existing 25 MB limit is retained.
- Syllabus metadata includes every published module/lesson/activity while protected content still requires enrollment and sequential access. Stable IDs, rather than route extras, drive access decisions.
- A lesson's resources show only that lesson's readings, files and assessments. Broader module/course work has separately named navigation. No student course-cover folder or embedded teacher video preview remains in student resources.
- The current player stays alive when scrolling to lesson actions; it still disposes on lesson change/page exit. This prevents controller/session resets without changing playback controls or their styling.
- Automatic status and sync errors replace manual completion actions. Offline video evidence remains provisional until the server confirms it; future lessons stay locked until confirmation.

### Reviews

- An enrolled student with at least one confirmed completed lesson can submit one editable review per course. Course instructors cannot review their own courses.
- Server validation derives the reviewer from auth and checks rating 1–5 and plain-text length 3–2,000. Clients have no direct review-table access; public projection excludes email addresses.
- Pages contain at most 20 reviews, with filters, retry, real aggregates and no unsupported helpful/reply controls. Saving is asynchronous, blocks repeated submission, retains input on failure and refreshes affected course data.
- Signing out/switching accounts hides the open review draft and prevents submitting it as the next account.

## Deployment and configuration

- Migrations `20261026160000` through `20261026200000` add evidence, outcomes, author configuration, reviews, independent video release, bounded retention, prerequisite protection, batching and release-frontier integrity. There are 77 deployed migrations after this delivery.
- `prepare-lesson-reading` is deployed. It uses the existing Supabase URL/service-role variables supplied to Edge Functions; no new third-party key is required. Caller RLS is checked before service-role storage access.
- `pg_cron` job `cboa-learning-evidence-retention-v1` runs at minute 23 each hour. It prunes at most 1,000 sessions expired more than one day ago and their receipt records. Coverage, grades and achievements remain intact.
- Each session retains its latest 100 evidence receipts; uploads contain at most 50 events. Reconciliation runs once per batch, rather than for every sample. The client releases its local file lock during network I/O and drains acknowledged batches in sequence.
- Added `pdfrx` for in-app native PDF viewing. Android native compilation succeeded. iOS requires CocoaPods/plugin resolution and an actual Mac/device validation before release.
- Ship the updated client with this backend. Old clients cannot use legacy manual completion shortcuts; they must update to capture automatic evidence. Do not re-enable unsafe RPCs to support old clients.
- Free/paid pricing and authorized entitlement remain from Phase 2. Consumer paid checkout is unavailable until the separately deferred payment integration is configured and verified.

## Verification record

- Supabase migration rehearsals use synthetic users/content inside rolled-back transactions. Both pending final migrations were rehearsed together before deployment, including a second run with expanded release tests.
- Post-deployment automatic-evidence and Phase 2 access/publication fixtures passed. They exercise direct-write denial, future-content/storage protection, forged completion, source/version checks, seeks, replay conflicts, mixed requirements, reused quizzes, grading, eligibility and ownership.
- Extended release fixtures pass: newly added earlier-module/lesson quizzes cannot reset an established frontier, new enrollees do not inherit waivers, waivers do not create attempts/completion rows, and removing a required reading during an active lesson publishes successfully.
- Existing history fingerprints remain unchanged for lesson progress, quiz attempts, assignment submissions and course completions. Counts remain 14 enrollments, two lesson-progress records, two quiz attempts, six submissions and one durable completion. No actual learner course was published or repaired by the fixtures.
- Final resumed Flutter regression run: **297 passed, one skipped**, using `flutter test --no-pub --concurrency=1 --reporter expanded`. The suite includes exact resource scope, account transitions, review retry/privacy, evidence replay/clock handling, authoring configuration, responsive layouts, routing and player/autoplay regressions. The skipped opt-in catalog integration check was separately run earlier against live read-only data and passed.
- Latest focused fullscreen/autoplay suite: six passed, including server-lock and failed-sync cases. It exposed and verified the player retention fix.
- Final project static analysis: zero errors and zero warnings. It reported 25 informational style/deprecation findings; the remaining new unbraced conditional was corrected afterward and checked separately. The other 24 findings are outside this course-learning scope.
- Certificate renderer: two Deno tests passed, including Urdu PDF output. This validates rendering and synthetic eligibility, not issuance to a real learner.
- Reading parser: four Deno tests passed for actual PDF pages, Urdu/mixed-whitespace text, malformed/empty/unsupported files and size limits. The reading Edge Function passes Deno type-checking and its tested parser is deployed.
- Live read-only outline query: 3.823 ms execution, five lesson rows across the current released manifests, with no temporary-disk work. This small dataset measurement is not a large-catalog load test. Existing access/attempt indexes and bounded batches are retained; a separate full-app performance audit remains deferred.
- Android debug APK builds succeeded. Native integration execution on the isolated Pixel 5/emulator-5556 did not reach assertions because emulator connections/installation failed. The user's running emulator-5554 was preserved. No iOS runtime test was possible on Windows.

## Remaining release checks and operational limits

1. Run native playback/speed/fullscreen, PDF reading, permission/access, offline kill/reopen/account-switch, grading-return navigation and responsive/accessibility checks on a working Android device. Run the equivalent acceptance on iOS with a Mac/device.
2. Offline learning currently centers on private video downloads and evidence replay. An already loaded reading can queue evidence while offline; reopening uncached reading content requires a connection. General app caching and broader document offline support are not claimed by this delivery.
3. Web evidence persistence has not been verified; the current durable store uses native app-support files. Do not advertise web offline-learning parity.
4. Review real course authoring readiness. Historical empty published courses and unpublished curriculum detected in Phase 0 were deliberately preserved; no speculative data repairs were made.
5. Service-role privileges remain administrative. Keep service credentials server-side and monitor cleanup failures, evidence rejection rates and growing queues. The private recovery snapshots are local TEMP artifacts, not durable managed backups.
6. Application rollback must preserve the new server authorization boundary and all attempts/coverage/achievements. Prefer a forward corrective migration. Synthetic fixture rollback is verified; a destructive production restore drill has not been run.

This report separates deployed implementation from remaining device/release acceptance. The full-app performance/caching audit is not part of these changes.

## Native acceptance checklist

1. Enroll a fresh student in a free course. Confirm all module titles appear, only the current lesson opens, and protected future content cannot be opened through a saved/deep link. Confirm unpaid/cancelled access is denied.
2. Watch a required video at normal and faster speed, seek over an interval, background/resume, scroll to actions and enter/leave fullscreen. Only real foreground coverage counts; controls and playback remain smooth.
3. Read a multipage PDF and long text/Urdu reading. Visit all sections with sufficient foreground time; background or merely opening the file must not complete it. Check text scaling and screen-reader navigation.
4. Complete a mixed lesson. Fail/retry its quiz; submit, reject, revise and approve its assignment. Confirm pending review blocks progression and approval refreshes the student player, My Learning and instructor roster.
5. Open Materials for the selected lesson, module folder and course work. Check exact scope, no embedded video/drafts, centered combined empty state, clear offline errors and correct back navigation.
6. Download an accessible video privately. Kill/reopen offline, play, then reconnect. Check pending progress and replay; switch accounts and verify another student's files/progress are never reused. A future locked lesson must remain inaccessible offline.
7. Finish all required work and open the certificate. Retry access and confirm a single durable achievement. Edit/publish the curriculum and verify prior completion/certificate access remains available; new students follow the updated requirements.
8. Submit/edit a real eligible review, simulate a network failure and retry. Verify aggregates refresh and an open draft disappears after sign-out/account switch. Repeat on Android and iOS in light/dark mode, narrow widths and large text.
