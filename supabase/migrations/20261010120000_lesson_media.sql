-- Short lecture pilot. Increase both this bucket limit and the client policy together.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('lesson-videos', 'lesson-videos', false, 26214400,
        array['video/mp4', 'video/webm', 'video/quicktime'])
on conflict (id) do update set public = false, file_size_limit = 26214400,
  allowed_mime_types = excluded.allowed_mime_types;

create table public.lesson_media (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  teacher_id uuid not null references public.profiles(id),
  object_path text not null unique,
  byte_size bigint not null check (byte_size > 0 and byte_size <= 26214400),
  mime_type text not null check (mime_type in ('video/mp4', 'video/webm', 'video/quicktime')),
  duration_seconds numeric check (duration_seconds > 0),
  status text not null default 'uploading' check (status in
    ('uploading', 'transcribing', 'needs_review', 'ready', 'failed')),
  transcript_language text,
  transcript_segments jsonb not null default '[]'::jsonb,
  processing_error text,
  provider_request_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, lesson_id),
  check (object_path = teacher_id::text || '/' || lesson_id::text || '/' || id::text ||
    case mime_type when 'video/mp4' then '.mp4'
      when 'video/webm' then '.webm' else '.mov' end),
  check (jsonb_typeof(transcript_segments) = 'array')
);
revoke insert (video_path), update (video_path) on public.lessons from authenticated;
create index lesson_media_lesson_idx on public.lesson_media(lesson_id, created_at desc);
create trigger lesson_media_updated_at before update on public.lesson_media
for each row execute function public.set_updated_at();

create table public.lesson_checkpoints (
  id uuid primary key default gen_random_uuid(),
  media_id uuid not null references public.lesson_media(id) on delete cascade,
  timestamp_seconds integer not null check (timestamp_seconds >= 0),
  question text not null check (length(trim(question)) > 0),
  options jsonb not null check (jsonb_typeof(options) = 'array' and jsonb_array_length(options) = 4),
  explanation text not null default '',
  source_start_seconds integer not null check (source_start_seconds >= 0),
  source_end_seconds integer not null check (source_end_seconds > source_start_seconds),
  status text not null default 'draft' check (status in ('draft', 'approved')),
  created_at timestamptz not null default now(),
  unique (media_id, timestamp_seconds),
  check (timestamp_seconds >= source_end_seconds)
);
create table public.lesson_checkpoint_keys (
  checkpoint_id uuid primary key references public.lesson_checkpoints(id) on delete cascade,
  correct_index integer not null check (correct_index between 0 and 3)
);
create table public.lesson_checkpoint_attempts (
  checkpoint_id uuid not null references public.lesson_checkpoints(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  answer_index integer not null check (answer_index between 0 and 3),
  is_correct boolean not null,
  answered_at timestamptz not null default now(),
  primary key (checkpoint_id, student_id)
);

alter table public.lesson_media enable row level security;
alter table public.lesson_checkpoints enable row level security;
alter table public.lesson_checkpoint_keys enable row level security;
alter table public.lesson_checkpoint_attempts enable row level security;
revoke all on public.lesson_media, public.lesson_checkpoints,
  public.lesson_checkpoint_keys, public.lesson_checkpoint_attempts from anon, authenticated;
grant select on public.lesson_media, public.lesson_checkpoints,
  public.lesson_checkpoint_attempts to authenticated;

create function public.can_access_lesson_media(p_lesson_id uuid, p_teacher_only boolean default false)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    where l.id = p_lesson_id and (
      c.instructor_id = (select auth.uid()) or
      (not p_teacher_only and c.status = 'published' and l.status = 'published'
        and exists (select 1 from public.enrollments e where e.course_id = c.id
          and e.student_id = (select auth.uid()) and e.status = 'active'))
    )
  );
$$;
revoke all on function public.can_access_lesson_media(uuid, boolean) from public, anon;
grant execute on function public.can_access_lesson_media(uuid, boolean) to authenticated;

create policy lesson_media_teacher_read on public.lesson_media for select to authenticated
using (public.can_access_lesson_media(lesson_id, true));
create policy lesson_media_student_read on public.lesson_media for select to authenticated
using (status = 'ready' and object_path in (select video_path from public.lessons
  where id = lesson_id) and public.can_access_lesson_media(lesson_id));
create policy lesson_media_teacher_transcript on public.lesson_media for update to authenticated
using (status = 'needs_review' and public.can_access_lesson_media(lesson_id, true))
with check (status = 'needs_review' and public.can_access_lesson_media(lesson_id, true));
create policy lesson_checkpoints_read on public.lesson_checkpoints for select to authenticated
using (exists (select 1 from public.lesson_media lm where lm.id = media_id and
  (public.can_access_lesson_media(lm.lesson_id, true) or
   (lm.status = 'ready' and public.lesson_checkpoints.status = 'approved' and
    public.can_access_lesson_media(lm.lesson_id)))));
