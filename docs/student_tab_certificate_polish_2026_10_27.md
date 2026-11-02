# Student tabs, certificate and Continue Learning

Date: 27 October 2026.

- Discover's existing title/search geometry is shared through `StudentTabHeader`: 24.h top inset, 24.w horizontal margins, Inter bold 24.sp title and 20.h title-to-search spacing. Learn retains Downloads without changing the title/search geometry. Quizzes/Assignments use the same header with a persistent editable search; tab navigation and status filters remain intact.
- Editable search now matches Discover's 52.h search control, text, icon spacing, fill and border. Focus uses the existing primary token. Account changes reset the assessment search field and query together.
- The certificate page uses a constrained, scrollable award layout, clear recipient/course/date hierarchy, a separate selectable certificate ID and one PDF action. Its controller refreshes the signed URL without replacing the page with a loading screen, guards duplicate taps, checks account identity and restores the action after failure. PDF generation/eligibility are unchanged.
- Continue Learning cards previously had **no tap handler**. They now navigate by their exact course ID; the destination reloads through the repository and its account-aware provider disposes on exit.
- The live dashboard now consumes `MyLearningController.ongoingCourses`, the same enrolled-course dataset as Learn. The repository reads active/completed enrollments, persisted lesson completion and server course eligibility. Completed courses are excluded by durable eligibility; cards label the percentage **Lesson progress**, because required assessments may remain after all lessons are finished.
- Dashboard pull-to-refresh invalidates the shared enrolled data. Existing learning-event/resume refreshes remain in place. A responsive minimum card height also prevents overflow on wider/shorter screens and large text.

No schema, credentials, payment, PDF rendering or backend deployment changes are required. Verification uses repository/provider fixtures for UI behavior; it does not claim a new signed-in device/Supabase end-to-end session.

Verification: **14 focused tests passed**, covering matching header bounds/styles at normal and large text sizes, enrolled-data selection, distinct card course IDs, search/filter/tab behavior, empty dashboard sections, certificate large-text layout and loading/failure behavior. Static analysis of the changed components and tests found no issues.

Search follow-up: matching the outer bounds was insufficient because the editable field still used InputDecorator's internal layout. Both search variants now use the same `_SearchSurface` row, border, fill, icon and spacing; the editable input has no independent decoration. Five relevant tests pass, including actual icon/hint offsets at large text sizes, icon-tap focus, and filtering/clearing.
