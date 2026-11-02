# Teacher Course Upload and Publication

## Scope and decisions

Deliver a draft-first course workflow using existing Flutter/Riverpod and Supabase patterns. Retain existing test records. Keep the video pilot limit at 25 MB; keep checkpoint generation behind its existing feature flag. Cover artwork is a public catalog asset, never a location for private documents. Videos remain private and enrollment-gated. No payment-provider work is included.

## Phase 1: Transactional drafts

### Draft preview data integrity

- Overview descriptions and topics come from the saved course and module titles;
  topics are not presented as separately authored learning outcomes.
- Lecture totals are calculated from saved module lessons. No sample syllabus is
  inserted when modules or lessons are missing; empty states are displayed instead.
- A module accepts at most 10 lessons. The module card shows its count and disables
  adding after 10; the database trigger also rejects direct and concurrent inserts.
- Enrollment defaults to zero rather than a fabricated audience. Courses without
  a rating show "No ratings yet" rather than implying existing reviews.
- Instructor details load from `public_teacher_profiles` with loading/retry/empty
  states. No stock instructor portrait, invented biography or course-as-instructor
  rating is displayed.
- The unsupported certificate preview and live-mode handout promotion are hidden.
  No database records were deleted or rewritten by this cleanup.
- Missing course/lesson navigation no longer falls back to prototype records.
- Public course counts and syllabus titles/durations use
  `get_public_course_syllabus` (migration `20261019000000`). Enrolled users keep
  their authorized lesson data; unenrolled students see locked metadata-only
  entries rather than a false zero count. Private paths, notes and transcripts
  are never returned by the public function. Lesson RLS is not relaxed.
- A lesson is catalog-visible only when both the lesson and parent course are
  published. Publishing a lesson alone does not publish the parent course.
- Hosted verification after migration: anonymous syllabus access returns 5
  published lesson metadata entries across the current 11 published courses;
  direct anonymous lesson-row access remains empty and no private fields are
  present. Re-run `tool/test_public_course_syllabus.ps1` for current totals.
- Regression coverage: `test/course_preview_real_data_test.dart`, including phone
  and tablet widths, plus the Supabase course mapper tests.

- Create course, initial modules, and lessons in one owner-authorized database transaction.
- Use a client-generated course UUID as an idempotency key: retrying the same form must not create another course.
- Never publish through the create screen. Navigate to the saved draft's management screen.
- Report save failures and retain form values for retry.

## Phase 2: Covers

- Add a Material image-picker action to course management, with progress/busy/error states.
- Accept JPEG/PNG/WebP images up to 5 MB; inspect file bytes and decoded image dimensions before uploading.
- Store covers under teacher/course/random-version paths in course-thumbnails.
- Allow only the owner to upload and attach a cover. Validate object existence and metadata on attachment.
- Upload first, attach transactionally, then remove the previous unreferenced cover. Never remove a cover still referenced by a course.
- Resolve storage paths to display URLs centrally and use the same cover renderer across student and teacher course surfaces.
- Keep the previous cover if upload fails. Do not delete a potentially committed new cover after an ambiguous network response.

## Phase 3: Lesson media

- Course creation includes an optional first-lesson video picker. The draft is
  persisted before its real lesson UUID is passed to the existing compression/TUS
  uploader; a picker selection alone never creates a playable lesson.
- Saving blocks back navigation and form changes through preparation/upload.
  Video failure retains the saved draft and opens curriculum for retry rather
  than reporting that the course itself failed to save.
- Curriculum preview shows a non-playable missing-video state until the lesson
  has a stored video path or external URL; locked lessons remain non-playable.
  Management uses a leading play/add-video icon and opens a dedicated lesson
  media route. Metadata displays attachment status before estimated duration.
- Video upload, inline playback, transcript correction and optional checkpoint
  review are on the same full-screen page, not dialogs or bottom sheets.
  Publication invalidates course data without retaining a removed curriculum
  row's context. Active operations block back/navigation and other page actions.
- Processing transcripts refresh periodically. Unsaved edits survive refreshes
  and failed saves; video publication is disabled until edits are saved.

- Preserve the existing resumable upload, transcript processing/retry, manual correction, and video publication flow.
- On a draft course, publishing reviewed media readies its lesson. On a live course, reviewed media remains pending until Publish changes releases it.
- Adding modules, lessons, handouts, assessment links, cover artwork, or replacement video keeps the current course available. Draft content remains teacher-only until Publish changes commits the next release.
- Validate stored objects and enforce the existing private-media policies.

## Phase 4: Publication gates

