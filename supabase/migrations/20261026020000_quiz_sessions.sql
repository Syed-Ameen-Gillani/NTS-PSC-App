-- One resumable session per learner/quiz; completed attempts remain immutable.
create table public.quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  started_at timestamptz not null default now(),
  expires_at timestamptz not null,
  answers jsonb not null default '{}'::jsonb,
  question_snapshot jsonb not null,
  quiz_title text not null,
  passing_score integer not null,
  attempt_id uuid references public.quiz_attempts(id) on delete cascade
);
create unique index quiz_one_open_session on public.quiz_sessions(quiz_id,student_id)
  where attempt_id is null;
alter table public.quiz_sessions enable row level security;
revoke all on public.quiz_sessions from anon,authenticated;
alter table public.quiz_attempts drop constraint quiz_attempts_quiz_id_student_id_key;
alter table public.quiz_attempts add column review_snapshot jsonb;

create function public.start_quiz_session(p_quiz_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare q public.quizzes; s public.quiz_sessions;
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='student') then
    raise exception 'Student access required' using errcode='42501';
  end if;
  select * into q from public.quizzes where id=p_quiz_id for update;
  if not found or q.status<>'published' or (q.course_id is not null and not exists(
    select 1 from public.enrollments where course_id=q.course_id and student_id=auth.uid()
      and status in ('active','completed'))) then
    raise exception 'Quiz unavailable' using errcode='42501';
  end if;
  if not exists(select 1 from public.quiz_questions where quiz_id=q.id) then
    raise exception 'Quiz has no questions';
  end if;
  select * into s from public.quiz_sessions where quiz_id=q.id and student_id=auth.uid()
    and attempt_id is null for update;
  if not found then
    insert into public.quiz_sessions(quiz_id,student_id,expires_at,quiz_title,passing_score,question_snapshot)
      select q.id,auth.uid(),now()+make_interval(mins=>q.duration_minutes),q.title,q.passing_score,
        jsonb_agg(jsonb_build_object('id',qq.id,'question_text',qq.question_text,'options',qq.options,
          'correct_option_index',k.correct_option_index,'explanation',k.explanation) order by qq.display_order)
      from public.quiz_questions qq join public.quiz_answer_keys k on k.question_id=qq.id
      where qq.quiz_id=q.id returning * into s;
  end if;
  return (to_jsonb(s)-'question_snapshot')||jsonb_build_object('server_now',now(),
    'questions',(select jsonb_agg(value-'correct_option_index'-'explanation')
      from jsonb_array_elements(s.question_snapshot)));
end;
$$;

create function public.save_quiz_session(p_session_id uuid,p_answers jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare s public.quiz_sessions; a record; options_count integer;
begin
  select * into s from public.quiz_sessions where id=p_session_id and student_id=auth.uid() for update;
  if not found then raise exception 'Attempt unavailable' using errcode='42501'; end if;
  if s.attempt_id is not null then return; end if;
  if now()>=s.expires_at then raise exception 'Quiz time has ended'; end if;
  if jsonb_typeof(p_answers) is distinct from 'object' then raise exception 'Invalid answers'; end if;
  for a in select * from jsonb_each(p_answers) loop
    select jsonb_array_length(value->'options') into options_count
      from jsonb_array_elements(s.question_snapshot) where value->>'id'=a.key;
    if options_count is null or jsonb_typeof(a.value)<>'number' or a.value::text !~ '^[0-9]+$'
      or (a.value::text)::numeric>=options_count then raise exception 'Invalid answer'; end if;
  end loop;
  update public.quiz_sessions set answers=p_answers where id=s.id;
end;
$$;

create function public.finish_quiz_session(p_session_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.quiz_sessions; q public.quizzes; question record; review jsonb:='[]';
  attempt uuid; total integer; v_score integer:=0; selected integer;
begin
  select * into s from public.quiz_sessions where id=p_session_id and student_id=auth.uid() for update;
  if not found then raise exception 'Attempt unavailable' using errcode='42501'; end if;
  if s.attempt_id is not null then return public.get_quiz_attempt_review(s.attempt_id); end if;
  select * into q from public.quizzes where id=s.quiz_id for share;
  if q.status<>'published' or (q.course_id is not null and not exists(select 1 from public.enrollments
    where course_id=q.course_id and student_id=auth.uid() and status in ('active','completed'))) then
    raise exception 'Quiz unavailable' using errcode='42501';
  end if;
  total:=jsonb_array_length(s.question_snapshot);
  if total=0 then raise exception 'Quiz unavailable'; end if;
  insert into public.quiz_attempts(quiz_id,student_id,score,total_questions)
    values(q.id,auth.uid(),0,total) returning id into attempt;
  for question in select * from jsonb_to_recordset(s.question_snapshot)
    as x(id uuid,question_text text,options jsonb,correct_option_index integer,explanation text) loop
    selected:=(s.answers->>question.id::text)::integer;
    if selected=question.correct_option_index then v_score:=v_score+1; end if;
    insert into public.quiz_attempt_answers(attempt_id,question_id,selected_option_index,is_correct)
      select attempt,question.id,selected,coalesce(selected=question.correct_option_index,false)
      where exists(select 1 from public.quiz_questions where id=question.id);
    review:=review||jsonb_build_array(to_jsonb(question)||jsonb_build_object('selected_option_index',selected));
  end loop;
  update public.quiz_attempts a set score=v_score,passing_score=s.passing_score,
    review_snapshot=jsonb_build_object('quiz_title',s.quiz_title,'questions',review) where a.id=attempt;
  update public.quiz_sessions set attempt_id=attempt where id=s.id;
  return public.get_quiz_attempt_review(attempt);
end;
$$;
revoke all on function public.start_quiz_session(uuid) from public,anon;
create or replace function public.get_quiz_attempt_review(p_attempt_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare a public.quiz_attempts; result jsonb;
begin
  select * into a from public.quiz_attempts where id=p_attempt_id and student_id=auth.uid();
  if not found then raise exception 'Quiz attempt unavailable'; end if;
  if a.review_snapshot is not null then
    result:=a.review_snapshot||jsonb_build_object('attempt_id',a.id,'quiz_id',a.quiz_id,
      'score',a.score,'total_questions',a.total_questions);
  else result:=public.get_quiz_attempt_review_internal(p_attempt_id); end if;
  return result||jsonb_build_object('passing_score',a.passing_score,
    'passed',a.score::numeric*100/a.total_questions>=a.passing_score);
end;
$$;
revoke all on function public.save_quiz_session(uuid,jsonb) from public,anon;
revoke all on function public.finish_quiz_session(uuid) from public,anon;
grant execute on function public.start_quiz_session(uuid) to authenticated;
grant execute on function public.save_quiz_session(uuid,jsonb) to authenticated;
grant execute on function public.finish_quiz_session(uuid) to authenticated;
-- Older clients may retrieve their latest result, but cannot bypass sessions.
create or replace function public.submit_quiz(p_quiz_id uuid,p_answers jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare attempt uuid;
begin
  select id into attempt from public.quiz_attempts where quiz_id=p_quiz_id and student_id=auth.uid()
    order by submitted_at desc limit 1;
  if attempt is null then raise exception 'Update the app to start this quiz'; end if;
  return public.get_quiz_attempt_review(attempt);
end;
$$;
