create table public.ai_quiz_generation_requests (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  topic text not null,
  difficulty text not null check (difficulty in ('Easy', 'Medium', 'Hard')),
  question_count integer not null check (question_count between 1 and 10),
  duration_minutes integer not null check (duration_minutes in (5, 10, 15, 20, 30)),
  model text not null,
  status text not null default 'reserved' check (status in ('reserved', 'completed')),
  quiz_id uuid references public.quizzes (id),
  created_at timestamptz not null default now()
);
create index ai_quiz_requests_teacher_day_idx
  on public.ai_quiz_generation_requests (teacher_id, created_at desc);
alter table public.ai_quiz_generation_requests enable row level security;
revoke all on public.ai_quiz_generation_requests from anon, authenticated;
grant select on public.ai_quiz_generation_requests to authenticated;
create policy ai_quiz_requests_owner_read on public.ai_quiz_generation_requests
for select to authenticated using (teacher_id = (select auth.uid()));

create function public.reserve_ai_quiz_generation(
  p_topic text, p_difficulty text, p_question_count integer,
  p_duration_minutes integer, p_model text
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
begin
  if v_user is null or not exists (
    select 1 from public.profiles p where p.id = v_user and p.role = 'teacher'
  ) then raise exception 'Teacher account required'; end if;
  if length(trim(coalesce(p_topic, ''))) < 3 or length(p_topic) > 200 or
     p_difficulty not in ('Easy', 'Medium', 'Hard') or
     p_question_count not between 1 and 10 or
     p_duration_minutes not in (5, 10, 15, 20, 30) or
     length(trim(coalesce(p_model, ''))) = 0 then
    raise exception 'Invalid generation request';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 0));
  if (select count(*) from public.ai_quiz_generation_requests r
      where r.teacher_id = v_user and
        r.created_at >= date_trunc('day', now() at time zone 'UTC') at time zone 'UTC') >= 5 then
    raise exception 'Daily AI quiz limit reached';
  end if;
  insert into public.ai_quiz_generation_requests
    (teacher_id, topic, difficulty, question_count, duration_minutes, model)
  values (v_user, trim(p_topic), p_difficulty, p_question_count, p_duration_minutes, p_model)
  returning id into v_id;
  return v_id;
end;
$$;

create function public.create_ai_quiz_draft(
  p_request_id uuid, p_questions jsonb
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_request public.ai_quiz_generation_requests%rowtype;
  v_quiz_id uuid;
  v_question_id uuid;
  v_question jsonb;
  v_options text[];
  v_index integer := 0;
  v_correct integer;
begin
  select * into v_request from public.ai_quiz_generation_requests
  where id = p_request_id and teacher_id = v_user for update;
  if not found or v_request.status <> 'reserved' or
     jsonb_typeof(p_questions) is distinct from 'array' or
     jsonb_array_length(p_questions) <> v_request.question_count then
    raise exception 'Generation request unavailable or question count invalid';
  end if;
  insert into public.quizzes
    (teacher_id, title, category, difficulty, duration_minutes, is_ai_generated)
  values (v_user, v_request.topic, 'AI Generated', v_request.difficulty,
    v_request.duration_minutes, true)
  returning id into v_quiz_id;
  for v_question in select value from jsonb_array_elements(p_questions) loop
    if jsonb_typeof(v_question -> 'options') is distinct from 'array' or
       jsonb_array_length(v_question -> 'options') <> 4 or
       length(trim(coalesce(v_question ->> 'question', ''))) = 0 then
      raise exception 'Generated question is invalid';
    end if;
    select array_agg(value order by ordinality) into v_options
    from jsonb_array_elements_text(v_question -> 'options') with ordinality;
    if exists (select 1 from unnest(v_options) option where length(trim(option)) = 0) then
      raise exception 'Generated option is empty';
    end if;
    v_correct := (v_question ->> 'correct_index')::integer;
    if v_correct not between 0 and 3 then raise exception 'Generated answer is invalid'; end if;
    insert into public.quiz_questions (quiz_id, display_order, question_text, options)
    values (v_quiz_id, v_index, trim(v_question ->> 'question'), v_options)
    returning id into v_question_id;
    insert into public.quiz_answer_keys (question_id, correct_option_index, explanation)
    values (v_question_id, v_correct, coalesce(v_question ->> 'explanation', ''));
    v_index := v_index + 1;
  end loop;
  update public.ai_quiz_generation_requests
  set status = 'completed', quiz_id = v_quiz_id where id = p_request_id;
  return v_quiz_id;
end;
$$;

revoke all on function public.reserve_ai_quiz_generation(text, text, integer, integer, text)
  from public, anon, authenticated;
revoke all on function public.create_ai_quiz_draft(uuid, jsonb)
  from public, anon, authenticated;
grant execute on function public.reserve_ai_quiz_generation(text, text, integer, integer, text)
  to authenticated;
grant execute on function public.create_ai_quiz_draft(uuid, jsonb) to authenticated;
