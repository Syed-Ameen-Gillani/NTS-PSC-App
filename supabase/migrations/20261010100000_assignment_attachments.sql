-- Private uploads are bound to a submission revision only by the guarded RPC.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'assignment-submissions', 'assignment-submissions', false, 26214400,
  array[
    'application/pdf', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain', 'image/jpeg', 'image/png', 'video/mp4', 'video/quicktime'
  ]
)
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table public.assignment_submission_attachments (
  id uuid primary key default gen_random_uuid(),
  revision_id uuid not null references public.assignment_submission_revisions (id) on delete cascade,
  uploader_id uuid not null references public.profiles (id),
  object_path text not null unique,
  original_name text not null check (length(trim(original_name)) between 1 and 255),
  mime_type text not null,
  size_bytes bigint not null check (size_bytes between 1 and 26214400),
  created_at timestamptz not null default now()
);
create index assignment_attachments_revision_idx on public.assignment_submission_attachments (revision_id);

alter table public.assignment_submission_attachments enable row level security;
revoke all on public.assignment_submission_attachments from anon, authenticated;
grant select on public.assignment_submission_attachments to authenticated;
create policy assignment_attachments_read on public.assignment_submission_attachments
for select to authenticated using (exists (
  select 1 from public.assignment_submission_revisions r
  join public.assignment_submissions s on s.id = r.submission_id
  join public.assignments a on a.id = s.assignment_id
  join public.courses c on c.id = a.course_id
  where r.id = revision_id and
    (s.student_id = (select auth.uid()) or c.instructor_id = (select auth.uid()))
));

create policy assignment_objects_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'assignment-submissions' and
  owner_id = (select auth.uid())::text and
  (storage.foldername(name))[1] = (select auth.uid())::text and
  exists (
    select 1 from public.assignments a
    join public.enrollments e on e.course_id = a.course_id
    where a.id::text = (storage.foldername(name))[2]
      and a.status = 'published' and a.due_at > now()
      and e.student_id = (select auth.uid()) and e.status = 'active'
  )
);
create policy assignment_objects_select on storage.objects for select to authenticated
using (
  bucket_id = 'assignment-submissions' and (
    owner_id = (select auth.uid())::text or exists (
      select 1 from public.assignment_submission_attachments att
      join public.assignment_submission_revisions r on r.id = att.revision_id
      join public.assignment_submissions s on s.id = r.submission_id
      join public.assignments a on a.id = s.assignment_id
      join public.courses c on c.id = a.course_id
      where att.object_path = name and c.instructor_id = (select auth.uid())
    )
  )
);
create policy assignment_objects_delete_orphan on storage.objects for delete to authenticated
using (
  bucket_id = 'assignment-submissions' and owner_id = (select auth.uid())::text
  and not exists (
    select 1 from public.assignment_submission_attachments att where att.object_path = name
  )
);

alter table public.assignment_submission_revisions
  drop constraint assignment_submission_revisions_response_check;

create function public.submit_assignment(
  p_assignment_id uuid, p_response text, p_attachments jsonb
)
returns public.assignment_submissions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_assignment public.assignments%rowtype;
  v_submission public.assignment_submissions%rowtype;
  v_revision_id uuid;
  v_attachment jsonb;
  v_path text;
  v_object storage.objects%rowtype;
  v_count integer;
  v_size bigint;
  v_mime text;
begin
  if v_user is null or p_attachments is null or jsonb_typeof(p_attachments) <> 'array' then
    raise exception 'Sign in and provide an attachment list';
  end if;
  v_count := jsonb_array_length(p_attachments);
  if v_count > 3 or (length(trim(coalesce(p_response, ''))) = 0 and v_count = 0) then
    raise exception 'Provide a response or up to three attachments';
  end if;
  select * into v_assignment from public.assignments where id = p_assignment_id for update;
  if not found or v_assignment.status <> 'published' or v_assignment.due_at <= now() then
    raise exception 'Assignment is unavailable';
  end if;
  if not exists (select 1 from public.profiles p where p.id = v_user and p.role = 'student')
    or not exists (
      select 1 from public.enrollments e where e.course_id = v_assignment.course_id
        and e.student_id = v_user and e.status = 'active'
    ) then
    raise exception 'Active student enrollment required';
  end if;

  select * into v_submission from public.assignment_submissions
    where assignment_id = p_assignment_id and student_id = v_user for update;
  if found then
    if v_submission.status <> 'disapproved' then
      raise exception 'Submission cannot be revised';
    end if;
    update public.assignment_submissions
    set status = 'pending', current_revision = current_revision + 1,
      submitted_at = now(), reviewed_at = null, reviewer_id = null, feedback = ''
    where id = v_submission.id returning * into v_submission;
  else
    insert into public.assignment_submissions (assignment_id, student_id)
    values (p_assignment_id, v_user) returning * into v_submission;
  end if;
  insert into public.assignment_submission_revisions
    (submission_id, revision_number, response)
  values (v_submission.id, v_submission.current_revision, trim(coalesce(p_response, '')))
  returning id into v_revision_id;

  for v_attachment in select value from jsonb_array_elements(p_attachments) loop
    v_path := v_attachment->>'path';
    if v_path is null or v_path !~ ('^' || v_user::text || '/' || p_assignment_id::text || '/[a-f0-9-]{36}[.][a-z0-9]+$')
      or length(trim(coalesce(v_attachment->>'name', ''))) not between 1 and 255 then
      raise exception 'Invalid attachment metadata';
    end if;
    select * into v_object from storage.objects
    where bucket_id = 'assignment-submissions' and name = v_path
      and owner_id = v_user::text for update;
    if not found or exists (
      select 1 from public.assignment_submission_attachments where object_path = v_path
    ) then
      raise exception 'Attachment is unavailable';
    end if;
    v_size := nullif(v_object.metadata->>'size', '')::bigint;
    v_mime := v_object.metadata->>'mimetype';
    if v_size not between 1 and 26214400 or v_mime is null or
      not (v_mime = any (array[
        'application/pdf', 'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain', 'image/jpeg', 'image/png', 'video/mp4', 'video/quicktime'
      ])) then
      raise exception 'Attachment type or size is not allowed';
    end if;
    insert into public.assignment_submission_attachments
      (revision_id, uploader_id, object_path, original_name, mime_type, size_bytes)
    values (v_revision_id, v_user, v_path, v_attachment->>'name', v_mime, v_size);
  end loop;
  return v_submission;
end;
$$;

revoke all on function public.submit_assignment(uuid, text, jsonb) from public, anon, authenticated;
grant execute on function public.submit_assignment(uuid, text, jsonb) to authenticated;
