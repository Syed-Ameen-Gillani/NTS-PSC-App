create function public.can_access_assessment(p_kind text,p_id uuid)
returns boolean language plpgsql stable security definer set search_path='' as $$
declare v_course uuid; v_owner uuid; v_status text; v_link record;
begin
  if p_kind='quiz' then
    select course_id,teacher_id,status into v_course,v_owner,v_status from public.quizzes where id=p_id;
  elsif p_kind='assignment' then
    select a.course_id,c.instructor_id,a.status into v_course,v_owner,v_status
      from public.assignments a join public.courses c on c.id=a.course_id where a.id=p_id;
  else return false; end if;
  if v_owner=auth.uid() then return true; end if;
  if auth.uid() is null or v_status is distinct from 'published' then return false; end if;
  if v_course is null then return p_kind='quiz'; end if;
  if not public.has_course_entitlement(v_course) then return false; end if;
  for v_link in select * from public.curriculum_assessment_links x
    where x.course_id=v_course and x.is_released and not x.is_retired
      and ((p_kind='quiz' and x.quiz_id=p_id) or (p_kind='assignment' and x.assignment_id=p_id)) loop
    if v_link.lesson_id is not null then
      if public.can_open_lesson(v_course,v_link.lesson_id) then return true; end if;
    elsif v_link.module_id is not null then
      if exists(select 1 from public.released_course_lessons(v_course) l where l.module_id=v_link.module_id)
        and not exists(select 1 from public.released_course_lessons(v_course) l
          where l.module_id=v_link.module_id and not public.lesson_gate_satisfied(auth.uid(),v_course,l.lesson_id)) then return true; end if;
    elsif not exists(select 1 from public.released_course_lessons(v_course) l
      where not public.lesson_gate_satisfied(auth.uid(),v_course,l.lesson_id)
        or not public.module_assessment_gate_satisfied(auth.uid(),v_course,l.module_id)) then return true;
    end if;
  end loop;
  return false;
end;
$$;
revoke all on function public.can_access_assessment(text,uuid) from public,anon;
grant execute on function public.can_access_assessment(text,uuid) to authenticated;
drop policy quizzes_read on public.quizzes;
create policy quizzes_read on public.quizzes for select to authenticated using(public.can_access_assessment('quiz',id));
drop policy assignments_read on public.assignments;
create policy assignments_read on public.assignments for select to authenticated using(public.can_access_assessment('assignment',id));

-- Preserve existing scoring, deadlines, idempotency and snapshots behind guards.
alter function public.start_quiz_session(uuid) rename to start_quiz_session_before_access;
alter function public.save_quiz_session(uuid,jsonb) rename to save_quiz_session_before_access;
alter function public.finish_quiz_session(uuid) rename to finish_quiz_session_before_access;
alter function public.submit_assignment(uuid,text,jsonb) rename to submit_assignment_before_access;
alter function public.record_lesson_completion(uuid,uuid,boolean) rename to record_lesson_completion_before_access;
revoke all on function public.start_quiz_session_before_access(uuid),
  public.save_quiz_session_before_access(uuid,jsonb),public.finish_quiz_session_before_access(uuid),
  public.submit_assignment_before_access(uuid,text,jsonb),
  public.record_lesson_completion_before_access(uuid,uuid,boolean) from public,anon,authenticated;

create function public.start_quiz_session(p_quiz_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  if not public.can_access_assessment('quiz',p_quiz_id) then
    raise exception 'Complete the earlier learning requirements first' using errcode='42501'; end if;
  return public.start_quiz_session_before_access(p_quiz_id);
end;
$$;
create function public.require_quiz_session_access(p_session uuid)
returns void language plpgsql stable security definer set search_path='' as $$
begin
  if not exists(select 1 from public.quiz_sessions s where s.id=p_session and s.student_id=auth.uid()
    and public.can_access_assessment('quiz',s.quiz_id)) then
    raise exception 'Quiz access is unavailable' using errcode='42501'; end if;
end;
$$;
create function public.save_quiz_session(p_session_id uuid,p_answers jsonb)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform public.require_quiz_session_access(p_session_id);
  perform public.save_quiz_session_before_access(p_session_id,p_answers);
end;
$$;
create function public.finish_quiz_session(p_session_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  perform public.require_quiz_session_access(p_session_id);
  return public.finish_quiz_session_before_access(p_session_id);
end;
$$;
create function public.submit_assignment(p_assignment_id uuid,p_response text,p_attachments jsonb)
returns public.assignment_submissions language plpgsql security definer set search_path='' as $$
begin
  if not public.can_access_assessment('assignment',p_assignment_id) then
    raise exception 'Complete the earlier learning requirements first' using errcode='42501'; end if;
  return public.submit_assignment_before_access(p_assignment_id,p_response,p_attachments);
end;
$$;
create function public.record_lesson_completion(p_course_id uuid,p_lesson_id uuid,p_completed boolean)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not public.has_course_entitlement(p_course_id) or not public.can_open_lesson(p_course_id,p_lesson_id) then
    raise exception 'Complete the earlier learning requirements first' using errcode='42501'; end if;
  perform public.record_lesson_completion_before_access(p_course_id,p_lesson_id,p_completed);
end;
$$;
-- Rebind the legacy offline entry explicitly to the guarded function.
create or replace function public.record_offline_lesson_completion(p_lesson_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_course uuid;
begin
  select m.course_id into v_course from public.lessons l join public.course_modules m on m.id=l.module_id where l.id=p_lesson_id;
  perform public.record_lesson_completion(v_course,p_lesson_id,true);
end;
$$;
revoke all on function public.require_quiz_session_access(uuid) from public,anon,authenticated;
revoke all on function public.start_quiz_session(uuid),public.save_quiz_session(uuid,jsonb),
  public.finish_quiz_session(uuid),public.submit_assignment(uuid,text,jsonb),
  public.record_lesson_completion(uuid,uuid,boolean) from public,anon;
grant execute on function public.start_quiz_session(uuid),public.save_quiz_session(uuid,jsonb),
  public.finish_quiz_session(uuid),public.submit_assignment(uuid,text,jsonb),
  public.record_lesson_completion(uuid,uuid,boolean) to authenticated;
