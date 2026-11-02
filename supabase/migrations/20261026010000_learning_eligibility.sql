-- Authoritative current eligibility; issuance/history is a separate concern.
create function public.get_my_course_eligibility()
returns table(course_id uuid,lessons_remaining bigint,quizzes_remaining bigint,
  assignments_remaining bigint,is_complete boolean)
language sql stable security definer set search_path='' as $$
  with enrolled as (
    select e.id,e.course_id from public.enrollments e
    where e.student_id=auth.uid() and e.status in ('active','completed')
  ), counts as (
    select e.course_id,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
       where m.course_id=e.course_id and l.status='published') as lesson_total,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
       where m.course_id=e.course_id and l.status='published' and not exists(
         select 1 from public.lesson_progress p where p.enrollment_id=e.id
           and p.lesson_id=l.id and p.completed_at is not null)) as lessons_remaining,
      (select count(distinct q.id) from public.curriculum_assessment_links links
       join public.quizzes q on q.id=links.quiz_id
       where links.course_id=e.course_id and not exists(
         select 1 from public.quiz_attempts a where a.quiz_id=q.id and a.student_id=auth.uid()
           and a.score::numeric*100/a.total_questions >= a.passing_score)) as quizzes_remaining,
      (select count(distinct a.id) from public.curriculum_assessment_links links
       join public.assignments a on a.id=links.assignment_id
       where links.course_id=e.course_id and not exists(
         select 1 from public.assignment_submissions s where s.assignment_id=a.id
           and s.student_id=auth.uid() and s.status='approved')) as assignments_remaining
    from enrolled e
  ) select course_id,lessons_remaining,quizzes_remaining,assignments_remaining,
      lesson_total>0 and lessons_remaining=0 and quizzes_remaining=0 and assignments_remaining=0
    from counts;
$$;
revoke all on function public.get_my_course_eligibility() from public,anon;
grant execute on function public.get_my_course_eligibility() to authenticated;
