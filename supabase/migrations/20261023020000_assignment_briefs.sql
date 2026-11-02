-- Teacher-provided assignment briefs are separate from student submissions.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'assignment-briefs', 'assignment-briefs', false, 26214400,
  array[
    'application/pdf', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain'
  ]
)
on conflict (id) do update set public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table public.assignment_brief_attachments (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  uploader_id uuid not null references public.profiles (id),
  object_path text not null unique,
  original_name text not null check (length(trim(original_name)) between 1 and 255),
  mime_type text not null,
  size_bytes bigint not null check (size_bytes between 1 and 26214400),
  status text not null default 'uploading' check (status in ('uploading', 'ready')),
  created_at timestamptz not null default now()
);
create index assignment_briefs_assignment_idx
  on public.assignment_brief_attachments (assignment_id, created_at);
alter table public.assignment_brief_attachments enable row level security;
revoke all on public.assignment_brief_attachments from anon, authenticated;
grant select, delete on public.assignment_brief_attachments to authenticated;

create policy assignment_briefs_read on public.assignment_brief_attachments
for select to authenticated using (exists (
  select 1 from public.assignments a
  join public.courses c on c.id = a.course_id
  where a.id = assignment_brief_attachments.assignment_id
    and (c.instructor_id = (select auth.uid()) or (
      assignment_brief_attachments.status = 'ready'
      and a.status = 'published' and c.status = 'published'
      and exists (select 1 from public.enrollments e
        where e.course_id = c.id and e.student_id = (select auth.uid())
          and e.status = 'active')
    ))
));
create policy assignment_briefs_delete on public.assignment_brief_attachments
for delete to authenticated using (exists (
  select 1 from public.assignments a
  join public.courses c on c.id = a.course_id
  where a.id = assignment_brief_attachments.assignment_id
    and a.status = 'draft' and c.instructor_id = (select auth.uid())
));

create policy assignment_brief_objects_insert on storage.objects
for insert to authenticated with check (
  bucket_id = 'assignment-briefs'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = 'briefs'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and exists (select 1 from public.assignment_brief_attachments b
    join public.assignments a on a.id = b.assignment_id
    join public.courses c on c.id = a.course_id
    where b.object_path = name and b.status = 'uploading'
      and a.status = 'draft' and c.instructor_id = (select auth.uid()))
);
create policy assignment_brief_objects_read on storage.objects
for select to authenticated using (
  bucket_id = 'assignment-briefs'
  and exists (select 1 from public.assignment_brief_attachments b
    join public.assignments a on a.id = b.assignment_id
    join public.courses c on c.id = a.course_id
    where b.object_path = name and (c.instructor_id = (select auth.uid()) or (
      b.status = 'ready' and a.status = 'published' and c.status = 'published'
      and exists (select 1 from public.enrollments e
        where e.course_id = c.id and e.student_id = (select auth.uid())
          and e.status = 'active')))
  )
);
create policy assignment_brief_objects_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'assignment-briefs'
  and exists (select 1 from public.assignment_brief_attachments b
    join public.assignments a on a.id = b.assignment_id
    join public.courses c on c.id = a.course_id
    where b.object_path = name and a.status = 'draft'
      and c.instructor_id = (select auth.uid()))
);

create function public.begin_assignment_brief(
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
      where assignment_id = p_assignment_id) >= 5 then
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

create function public.finish_assignment_brief(p_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_row public.assignment_brief_attachments%rowtype;
begin
  select * into v_row from public.assignment_brief_attachments
    where id = p_id for update;
  if not found or not exists (
    select 1 from public.assignments a join public.courses c on c.id = a.course_id
    where a.id = v_row.assignment_id and a.status = 'draft'
      and c.instructor_id = auth.uid()
  ) then
    raise exception 'Draft assignment required' using errcode = '42501';
  end if;
  if not exists (select 1 from storage.objects o
    where o.bucket_id = 'assignment-briefs' and o.name = v_row.object_path
      and (o.metadata->>'size')::bigint = v_row.size_bytes) then
    raise exception 'Assignment file upload is incomplete';
  end if;
  update public.assignment_brief_attachments set status = 'ready' where id = p_id;
end;
$$;
revoke all on function public.begin_assignment_brief(uuid,text,text,bigint),
  public.finish_assignment_brief(uuid) from public, anon;
grant execute on function public.begin_assignment_brief(uuid,text,text,bigint),
  public.finish_assignment_brief(uuid) to authenticated;