create policy lesson_checkpoints_teacher_update on public.lesson_checkpoints for update to authenticated
using (exists (select 1 from public.lesson_media lm where lm.id = media_id and
  lm.status = 'needs_review' and public.can_access_lesson_media(lm.lesson_id, true)))
with check (exists (select 1 from public.lesson_media lm where lm.id = media_id and
  lm.status = 'needs_review' and public.can_access_lesson_media(lm.lesson_id, true)));
create policy lesson_attempts_self_read on public.lesson_checkpoint_attempts for select to authenticated
using (student_id = (select auth.uid()));

create policy lesson_video_teacher_upload on storage.objects for insert to authenticated
with check (bucket_id = 'lesson-videos' and exists (
  select 1 from public.lesson_media lm where lm.object_path = name and
    lm.teacher_id = (select auth.uid()) and lm.status = 'uploading' and
    public.can_access_lesson_media(lm.lesson_id, true)));
create policy lesson_video_authorized_read on storage.objects for select to authenticated
using (bucket_id = 'lesson-videos' and exists (
  select 1 from public.lesson_media lm where lm.object_path = name and
    (public.can_access_lesson_media(lm.lesson_id, true) or
     (lm.status = 'ready' and exists (select 1 from public.lessons l
       where l.id = lm.lesson_id and l.video_path = lm.object_path) and
      public.can_access_lesson_media(lm.lesson_id)))));

create function public.begin_lesson_media(p_lesson_id uuid, p_byte_size bigint, p_mime_type text)
returns table(media_id uuid, object_path text) language plpgsql security definer
set search_path = '' as $$
declare v_id uuid := gen_random_uuid(); v_extension text;
begin
  if not public.can_access_lesson_media(p_lesson_id, true) then
    raise exception 'Teacher ownership required';
  end if;
  if p_byte_size < 1 or p_byte_size > 26214400 then
    raise exception 'Video exceeds 25 MB limit';
  end if;
  v_extension := case p_mime_type when 'video/mp4' then '.mp4'
    when 'video/webm' then '.webm' when 'video/quicktime' then '.mov' else null end;
  if v_extension is null then raise exception 'Unsupported video type'; end if;
  media_id := v_id;
  object_path := (select auth.uid())::text || '/' || p_lesson_id::text || '/' ||
    v_id::text || v_extension;
  insert into public.lesson_media(id, lesson_id, teacher_id, object_path, byte_size, mime_type)
  values (media_id, p_lesson_id, (select auth.uid()), object_path, p_byte_size, p_mime_type);
  return next;
end;
$$;

