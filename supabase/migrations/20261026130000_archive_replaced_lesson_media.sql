-- Keep only the currently released media ready after a video change. Archived
-- rows retain transcript and checkpoint history until private file cleanup.
create function public.archive_replaced_lesson_media()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.video_path is distinct from old.video_path then
    update public.lesson_media set status='archived'
    where lesson_id=new.id and status='ready'
      and object_path is distinct from new.video_path;
  end if;
  return new;
end;
$$;
create trigger lesson_video_replaced after update of video_path on public.lessons
for each row execute function public.archive_replaced_lesson_media();
