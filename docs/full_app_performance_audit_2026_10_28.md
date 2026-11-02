# Full app performance, caching and offline learning audit

Date: 28 October 2026. Status: **approved; incremental implementation in progress**.

## Implementation checkpoint (29 October 2026)

- Phase 1: Expired video downloads remain visible but require online authorization renewal before playback. Recovery preserves completed transfers, scans the library once, and checks saved file size and account. The offline player starts from a valid private file without waiting for remote media discovery. The legacy progress sync call was removed after confirming the automatic evidence path is authoritative.
- Phase 2: Discovery, category, featured, instructor, and course-list previews use bounded requests; full category/course and instructor lists load 20 at a time. Previously displayed courses stay visible while the next page loads or retries. Category counts and notification unread totals are requested on the server. Catalog pages have a three-minute idle memory cache and refresh on relevant publication, deletion, cover, and enrollment changes. Featured courses have a shared provider and refresh with the other catalog projections. Enrollment and lesson-progress queries during course hydration are scoped to the displayed courses. Single-quiz lookup now scopes quiz, answer-key, and attempt queries to that ID instead of loading the whole collection. Teacher finance loads separately from studio data, so a slow payout request no longer blocks the dashboard. Independent dashboard requests start together. Evidence acknowledgements no longer invalidate the whole public catalog.
- Phase 3: Local-first playback is in place. Native playback profiling, signed-URL renewal, image-cost measurements, and Android/iOS device comparisons remain open.
- Phase 4: Cancellation can recover a persisted native task ID and intact expired files can renew access from both course and single-video download flows without transferring the file again. Cancelling a course download is no longer counted as a failed lesson. An account-scoped, atomic course ledger retains remaining lesson IDs and Wi-Fi preference, so completed lessons are skipped on resume. Lesson notes and PDF readings/handouts can be explicitly saved in app-private storage, reopened from Downloads, and used during connection failures while a recent server-issued learning ticket remains valid. The server still decides completion. On-device download and offline playback were verified on physical Android hardware (Realme RMX5377, Android 16): 3 lesson videos totaling 52.7 MB downloaded with `.nomedia` private isolation and played locally with Wi-Fi and mobile data completely disabled. Native partial-transfer pause/resume, storage quota controls, and offline Office documents remain open.
- Phase 5: Read-only evidence transactions no longer rewrite the outbox, and corrupt checkpoint queues retain a recovery copy. Checkpoint answers are queued only on connection failures. A server-confirmed unavailable checkpoint is retained in a separate recovery file and removed from the retry queue, so it cannot block later answers. Other server failures retain the queue and stop that sync pass. Full native-background, RLS, and live-data regression gates remain open.

Focused Flutter analysis and tests for catalog paging, navigation, download recovery, saved readings, evidence storage, and offline download UI have passed. A profile APK built and launched on the Android emulator (`emulator-5554`); this verifies startup, not playback/download throughput or background recovery. The full regression suite initially found outdated assertions and two real short-screen overflows, which were corrected. A direct serial rerun (`flutter test --concurrency=1 --reporter expanded`) subsequently passed all **331 tests**. ARM64 debug build was installed and verified directly on the physical **RMX5377** phone (`3C766Q003DS00000`, Android 16 / API 36): teacher studio playback, student course syllabus navigation, category tab synchronization fix, full 3-video course background download, in-app Downloads screen enumeration, and completely offline video playback with network radios disabled have all passed on device. The native media integration fixture's playback interval was corrected and its PDF and video checks separated, but a native rerun stalled before test output on the connected Android device; native media automated integration test remains open. Changed files analyze cleanly with zero issues. No measured profile-mode playback baseline or live SQL query plan has been completed. Per explicit user request, iOS testing is excluded from this implementation pass. The original static-audit findings below describe the state *before* this implementation checkpoint.

Live read-only access checks used the configured Supabase project and separate signed-in student and teacher sessions. Anonymous catalog reads returned 12 published courses; anonymous enrollment reads returned zero rows and several protected tables rejected anonymous reads. The sampled student session could read its own four enrollments and seven quiz attempts, but returned zero rows for a different learner's sampled enrollment and attempt and zero quiz answer keys. The teacher session could read five answer keys for its own quiz access. These are sampled **read** boundaries, not a complete RLS certification: no write/RPC bypass, revocation, or cross-role mutation test was performed. The service-role connection was used only to locate comparison rows; it was not used to infer RLS enforcement.

