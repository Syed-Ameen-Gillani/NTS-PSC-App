-- Qualify outer table references: an unqualified course_id inside an enrollment
-- subquery binds to enrollments.course_id and silently becomes a tautology.
alter policy assignments_read on public.assignments using (
  exists (select 1 from public.courses c where c.id = assignments.course_id
    and c.instructor_id = (select auth.uid())) or (
    assignments.status = 'published' and exists (
      select 1 from public.enrollments e where e.course_id = assignments.course_id
        and e.student_id = (select auth.uid()) and e.status = 'active'
    )
  )
);
alter policy quizzes_read on public.quizzes using (
  quizzes.teacher_id = (select auth.uid()) or (
    quizzes.status = 'published' and (quizzes.course_id is null or exists (
      select 1 from public.enrollments e where e.course_id = quizzes.course_id
        and e.student_id = (select auth.uid()) and e.status = 'active'
    ))
  )
);
