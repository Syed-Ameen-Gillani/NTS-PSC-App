# Student data, search, and performance audit — 26 October 2026

## Architecture and evidence

Student Home, Discover, category listings, My Learning, and the public faculty profile consume Riverpod controllers and `CourseRepository`. Production selects `SupabaseCourseRepository`; the mock branches are test fixtures. Supabase RLS exposes published courses and the signed-in teacher's drafts. Enrollment/progress are read under the current Supabase session. The SQL syllabus RPC adds public lesson outlines without exposing protected lesson content.

## Confirmed issues (before implementation)

| Priority | Screen / flow | Root cause | Acceptance criterion |
| --- | --- | --- | --- |
| P0 | Home and Discover search | `CustomSearchBar` is a decorative `Container` with no tap or input handler. | Tapping opens usable course search; clear, empty, loading, error and rapid edits behave correctly. |
| P0 | Catalog / category / faculty | Every repository method calls `_loadCourses`, retrieving every visible course, all nested syllabus, teacher names, enrollments, eligibility and progress before filtering. Home invokes four such methods sequentially; Discover invokes two. | Targeted queries and shared per-screen fetch avoid duplicate round trips; category/faculty/id filters run server-side. |
| P0 | Faculty profile | Its course provider filters all catalog rows locally; errors render an empty `SizedBox`, identical to no courses. | Only that instructor's published courses load; true empty and retryable error are distinct. |
| P1 | Home filters | Available courses combine featured and only the current New Courses list, which currently happens to be the entire published catalog. This works by accident and can break when New Courses gets a real limit. | All/subject chips use a dedicated published catalog, with one consistent See All dataset. |
| P1 | New Courses | Sorts by `created_at`, including old drafts that were published recently; the `published_at` field is available. | Most recently published courses first, stable tie-break, published only. |
| P1 | My Learning search | Has its own unstyled field and searches only an already loaded enrollment list. Its search state survives account switches. | Uses shared search appearance; query clears predictably and no prior account state appears. |
| P1 | Auth/cache mutation | Home and Discover watch auth, but some family providers read repository without watching auth; enrollment invalidates Home/Discover but not categories or other catalog views. | Account changes rebuild user-scoped views; enrollment/progress updates are visible on revisits. |
| P2 | Discovery recommendations | Production labels all published courses as “Recommended for you” without personalization. | Label is honest until a recommendation algorithm exists, or implement one with explicit business rules. |
| P2 | Ratings/learner counts | Catalog mapper defaulted rating and enrolledCount to zero; no published aggregate was fetched. | Use a verified public learner aggregate; continue hiding rating where there is no review backend. |

Mock data is gated behind `AppConfig.isSupabaseEnabled == false`, which production sets true. The public profile's mock bio and mock metrics remain in that test-only branch. This audit does not treat those fixtures as production data. Student assignment search and transcript search already filter their loaded, user-scoped data; they are separate domains and need no catalog query.

Other student surfaces checked: production quiz and assignment controllers read their Supabase repositories; their searches filter loaded, user-scoped lists. The lesson transcript search filters the loaded transcript. The live classes route uses `LiveMeetingsScreen`, while Home shows the course-exploration banner when there is no live session. Course reviews deliberately show “Reviews are not available yet” in Supabase mode because this project has no course-review table; the mock review controls are test-only. The static assignment weekly target is a UI goal, not a claimed backend count.

## Risks requiring validation

- Existing lessons RLS and syllabus merge may produce different outlines for unenrolled and enrolled users. Test both identities.
- Server-side course limits need cursor pagination before the catalog grows beyond one page; the current app has no pagination contract. Do not silently truncate See All.
- Home/Discover/provider lifetimes may cause fresh requests on navigation; measure after consolidating loads.
- Faculty list may include teachers with no published course. A zero-course empty state is valid.

## Phased implementation plan

### Phase 1 — Correct repository queries (P0)

**Dependencies:** existing Supabase RLS and syllabus RPC, no schema changes. Introduce a scoped catalog loader with published/category/instructor/id filters, ordered by publication time; fetch enrollment/progress only for the current user's enrolled courses. Use one catalog call per Home/Discover build and derive their sections locally from that snapshot. Preserve teacher draft access in teacher-specific methods. **Acceptance:** publication, category, instructor and ID predicates execute in PostgREST; student Home/Discover do not repeat full-catalog calls per section.

### Phase 2 — Functional search and navigation (P0/P1)

**Dependencies:** Phase 1. Make shared search bar open a dedicated results page using the current published catalog (server-side search, bounded pages once pagination is available), with debounce or request-generation protection, clear button, retry, no-result state and detail navigation. Match My Learning field styling but continue searching enrolled courses locally. **Acceptance:** queries find titles/categories/instructors; clearing restores results; stale responses cannot replace a newer query.

