# Assessment persistence

Normal app runs use Supabase. Mock quiz and assignment repositories are test fixtures only.

## Database paths

- Creating or editing a quiz calls `save_teacher_quiz`. That function saves the quiz, ordered questions, and answer keys in one transaction. The Flutter repository reloads the saved quiz before reporting success.
- Creating an assignment inserts a draft into `assignments`, then uploads any brief files to private Storage and records their metadata. Draft edits and publication are database writes; the repository reloads the saved row and brief metadata.
- Optional assignment links use `assignments.external_url`. Migration `20261024010000_assignment_external_links.sql` was applied to the configured hosted project on 2026-10-24. It also grants authenticated teachers column-level insert and update access.
- The repository retains a compatibility path for installations that have not yet applied this migration: assignments without links continue to work, while saving a non-empty link fails clearly instead of silently dropping it.
- Publishing a draft quiz or assignment now starts with course, module, or lesson placement. Migration `20261024020000_publish_assessment_on_link.sql` makes assignment placement and publication one database transaction; quiz placement already publishes through the same RPC. Cancelling the selector leaves the draft unchanged.

## Reusing an assessment in another course (2026-10-25)

`20261025000000_reuse_assessments_across_courses.sql` and `20261025010000_validate_reused_quiz_before_publication.sql` are applied to the hosted project. A published assessment can be linked to another course owned by the same teacher. The link RPC creates a course-specific published copy and then places it in the chosen course, module, or lesson. Quiz questions and answer keys, assignment instructions, optional URL, and ready brief references are copied. Each course has its own attempts, submissions, notifications, and analysis; changes to one copy do not rewrite another course's assessment. An assignment with a past due date cannot be reused. Linking again within an already-used course reuses that course's copy.

The temporary two-course Auth/REST verification passed: both courses received a published quiz and assignment, and the quiz copy retained its question. Temporary records were removed afterward. The teacher's three-dot menu now remains available for linked assessments and opens the course selector under **Link to course**.

## Hosted verification (2026-10-24)

- Migration history reports `20261024010000`; the live column and both authenticated column grants were confirmed.
- Migration history also reports `20261024020000`; `supabase/tests/publish_assessment_on_link.sql` passed on the hosted database, including rollback of an expired assignment's attempted placement.
- The live `save_teacher_quiz` RPC exists.
- `supabase/tests/atomic_quiz_save.sql` passed against the hosted database after updating its unlinked-quiz expectation to match the course-link publication rule. It verifies atomic question and answer-key persistence, rollback on invalid input, and teacher-only writes.
- `supabase/tests/assignment_external_links.sql` passed against the hosted database. It verifies teacher insert/update, link retention through publication, and the HTTPS constraint.
- `tool/test_assessment_persistence.ps1` passed against hosted Auth, REST, and private Storage APIs. A temporary signed-in teacher saved and reread an assignment link and a private brief file, plus a two-question quiz with both answer keys. The script removed its temporary Storage object, quiz, assignment, course, and account afterward.
- The focused Flutter assignment and quiz tests passed (18 tests).
- The SQL tests roll back their writes. The API smoke covers Storage but not device screen navigation; a teacher UI/device acceptance check remains separate.

## Hosted acceptance check

1. Confirm the intended Supabase project reports migrations through `20261024020000`. Do not put a service-role key in the app.
2. Sign in as a teacher. Create a quiz with multiple questions, save it, leave the screen, and reopen it. Confirm the title, options, correct answers, and explanations survived a fresh app launch.
3. Create an assignment with an HTTPS link and a brief file. Reopen its draft, edit it, use Publish to choose a curriculum location, and confirm the link and file survive a fresh app launch.
4. Sign in as an enrolled student. Confirm the published assignment shows the external-link action and attached brief, while an assignment without a link does not show that action.
5. Rerun `supabase/tests/atomic_quiz_save.sql`, `supabase/tests/assignment_external_links.sql`, and `supabase/tests/publish_assessment_on_link.sql` after future schema changes. These tests roll back their writes and require retained test profiles.

The authenticated teacher API and private Storage write/read round trip is complete. Device UI acceptance remains open.

Student attempts, revision recovery, course-completion requirements and private certificate issuance are now documented in [student learning](student_learning.md), including the deployed October 2026 migration set and live end-to-end verification.
