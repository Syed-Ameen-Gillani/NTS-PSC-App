-- Product rule: a released handout is complete once its PDF opens successfully.
-- The client only reports the open; this function revalidates every protected
-- identity and writes the active content version server-side.
create function public.confirm_learning_material_opened(
  p_lesson_id uuid,
  p_activity_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_course uuid;
  v_enrollment uuid;
  v_item jsonb;
  v_spec jsonb;
  v_lesson_completed boolean;
begin
  if auth.uid() is null or not exists(
    select 1 from public.profiles
    where id=auth.uid() and role='student'
  ) then
    raise exception 'Student access required' using errcode='42501';
  end if;

  select m.course_id into v_course
  from public.lessons l
  join public.course_modules m on m.id=l.module_id
  where l.id=p_lesson_id;

  if v_course is null
    or not public.has_course_entitlement(v_course)
    or not public.can_open_lesson(v_course,p_lesson_id) then
    raise exception 'Lesson access required' using errcode='42501';
  end if;

  select a.value into v_item
  from public.released_course_lessons(v_course) l
  cross join lateral jsonb_array_elements(l.activities) a(value)
  where l.lesson_id=p_lesson_id
    and (a.value->>'id')::uuid=p_activity_id;

  if v_item is null or v_item->>'kind'<>'material' then
    raise exception 'Released handout required' using errcode='22023';
  end if;

  select id into v_enrollment
  from public.enrollments
  where course_id=v_course and student_id=auth.uid()
    and status in ('active','completed')
  for update;
  if v_enrollment is null then
    raise exception 'Active enrollment required' using errcode='42501';
  end if;

  v_spec:=public.learning_activity_descriptor(p_lesson_id,p_activity_id);
  insert into public.learning_activity_progress(
    enrollment_id,
    activity_id,
    content_version,
    coverage,
    engaged_ms,
    completed_at
  ) values(
    v_enrollment,
    p_activity_id,
    v_spec->>'version',
    int8multirange(int8range(0,(v_spec->>'units')::bigint,'[)')),
    (v_spec->>'min_ms')::bigint,
    now()
  )
  on conflict(enrollment_id,activity_id,content_version) do update set
    coverage=excluded.coverage,
    engaged_ms=greatest(
      public.learning_activity_progress.engaged_ms,
      excluded.engaged_ms
    ),
    completed_at=coalesce(
      public.learning_activity_progress.completed_at,
      excluded.completed_at
    );

  perform public.reconcile_course_completion(auth.uid());
  select exists(
    select 1 from public.lesson_progress
    where enrollment_id=v_enrollment and lesson_id=p_lesson_id
      and completed_at is not null
  ) into v_lesson_completed;

  return jsonb_build_object(
    'activity_completed',true,
    'lesson_id',p_lesson_id,
    'lesson_completed',v_lesson_completed
  );
end;
$$;

revoke all on function public.confirm_learning_material_opened(uuid,uuid)
  from public,anon;
grant execute on function public.confirm_learning_material_opened(uuid,uuid)
  to authenticated;