create function public.finalize_lesson_media(p_media_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media; v_object storage.objects;
begin
  select * into v_media from public.lesson_media where id = p_media_id for update;
  if not found or v_media.teacher_id <> (select auth.uid()) or v_media.status <> 'uploading' then
    raise exception 'Upload cannot be finalized';
  end if;
  select * into v_object from storage.objects
  where bucket_id = 'lesson-videos' and name = v_media.object_path;
  if not found or (v_object.metadata->>'size')::bigint <> v_media.byte_size or
    v_object.metadata->>'mimetype' <> v_media.mime_type then
    raise exception 'Uploaded video does not match the reservation';
  end if;
  update public.lesson_media set status = 'transcribing' where id = p_media_id;
end;
$$;

create function public.publish_lesson_media(p_media_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media;
begin
  select * into v_media from public.lesson_media where id = p_media_id for update;
  if not found or v_media.teacher_id <> (select auth.uid()) or
    v_media.status <> 'needs_review' or jsonb_array_length(v_media.transcript_segments) = 0 then
    raise exception 'Reviewed transcript required';
  end if;
  update public.lesson_media set status = 'ready' where id = p_media_id;
  update public.lessons set video_path = v_media.object_path, external_video_url = null
  where id = v_media.lesson_id;
end;
$$;

create function public.save_lesson_transcript(p_media_id uuid, p_segments jsonb,
  p_language text default 'ur')
returns void language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media; v_segment jsonb; v_previous numeric := 0;
begin
  select * into v_media from public.lesson_media where id = p_media_id for update;
  if not found or v_media.teacher_id <> (select auth.uid()) or
    v_media.status not in ('transcribing', 'needs_review', 'failed') then
    raise exception 'Transcript cannot be edited';
  end if;
  if jsonb_typeof(p_segments) <> 'array' or jsonb_array_length(p_segments) < 1 or
    jsonb_array_length(p_segments) > 10000 or p_language not in ('ur', 'en', 'mixed') then
    raise exception 'Invalid transcript';
  end if;
  for v_segment in select value from jsonb_array_elements(p_segments) loop
    if jsonb_typeof(v_segment->'start') <> 'number' or
      jsonb_typeof(v_segment->'end') <> 'number' or
      jsonb_typeof(v_segment->'text') <> 'string' or
      (v_segment->>'start')::numeric < v_previous or
      (v_segment->>'end')::numeric <= (v_segment->>'start')::numeric or
      length(trim(v_segment->>'text')) < 1 or length(v_segment->>'text') > 2000 then
      raise exception 'Invalid transcript segment';
    end if;
    v_previous := (v_segment->>'end')::numeric;
  end loop;
  update public.lesson_media set transcript_segments = p_segments,
    transcript_language = p_language, status = 'needs_review', processing_error = null
  where id = p_media_id;
end;
$$;

create function public.review_lesson_checkpoint(p_checkpoint_id uuid, p_question text,
  p_options jsonb, p_correct_index integer, p_explanation text,
  p_approved boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media;
begin
  select lm.* into v_media from public.lesson_media lm
  join public.lesson_checkpoints lc on lc.media_id = lm.id
  where lc.id = p_checkpoint_id for update of lm;
  if not found or v_media.teacher_id <> (select auth.uid()) or
    v_media.status <> 'needs_review' or length(trim(p_question)) < 3 or
    jsonb_typeof(p_options) <> 'array' or jsonb_array_length(p_options) <> 4 or
    p_correct_index not between 0 and 3 then
    raise exception 'Invalid checkpoint review';
  end if;
  update public.lesson_checkpoints set question = trim(p_question), options = p_options,
    explanation = p_explanation, status = case when p_approved then 'approved' else 'draft' end
  where id = p_checkpoint_id;
  update public.lesson_checkpoint_keys set correct_index = p_correct_index
  where checkpoint_id = p_checkpoint_id;
end;
$$;

create function public.get_teacher_lesson_checkpoints(p_media_id uuid)
returns table(id uuid, timestamp_seconds integer, question text, options jsonb,
  explanation text, source_start_seconds integer, source_end_seconds integer,
  status text, correct_index integer)
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.lesson_media lm where lm.id = p_media_id
    and lm.teacher_id = (select auth.uid())) then
    raise exception 'Teacher ownership required';
  end if;
  return query select c.id, c.timestamp_seconds, c.question, c.options,
    c.explanation, c.source_start_seconds, c.source_end_seconds, c.status,
    k.correct_index from public.lesson_checkpoints c
    join public.lesson_checkpoint_keys k on k.checkpoint_id = c.id
    where c.media_id = p_media_id order by c.timestamp_seconds;
end;
$$;
revoke all on function public.begin_lesson_media(uuid, bigint, text),
  public.finalize_lesson_media(uuid), public.publish_lesson_media(uuid),
  public.save_lesson_transcript(uuid, jsonb, text),
  public.review_lesson_checkpoint(uuid, text, jsonb, integer, text, boolean),
  public.get_teacher_lesson_checkpoints(uuid)
  from public, anon;
grant execute on function public.begin_lesson_media(uuid, bigint, text),
  public.finalize_lesson_media(uuid), public.publish_lesson_media(uuid),
  public.save_lesson_transcript(uuid, jsonb, text),
  public.review_lesson_checkpoint(uuid, text, jsonb, integer, text, boolean),
  public.get_teacher_lesson_checkpoints(uuid)
  to authenticated;

create function public.answer_lesson_checkpoint(p_checkpoint_id uuid, p_answer_index integer)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_question public.lesson_checkpoints; v_media public.lesson_media;
  v_correct integer; v_attempt public.lesson_checkpoint_attempts;
begin
  select * into v_question from public.lesson_checkpoints where id = p_checkpoint_id;
  select * into v_media from public.lesson_media where id = v_question.media_id;
  if v_question.status <> 'approved' or v_media.status <> 'ready' or
    not public.can_access_lesson_media(v_media.lesson_id) or
    not exists(select 1 from public.lessons where id = v_media.lesson_id
      and video_path = v_media.object_path) or p_answer_index not between 0 and 3 then
    raise exception 'Checkpoint unavailable';
  end if;
  select correct_index into v_correct from public.lesson_checkpoint_keys
  where checkpoint_id = p_checkpoint_id;
  insert into public.lesson_checkpoint_attempts(checkpoint_id, student_id, answer_index, is_correct)
  values (p_checkpoint_id, (select auth.uid()), p_answer_index, p_answer_index = v_correct)
  on conflict (checkpoint_id, student_id) do nothing;
  select * into v_attempt from public.lesson_checkpoint_attempts
  where checkpoint_id = p_checkpoint_id and student_id = (select auth.uid());
  return jsonb_build_object('isCorrect', v_attempt.is_correct,
    'correctIndex', v_correct, 'answerIndex', v_attempt.answer_index);
end;
$$;
revoke all on function public.answer_lesson_checkpoint(uuid, integer) from public, anon;
grant execute on function public.answer_lesson_checkpoint(uuid, integer) to authenticated;