### Phase 3 — Cache and user isolation (P1)

**Dependencies:** Phases 1–2. Have user-scoped providers watch auth, invalidate after enrollment and learning mutations, and use a short-lived shared snapshot only where reuse is safe. **Acceptance:** switch/logout never shows the previous student's learning data; returning after enrollment shows correct state without redundant requests.

### Phase 4 — Presentation integrity and regression (P1/P2)

**Dependencies:** earlier phases. Replace misleading recommendation/rating/count labels, add faculty empty/error states, and keep current design patterns. Verify RLS-backed catalog and enrollment behavior using focused mapper/provider/widget tests, scoped static analysis and Android build. Manual live validation should cover student A/B, teacher, signed-out, new publication and deleted resources.

## Validation limits

Unit/widget tests prove mapping and interactions, not hosted RLS. Hosted reads using real student/teacher sessions and device navigation are required before calling the full experience production-ready.

## Implementation and verification record

- **Phase 1 implemented:** Supabase publication, featured, category, instructor and ID filters now execute in PostgREST. Course and category counts paginate with stable ordering instead of stopping at the default result limit. Enrolled course loading starts from the signed-in student's enrollments. Home and Discover share published catalog and category providers; Home derives its previews, including Continue Learning, from that single catalog snapshot. Publication time controls New Courses order. Catalog retains enrollment/progress enrichment so course cards and detail navigation do not mistake an enrolled learner for a guest.
- **Phase 2 implemented:** Home and Discover search now opens a real search page. Production uses the `search_published_courses` RPC, which matches course title, description, category and instructor, returns published IDs in stable 20-course pages, and caps each request at 50. The client debounces input, loads details under normal RLS, and offers Show more; results for an outdated query cannot replace the current query. My Learning, quiz and assignment searches use the same field treatment and filter already loaded user-scoped data. Mock tests use the same page contract against fixtures.
- **Phase 3 implemented for covered mutations:** Catalog invalidation follows enrollment, lesson completion including offline sync, quiz results, learning activity sync, course publication, cover changes and deletion. Public faculty and category list providers dispose when their pages close and watch the account identity. My Learning search resets on account change. Home and Discover support pull-to-refresh. Cross-device publication refresh while the app remains open still depends on user refresh or app lifecycle; no catalog Realtime subscription was added.
- **Phase 4 implemented:** Faculty profile now distinguishes zero published courses from failed loading and offers Retry. Missing instructor photos show a neutral avatar instead of another teacher's face. A bounded public learner-count RPC supplies course counts without exposing learner identities; rating stays hidden where there is no review backend. “Recommended for you” was renamed “Explore more courses” because there is no personalization algorithm. Empty/error states and retry were added to covered catalog screens.

### Hosted read verification

Read-only checks against the linked Supabase project returned 10 published courses, 9 active categories and 13 active/completed enrollments. All 10 published courses have `published_at > created_at`, confirming that sorting by creation time was wrong for this dataset. The instructor shown in the supplied faculty screenshot exists and has **zero published courses**; the explicit empty state is correct. An anonymous PostgREST read accepted the nested course projection with a published-status filter. These checks do not prove authenticated student RLS or device navigation.

### Automated checks

- Focused Home, category, Discover, catalog mapping, search and assignment tests passed, including new catalog search filtering, Show more pagination and quiz search interaction tests.
- Migration `20261026100000_student_course_search.sql` was applied to the linked project. Anonymous RPC checks returned two distinct two-course pages; a category query returned published matches; a draft-only course name returned no results.
- Migration `20261026110000_public_course_learner_counts.sql` was applied to the linked project. Its anonymous aggregate returned 10 published-course rows and 12 active learners in total, matching a separate read-only database count exactly.
- Scoped `flutter analyze` passed for the edited student files. A separate analysis including `course_enroll_modal.dart` still reports its pre-existing deprecated radio parameters and brace style infos; those are outside this data audit.
- Android debug APK built successfully. iOS and end-to-end signed-in device flows were not run in this audit.

### Remaining work before a large-scale production claim

1. Paginate full catalog and instructor views before the catalog exceeds a modest size. Home/Discover currently share one complete catalog snapshot, which is efficient for today's 10 courses but grows linearly in network payload and widget work. Search itself is server-paginated.
2. Course ratings remain unavailable in production because there is no course-review backend. Keep the Reviews tab's existing unavailable state until a separate reviewed feature is built.
3. Validate two real student accounts, a teacher account, signed-out browsing, enrollment/progress invalidation, unpublished/deleted course navigation and slow/offline errors on Android; repeat platform-relevant checks on iOS when available.
