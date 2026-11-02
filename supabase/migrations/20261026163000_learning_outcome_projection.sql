-- Safe, account-scoped projection. Protected notes/files still use existing RLS.
create function public.get_learning_outcome(p_lesson_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_course uuid;v_enrollment uuid;v_item jsonb;v_spec jsonb;v_items jsonb:='[]';v_activities jsonb;
begin
  select m.course_id into v_course from public.lessons l join public.course_modules m on m.id=l.module_id where l.id=p_lesson_id;
  if not public.has_course_entitlement(v_course) or not public.can_open_lesson(v_course,p_lesson_id) then
    raise exception 'Lesson access required' using errcode='42501'; end if;
  select id into v_enrollment from public.enrollments where course_id=v_course and student_id=auth.uid();
  select activities into v_activities from public.released_course_lessons(v_course) where lesson_id=p_lesson_id;
  for v_item in select value from jsonb_array_elements(v_activities) loop
    begin
      if v_item->>'kind' in ('video','reading','material') then
        v_spec:=public.learning_activity_descriptor(p_lesson_id,(v_item->>'id')::uuid);
      else v_spec:='{}'; end if;
      v_items:=v_items||jsonb_build_array(v_item||v_spec||jsonb_build_object('completed',
        public.learning_activity_satisfied(auth.uid(),v_course,p_lesson_id,v_item)));
    exception when sqlstate '22023' then
      v_items:=v_items||jsonb_build_array(v_item||jsonb_build_object('completed',false,'preparation_required',true,'message',sqlerrm));
    end;
  end loop;
  return jsonb_build_object('course_id',v_course,'lesson_id',p_lesson_id,'activities',v_items,
    'completed',exists(select 1 from public.lesson_progress where enrollment_id=v_enrollment
      and lesson_id=p_lesson_id and completed_at is not null));
end;
$$;
revoke all on function public.get_learning_outcome(uuid) from public,anon;
grant execute on function public.get_learning_outcome(uuid) to authenticated;
