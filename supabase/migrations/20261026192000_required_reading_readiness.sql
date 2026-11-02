alter function public.get_teacher_lesson_activities(uuid) rename to get_teacher_lesson_activities_before_readiness;
revoke all on function public.get_teacher_lesson_activities_before_readiness(uuid) from public,anon,authenticated;
create function public.get_teacher_lesson_activities(p_lesson_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare items jsonb;item jsonb;result jsonb:='[]';material public.curriculum_materials;
begin
 items:=public.get_teacher_lesson_activities_before_readiness(p_lesson_id);
 for item in select value from jsonb_array_elements(items) loop
   if item->>'kind'='material' then
     select * into material from public.curriculum_materials where id=(item->>'material_id')::uuid;
     item:=item||jsonb_build_object('can_prepare',material.mime_type in ('application/pdf','text/plain'),
       'reading_ready',material.reading_hash is not null);
     if material.reading_hash is null and material.mime_type in ('application/pdf','text/plain') then
       item:=item||jsonb_build_object('warning','Check this reading before making it required in a published course.'); end if;
   end if;
   result:=result||jsonb_build_array(item);
 end loop;
 return result;
end;
$$;
create trigger learning_video_activity_refresh after insert or update on public.learning_video_metadata
for each row execute function public.refresh_lesson_activity_placements();
revoke all on function public.get_teacher_lesson_activities(uuid) from public,anon;
grant execute on function public.get_teacher_lesson_activities(uuid) to authenticated;

create function public.require_prepared_course_readings()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.active_release_id is distinct from old.active_release_id and exists(
   select 1 from public.course_releases r cross join lateral jsonb_array_elements(r.manifest->'modules') m
   cross join lateral jsonb_array_elements(m->'lessons') l
   cross join lateral jsonb_array_elements(l->'activities') a
   join public.curriculum_materials f on f.id=(a->>'material_id')::uuid
   where r.id=new.active_release_id and a->>'kind'='material' and (a->>'required')::boolean and f.reading_hash is null
 ) then raise exception 'Check required readings in Lesson Studio before publishing' using errcode='22023'; end if;
 return new;
end;
$$;
create trigger prepared_course_readings before update of active_release_id on public.courses
for each row execute function public.require_prepared_course_readings();
revoke all on function public.require_prepared_course_readings() from public,anon,authenticated;

create or replace function public.confirm_learning_video(p_source text,p_duration_ms bigint,p_lesson_id uuid default null)
returns void language plpgsql security definer set search_path='' as $$
declare v_lesson uuid:=p_lesson_id;
begin
 if v_lesson is null then select lesson_id into v_lesson from public.lesson_media
   where object_path=p_source and teacher_id=auth.uid(); end if;
 if not public.can_access_lesson_media(v_lesson,true) or not exists(select 1 from public.lessons l where l.id=v_lesson
   and (l.external_video_url=p_source or exists(select 1 from public.lesson_media m where m.lesson_id=l.id and m.object_path=p_source)
     or exists(select 1 from public.curriculum_draft_changes d where d.lesson_id=l.id and d.changes->>'external_video_url'=p_source))) then
   raise exception 'Teacher video access required' using errcode='42501'; end if;
 insert into public.learning_video_metadata values(v_lesson,p_source,p_duration_ms)
   on conflict(lesson_id,source) do update set duration_ms=excluded.duration_ms;
end;
$$;
