-- Return answer keys only for a submitted attempt owned by the caller.
create function public.get_quiz_attempt_review(p_attempt_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_attempt public.quiz_attempts%rowtype;
  v_title text;
  v_questions jsonb;
begin
  if auth.uid() is null then
    raise exception 'Sign in required';
  end if;
  select * into v_attempt from public.quiz_attempts
  where id = p_attempt_id and student_id = auth.uid();
  if not found then
    raise exception 'Quiz attempt unavailable';
  end if;
  select title into v_title from public.quizzes where id = v_attempt.quiz_id;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', q.id,
    'question_text', q.question_text,
    'options', q.options,
    'correct_option_index', k.correct_option_index,
    'explanation', k.explanation,
    'selected_option_index', a.selected_option_index
  ) order by q.display_order), '[]'::jsonb) into v_questions
  from public.quiz_attempt_answers a
  join public.quiz_questions q on q.id = a.question_id
  join public.quiz_answer_keys k on k.question_id = q.id
  where a.attempt_id = p_attempt_id;
  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'quiz_id', v_attempt.quiz_id,
    'quiz_title', v_title,
    'score', v_attempt.score,
    'total_questions', v_attempt.total_questions,
    'questions', v_questions
  );
end;
$$;

revoke all on function public.get_quiz_attempt_review(uuid) from public, anon, authenticated;
grant execute on function public.get_quiz_attempt_review(uuid) to authenticated;
