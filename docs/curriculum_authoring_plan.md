# Curriculum authoring audit and implementation

## Findings

- Instructor details use an auto-disposed FutureProvider. TabBarView can remove
  its listener between visits, so the result is discarded and fetched again.
  Repeated tab selection is not an appropriate refresh policy for public profiles.
- An empty lesson currently shows a leading video-camera action. Existing video
  lessons should keep the leading play action; empty ones need a trailing Add video.
- Add lesson accepts an external URL and text only. Native file upload exists on
  the later lesson-video page and on initial course creation, but is missing here.
- Course handouts are explicitly disabled in Supabase mode. Mock uploads only
  invent metadata; text notes are not PDF/handout uploads.
- Assignments belong to courses, quizzes optionally belong to courses, and
  in-video checkpoints belong to a video. There is no module/lesson association
  for ordinary quizzes/assignments or actual teaching documents.

## Direction

Coursera modules combine videos, readings and assessments. Assessments are
independent learning items, not document attachments or video files. Keep the
existing assessment authoring, draft/publication, grading and submission flows;
add curriculum associations rather than duplicate those systems.

References: [Coursera assignments](https://www.coursera.support/s/article/learner-000001563?language=en_US)
and [a module-based Coursera syllabus](https://www.coursera.org/learn/university-teaching).

## Prioritized phases

1. **Fetch lifecycle and semantics.** Cache successful instructor lookups for five
   minutes after the last listener leaves. Preserve explicit Retry/invalidation;
   do not cache errors. Show Add video trailing only when no video is attached.
   Acceptance: repeated tab visits reuse data; real videos retain leading Play.
2. **Secure curriculum backend.** Add private course/module/lesson materials and
   assessment-link tables, strict parent/course checks, teacher ownership, active
   enrollment and published-content visibility. Reuse existing assessment IDs and
   APIs. A draft standalone quiz may be bound to a course atomically; a published
   quiz must not be reassigned. Documents are limited to 25 MB and approved types.
   Acceptance: no cross-course linking, no public private-file URLs, no answer-key
   exposure, no student visibility for drafts/uploading files.
3. **Lesson creation.** Extract a Riverpod-backed lesson sheet with native video
   selection and document selection, metadata validation and blocked navigation
   while saving. Save the lesson once, then upload its assets. Keep the saved ID
   after partial failure so Retry never creates another lesson. Reuse compression,
   transcription and teacher review on the existing media screen.
4. **Curriculum access.** Provide one shared material/assessment workspace for
   course, module or lesson scope. Teachers upload/open/remove handouts and link
   existing assessments; students open only authorized files and published
   assessments. Offer entry points from the module, lesson-media workspace and
   student lesson screen. Course-level handouts use the same real implementation.
5. **Verification and rollout.** Test cache reuse/retry, empty/populated rows,
   validation, partial-upload retries, real repository mapping and responsive
   controls. Add SQL authorization/relationship regressions; inspect/apply only
   the new migration using existing secret-redacting tooling when available.
   Run focused Flutter tests, scoped analysis and Android debug build. Report
   hosted deployment/RLS verification separately from controller-double tests.

## Dependencies and risks

- Phases 3/4 require phase 2 on the hosted database. No new third-party provider
  credentials are needed; the existing Supabase database/storage connection is used.
- Native video still uses existing source/compressed size limits. Selected files
  remain local until the lesson is saved; cancellation must not upload anything.
- Storage and metadata are not one transaction. Uploading rows are hidden from
  students; failed upload cleanup is best-effort and retry must be explicit.
- Linking an assessment does not publish it, change grades, copy its questions or
  grant access outside the existing course/enrollment policies.
- This is module/lesson association, not a wholesale replacement with Coursera's
  proprietary course editor or a claim of identical behavior.

## Implementation status (2026-10-20)

- Phases 1-4 implemented. The two migrations `20261020000000` and
  `20261020010000` were applied to the hosted project using the existing
  secret-redacting deployment script. No new provider credentials are required.
- Instructor results survive tab disposal for five idle minutes. Errors remain
  retryable. Empty teacher lesson rows have a trailing Add video action; attached
  videos retain their leading play action.
- Add lecture / lesson supports native video selection, optional external HTTPS
  video URLs, study notes and PDF/DOCX/PPTX/TXT documents (25 MB per file).
  Metadata is created idempotently before asset upload. Partial failures retain
  the saved lesson ID and only retry outstanding uploads. Native video uploads
  continue into the existing transcript/review workspace.
- Teachers manage lesson documents and assessment links in Lesson Studio from the
  lesson's trailing action. The shared materials route remains for student access
  and existing course/module data. Teachers can upload/open/remove documents and
  link/unlink assessments. Existing quiz and
  assignment authoring, publication, attempt and review flows remain authoritative.
  A new assessment is created through those flows, then selected for placement.
- Lesson Studio lists assessments linked directly to the lesson and those inherited
  from its module or course, with a placement label. Unlinking uses the actual
  link's scope.
- Students see ready private documents and published assessments only when their
  course/lesson access permits it. Document viewing uses a short-lived signed URL
  and the device's external viewer, not a new embedded PDF renderer.

### Verification

- 32 focused Flutter tests passed across curriculum authoring/resources, responsive
  lesson sheets, teacher workspace/media, lesson player and real course previews.
- Scoped Flutter analysis passed with no issues. Android debug APK built
  successfully. Existing Gradle/AGP/Kotlin future-support warnings remain; no
  unrelated build-tool upgrade was attempted.
- Hosted SQL regression `supabase/tests/curriculum_materials.sql` passed, including
  ownership/enrollment rules, cross-course rejection, draft/uploading visibility,
  duplicate links, hidden answer keys and idempotent lesson creation. Its storage
  fixtures are metadata-only; this does not establish HTTP file transfer success.
- The broad widget suite also exposed two pre-existing expectation mismatches:
  immediate authentication after signup, and dummy content for a missing course.
  Neither unrelated application behavior was changed for this task.
- Native file-picker/upload/viewer behavior still requires an Android/iOS device
  smoke test. Do not treat provider doubles or SQL fixtures as that verification.

### Explicit boundaries

- Materials accompany the existing lesson model. The course publication guard
  still requires published video lessons; standalone reading-only lesson types and
  a fully ordered mixed-item curriculum editor are not introduced here.
- Material upload cleanup is best-effort if the network fails. Uploading rows stay
  hidden from students; long-lived orphan reservations need operational cleanup.
- No new video encoding service, quality variants, assessment engine or offline
  document-download subsystem is introduced by this change.

### Device acceptance checklist

1. Open Instructor, visit another course tab and return; verify no repeated request
   within the cache window. Verify Retry after an actual failed lookup.
2. Create a lesson with a native video and a PDF; verify compression/upload progress,
   blocked navigation while saving, transcript review and published lesson access.
3. Interrupt a document upload after lesson creation; retry and verify one lesson,
   no repeated successful video upload and no duplicate successful document.
4. Upload course/module/lesson handouts, open each as an enrolled student, and verify
   another account without enrollment cannot obtain its signed URL.
5. Link draft and published assessments. Confirm only published ones appear to
   students, attempts/submissions work, and unlinking does not delete assessment data.
6. Check long filenames/titles, narrow screens, large text, keyboard visibility,
   picker cancellation, unsupported/empty/oversized files and unavailable viewers.
