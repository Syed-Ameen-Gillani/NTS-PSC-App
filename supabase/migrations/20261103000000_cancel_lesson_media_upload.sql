create or replace function public.cancel_lesson_media_upload(p_media_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_media public.lesson_media;
begin
  select * into v_media
  from public.lesson_media
  where id = p_media_id
  for update;

  if not found
    or v_media.teacher_id is distinct from auth.uid()
    or not public.can_access_lesson_media(v_media.lesson_id, true) then
    raise exception 'Video upload is unavailable' using errcode = '42501';
  end if;

  if v_media.status <> 'uploading' then
    return false;
  end if;

  delete from public.lesson_media where id = p_media_id;
  return true;
end;
$$;

revoke all on function public.cancel_lesson_media_upload(uuid)
from public, anon;
grant execute on function public.cancel_lesson_media_upload(uuid)
to authenticated;
