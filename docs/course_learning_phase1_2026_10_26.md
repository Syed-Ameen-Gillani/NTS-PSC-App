# Course learning — Phase 1 implementation report

Date: 26 October 2026. Status: Phase 1 complete. Phase 2 has not started.

Parent: [phased plan](course_learning_experience_plan_2026_10_26.md). Baseline: [Phase 0 audit](course_learning_phase0_2026_10_26.md).

## Implemented behavior

### Assessment history protection

- Corrected the assignment DELETE policy. A security-definer existence helper avoids the assignment/submission RLS recursion exposed during rehearsal.
- Added database delete guards for assignments with submissions and quizzes with attempts/sessions. Released assessments are also retained, even before the first attempt.
- Submission/revision/attempt IDs and existing completion records were preserved. Retirement/unlinking no longer requires deleting assessment history.

### Ordered lesson activities

- Added `lesson_activity_placements` referencing existing lesson video/reading, materials and assessment links. No questions, answers or submissions are duplicated.
- Placements have stable IDs, deterministic order, required state and rule version. Source refresh/backfill preserves configured order and required choices.
- Backfilled current sources and added source-change triggers. Same-course/module/lesson validation prevents mismatched material and assessment scopes.
- Existing videos, inline readings and graded assessments default to required. Handouts alongside primary content remain supplemental. A handout-only lesson treats its documents as the primary required reading, so it can be a valid reading lesson.
- Added owner-only activity draft retrieval, transactional activity configuration and module/lesson reorder APIs. The existing ten-lesson module limit remains enforced.
- Added typed activity metadata to the lesson model; lesson copies preserve it. Extracted the existing lesson model to keep the shared model file below the project length limit.

These APIs and data contracts support the teacher controls scheduled for Phase 4. Automatic use of required/optional criteria for learning completion remains Phase 3; the current completion policy is not presented as already replaced.

### Publication and draft privacy

- Added immutable `course_releases`, retained release-source references and a single active release pointer.
- Bootstrapped one release for each of the 11 currently published courses using only currently released content. Existing draft work was not promoted during migration.
- Stored staged title, reading text, duration, external URL and ordering changes in a separate owner-only draft table. Private draft readings are never added to publicly readable module rows or returned to students.
- Source additions and removal are staged. The current student release remains available until explicit publication; owner draft lists hide pending removals.
- Corrected publication readiness for quiz-only and assignment/quiz lessons. Empty required work and invalid configured sources cannot replace an already published lesson.
- Publication applies staged metadata, ordering and source removals, validates readiness, releases eligible lessons/modules and captures the manifest in one transaction. A failed validation rolls everything back.
- Relinking revives the existing exact placement rather than creating a duplicate. Historical sources and released file references remain available for preservation; the client cannot eagerly delete those files.
- Released assignment definitions cannot change in place. A new assignment version can be created and linked while the old release remains intact. The teacher version-editing UI is part of Phase 4.

Pending removal uses retirement, not destructive row/file cleanup. This retains history and avoids changing students' current release before publication. Storage retention will require an explicit future retention policy if historical files are eventually removed.

### Complete outline retrieval

- Added `get_public_course_outline` with course/release/module/lesson/activity metadata. It reads the active manifest independently of protected lesson joins.
- Retained the legacy syllabus API, deriving its safe response from the same release.
- Updated the course repository to hydrate the complete outline in batches. Missing module rows are restored rather than silently dropping their lessons.
- Authorized lesson content is preserved when public metadata is merged; metadata-only lessons remain locked with empty notes/video paths.
- Owner previews overlay only their own private draft values and activity configuration. Students and anonymous users use the published projection.
- Updated link/unlink confirmation wording to explain that course changes must be published.

No video-player controls or unrelated screen layouts were changed.

## Deployed migrations

Applied to the configured Supabase project:

1. `20261026140000_assessment_history_safety.sql`
2. `20261026141000_lesson_activity_placements.sql`
3. `20261026142000_course_release_manifests.sql`
4. `20261026143000_staged_curriculum_edits.sql`
5. `20261026144000_activity_course_publication.sql`
6. `20261026145000_release_integrity_guards.sql`

Before deployment, a private recovery snapshot was saved outside the repository containing existing public data, function/policy/constraint/trigger definitions and migration history. The JSON was parsed successfully and was approximately 1.3 MB. This is a targeted recovery snapshot, not a complete project disaster-recovery backup; auth accounts and stored binary files were not changed by deployment.

After deployment:

| Check | Result |
| --- | --- |
| Phase 1 migrations applied | 6 |
| Published courses / active releases | 11 / 11 |
| Activity placements | 15 |
| Duplicate source placements | 0 |
| Owner draft change records | 0 |
| Private new tables with RLS | 4 |
| Test accounts remaining | 0 |
| Existing enrollments | 14, unchanged |
| Existing earned completions | 1, unchanged |
| Completion/progress/quiz attempt/submission fingerprints | Unchanged before versus after deployment |

## Verification

- Rehearsed the migration set in a transaction and rolled it back before live application.
- Executed isolated SQL checks before and after deployment. Fresh synthetic teacher/student/unrelated-teacher identities, courses, assessments and storage metadata were created inside rollback-only transactions; no fixtures remained.
- SQL checks covered all seven requested content combinations; reading-only and assessment-only publication; idempotent backfill; staged required/order changes; teacher/student/outsider contexts; draft-reading privacy; staged material removal/unlink; failed-publication atomicity; relinking without duplicates; no-op publication; submission delete protection; release immutability; anonymous outline access and denial of private manifest access.
- These SQL checks use actual database role/JWT-claim contexts. They are not native-device upload/playback tests and use fixture storage metadata rather than real video bytes.
- Anonymous REST checks passed against both the new outline and legacy syllabus. Current data returns 11 published courses and 5 released lessons; private release/draft/placement tables reject anonymous reads, and direct anonymous lesson reads return zero rows.
- Flutter outline/mapping/publication/curriculum checks: 31 passed.
- Additional confirmation/resources/download/player/quiz/assignment regression checks: 27 passed.
- Scoped Flutter analysis: no issues.
- Real read-only Flutter/Supabase catalog integration: 1 passed against the deployed outline API.

Repeatable checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/test_course_release_phase1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tool/test_public_course_outline.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tool/test_public_course_syllabus.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tool/query_supabase.ps1 -File tool/learning_phase1_health.sql
```

`-RehearseMigrations` is for a baseline database before these migrations are applied. The default command tests already deployed functions and rolls all fixtures back.

## Boundaries and remaining work

- The six historical published courses without modules remain unchanged. Their enrollments were preserved; no curriculum was invented or silently published.
- The real assessment-only draft module remains draft until its teacher explicitly chooses Publish changes. The corrected release logic now permits it when its activities are ready.
- Sequential backend access/payment entitlement is Phase 2. Legacy boolean completion endpoints remain until their coordinated replacement in Phase 3.
- Required/optional authoring controls, complete student activity rendering, lesson-specific resource navigation and syllabus styling remain in their approved later phases.
- Existing assessment records retain their server publication state for immutable release/history. Teacher UI distinctions between staged unlinking, an active release and a reusable historical assessment need the Phase 4 authoring presentation; retirement does not fabricate a new editable draft assessment.
- Paid checkout credentials/provider selection and native iOS verification remain external dependencies. No new configuration is needed for Phase 1.
- No Android/iOS device session was run for this backend/model phase. Native verification remains a later integration gate.

Rollback strategy: preserve new history and release records, deploy compatible client fixes or a forward corrective migration, and use the recovery snapshot for targeted restoration if needed. Do not delete attempts/submissions/completions or drop release tables after new writes.
