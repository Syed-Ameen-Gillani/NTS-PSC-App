-- Students may track lessons only within their own active enrollment.
grant select on public.lesson_progress to authenticated;
grant insert (enrollment_id, lesson_id, resume_seconds, watched_seconds,
  completed_at, last_viewed_at) on public.lesson_progress to authenticated;
grant update (resume_seconds, watched_seconds, completed_at, last_viewed_at)
  on public.lesson_progress to authenticated;

create policy lesson_progress_student_read on public.lesson_progress
for select to authenticated using (exists (
  select 1 from public.enrollments e
  where e.id = enrollment_id and e.student_id = (select auth.uid())
));

create policy lesson_progress_student_insert on public.lesson_progress
for insert to authenticated with check (exists (
  select 1 from public.enrollments e
  join public.course_modules m on m.course_id = e.course_id
  join public.lessons l on l.module_id = m.id
  where e.id = enrollment_id and l.id = lesson_id
    and e.student_id = (select auth.uid()) and e.status = 'active'
));

create policy lesson_progress_student_update on public.lesson_progress
for update to authenticated
using (exists (
  select 1 from public.enrollments e
  where e.id = enrollment_id and e.student_id = (select auth.uid())
    and e.status = 'active'
))
with check (exists (
  select 1 from public.enrollments e
  join public.course_modules m on m.course_id = e.course_id
  join public.lessons l on l.module_id = m.id
  where e.id = enrollment_id and l.id = lesson_id
    and e.student_id = (select auth.uid()) and e.status = 'active'
));
