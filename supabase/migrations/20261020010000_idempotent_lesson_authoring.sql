-- Stable draft IDs make a lost create response safe to retry. Parent locking also
-- prevents concurrent authors from choosing the same display_order.
create function public.create_curriculum_lesson(
  p_id uuid,p_module_id uuid,p_title text,p_duration_seconds integer,
  p_external_video_url text default null,p_notes text default ''
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_course uuid; v_owner uuid; v_status text; v_lesson public.lessons; v_order integer;
begin
  select c.id,c.instructor_id,c.status into v_course,v_owner,v_status
    from public.course_modules m join public.courses c on c.id=m.course_id
    where m.id=p_module_id for update of c;
  if v_owner is distinct from auth.uid() or auth.uid() is null then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  select * into v_lesson from public.lessons where id=p_id;
  if found then
    if v_lesson.module_id<>p_module_id then raise exception 'Lesson ID is unavailable'; end if;
    return to_jsonb(v_lesson);
  end if;
  if v_status<>'draft' then raise exception 'Move the course to drafts before adding lessons'; end if;
  if p_id is null or length(trim(p_title))=0 or p_duration_seconds not between 60 and 36000
    or (nullif(trim(p_external_video_url),'') is not null and
      p_external_video_url !~ '^https://[^/[:space:]]+/.+') then
    raise exception 'Complete the lesson details';
  end if;
  select coalesce(max(display_order),-1)+1 into v_order from public.lessons where module_id=p_module_id;
  insert into public.lessons(id,module_id,title,duration_seconds,external_video_url,notes,display_order,status)
  values(p_id,p_module_id,trim(p_title),p_duration_seconds,nullif(trim(p_external_video_url),''),coalesce(p_notes,''),v_order,
    case when nullif(trim(p_external_video_url),'') is null then 'draft' else 'published' end)
  returning * into v_lesson;
  return to_jsonb(v_lesson);
end;
$$;
revoke all on function public.create_curriculum_lesson(uuid,uuid,text,integer,text,text) from public,anon;
grant execute on function public.create_curriculum_lesson(uuid,uuid,text,integer,text,text) to authenticated;
