-- Access waivers preserve an established frontier; they never create grades.
create table public.learning_assessment_waivers (
  enrollment_id uuid not null references public.enrollments(id),
  assessment_link_id uuid not null references public.curriculum_assessment_links(id),
  release_id uuid not null references public.course_releases(id),
  reason text not null,
  primary key(enrollment_id,assessment_link_id)
);
alter table public.learning_assessment_waivers enable row level security;
revoke all on public.learning_assessment_waivers from public,anon,authenticated;

create function public.assessment_link_requirement_met(p_student uuid,p_link uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select coalesce((select public.assessment_requirement_met(p_student,x.quiz_id,x.assignment_id)
    or exists(select 1 from public.learning_assessment_waivers w join public.enrollments e on e.id=w.enrollment_id
      where w.assessment_link_id=x.id and e.student_id=p_student and e.course_id=x.course_id)
    from public.curriculum_assessment_links x where x.id=p_link),false);
$$;
revoke all on function public.assessment_link_requirement_met(uuid,uuid) from public,anon,authenticated;

-- Run before the active pointer changes: duration/text descriptors must still
-- resolve against the OLD release, including activities removed by this publish.
drop trigger preserve_access_after_release on public.courses;
create or replace function public.preserve_learning_access_frontier()
returns trigger language plpgsql security definer set search_path='' as $$
declare old_manifest jsonb;new_manifest jsonb;e record;l record;allowed uuid[];
  all_finished boolean;frontier bigint;previous_module uuid;module_finished boolean;
begin
 if old.active_release_id is null or new.active_release_id is not distinct from old.active_release_id then return new; end if;
 select manifest into old_manifest from public.course_releases where id=old.active_release_id;
 select manifest into new_manifest from public.course_releases where id=new.active_release_id;
 for e in select id,student_id from public.enrollments where course_id=new.id and status in ('active','completed') order by id for update loop
  allowed:='{}';all_finished:=true;previous_module:=null;
  for l in select (x.value->>'id')::uuid id,(m.value->>'id')::uuid module_id,x.value->'activities' activities
    from jsonb_array_elements(old_manifest->'modules') with ordinality m
    cross join lateral jsonb_array_elements(m.value->'lessons') with ordinality x
    order by m.ordinality,x.ordinality loop
   if previous_module is not null and previous_module<>l.module_id then
    select not exists(select 1 from jsonb_array_elements(old_manifest->'assessments') a
      where a->>'module_id'=previous_module::text and a->>'lesson_id' is null
        and not public.assessment_link_requirement_met(e.student_id,(a->>'id')::uuid)) into module_finished;
    if not module_finished then all_finished:=false;exit;end if;
   end if;
   previous_module:=l.module_id;
   allowed:=array_append(allowed,l.id);
   if not public.manifest_lesson_gate_satisfied(e.student_id,new.id,l.id,l.activities) then
    all_finished:=false;exit;
   end if;
  end loop;
  if all_finished and exists(select 1 from jsonb_array_elements(old_manifest->'assessments') a
    where a->>'module_id'=previous_module::text and a->>'lesson_id' is null
      and not public.assessment_link_requirement_met(e.student_id,(a->>'id')::uuid)) then all_finished:=false;end if;
  with ordered as(select (x.value->>'id')::uuid id,row_number() over(order by m.ordinality,x.ordinality) n
    from jsonb_array_elements(new_manifest->'modules') with ordinality m
    cross join lateral jsonb_array_elements(m.value->'lessons') with ordinality x)
  select max(n) into frontier from ordered where id=any(allowed);
  insert into public.learning_access_grandfathering(enrollment_id,lesson_id,reason)
   select e.id,(x.value->>'id')::uuid,'new release before established access frontier'
   from (select x.value,row_number() over(order by m.ordinality,x.ordinality) n
     from jsonb_array_elements(new_manifest->'modules') with ordinality m
     cross join lateral jsonb_array_elements(m.value->'lessons') with ordinality x) x
   where x.n<frontier or (all_finished and x.n=frontier) on conflict do nothing;
  -- Lesson-scoped requirements follow that lesson's explicit waiver. Module
  -- work is waived only behind the frontier, never in the current module.
  insert into public.learning_assessment_waivers(enrollment_id,assessment_link_id,release_id,reason)
   select e.id,(a->>'id')::uuid,new.active_release_id,'requirement added behind established access frontier'
   from jsonb_array_elements(new_manifest->'assessments') a
   where exists(select 1 from public.learning_access_grandfathering g where g.enrollment_id=e.id and g.lesson_id=(a->>'lesson_id')::uuid)
    or (a->>'lesson_id' is null and a->>'module_id' is not null and exists(
      select 1 from (select m.module_id,max(row_number_value) last_n from
       (select m.value->>'id' module_id,row_number() over(order by m.ordinality,x.ordinality) row_number_value
        from jsonb_array_elements(new_manifest->'modules') with ordinality m
        cross join lateral jsonb_array_elements(m.value->'lessons') with ordinality x) m
       group by m.module_id) modules
      where modules.module_id=a->>'module_id' and (modules.last_n<frontier or (all_finished and modules.last_n=frontier))))
   on conflict do nothing;
 end loop;
 return new;
end;
$$;

alter function public.get_learning_outcome(uuid) rename to get_learning_outcome_before_waivers;
revoke all on function public.get_learning_outcome_before_waivers(uuid) from public,anon,authenticated;
create function public.get_learning_outcome(p_lesson_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;items jsonb;waived boolean;
begin
 result:=public.get_learning_outcome_before_waivers(p_lesson_id);
 select exists(select 1 from public.learning_access_grandfathering g join public.enrollments e on e.id=g.enrollment_id
   where e.student_id=auth.uid() and e.course_id=(result->>'course_id')::uuid and g.lesson_id=p_lesson_id) into waived;
 select coalesce(jsonb_agg(case when exists(select 1 from public.learning_assessment_waivers w
   join public.enrollments e on e.id=w.enrollment_id where e.student_id=auth.uid()
     and w.assessment_link_id=(item->>'assessment_link_id')::uuid) and item->>'completed'<>'true'
   then item||jsonb_build_object('state','waived') else item end),'[]') into items
   from jsonb_array_elements(result->'activities') item;
 return result||jsonb_build_object('activities',items,'requirements_waived',waived);
end;
$$;
revoke all on function public.get_learning_outcome(uuid) from public,anon;
grant execute on function public.get_learning_outcome(uuid) to authenticated;
create trigger preserve_access_before_release before update of active_release_id on public.courses
for each row execute function public.preserve_learning_access_frontier();

create or replace function public.module_assessment_gate_satisfied(p_student uuid,p_course uuid,p_module uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.course_completions where student_id=p_student and course_id=p_course)
  or not exists(select 1 from public.curriculum_assessment_links x
    where x.course_id=p_course and x.module_id=p_module and x.lesson_id is null
      and x.is_released and not x.is_retired and not public.assessment_link_requirement_met(p_student,x.id));
$$;

create or replace function public.course_requirements(p_student_id uuid)
returns table(course_id uuid,lessons_remaining bigint,quizzes_remaining bigint,assignments_remaining bigint,is_complete boolean)
language sql stable security definer set search_path='' as $$
 with enrolled as(select e.id,e.course_id from public.enrollments e where e.student_id=p_student_id and e.status in ('active','completed')),
 required_links as(
  select e.course_id,x.id,x.quiz_id,x.assignment_id from enrolled e
  cross join lateral public.released_course_lessons(e.course_id) l
  cross join lateral jsonb_array_elements(l.activities) a
  join public.curriculum_assessment_links x on x.id=(a->>'assessment_link_id')::uuid
  where (a->>'required')::boolean and a->>'kind' in ('quiz','assignment')
  union select e.course_id,x.id,x.quiz_id,x.assignment_id from enrolled e
   join public.curriculum_assessment_links x on x.course_id=e.course_id
   where x.lesson_id is null and x.is_released and not x.is_retired
 ), counts as(select e.course_id,
  (select count(*) from public.released_course_lessons(e.course_id)) total,
  (select count(*) from public.released_course_lessons(e.course_id) l where not public.lesson_gate_satisfied(p_student_id,e.course_id,l.lesson_id)) lr,
  (select count(distinct x.quiz_id) from required_links x where x.course_id=e.course_id and x.quiz_id is not null
    and not public.assessment_link_requirement_met(p_student_id,x.id)) qr,
  (select count(distinct x.assignment_id) from required_links x where x.course_id=e.course_id and x.assignment_id is not null
    and not public.assessment_link_requirement_met(p_student_id,x.id)) ar from enrolled e)
 select c.course_id,c.lr,c.qr,c.ar,c.total>0 and c.lr=0 and c.qr=0 and c.ar=0 from counts c;
$$;

-- A waived lesson is available to revise, but has no invented completion date.
create or replace function public.lesson_access_state(p_course uuid,p_lesson uuid)
returns text language plpgsql stable security definer set search_path='' as $$
declare enrollment uuid;
begin
 if exists(select 1 from public.courses c join public.course_modules m on m.course_id=c.id
   join public.lessons l on l.module_id=m.id where c.id=p_course and l.id=p_lesson and c.instructor_id=auth.uid()) then return 'preview';end if;
 if not exists(select 1 from public.released_course_lessons(p_course) where lesson_id=p_lesson) then return 'unavailable';end if;
 if not public.has_course_entitlement(p_course) then return 'enrollment_required';end if;
 select id into enrollment from public.enrollments where student_id=auth.uid() and course_id=p_course and status in ('active','completed');
 if exists(select 1 from public.lesson_progress where enrollment_id=enrollment and lesson_id=p_lesson and completed_at is not null)
   or exists(select 1 from public.course_completions where enrollment_id=enrollment) then return 'completed';end if;
 if exists(select 1 from public.learning_access_grandfathering where enrollment_id=enrollment and lesson_id=p_lesson) then return 'available';end if;
 if not public.lesson_prerequisites_met(auth.uid(),p_course,p_lesson) then return 'prerequisite_required';end if;
 if public.lesson_gate_satisfied(auth.uid(),p_course,p_lesson) then return 'completed';end if;
 return 'available';
end;
$$;
