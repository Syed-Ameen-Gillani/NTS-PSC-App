-- The first published lesson is available as a signed-in course preview.
-- Enrollment grants access to every published lesson; progress continues to
-- describe completion and no longer controls entitlement.
create or replace function public.lesson_access_state(p_course uuid,p_lesson uuid)
returns text language plpgsql stable security definer set search_path='' as $$
declare enrollment uuid; target_sequence bigint;
begin
  if exists(select 1 from public.courses c join public.course_modules m on m.course_id=c.id
    join public.lessons l on l.module_id=m.id where c.id=p_course and l.id=p_lesson
      and c.instructor_id=auth.uid()) then return 'preview';end if;

  select sequence_number into target_sequence
  from public.released_course_lessons(p_course) where lesson_id=p_lesson;
  if target_sequence is null then return 'unavailable';end if;

  if not public.has_course_entitlement(p_course) then
    return case when target_sequence=1 then 'preview' else 'enrollment_required' end;
  end if;

  select id into enrollment from public.enrollments
  where student_id=auth.uid() and course_id=p_course and status in ('active','completed');
  if exists(select 1 from public.lesson_progress
      where enrollment_id=enrollment and lesson_id=p_lesson and completed_at is not null)
    or exists(select 1 from public.course_completions where enrollment_id=enrollment)
    or public.lesson_gate_satisfied(auth.uid(),p_course,p_lesson) then
    return 'completed';
  end if;
  return 'available';
end;
$$;

