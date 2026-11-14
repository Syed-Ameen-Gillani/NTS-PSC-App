-- Enrollment grants access to every released lesson. Completion of a lesson
-- depends on that lesson's required activities, regardless of lesson order.
-- Evaluate evidence directly: lesson_gate_satisfied also accepts historical
-- access waivers, which must never create new completion records by themselves.
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
      and jsonb_typeof(l.activities)='array'
      and jsonb_array_length(l.activities)>0
      and not exists (
        select 1 from jsonb_array_elements(l.activities) as a(item)
        where (a.item->>'required')::boolean
          and not public.learning_activity_satisfied(
            p_student_id,e.course_id,l.lesson_id,a.item)
      )
      and not exists (
        select 1 from public.lesson_progress p
        where p.enrollment_id=e.id and p.lesson_id=l.lesson_id
          and p.completed_at is not null
      )
      and not exists(select 1 from public.course_completions c where c.enrollment_id=e.id)
    on conflict(enrollment_id,lesson_id) do update set completed_at=excluded.completed_at
      where public.lesson_progress.completed_at is null;
  -- Course completion still checks every released lesson and required assessment.
  perform public.reconcile_course_completion_before_evidence(p_student_id);
  perform set_config('app.learning_reconcile',coalesce(v_before,''),true);
end;
$$;
revoke all on function public.reconcile_course_completion(uuid) from public,anon,authenticated;

-- Existing accepted evidence for a later lesson should become visible without
-- requiring the student to replay it. The operation is idempotent.
do $$
declare v_student uuid;
begin
  for v_student in
    select distinct e.student_id from public.enrollments e
    where e.status in ('active','completed')
      and not exists (
        select 1 from public.course_completions c where c.enrollment_id=e.id
      )
    order by e.student_id
  loop
    perform public.reconcile_course_completion(v_student);
  end loop;
end;
$$;
