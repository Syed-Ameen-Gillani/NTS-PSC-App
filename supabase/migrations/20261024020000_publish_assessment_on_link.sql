-- Placement and publication are one transaction for both assessment types.
create or replace function public.link_curriculum_assessment(
  p_course_id uuid,p_module_id uuid,p_lesson_id uuid,p_kind text,p_assessment_id uuid
) returns void language plpgsql security definer set search_path='' as $$
declare
  v_quiz public.quizzes;
  v_assignment public.assignments;
begin
  if not public.can_access_curriculum(p_course_id,p_module_id,p_lesson_id,true) then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  if p_kind='quiz' then
    select * into v_quiz from public.quizzes where id=p_assessment_id for update;
    if not found or v_quiz.teacher_id<>auth.uid() or
      (v_quiz.course_id is not null and v_quiz.course_id<>p_course_id) or
      (v_quiz.course_id is null and v_quiz.status<>'draft') then
      raise exception 'Choose a draft quiz or a quiz already assigned to this course';
    end if;
    if v_quiz.course_id is null then
      update public.quizzes set course_id=p_course_id,status='published'
      where id=v_quiz.id;
    end if;
    insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,quiz_id)
      values(p_course_id,p_module_id,p_lesson_id,p_assessment_id) on conflict do nothing;
  elsif p_kind='assignment' then
    select * into v_assignment from public.assignments where id=p_assessment_id for update;
    if not found or v_assignment.course_id<>p_course_id then
      raise exception 'Choose an assignment from this course';
    end if;
    insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,assignment_id)
      values(p_course_id,p_module_id,p_lesson_id,p_assessment_id) on conflict do nothing;
    if v_assignment.status='draft' then
      update public.assignments set status='published' where id=v_assignment.id;
    end if;
  else
    raise exception 'Unknown assessment type';
  end if;
end;
$$;