Live `EXPLAIN (ANALYZE, BUFFERS)` remains unavailable: the configured `DATABASE_URL` host does not resolve in this environment. A disposable, read-only query-plan probe is under ignored `build/verification/pg_probe`; it embeds no credentials. No indexes or migrations were changed without measured plans. The installed `background_downloader` 9.5.9 supports pause/resume, but the app wrapper currently removes its pending record on a non-complete result and cancels a previous task on retry. Manual native partial-transfer resume, signed-URL renewal during resume, and process-death reconciliation therefore remain open. Existing automatic native retries and course-level restart from the last completed lesson should not be described as partial-file resume.

## Scope and evidence limits

Reviewed the actual Flutter startup, repositories, Riverpod state, course discovery/enrollment/curriculum, teacher studio/insights, assessments, reviews, certificates, notifications, live sessions, video preparation/playback, local stores, downloads, synchronization, and relevant SQL migrations. Read `memory/rules.md`. This is a cross-feature static audit, not a claim that every screen or production policy was exercised end to end.

An Android emulator was detected (`emulator-5554`, Android API 37). No profile-mode benchmark, physical-device test, iOS test, live Supabase query plan, production RLS verification, or load test was performed. Existing test files were inspected as coverage inventory; tests were not run for this audit. Findings below distinguish confirmed implementation behavior from risks requiring measurement. No application code, dependencies, configuration or migrations were changed.

The worktree contains substantial existing work. Implementation must preserve it and use focused diffs, not repository-wide resets or formatting.

## Decision

Keep Supabase, Riverpod, GoRouter, `video_player`, and the existing native download infrastructure. The highest-value work is reducing excessive data acquisition and invalidation, repairing download lifecycle/expiry handling, and making offline state recovery reliable. There is no measured justification for replacing the player, adding an encoding service, or rewriting all persistence.

PayFast remains deferred. Cached enrollment, playback position, or downloaded files must never grant server-side completion or paid entitlement.

## Research and product comparisons

