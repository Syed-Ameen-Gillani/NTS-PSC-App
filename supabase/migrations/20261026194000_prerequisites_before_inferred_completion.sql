-- A result reused in a later lesson is valid evidence, but cannot make that
-- lesson revisitable before all intervening required work has been satisfied.
create function public.lesson_prerequisites_met(p_student uuid,p_course uuid,p_lesson uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.released_course_lessons(p_course) target where target.lesson_id=p_lesson)
   and not exists(select 1 from public.released_course_lessons(p_course) previous
     cross join public.released_course_lessons(p_course) target
     where target.lesson_id=p_lesson and previous.sequence_number<target.sequence_number
       and (not public.lesson_gate_satisfied(p_student,p_course,previous.lesson_id)
         or (previous.module_id<>target.module_id and not public.module_assessment_gate_satisfied(p_student,p_course,previous.module_id))));
$$;
revoke all on function public.lesson_prerequisites_met(uuid,uuid,uuid) from public,anon,authenticated;
create or replace function public.lesson_access_state(p_course uuid,p_lesson uuid)
returns text language plpgsql stable security definer set search_path='' as $$
declare enrollment uuid;
begin
 if exists(select 1 from public.courses c join public.course_modules m on m.course_id=c.id
   join public.lessons l on l.module_id=m.id where c.id=p_course and l.id=p_lesson and c.instructor_id=auth.uid()) then return 'preview'; end if;
 if not exists(select 1 from public.released_course_lessons(p_course) where lesson_id=p_lesson) then return 'unavailable'; end if;
 if not public.has_course_entitlement(p_course) then return 'enrollment_required'; end if;
 select id into enrollment from public.enrollments where student_id=auth.uid() and course_id=p_course and status in ('active','completed');
 -- Explicitly earned history/frontier waivers survive later curriculum edits.
 if exists(select 1 from public.lesson_progress where enrollment_id=enrollment and lesson_id=p_lesson and completed_at is not null)
   or exists(select 1 from public.course_completions where enrollment_id=enrollment)
   or exists(select 1 from public.learning_access_grandfathering where enrollment_id=enrollment and lesson_id=p_lesson) then return 'completed'; end if;
 if not public.lesson_prerequisites_met(auth.uid(),p_course,p_lesson) then return 'prerequisite_required'; end if;
 if public.lesson_gate_satisfied(auth.uid(),p_course,p_lesson) then return 'completed'; end if;
 return 'available';
end;
$$;
create or replace function public.reconcile_course_completion(p_student_id uuid)
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
      and public.lesson_prerequisites_met(p_student_id,e.course_id,l.lesson_id)
      -- Access waivers must not manufacture completed lessons.
      and not exists(select 1 from public.learning_access_grandfathering g where g.enrollment_id=e.id and g.lesson_id=l.lesson_id)
      and not exists(select 1 from public.course_completions c where c.enrollment_id=e.id)
    on conflict(enrollment_id,lesson_id) do update set completed_at=excluded.completed_at
      where public.lesson_progress.completed_at is null;
  perform public.reconcile_course_completion_before_evidence(p_student_id);
  perform set_config('app.learning_reconcile',coalesce(v_before,''),true);
end;
$$;

