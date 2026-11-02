create or replace function public.submit_assignment(
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
  if not found or v_assignment.status <> 'published' or (v_assignment.due_at <= now() and not exists(select 1 from public.assignment_submissions where assignment_id=p_assignment_id and student_id=v_user and status='disapproved')) then
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
-- A request key recovers a committed submission after a lost network response.
create table public.assignment_submission_requests (
  id uuid primary key, student_id uuid not null references public.profiles(id) on delete cascade,
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  result jsonb not null
);
alter table public.assignment_submission_requests enable row level security;
revoke all on public.assignment_submission_requests from anon,authenticated;
create function public.submit_assignment_request(
  p_request_id uuid,p_assignment_id uuid,p_response text,p_attachments jsonb
) returns jsonb language plpgsql security definer set search_path='' as $$
declare saved public.assignment_submission_requests; result jsonb;
begin
  if auth.uid() is null or p_request_id is null then raise exception 'Sign in required' using errcode='42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_request_id::text,0));
  select * into saved from public.assignment_submission_requests where id=p_request_id;
  if found then
    if saved.student_id<>auth.uid() or saved.assignment_id<>p_assignment_id then
      raise exception 'Request unavailable' using errcode='42501';
    end if;
    return saved.result;
  end if;
  result:=to_jsonb(public.submit_assignment(p_assignment_id,p_response,p_attachments));
  insert into public.assignment_submission_requests values(p_request_id,auth.uid(),p_assignment_id,result);
  return result;
end;
$$;
revoke all on function public.submit_assignment_request(uuid,uuid,text,jsonb) from public,anon;
grant execute on function public.submit_assignment_request(uuid,uuid,text,jsonb) to authenticated;

alter policy assignment_objects_insert on storage.objects with check (
  bucket_id='assignment-submissions' and owner_id=(select auth.uid())::text
  and (storage.foldername(name))[1]=(select auth.uid())::text
  and exists(select 1 from public.assignments a join public.enrollments e on e.course_id=a.course_id
    where a.id::text=(storage.foldername(name))[2] and a.status='published'
    and e.student_id=(select auth.uid()) and e.status='active'
    and (a.due_at>now() or exists(select 1 from public.assignment_submissions s
      where s.assignment_id=a.id and s.student_id=(select auth.uid()) and s.status='disapproved')))
);