| Official reference | Verified guidance/capability | Application to CBOA |
| --- | --- | --- |
| [Flutter offline-first architecture](https://docs.flutter.dev/app-architecture/design-patterns/offline-first) | Repositories coordinate local/remote data and explicit synchronization strategies. | Extend existing repositories; avoid a parallel offline UI/data architecture. |
| [Supabase query optimization](https://supabase.com/docs/guides/database/query-optimization) | Use query plans and indexes appropriate to actual access patterns. | Measure expensive queries under realistic RLS before adding indexes. |
| [Supabase Smart CDN](https://supabase.com/docs/guides/storage/cdn/smart-cdn) | Smart CDN is plan-dependent; signed URL tokens form distinct cache keys; invalidation is not instantaneous. | Verify project plan, reuse still-valid signed URLs within authorized scope, version media paths, and do not confuse URL expiry with immediate cache revocation. |
| [Coursera app listing](https://apps.apple.com/us/app/coursera-grow-your-career/id736535961) | Advertises downloaded videos and coursework across devices. | Useful product reference for downloads/resume; does not establish Coursera's internal database, buffering algorithms or offline graded-submission rules. |
| [Udemy Android downloads](https://support.udemy.com/hc/en-us/articles/115006973308-Downloading-courses-for-offline-viewing-on-the-Android-app) | Official indexed guidance describes lecture/section/course downloads, quality/Wi-Fi preferences, app-contained files and periodic reconnection for some content. | Provide explicit availability and refresh states. The direct article redirected during research; no hands-on parity claim. |
| [YouTube offline viewing](https://support.google.com/youtube/answer/7381437?hl=en) | Offline downloads are app-contained/encrypted and are not gallery exports. | CBOA already uses private storage, but that is not equivalent to YouTube encryption or DRM. |
| [Flutter video_player](https://pub.dev/packages/video_player) | Uses native Android/iOS playback implementations. | Retain the existing native player; investigate actual buffering before changing it. |
| [background_downloader 9.5.9](https://pub.dev/packages/background_downloader/versions/9.5.9) | Native background transfers, retry, pause/resume and task tracking are available. | Use the project's pinned API; package capability does not mean CBOA exposes or persists every feature. |

These references inform architecture, not a promise to reproduce another platform's infrastructure.

### Resolve the progression contradiction first

Older project plans requested sequential lesson locks. The newer migration `supabase/migrations/20261028000000_course_preview_and_entitled_access.sql` permits the first released lesson as preview and grants enrolled students access to published lessons. Preserve this newer product policy; do not reintroduce sequential locks as a caching change. Completion still depends on server-validated required activities. Confirm the deployed database matches the intended migration before rollout.

## Current architecture and working foundations

- Feature repositories own Supabase/filesystem access; Riverpod shares state; GoRouter routes between student and teacher experiences.
- `supabase_course_repository.dart` guards responses against account identity changes and hydrates published outlines/access. Search already uses a bounded RPC. Course reviews have paginated loading and duplicate suppression. Teacher learner-roster RPCs support limits, offsets and search.
- Teacher insights use bounded recent-enrollment/history requests. These should be reused, not replaced with client-side full-table filtering.
- Native video controllers have initialization timeout/disposal, lifecycle pausing, persisted playback preferences, and a shared full-screen player. Existing UI and controls should remain intact.
- Video delivery is principally one compressed H.264 MP4 per source. The quality menu correctly avoids pretending there are multiple renditions. Uploads already use resumable TUS infrastructure.
- Downloads use `background_downloader` 9.5.9 with retries, Wi-Fi requirements and pause capability on tasks. Files live in account-specific application-support folders with `.nomedia`, not the gallery. Atomic manifests and completed-transfer recovery already exist.
- Learning evidence has persisted sessions/events, ordered sequences, server validation, deduplication receipts, revision/source binding and retryable synchronization. Offline playback position alone does not award completion.
- Assignment drafts persist account-scoped content and hashed attachments. Video study notes/preferences also persist locally. These are distinct from server-confirmed submissions/progress.
- Certificates are issued through `supabase/functions/course-certificate/index.ts`, which authenticates the user, checks completion, and returns a short-lived signed document URL.

## Findings, prioritized

P1 = high user/reliability impact; P2 = important scalability or efficiency work. No measured latency, memory saving or production vulnerability is asserted below.

| Priority | Confirmed code evidence | Impact and proposed treatment |
| --- | --- | --- |
| P1 | `lib/features/learn/data/offline_lesson_library.dart`: `listDownloads()` calls `find()` and deletes entries that fail validation; `offline_file_store.dart` expires authorization after seven days. | An otherwise intact download can disappear merely by listing it after expiry. Separate expired authorization from missing/corrupt media; display reconnect-to-refresh, and revalidate before playback without unnecessary redownload. |
| P1 | Same library: active task registry is in memory; `course_download_controller.dart` keeps the pending lesson queue in memory. Recovery recognizes completed files, but does not reconstruct the entire queue/UI. | Process death can lose queue state; account cleanup cannot rely only on memory-known native tasks. Persist owner/revision/task identities and reconcile native tasks before restoring, cancelling or purging. Validate Android/iOS termination behavior. |
| P1 | `hosted_lesson_player.dart` finds a download but still attempts remote media discovery with a 30-second timeout; fallback catches specific network failures. `main.dart` may await profile restoration up to 15 seconds before `runApp`. | Offline launches/playback can wait unnecessarily or fail on unclassified transient errors. Measure cold/warm/offline paths; make authorized cached playback usable promptly without treating every server denial as a network failure. |
| P1 | `learning_evidence_store.dart` loads and rewrites the whole JSON document per transaction, including read transactions. Repository queue permits up to 20,000 events. | Write amplification and main-isolate JSON work grow with backlog. Measure file size, transaction duration and frame impact; separate reads/writes first, then migrate the outbox transactionally if benchmarks justify it. |
| P1 | `offline_lesson_library.dart`: checkpoint synchronization breaks on any failure; malformed queue parsing returns an empty list. | A permanent rejection may block later answers; corruption can be silently discarded. Preserve/quarantine malformed files and distinguish transient failure, invalid item and explicit authorization denial. |
| P2 | `lib/core/repositories/supabase_course_repository.dart`: `_loadCourses` pages until all matches, fetches nested modules/lessons, hydrates outlines/access, then enrichment and progress. Categories scan all published course category rows. Teachers are also loaded to exhaustion. | Chunked network retrieval is not bounded UI pagination. Introduce lightweight bounded list projections, load detail on demand, and obtain category counts server-side. Preserve ordering and identity guards. |
| P2 | `course_outline_loader.dart` and `supabase_course_enrichment.dart` perform multiple RPCs per batch. `home_controller.dart` awaits catalog/categories/learning in sequence; category detail can independently reload courses. | Excess round trips and delayed first usable content are plausible; capture request traces before deciding which calls to parallelize/combine. Keep public catalog separate from user progress. |
| P2 | `learning_activity_sync.dart` invalidates catalog, home, learning, assessments and provider families on learning changes; realtime refresh is debounced but evidence-triggered refresh is broad. Catalog also watches the full auth state. | Completing one lesson can trigger unrelated reloads. Invalidate affected course/lesson/user projections and use auth identity rather than unrelated profile state where appropriate. |
| P2 | `curriculum_providers.dart` summary loads context plus full material/assessment lists; `course_workspace_module.dart:208` watches it per lesson. | Course Studio creates a per-lesson query fan-out for counts. Use an authorized aggregate keyed by course/module/release and keep lesson-specific detail lazy. Do not repeat the earlier mistake of showing module counts under each lesson. |
| P2 | `supabase_quiz_repository.dart` loads visible quizzes with nested questions and student attempts; assignment repository/controller load whole visible collections/briefs/submissions. `teacher_controller.dart` builds courses, quizzes, dashboard and finance together. | List screens fetch more than display needs and unrelated teacher sections are coupled. Split summaries from details, page datasets and load finance only for its consumers. Respect quiz key RLS. |
| P2 | `quiz_session_controller.dart` chains server saves on selections using accumulated answers. `assignment_draft_store.dart` reads/hashes attachment bytes, potentially three 25 MiB files. | Rapid answers can amplify writes; large drafts can pressure memory. Measure first; coalesce only safely acknowledged answer snapshots and stream file validation if needed. Never defer final graded submission to an unverified cache. |
| P2 | `listDownloads()` invokes `find()` per item, which re-enters directory/recovery scanning. | Repeated scans can become quadratic with library size. Recover once, then enumerate/validate from one directory snapshot. |
| P2 | No managed offline outline/reading library was found in `lesson_reading_repository.dart`; downloads screen reconstructs a minimal lesson from video metadata. | Video downloads do not make the complete course usable offline. Add explicit course/lesson snapshots and opted-in resources; do not label quizzes, assignments or remote PDFs fully offline today. |
| P2 | `app_image_provider.dart` uses `NetworkImage`/`AssetImage`; no explicit persistent image-cache policy. Instructor provider's five-minute idle keepAlive is not a freshness TTL. | Returning/offline screens can refetch images or display retained metadata beyond desired freshness. Define caches by data type; do not add a global forever cache. |
| P2 | Notifications load 50 rows; inbox badge is derived from that loaded slice. Live-session list has no time window/pagination. | Badge can undercount and historical sessions grow. Use a bounded unread aggregate plus paged inbox, and time-window/paged sessions. Preserve fresh authorization when joining. |

Additional boundaries: the legacy `offline_progress_queue.dart` production sync is effectively inactive after automatic evidence completion; it is not the primary progress mechanism. `main.dart` still schedules it. Remove obsolete scheduling only after confirming all call sites. Teacher transcription polling is conditional on processing state (eight seconds), not permanent polling; pause/resume it according to screen/app lifecycle instead of removing necessary job updates.

Existing SQL includes activity/source, student-attempt, evidence-owner/expiry, review and assessment indexes. Do not add duplicate indexes. Complex release JSON traversal and RLS costs require representative `EXPLAIN (ANALYZE, BUFFERS)` and call-frequency evidence.

## Proposed caching matrix

Durations below are starting policies to validate against measurements, not current implemented guarantees. All private keys include user identity; content keys include release/version where applicable. Cached display data never authorizes a protected network request.

| Data | Layer | Freshness/invalidation | Rationale |
| --- | --- | --- | --- |
| Public course cards/categories/instructor summaries | Shared in-memory query cache; bounded disk snapshots if justified | About 5 minutes; explicit refresh, publication/profile events; bounded LRU | Fast discovery without downloading protected detail. |
| Search results | In-memory by normalized query/filter/page | Short-lived; discard on catalog revision; deduplicate in-flight requests | Avoid retaining an unbounded search history. |
| Published outline | Memory plus opted-in offline snapshot | Course release key; refresh on opening online/publish notification | Preserve order and distinguish downloaded version from current version. |
| Entitlement/access | Server-authoritative; separately scoped offline lease | Revalidate online and before protected operations; expire offline access explicitly | A display cache is not a payment/access grant. Offline revocation cannot be instantaneous. |
| Progress/activity outcomes | Memory plus durable last-confirmed snapshot and outbox | Acknowledgement, submission/grading, release change, resume | Display pending sync separately; server decides completion. |
| Quiz cards/assignment summaries | User-scoped memory, limited disk display snapshot | Submission/grade/link/deadline changes; short refresh window | Details and attempt authorization fetched when needed. |
| Timed quiz sessions/results | Server authoritative; existing active-session handling | Server expiry/submit; no new offline graded attempts | Avoid answer-key caching and ambiguous timed submissions. |
| Assignment drafts | Existing private durable store | Keep until submission/discard; explicit retention and logout policy | Avoid losing work; distinguish draft from receipt. |
| Playback position/preferences/notes | Existing account/source private store | Persist throttled; source/version change; clear by retention policy | Local resume does not imply completion. |
| Downloaded videos/documents | App-private files plus manifest/task ledger | Explicit delete, changed revision, access revalidation, quota cleanup | User-managed downloads must not be evicted as incidental cache. |
| Thumbnails/avatars | Framework memory plus bounded disk image cache only if measured useful | Versioned URL, size limits, refresh/profile edit; account cleanup for private images | Reduce repeated transfer without caching signed protected content indiscriminately. |
| Signed media URLs | Short-lived memory per user/object/version | Expiry safety margin, auth change, explicit denial; bounded refresh retry | Reduce CDN misses while preserving authorization boundaries. |
| Reviews/ratings | Paged memory | Save/edit invalidates course aggregate and review pages; short freshness | Existing pagination is a useful base. |
| Teacher finance/roster/live sessions | Paged memory | Relevant write/event and explicit refresh; fresh join/access checks | Do not queue financial mutations offline. |
| Notifications/certificates | Paged memory; optional private downloaded PDF | Read events update count; certificate issuance always server checked | Do not regenerate PDFs or load every notification for a count. |

Logout/account switch must clear private memory, signed URLs and active sessions, reconcile/cancel native tasks for the previous owner, and apply documented local-draft/download cleanup. One account's cached content must never appear under another account. Public caches can survive if they contain only public fields.

## Playback and offline assessment

| Capability | Current state | Required improvement |
| --- | --- | --- |
| Native network video and full screen | Present; existing controls/lifecycle | Profile startup, stalls, seek and speed changes; retain UI/player. |
| Adaptive streaming/quality ladder | No app-generated rendition ladder | Not a configuration-free client fix. Defer HLS/encoding until measured need and approved hosting/cost plan. |
| Durable partial streaming cache | Not established; native buffering is transient | Do not advertise native buffers as offline downloads. |
| Whole-file private downloads | Present, size validation and atomic commits | Expiry/revalidation, persistent queue and task reconciliation. |
| Pause/resume/retry | Native task capability; app integration incomplete | Persist states and expose safe pause/resume/retry; verify server range support and signed URL renewal. |
| Wi-Fi only | Task flag exists | Ensure persisted preference and queued-task behavior match UI. |
| Storage/quality controls | Total downloaded size visible; no comprehensive quota/disk preflight or multiple source qualities | Add capacity/error management; display original available quality honestly. |
| Video offline progress | Evidence outbox and server tickets exist | Ensure every download entry path acquires eligible evidence metadata; surface pending/rejected states. |
| Reading/handout offline | No complete managed lesson resource library | Add explicit private downloads and versioned manifests after authorization. |
| Quiz/assignment offline | Some drafts/checkpoint queues exist; formal submission remains online | Keep graded submission online; preserve drafts and offer deliberate retry with server receipt. |
| Cross-device completion/certificates | Backend source of truth exists | Targeted refresh and durable pending/confirmed distinction. |

Retain single-file MP4 and Supabase Storage initially. Measure object size, bitrate, first-frame latency, cache hit behavior and network throughput. Supabase CDN is not a transcoder. Compression quality, the existing approximately 25 MB upload constraint, and ABR are separate concerns; do not lower bitrate or change product upload limits as speculative playback optimization.

### Persistence recommendation and migration cost

Keep preferences and small atomic manifests in their existing stores. First eliminate unnecessary JSON rewrites and repeated scans. For a persistent task ledger, offline snapshots and a large evidence outbox, SQLite through a maintained Flutter repository adapter (for example Drift) is a reasonable next step **only if baseline data or recovery requirements justify adding it**. It costs a dependency, schema/version migration, Android/iOS verification and an import/recovery path; an unbounded key-value cache does not solve transactional outbox requirements.

If approved, migrate one store at a time: account-scoped import, preserve original JSON, verify row counts/event sequence/hash, commit a migration marker, then switch reads. Never drop or renumber pending evidence. Keep media files in place. Do not dual-write unsafely or roll back to an obsolete queue after server acknowledgements. A rollback must export the current unacknowledged state or retain the new reader.

## Phased implementation plan

### Phase 1 — Measured baseline and isolated reliability fixes

**Priority/cost:** P1, small-to-medium. Dependency: approval of this plan.

- Capture profile-mode cold/warm launch, home/learn/assessment/teacher studio/roster opens, video first frame, seek/stall time, memory and offline launch. Record request counts/bytes and p50/p95 across repeated comparable runs.
- Instrument development builds without logging tokens, signed URLs, answers or personal data. Distinguish request latency, server time, decoding and widget work.
- Separate expired authorization from corrupt downloads; stop automatic deletion of intact expired files. Recover downloads once per listing. Remove proven no-op synchronization scheduling.
- Audit startup/auth offline routing without relaxing online entitlement checks.

**Affected:** `main.dart`, offline library/file store/download controller, auth initialization, existing `test/offline_*`, development tooling/documentation.

**Migrations/dependencies:** none expected. **Acceptance:** repeatable baseline recorded; expired file retained but unplayable until authorized refresh; corrupt file never played; listing scans once; offline launch shows usable authorized content or a clear reconnect state. **Risks:** retaining inaccessible data or premature authenticated UI. **Rollback:** focused changes behind compatible state interpretation; preserve manifests and files; never restore destructive expiry deletion as a data migration.

### Phase 2 — Bounded queries and coordinated caching

**Priority/cost:** P2 with broad impact, medium-to-large. Dependency: Phase 1 request traces.

- Introduce lightweight paged catalog/assessment/teacher summaries and separately keyed detail loads; reuse existing bounded search, reviews and roster patterns.
- Batch exact lesson-level attachment counts. Separate catalog from user progress, and teacher finance from teacher overview.
- Deduplicate in-flight requests, bound memory caches, define refresh/expiry, and replace broad invalidations with course/lesson/user-specific updates.
- Fix notification total count and bound live-session history as separate small changes.
- Measure SQL plans with representative data/RLS, then add only justified indexes or aggregate/list RPCs.

**Affected:** core course/quiz/assignment repositories, outline/enrichment/search, home/learn/teacher controllers, curriculum providers, learning sync, notification/live repositories.

**Migrations/dependencies:** additive paged/aggregate RPCs and grants/RLS tests where needed; measured indexes only; no cache package required initially. **Acceptance:** list opening does not load every course or quiz question; one lesson completion does not refetch unrelated catalog/finance; paging has no duplicate/missing items; lesson counts match actual links; account switch never displays stale private results; request-count improvements recorded against baseline. **Risks:** stale projections, differing sort order, access leaks in RPCs. **Rollback:** retain existing RPCs/readers while introducing new endpoints; additive schema only; independent toggles per projection.

### Phase 3 — Targeted playback and delivery optimization

**Priority/cost:** P2, medium. Dependencies: baseline and scoped cache keys.

- Make valid downloaded playback local-first with background online revalidation where policy allows; handle explicit denial differently from temporary unreachability.
- Cache signed URLs only within owner/object/expiry scope; one bounded renewal on expiry, preserving position and speed.
- Profile controller initialization/disposal, rapid lesson switching, fullscreen, repeated seeking, long sessions and speed changes. Change buffering/native options only if measurements identify a problem.
- Review thumbnail decoding sizes and bounded image caching from measured network/memory costs.

**Affected:** hosted/study/professional player, video source/initialization, media repository, app image provider. **Migrations/dependencies:** none by default; image dependency only with evidence. No player replacement or ABR service.

**Acceptance:** fewer avoidable remote calls on local playback; no controller leaks; valid local video starts without a remote timeout; expiry recovery retains position; no regression in controls, checkpoints or evidence. Compare startup/stall/frame metrics to baseline under the same conditions. **Risks:** stale media, false offline fallback, URL leakage. **Rollback:** retain old network initialization path; cache can be cleared independently of downloads/progress.

### Phase 4 — Reliable downloads and explicit offline learning

**Priority/cost:** P1, large. Dependencies: expiry semantics and Phase 3 source/version handling; can start after Phase 1 if offline reliability takes precedence over query work.

- Persist queue/task owner, course/lesson/source revision, destination, progress and terminal state. Reconcile the native task database on startup and account changes.
- Implement pause/resume/cancel/retry using pinned package APIs; fresh signed URL recovery and partial-file validation. Distinguish Android force-stop and iOS user force-quit from ordinary background execution; do not promise uninterrupted transfer in those states.
- Add free-space handling, storage preference/quota, Wi-Fi policy, safe cleanup and a clear refreshed/expired/updated status. Preserve an old valid file until replacement commits.
- Add bounded offline course/lesson snapshots and explicitly selected reading/handout downloads. Keep videos/resources private; no gallery export. Show which activities require internet.
- Use existing theme/widgets and Riverpod; no unrelated redesign.

**Affected:** offline library/file store/downloads UI, course download controller, reading/material repositories, learning-evidence ticket acquisition, auth cleanup.

**Migrations/dependencies:** local manifest schema/task ledger; conditional SQLite migration per persistence decision; backend lease endpoint only if existing authorized APIs cannot safely renew metadata. **Acceptance:** queue/task state survives restart; cancellation stops native work; logout cannot restore another user's task/content; disk-full leaves no playable partial file; existing downloads migrate without redownloading; expired access refreshes safely; offline resources reflect selected lesson and release. **Risks:** OS scheduling, migration loss, partial files, changed source. **Rollback:** preserve legacy manifests, additive ledger import and native task reconciliation; never erase user downloads as rollback.

### Phase 5 — Synchronization, recovery, security and regression

**Priority/cost:** P1, medium-to-large. Dependencies: phases 1–4 interfaces stable.

- Harden evidence/checkpoint outboxes: ordered/idempotent replay, transient backoff with jitter, permanent rejection quarantine, corrupt-store recovery, visible pending/confirmed/rejected state.
- Preserve server session expiry, source/release identity and completion rules. Old-version evidence must be accepted/rejected by explicit server policy, not silently attached to replacement content.
- Review assignment draft durability and quiz autosave coalescing only against measured pressure. Submission success requires persisted server receipt; ambiguous timeouts must be reconciled before retrying.
- Consolidate account cleanup and resume/connectivity synchronization; prevent duplicate timers and overlapping sync. Avoid treating connectivity status alone as server reachability.
- Verify database grants/RLS, signed media access, role separation, cached-content boundaries and completion/certificate eligibility.

**Affected:** evidence store/repository/sync/outcome, offline checkpoint queue, assignment drafts/submissions, quiz sessions, auth lifecycle, backend evidence/submission RPCs and tests.

**Migrations/dependencies:** additive idempotency/receipt changes only where existing contracts are insufficient; no generic offline submission system. **Acceptance:** repeated replay cannot award duplicate credit; invalid first item does not silently destroy/block unrelated work; account switch/reinstall behavior documented; interrupted migration preserves events; server-denied content never gets new access from cache; instructor/student progress converges after acknowledgement; certificates require confirmed completion. **Risks:** replay order, timing conflicts, incompatible old clients. **Rollback:** backward-compatible RPC contracts, preserve receipts and pending events; never restore acknowledged events into a stale outbox.

## Verification strategy and release gates

Record dataset size, device/OS, build mode, connection conditions and run count with each result. Use profile mode for performance, debug/unit tests for correctness, and production-like RLS for SQL comparisons. Emulator success is not sufficient evidence for iOS/native background behavior.

| Area | Required scenarios |
| --- | --- |
| Baseline | Small/large catalogs; few/many lessons; cold/warm caches; repeated navigation; request counts/bytes, first usable frame, memory and jank. |
| Queries | Pagination boundaries, filtering, mutation invalidation, RLS owner/student/anonymous, auth switch during an in-flight response, no answer-key exposure. |
| Playback | Stream/local, slow/offline network, expired URL, missing object, seeks/speed/fullscreen, pause/resume, rapid lesson changes, controller disposal, completion evidence. |
| Downloads | Single/course queue, Wi-Fi change, retry, pause/resume, cancel, process death, OS force-stop/force-quit, reboot, signed URL expiry, disk full, replacement, corrupt file/manifest. |
| Offline access | Seven-day boundary, clock changes, revoked enrollment, unpublished/deleted/replaced content, fresh install without cache, logout/login different user, private files absent from gallery. |
| Sync | Long backlog, intermittent connection, expired session, duplicate/out-of-order/rejected evidence, app exit mid-write/ack, local-store corruption, source revision conflict. |
| Assessments | Quiz autosave/final submit timeout recovery, server expiry, assignment draft attachments, duplicate submission prevention, grading refresh and server-confirmed course completion. |
| UI | Existing student/teacher flows, responsive layouts/text scaling, loading/empty/error states, accurate download status, pending progress, navigation and unchanged player controls. |

Reuse existing suites including offline file/library/queue tests, course download controller, learning evidence replay/store/clock, video initialization/speed/player, assignment drafts/workflow, quiz session, course access, reviews and learner roster tests. Add only missing behavioral coverage; run focused tests after each implementation and affected regression suites before rollout. This audit has not certified those suites as passing.

Performance acceptance is a recorded improvement against Phase 1 with no regression in the unaffected flows, not an invented millisecond target. Define concrete device/network-specific budgets after baselines. Security/data-loss gates are absolute: no cross-account display, unauthorized access, fabricated completion or lost unacknowledged evidence.

## Required access/configuration before implementation verification

- No new credentials are required to begin local Phase 1 development after approval.
- For live SQL evidence, use an authorized Supabase connection/dashboard and representative non-sensitive data. Confirm deployed migrations, RLS, project tier/CDN configuration, bucket restrictions and signed-URL behavior. Do not paste service-role keys into chat or ship them in Flutter.
- Provide/retain separate student and instructor test accounts, enrolled and unenrolled cases, and a test course with video/readings/assessments. Paid entitlement boundaries can be tested with authorized fixtures; PayFast stays out of scope.
- Android physical-device profiling and an iOS device/Mac signing environment are required before claiming native background/download parity. APNs configuration is not a prerequisite for local download correctness, but notification-driven refresh needs its existing platform configuration to test end to end.
- Any SQLite package, image-cache package, new backend lease policy, CDN plan change, or encoding service is a conditional proposal, not an approved configuration change.

Implementation is underway under the approved plan. Record changed files/migrations, measured results, test results and unresolved platform limits at the end of each phase.
