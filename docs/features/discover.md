# Discover previews and full lists

Discover displays up to three instructors and three additional courses. When
more than three items exist, the section heading shows **See all**.

- Instructors opens the full instructor list. Selecting an instructor opens their
  existing public profile.
- Explore more courses opens the existing course-list screen with
  `section=recommended`. Selecting a course opens its course details.
- Both destinations reuse `DiscoverController` data, including Supabase-backed
  instructor and course records. Preview limits are applied in the UI; the
  controller retains the full lists. The label reflects the current catalog
  selection behavior; there is no personalization engine.
- Empty sections remain hidden on Discover. The full instructor page handles
  loading, empty data and retry states.

`test/discover_see_all_test.dart` verifies the preview limits, navigation to both
full lists, access to items beyond the preview, and profile/course navigation.

Home and Discover search open the same course search screen. Production searches
published course titles, descriptions, categories and instructor names via the
bounded `search_published_courses` RPC. Results load 20 at a time with Show more.
Input is debounced and prior results are hidden while a new query settles. My
Learning, quiz and assignment searches use the shared field style and filter
their already loaded, user-scoped records. See
`docs/student_data_search_audit_2026_10_26.md` for the data-flow audit and
remaining catalog-scale work.
