create function public.released_course_lessons(p_course uuid)
returns table(lesson_id uuid,module_id uuid,sequence_number bigint,activities jsonb)
language sql stable security definer set search_path='' as $$
  select (l.value->>'id')::uuid,(m.value->>'id')::uuid,
    row_number() over(order by m.ordinality,l.ordinality),l.value->'activities'
  from public.courses c join public.course_releases r on r.id=c.active_release_id
  cross join lateral jsonb_array_elements(r.manifest->'modules') with ordinality m
  cross join lateral jsonb_array_elements(m.value->'lessons') with ordinality l
  where c.id=p_course and c.status='published';
$$;

create table public.learning_access_grandfathering (
  enrollment_id uuid not null references public.enrollments(id),
  lesson_id uuid not null references public.lessons(id),
  reason text not null,
  primary key(enrollment_id,lesson_id)
);
alter table public.learning_access_grandfathering enable row level security;
revoke all on public.learning_access_grandfathering from anon,authenticated;
-- Preserve the established frontier without manufacturing completion records.
insert into public.learning_access_grandfathering(enrollment_id,lesson_id,reason)
  select e.id,l.lesson_id,'pre-sequencing progress' from public.enrollments e
  cross join lateral public.released_course_lessons(e.course_id) l
  where exists(select 1 from public.course_completions c where c.enrollment_id=e.id)
    or l.sequence_number<=(select max(x.sequence_number) from public.lesson_progress p
      join public.released_course_lessons(e.course_id) x on x.lesson_id=p.lesson_id
      where p.enrollment_id=e.id and p.completed_at is not null);

create function public.assessment_requirement_met(p_student uuid,p_quiz uuid,p_assignment uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select case when p_quiz is not null then exists(select 1 from public.quiz_attempts a
    where a.quiz_id=p_quiz and a.student_id=p_student
      and a.score::numeric*100/a.total_questions>=a.passing_score)
  when p_assignment is not null then exists(select 1 from public.assignment_submissions s
    where s.assignment_id=p_assignment and s.student_id=p_student and s.status='approved')
  else false end;
$$;
create function public.lesson_gate_satisfied(p_student uuid,p_course uuid,p_lesson uuid)
returns boolean language plpgsql stable security definer set search_path='' as $$
declare v_enrollment uuid; v_activities jsonb; v_activity jsonb; v_link public.curriculum_assessment_links;
begin
  select id into v_enrollment from public.enrollments where course_id=p_course and student_id=p_student
    and status in ('active','completed');
  if v_enrollment is null then return false; end if;
  if exists(select 1 from public.learning_access_grandfathering where enrollment_id=v_enrollment and lesson_id=p_lesson)
    or exists(select 1 from public.course_completions where enrollment_id=v_enrollment) then return true; end if;
  select activities into v_activities from public.released_course_lessons(p_course) where lesson_id=p_lesson;
  if v_activities is null or jsonb_array_length(v_activities)=0 then return false; end if;
  for v_activity in select value from jsonb_array_elements(v_activities) where (value->>'required')::boolean loop
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
create function public.module_assessment_gate_satisfied(p_student uuid,p_course uuid,p_module uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.course_completions where student_id=p_student and course_id=p_course)
    or not exists(select 1 from public.curriculum_assessment_links x
      where x.course_id=p_course and x.module_id=p_module and x.lesson_id is null
        and x.is_released and not x.is_retired
        and not public.assessment_requirement_met(p_student,x.quiz_id,x.assignment_id));
$$;

create function public.lesson_access_state(p_course uuid,p_lesson uuid)
returns text language plpgsql stable security definer set search_path='' as $$
declare v_target record; v_previous record;
begin
  if exists(select 1 from public.courses c join public.course_modules m on m.course_id=c.id
    join public.lessons l on l.module_id=m.id where c.id=p_course and l.id=p_lesson
      and c.instructor_id=auth.uid()) then return 'preview'; end if;
  select * into v_target from public.released_course_lessons(p_course) where lesson_id=p_lesson;
  if not found then return 'unavailable'; end if;
  if not public.has_course_entitlement(p_course) then return 'enrollment_required'; end if;
  if public.lesson_gate_satisfied(auth.uid(),p_course,p_lesson) then return 'completed'; end if;
  for v_previous in select * from public.released_course_lessons(p_course) where sequence_number<v_target.sequence_number loop
    if not public.lesson_gate_satisfied(auth.uid(),p_course,v_previous.lesson_id)
      or (v_previous.module_id<>v_target.module_id and not
        public.module_assessment_gate_satisfied(auth.uid(),p_course,v_previous.module_id)) then
      return 'prerequisite_required'; end if;
  end loop;
  return 'available';
end;
$$;
create function public.can_open_lesson(p_course uuid,p_lesson uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.lesson_access_state(p_course,p_lesson) in ('available','completed','preview');
$$;

create or replace function public.can_access_curriculum(p_course uuid,p_module uuid default null,
  p_lesson uuid default null,p_manage boolean default false)
returns boolean language sql stable security definer set search_path='' as $$
  select auth.uid() is not null and exists(select 1 from public.courses c where c.id=p_course
    and (p_module is null or exists(select 1 from public.course_modules m where m.id=p_module and m.course_id=c.id))
    and (p_lesson is null or exists(select 1 from public.lessons l where l.id=p_lesson and l.module_id=p_module))
    and (c.instructor_id=auth.uid() or (not p_manage and public.has_course_entitlement(c.id)
      and (p_lesson is null or public.can_open_lesson(c.id,p_lesson))
      and (p_module is null or exists(select 1 from public.released_course_lessons(c.id) x
        where x.module_id=p_module and public.can_open_lesson(c.id,x.lesson_id))))));
$$;
create or replace function public.can_access_lesson_media(p_lesson_id uuid,p_teacher_only boolean default false)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.lessons l join public.course_modules m on m.id=l.module_id
    join public.courses c on c.id=m.course_id where l.id=p_lesson_id
      and (c.instructor_id=auth.uid() or (not p_teacher_only and public.can_open_lesson(c.id,l.id))));
$$;
drop policy lessons_read on public.lessons;
create policy lessons_read on public.lessons for select to anon,authenticated using(
  exists(select 1 from public.course_modules m where m.id=lessons.module_id
    and public.can_open_lesson(m.course_id,lessons.id)));

create function public.get_my_course_access(p_course_ids uuid[])
returns table(course_id uuid,entitled boolean,lesson_states jsonb)
language plpgsql stable security definer set search_path='' as $$
begin
  if coalesce(cardinality(p_course_ids),0)>200 then raise exception 'Request at most 200 courses'; end if;
  return query select c.id,public.has_course_entitlement(c.id),coalesce((select jsonb_object_agg(
    x.lesson_id,public.lesson_access_state(c.id,x.lesson_id)) from public.released_course_lessons(c.id) x),'{}'::jsonb)
    from public.courses c where c.id=any(coalesce(p_course_ids,'{}'::uuid[])) and c.status='published';
end;
$$;
revoke all on function public.released_course_lessons(uuid),
  public.assessment_requirement_met(uuid,uuid,uuid),public.lesson_gate_satisfied(uuid,uuid,uuid),
  public.module_assessment_gate_satisfied(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.lesson_access_state(uuid,uuid),public.can_open_lesson(uuid,uuid),
  public.get_my_course_access(uuid[]) from public;
grant execute on function public.lesson_access_state(uuid,uuid),public.can_open_lesson(uuid,uuid),
  public.get_my_course_access(uuid[]) to anon,authenticated;
