-- Students may fetch prompts for offline use, never explanations or answer keys.
revoke select on public.lesson_checkpoints from authenticated;
grant select (id, media_id, timestamp_seconds, question, options,
  source_start_seconds, source_end_seconds, status, created_at)
  on public.lesson_checkpoints to authenticated;

create or replace function public.save_lesson_transcript(p_media_id uuid,
  p_segments jsonb, p_language text default 'ur')
returns void language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media; v_segment jsonb; v_previous numeric := 0;
  v_duration numeric;
begin
  select * into v_media from public.lesson_media where id = p_media_id for update;
  if not found or v_media.teacher_id <> (select auth.uid()) or
    v_media.status not in ('transcribing', 'needs_review', 'failed') then
    raise exception 'Transcript cannot be edited';
  end if;
  select coalesce(v_media.duration_seconds, l.duration_seconds)
  into v_duration from public.lessons l where l.id = v_media.lesson_id;
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
      (v_duration > 0 and (v_segment->>'end')::numeric > v_duration + 1) or
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

create or replace function public.review_lesson_checkpoint(p_checkpoint_id uuid,
  p_question text, p_options jsonb, p_correct_index integer,
  p_explanation text, p_approved boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media;
begin
  select lm.* into v_media from public.lesson_media lm
  join public.lesson_checkpoints lc on lc.media_id = lm.id
  where lc.id = p_checkpoint_id for update of lm;
  if not found or v_media.teacher_id <> (select auth.uid()) or
    v_media.status <> 'needs_review' or length(trim(p_question)) < 3 or
    jsonb_typeof(p_options) <> 'array' or jsonb_array_length(p_options) <> 4 or
    p_correct_index not between 0 and 3 or length(trim(p_explanation)) < 1 then
    raise exception 'Invalid checkpoint review';
  end if;
  if exists (select 1 from jsonb_array_elements(p_options) item
    where jsonb_typeof(item) <> 'string' or length(trim(item #>> '{}')) = 0) or
    (select count(distinct lower(trim(item #>> '{}')))
      from jsonb_array_elements(p_options) item) <> 4 then
    raise exception 'Checkpoint options must be distinct and nonempty';
  end if;
  update public.lesson_checkpoints set question = trim(p_question), options = p_options,
    explanation = trim(p_explanation),
    status = case when p_approved then 'approved' else 'draft' end
  where id = p_checkpoint_id;
  update public.lesson_checkpoint_keys set correct_index = p_correct_index
  where checkpoint_id = p_checkpoint_id;
end;
$$;

create or replace function public.answer_lesson_checkpoint(
  p_checkpoint_id uuid, p_answer_index integer)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_question public.lesson_checkpoints; v_media public.lesson_media;
  v_correct integer; v_attempt public.lesson_checkpoint_attempts;
begin
  select * into v_question from public.lesson_checkpoints where id = p_checkpoint_id;
  if v_question.id is null then raise exception 'Checkpoint unavailable'; end if;
  select * into v_media from public.lesson_media where id = v_question.media_id;
  if v_media.id is null or v_question.status <> 'approved' or
    v_media.status <> 'ready' or
    not public.can_access_lesson_media(v_media.lesson_id) or
    not exists(select 1 from public.lessons where id = v_media.lesson_id
      and video_path = v_media.object_path) or p_answer_index not between 0 and 3 then
    raise exception 'Checkpoint unavailable';
  end if;
  select correct_index into v_correct from public.lesson_checkpoint_keys
  where checkpoint_id = p_checkpoint_id;
  insert into public.lesson_checkpoint_attempts(checkpoint_id, student_id,
    answer_index, is_correct)
  values (p_checkpoint_id, (select auth.uid()), p_answer_index,
    p_answer_index = v_correct)
  on conflict (checkpoint_id, student_id) do nothing;
  select * into v_attempt from public.lesson_checkpoint_attempts
  where checkpoint_id = p_checkpoint_id and student_id = (select auth.uid());
  return jsonb_build_object('isCorrect', v_attempt.is_correct,
    'correctIndex', v_correct, 'answerIndex', v_attempt.answer_index,
    'explanation', v_question.explanation);
end;
$$;
