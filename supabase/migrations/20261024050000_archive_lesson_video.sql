-- Detach a video without deleting checkpoint answers or transcript history.
alter table public.lesson_media drop constraint if exists lesson_media_status_check;
alter table public.lesson_media add constraint lesson_media_status_check
  check (status in ('uploading','transcribing','needs_review','ready','failed','archived'));

create function public.archive_lesson_media(p_media_id uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare
  v_media public.lesson_media;
  v_course uuid;
  v_path text;
begin
  select * into v_media from public.lesson_media where id = p_media_id for update;
  if not found or v_media.teacher_id is distinct from auth.uid() or
      not public.can_access_lesson_media(v_media.lesson_id, true) then
    raise exception 'Video is unavailable' using errcode = '42501';
  end if;
  if v_media.status = 'uploading' then
    raise exception 'Wait for the upload to finish before deleting the video';
  end if;
  if v_media.status = 'archived' then return v_media.object_path; end if;

  select c.id, l.video_path into v_course, v_path
  from public.lessons l
  join public.course_modules m on m.id = l.module_id
  join public.courses c on c.id = m.course_id
  where l.id = v_media.lesson_id for update of c;
  if v_path = v_media.object_path then
    update public.courses set status = 'draft'
      where id = v_course and status = 'published';
    update public.lessons set video_path = null, status = 'draft'
      where id = v_media.lesson_id;
  end if;
  update public.lesson_media set status = 'archived' where id = p_media_id;
  return v_media.object_path;
end;
$$;
revoke all on function public.archive_lesson_media(uuid) from public, anon;
grant execute on function public.archive_lesson_media(uuid) to authenticated;

-- The archived row stays for answer history; only its private file is removed.
create policy lesson_video_teacher_archive_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'lesson-videos' and exists (
    select 1 from public.lesson_media lm
    where lm.object_path = name and lm.teacher_id = auth.uid()
      and lm.status = 'archived'
  )
);
