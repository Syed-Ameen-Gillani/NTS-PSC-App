-- A quiz becomes learner-visible only after it is linked to a course. The
-- legacy guard prevents downgrading published rows, so suspend it only while
-- withdrawing unlinked quizzes. Linked drafts are then published with the
-- normal completeness validation active.
alter table public.quizzes disable trigger quizzes_publication;
update public.quizzes set status='draft', published_at=null
where course_id is null and status='published';
alter table public.quizzes enable trigger quizzes_publication;

update public.quizzes set status='published'
where course_id is not null and status='draft';

create or replace function public.enforce_quiz_link_status()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.status := case when new.course_id is null then 'draft' else 'published' end;
  return new;
end;
$$;

drop trigger if exists quizzes_link_status on public.quizzes;
create trigger quizzes_link_status
before insert or update of course_id, status on public.quizzes
for each row execute function public.enforce_quiz_link_status();

create or replace function public.link_curriculum_assessment(
  p_course_id uuid,p_module_id uuid,p_lesson_id uuid,p_kind text,p_assessment_id uuid
) returns void language plpgsql security definer set search_path='' as $$
declare v_quiz public.quizzes;
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
      update public.quizzes
      set course_id=p_course_id, status='published'
      where id=v_quiz.id;
    end if;
    insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,quiz_id)
      values(p_course_id,p_module_id,p_lesson_id,p_assessment_id) on conflict do nothing;
  elsif p_kind='assignment' then
    if not exists(select 1 from public.assignments where id=p_assessment_id and course_id=p_course_id) then
      raise exception 'Choose an assignment from this course';
    end if;
    insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,assignment_id)
      values(p_course_id,p_module_id,p_lesson_id,p_assessment_id) on conflict do nothing;
  else raise exception 'Unknown assessment type'; end if;
end;
$$;
