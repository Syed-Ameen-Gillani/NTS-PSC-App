-- INSERT ... RETURNING checks the SELECT policy before a security-definer
-- lookup by id can observe the new assignment. Allow the owning instructor
-- to read drafts directly; keep the existing student access gate unchanged.
alter policy assignments_read on public.assignments using (
  exists (
    select 1 from public.courses c
    where c.id = assignments.course_id
      and c.instructor_id = (select auth.uid())
  )
  or public.can_access_assessment('assignment', assignments.id)
);
