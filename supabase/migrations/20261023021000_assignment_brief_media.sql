-- Short assignment reference media shares the private brief access rules.
update storage.buckets set allowed_mime_types = array[
  'application/pdf', 'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/plain', 'image/jpeg', 'image/png', 'video/mp4', 'video/quicktime'
] where id = 'assignment-briefs';

create or replace function public.begin_assignment_brief(
  p_assignment_id uuid, p_name text, p_extension text, p_size bigint
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid := gen_random_uuid();
  v_path text;
  v_mime text;
begin
  if auth.uid() is null then
    raise exception 'Teacher access required' using errcode = '42501';
  end if;
  perform 1 from public.assignments a join public.courses c on c.id = a.course_id
    where a.id = p_assignment_id and a.status = 'draft'
      and c.instructor_id = auth.uid() for update of a;
  if not found then
    raise exception 'Draft assignment required' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_name, ''))) not between 1 and 255
    or p_size not between 1 and 26214400
    or (select count(*) from public.assignment_brief_attachments
      where assignment_id = p_assignment_id) >= 10 then
    raise exception 'Invalid assignment file or file limit reached';
  end if;
  v_mime := case lower(p_extension)
    when 'pdf' then 'application/pdf'
    when 'doc' then 'application/msword'
    when 'docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when 'ppt' then 'application/vnd.ms-powerpoint'
    when 'pptx' then 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    when 'xls' then 'application/vnd.ms-excel'
    when 'xlsx' then 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    when 'txt' then 'text/plain'
    when 'jpg' then 'image/jpeg'
    when 'jpeg' then 'image/jpeg'
    when 'png' then 'image/png'
    when 'mp4' then 'video/mp4'
    when 'mov' then 'video/quicktime'
    else null end;
  if v_mime is null then raise exception 'Unsupported assignment file type'; end if;
  v_path := 'briefs/' || auth.uid()::text || '/' || p_assignment_id::text
    || '/' || v_id::text || '.' || lower(p_extension);
  insert into public.assignment_brief_attachments
    (id, assignment_id, uploader_id, object_path, original_name, mime_type, size_bytes)
  values (v_id, p_assignment_id, auth.uid(), v_path, trim(p_name), v_mime, p_size);
  return jsonb_build_object('id', v_id, 'object_path', v_path, 'mime_type', v_mime);
end;
$$;

-- Replacement files may briefly coexist with the originals while a draft saves.
create function public.guard_assignment_briefs_on_publish()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'published' and old.status = 'draft' and exists (
    select 1 from public.assignment_brief_attachments b
    where b.assignment_id = new.id
    group by b.assignment_id
    having count(*) > 5 or count(*) filter (where b.status <> 'ready') > 0
  ) then
    raise exception 'Finish assignment file uploads before publishing';
  end if;
  return new;
end;
$$;
create trigger guard_assignment_briefs_on_publish
before update of status on public.assignments
for each row execute function public.guard_assignment_briefs_on_publish();
