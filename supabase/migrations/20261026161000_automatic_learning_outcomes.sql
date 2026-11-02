create function public.learning_activity_satisfied(p_student uuid,p_course uuid,p_lesson uuid,p_item jsonb)
returns boolean language plpgsql stable security definer set search_path='' as $$
declare v_link public.curriculum_assessment_links;v_spec jsonb;
begin
  if p_item->>'kind' in ('quiz','assignment') then
    select * into v_link from public.curriculum_assessment_links where id=(p_item->>'assessment_link_id')::uuid;
    return found and public.assessment_requirement_met(p_student,v_link.quiz_id,v_link.assignment_id);
  end if;
  v_spec:=public.learning_activity_descriptor(p_lesson,(p_item->>'id')::uuid);
  return exists(select 1 from public.learning_activity_progress p join public.enrollments e on e.id=p.enrollment_id
    where e.student_id=p_student and e.course_id=p_course and p.activity_id=(p_item->>'id')::uuid
      and p.content_version=v_spec->>'version' and p.completed_at is not null);
exception when sqlstate '22023' then return false;
end;
$$;
create or replace function public.manifest_lesson_gate_satisfied(p_student uuid,p_course uuid,p_lesson uuid,p_activities jsonb)
returns boolean language plpgsql stable security definer set search_path='' as $$
declare v_enrollment uuid;v_item jsonb;
begin
  select id into v_enrollment from public.enrollments where student_id=p_student and course_id=p_course and status in ('active','completed');
  if v_enrollment is null then return false; end if;
  if exists(select 1 from public.lesson_progress where enrollment_id=v_enrollment and lesson_id=p_lesson and completed_at is not null)
    or exists(select 1 from public.learning_access_grandfathering where enrollment_id=v_enrollment and lesson_id=p_lesson)
    or exists(select 1 from public.course_completions where enrollment_id=v_enrollment) then return true; end if;
  if p_activities is null or jsonb_array_length(p_activities)=0 then return false; end if;
  for v_item in select value from jsonb_array_elements(p_activities) where (value->>'required')::boolean loop
    if not public.learning_activity_satisfied(p_student,p_course,p_lesson,v_item) then return false; end if;
  end loop;
  return true;
end;
$$;

create or replace function public.course_requirements(p_student_id uuid)
returns table(course_id uuid,lessons_remaining bigint,quizzes_remaining bigint,assignments_remaining bigint,is_complete boolean)
language sql stable security definer set search_path='' as $$
  with enrolled as(select e.id,e.course_id from public.enrollments e where e.student_id=p_student_id and e.status in ('active','completed')),
  required_links as(
    select e.course_id,x.quiz_id,x.assignment_id from enrolled e
    cross join lateral public.released_course_lessons(e.course_id) l
    cross join lateral jsonb_array_elements(l.activities) a
    join public.curriculum_assessment_links x on x.id=(a->>'assessment_link_id')::uuid
    where (a->>'required')::boolean and a->>'kind' in ('quiz','assignment')
    union select e.course_id,x.quiz_id,x.assignment_id from enrolled e
      join public.curriculum_assessment_links x on x.course_id=e.course_id
      where x.lesson_id is null and x.is_released and not x.is_retired
  ), counts as(select e.course_id,
    (select count(*) from public.released_course_lessons(e.course_id)) total,
    (select count(*) from public.released_course_lessons(e.course_id) l
      where not public.lesson_gate_satisfied(p_student_id,e.course_id,l.lesson_id)) lr,
    (select count(distinct x.quiz_id) from required_links x where x.course_id=e.course_id and x.quiz_id is not null
      and not public.assessment_requirement_met(p_student_id,x.quiz_id,null)) qr,
    (select count(distinct x.assignment_id) from required_links x where x.course_id=e.course_id and x.assignment_id is not null
      and not public.assessment_requirement_met(p_student_id,null,x.assignment_id)) ar from enrolled e)
  select c.course_id,c.lr,c.qr,c.ar,c.total>0 and c.lr=0 and c.qr=0 and c.ar=0 from counts c;
$$;

alter function public.reconcile_course_completion(uuid) rename to reconcile_course_completion_before_evidence;
revoke all on function public.reconcile_course_completion_before_evidence(uuid) from public,anon,authenticated;
create function public.reconcile_course_completion(p_student_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_before text:=current_setting('app.learning_reconcile',true);
begin
  if v_before=p_student_id::text then return; end if;
  perform e.id from public.enrollments e where e.student_id=p_student_id
    and e.status in ('active','completed') order by e.id for update;
  perform set_config('app.learning_reconcile',p_student_id::text,true);
  insert into public.lesson_progress(enrollment_id,lesson_id,completed_at)
    select e.id,l.lesson_id,now() from public.enrollments e
    cross join lateral public.released_course_lessons(e.course_id) l
    where e.student_id=p_student_id and e.status in ('active','completed')
      and public.lesson_gate_satisfied(p_student_id,e.course_id,l.lesson_id)
      -- Access waivers must not manufacture completed lessons.
      and not exists(select 1 from public.learning_access_grandfathering g where g.enrollment_id=e.id and g.lesson_id=l.lesson_id)
      and not exists(select 1 from public.course_completions c where c.enrollment_id=e.id)
    on conflict(enrollment_id,lesson_id) do update set completed_at=excluded.completed_at
      where public.lesson_progress.completed_at is null;
  perform public.reconcile_course_completion_before_evidence(p_student_id);
  perform set_config('app.learning_reconcile',coalesce(v_before,''),true);
end;
$$;
-- Rebind trigger callers to the new reconciliation entry point.
create or replace function public.on_learning_requirement_changed()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_student uuid;
begin
  if tg_table_name='lesson_progress' then select student_id into v_student from public.enrollments where id=new.enrollment_id;
  else v_student:=new.student_id; end if;
  perform public.reconcile_course_completion(v_student);
  return new;
end;
$$;

create or replace function public.record_lesson_completion(p_course_id uuid,p_lesson_id uuid,p_completed boolean)
returns void language plpgsql security definer set search_path='' as $$
begin raise exception 'Progress updates automatically. Reopen the lesson in the updated app' using errcode='42501'; end;
$$;
create or replace function public.record_offline_lesson_completion(p_lesson_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin raise exception 'Reconnect and continue this lesson to sync automatic progress' using errcode='42501'; end;
$$;
do $$ declare v_columns text; begin
  select string_agg(quote_ident(column_name),',') into v_columns from information_schema.columns
    where table_schema='public' and table_name='lesson_progress';
  execute 'revoke insert ('||v_columns||'),update ('||v_columns||') on public.lesson_progress from authenticated';
end $$;
revoke insert,update,delete on public.lesson_progress from authenticated;
revoke all on function public.learning_activity_satisfied(uuid,uuid,uuid,jsonb),
  public.reconcile_course_completion(uuid) from public,anon,authenticated;
