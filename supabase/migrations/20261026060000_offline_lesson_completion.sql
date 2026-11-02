create function public.record_offline_lesson_completion(p_lesson_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare course uuid;
begin
  select m.course_id into course from public.lessons l join public.course_modules m on m.id=l.module_id
    where l.id=p_lesson_id;
  if course is null then raise exception 'Lesson unavailable' using errcode='42501'; end if;
  perform public.record_lesson_completion(course,p_lesson_id,true);
end;
$$;
revoke all on function public.record_offline_lesson_completion(uuid) from public,anon;
grant execute on function public.record_offline_lesson_completion(uuid) to authenticated;