- Database checks: owning teacher, nonempty title/description, active category, valid stored cover, at least one lesson, and at least one lesson with video, notes, or a handout ready to release. Every lesson no longer needs a video.
- Hosted lessons require ready media and a matching Storage object. External lectures require HTTPS URLs; reachability/codec compatibility still requires playback validation.
- Guard direct table status updates, not just the Flutter publish control.
- Serialize curriculum writes against course publication with a course row lock.
- Present actionable server validation messages in the teacher interface.
- Before course publication, read persisted description/cover fields and report
  the actual missing field. The older database trigger has a combined message
  for either missing field; a missing cover must not imply a lost description.
  No existing description is overwritten. Backend publication gates remain active.
- Use Publish course for the first release and Publish changes thereafter, with
  in-flight duplicate prevention. The student-facing release stays available
  while the instructor prepares the next one.
- Retain existing published records; enforce readiness on new publication and subsequent course edits without deleting historical data.

## Phase 5: Verification and rollout

### Course management layout

The management page composes `TeacherCourseWorkspace`, `CourseWorkspaceHeader`,
and `CourseWorkspaceModule`. Its existing dialogs and controller mutations remain
in the page. The layout uses an unframed course identity/publication area, aligned
metrics, a consistent tools row, right-aligned section actions, and full-width
lesson titles with leading video actions. Empty ratings are not shown as a metric.
`test/teacher_course_workspace_test.dart` checks 320/390/768/1024-pixel layouts,
publication/module/lesson callbacks, and produces a phone render under `build/`.

### Workflow reference

The product adapts module-based course content, video/transcript review and a
deliberate publication boundary; it does not claim parity with Coursera's private
instructor tooling. Learner-facing references:
- https://www.coursera.support/s/learner-help-center-videos?language=en_US
- https://www.coursera.support/s/article/learner-000001563?language=en_US

Regression coverage also includes `teacher_lesson_media_screen_test.dart` for
inline editing/save failure/publish lifecycle and `course_publication_validation_test.dart`
for accurate missing-field messages and preservation of saved descriptions.

- Apply the additive migration to the configured project after inspecting migration prerequisites.
- Test draft idempotency/rollback, owner isolation, missing-cover/media rejection, direct-update guard, cover replacement protection, and successful publication.
- Use a real test video to verify owner upload, reviewed media publication, enrollment access, and outsider denial. Retain clearly named test data.
- Run Flutter mapper/auth/dashboard and targeted repository tests; analyze changed code.
- Verify hosted transcription separately: provider completion is asynchronous and must not be inferred from successful upload or deployment.

## Operational follow-up

- Browser/real iPhone and Android file-picker/video playback checks require those runtime surfaces.
- Track unreferenced uploads; automatic age-based orphan sweeping is a separate operational job. Never indiscriminately delete Storage objects after a timeout.
- Increasing 25 MB requires coordinated bucket, reservation validation, Flutter validation, and timeout changes.

## Execution evidence

- 2026-10-19 follow-up: upload/download audit and recovery fixes are recorded in [course transfer audit](course_transfer_audit_2026_10_19.md). Hosted publication/access checks passed again. Downloads remain app-private; the new course-level action saves eligible hosted lessons, preserves successful downloads on retry, and reports external-only lessons separately.

- Applied `20261010150000_course_publication.sql` to the hosted project, together with its pending checkpoint guard/quota prerequisites (13 and 14).
- Implemented transactional draft creation, cover validation/upload/display, readiness enforcement, curriculum locking, and actionable publication failures. Catalog providers refresh after publication changes. Upload progress no longer updates disposed media sheets.
- Hosted smoke run `1791646715009` passed draft idempotency, cover upload, missing-cover/media publication rejection, published-curriculum locking, private video upload, owner isolation, transcript draft privacy, reviewed media publication, public catalog visibility, enrolled access and outsider denial. Test accounts and media remain in the project.
- Automatic transcription reached `needs_review` in a subsequent hosted run. This verifies provider/callback operation for the bundled test video, not the quality of Urdu transcription on representative lectures.
- Final hosted run `1791646839493` passed the complete journey using the automatically generated transcript, plus invalid-curriculum transaction rollback and attached-cover deletion protection. Earlier diagnostic records were also retained as requested.
- Eleven focused Flutter tests pass: image validation, course mapping, signup navigation, dashboard previews, lesson player and media models.
- Targeted analysis of the six upload/publication implementation files reports no issues. Wider analysis reports 19 pre-existing warnings/info (unused community imports and deprecated UI APIs); unrelated work was not removed.
- Device file-picker/playback checks, representative Urdu accuracy evaluation, cover-replacement race testing and orphan sweeping are not certified by these tests. The separate checkpoint-generator redeployment and feature enablement remain outside this publication rollout.
