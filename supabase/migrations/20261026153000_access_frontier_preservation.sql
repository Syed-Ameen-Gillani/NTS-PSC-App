create index quiz_attempt_access_gate on public.quiz_attempts(student_id,quiz_id);

create function public.manifest_lesson_gate_satisfied(p_student uuid,p_course uuid,
  p_lesson uuid,p_activities jsonb)
returns boolean language plpgsql stable security definer set search_path='' as $$
declare v_enrollment uuid; v_activity jsonb; v_link public.curriculum_assessment_links;
begin
  select id into v_enrollment from public.enrollments where course_id=p_course and student_id=p_student
    and status in ('active','completed');
  if v_enrollment is null then return false; end if;
  if exists(select 1 from public.learning_access_grandfathering where enrollment_id=v_enrollment and lesson_id=p_lesson)
    or exists(select 1 from public.course_completions where enrollment_id=v_enrollment) then return true; end if;
  if p_activities is null or jsonb_array_length(p_activities)=0 then return false; end if;
  for v_activity in select value from jsonb_array_elements(p_activities) where (value->>'required')::boolean loop
    if v_activity->>'kind' in ('quiz','assignment') then
      select * into v_link from public.curriculum_assessment_links where id=(v_activity->>'assessment_link_id')::uuid;
      if not found or not public.assessment_requirement_met(p_student,v_link.quiz_id,v_link.assignment_id) then return false; end if;
    elsif not exists(select 1 from public.lesson_progress p where p.enrollment_id=v_enrollment
      and p.lesson_id=p_lesson and p.completed_at is not null) then return false;
    end if;
  end loop;
  return true;
end;
$$;
create or replace function public.lesson_gate_satisfied(p_student uuid,p_course uuid,p_lesson uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select coalesce((select public.manifest_lesson_gate_satisfied(p_student,p_course,p_lesson,l.activities)
    from public.released_course_lessons(p_course) l where l.lesson_id=p_lesson),false);
$$;

create function public.preserve_learning_access_frontier()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_manifest jsonb; e record; l record; v_allowed uuid[]; v_all_finished boolean; v_frontier bigint;
begin
  if old.active_release_id is null or new.active_release_id is not distinct from old.active_release_id then return new; end if;
  select manifest into v_manifest from public.course_releases where id=old.active_release_id;
  for e in select id,student_id from public.enrollments where course_id=new.id and status in ('active','completed') loop
    v_allowed:='{}'; v_all_finished:=true;
    for l in select (x.value->>'id')::uuid id,x.value->'activities' activities
      from jsonb_array_elements(v_manifest->'modules') with ordinality m
      cross join lateral jsonb_array_elements(m.value->'lessons') with ordinality x
      order by m.ordinality,x.ordinality loop
      v_allowed:=array_append(v_allowed,l.id);
      if not public.manifest_lesson_gate_satisfied(e.student_id,new.id,l.id,l.activities) then
        v_all_finished:=false; exit; end if;
    end loop;
    select max(sequence_number) into v_frontier from public.released_course_lessons(new.id) where lesson_id=any(v_allowed);
    insert into public.learning_access_grandfathering(enrollment_id,lesson_id,reason)
      select e.id,x.lesson_id,'new release before established access frontier'
      from public.released_course_lessons(new.id) x
      where x.sequence_number<v_frontier or (v_all_finished and x.sequence_number=v_frontier)
      on conflict do nothing;
  end loop;
  return new;
end;
$$;
create trigger preserve_access_after_release after update of active_release_id on public.courses
for each row execute function public.preserve_learning_access_frontier();

-- Access waivers are not fabricated lesson-completion records.
create or replace function public.lesson_access_state(p_course uuid,p_lesson uuid)
returns text language plpgsql stable security definer set search_path='' as $$
declare v_target record; v_previous record;
begin
  if exists(select 1 from public.courses c join public.course_modules m on m.course_id=c.id
    join public.lessons l on l.module_id=m.id where c.id=p_course and l.id=p_lesson
      and c.instructor_id=auth.uid()) then return 'preview'; end if;
  select * into v_target from public.released_course_lessons(p_course) where lesson_id=p_lesson;
  if not found then return 'unavailable'; end if;
  if not public.has_course_entitlement(p_course) then
    if exists(select 1 from public.enrollments where course_id=p_course and student_id=auth.uid() and status='cancelled') then
      return 'access_revoked'; end if;
    return 'enrollment_required';
  end if;
  if public.lesson_gate_satisfied(auth.uid(),p_course,p_lesson) then
    if exists(select 1 from public.lesson_progress p join public.enrollments e on e.id=p.enrollment_id
      where e.course_id=p_course and e.student_id=auth.uid() and p.lesson_id=p_lesson and p.completed_at is not null)
      then return 'completed'; end if;
    return 'available';
  end if;
  for v_previous in select * from public.released_course_lessons(p_course) where sequence_number<v_target.sequence_number loop
    if not public.lesson_gate_satisfied(auth.uid(),p_course,v_previous.lesson_id)
      or (v_previous.module_id<>v_target.module_id and not
        public.module_assessment_gate_satisfied(auth.uid(),p_course,v_previous.module_id)) then return 'prerequisite_required'; end if;
  end loop;
  return 'available';
end;
$$;

create policy assignment_upload_access_gate on storage.objects as restrictive
for insert to authenticated with check(bucket_id<>'assignment-submissions' or
  case when split_part(name,'/',2) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    then public.can_access_assessment('assignment',split_part(name,'/',2)::uuid) else false end);
revoke all on function public.manifest_lesson_gate_satisfied(uuid,uuid,uuid,jsonb),
  public.preserve_learning_access_frontier() from public,anon,authenticated;

drop policy lesson_progress_student_insert on public.lesson_progress;
create policy lesson_progress_student_insert on public.lesson_progress for insert to authenticated with check(
  exists(select 1 from public.enrollments e where e.id=enrollment_id and e.student_id=auth.uid()
    and e.status in ('active','completed') and public.can_open_lesson(e.course_id,lesson_progress.lesson_id)));
drop policy lesson_progress_student_update on public.lesson_progress;
create policy lesson_progress_student_update on public.lesson_progress for update to authenticated using(
  exists(select 1 from public.enrollments e where e.id=enrollment_id and e.student_id=auth.uid()
    and e.status in ('active','completed') and public.can_open_lesson(e.course_id,lesson_progress.lesson_id)))
with check(exists(select 1 from public.enrollments e where e.id=enrollment_id and e.student_id=auth.uid()
  and e.status in ('active','completed') and public.can_open_lesson(e.course_id,lesson_progress.lesson_id)));
