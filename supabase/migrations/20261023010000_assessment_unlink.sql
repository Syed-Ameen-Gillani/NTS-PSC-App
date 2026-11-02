create or replace function public.guard_quiz_publication()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and old.status = 'published' then
    if not (current_setting('app.assessment_unlink', true) = 'on'
      and new.status = 'draft' and new.course_id is null
      and row(new.title,new.category,new.difficulty,new.duration_minutes,new.passing_score)
        is not distinct from
          row(old.title,old.category,old.difficulty,old.duration_minutes,old.passing_score))
      and row(new.title,new.category,new.difficulty,new.duration_minutes,
        new.passing_score,new.course_id,new.status) is distinct from
        row(old.title,old.category,old.difficulty,old.duration_minutes,
          old.passing_score,old.course_id,old.status) then
      raise exception 'Published quizzes are immutable';
    end if;
  end if;
  if new.status = 'published' and (tg_op = 'INSERT' or old.status = 'draft') then
    if tg_op = 'INSERT' then raise exception 'Create a draft before publishing'; end if;
    if not exists(select 1 from public.quiz_questions q where q.quiz_id=old.id) or
      exists(select 1 from public.quiz_questions q left join public.quiz_answer_keys k
        on k.question_id=q.id where q.quiz_id=old.id and
        (k.question_id is null or k.correct_option_index>=array_length(q.options,1))) then
      raise exception 'Quiz questions and answer keys must be complete';
    end if;
    new.published_at=now();
  else
    new.published_at=case when new.status='draft' then null else old.published_at end;
  end if;
  return new;
end;
$$;

create or replace function public.unlink_curriculum_assessment(p_link_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_link public.curriculum_assessment_links%rowtype;
begin
  select * into v_link from public.curriculum_assessment_links where id=p_link_id for update;
  if not found or not public.can_access_curriculum(
      v_link.course_id,v_link.module_id,v_link.lesson_id,true) then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  delete from public.curriculum_assessment_links where id=p_link_id;
  if v_link.quiz_id is not null and not exists(
    select 1 from public.curriculum_assessment_links where quiz_id=v_link.quiz_id) then
    if not exists(select 1 from public.quiz_attempts where quiz_id=v_link.quiz_id) then
      perform set_config('app.assessment_unlink','on',true);
      update public.quizzes set course_id=null,status='draft' where id=v_link.quiz_id;
      perform set_config('app.assessment_unlink','off',true);
    end if;
  elsif v_link.assignment_id is not null and not exists(
    select 1 from public.curriculum_assessment_links where assignment_id=v_link.assignment_id) then
    if not exists(select 1 from public.assignment_submissions
      where assignment_id=v_link.assignment_id) then
      update public.assignments set status='draft',published_at=null
      where id=v_link.assignment_id and status='published';
    end if;
  end if;
end;
$$;
revoke all on function public.unlink_curriculum_assessment(uuid) from public,anon;
grant execute on function public.unlink_curriculum_assessment(uuid) to authenticated;
