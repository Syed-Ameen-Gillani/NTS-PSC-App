-- Run as the caller: existing table grants, RLS and publication guards apply.
create function public.save_teacher_quiz(
  p_quiz_id uuid,
  p_title text,
  p_category text,
  p_difficulty text,
  p_duration_minutes integer,
  p_passing_score integer,
  p_is_ai_generated boolean,
  p_publish boolean,
  p_questions jsonb
) returns uuid
language plpgsql security invoker set search_path='' as $$
declare
  v_quiz_id uuid;
  v_question_id uuid;
  question jsonb;
  options text[];
  position integer := 0;
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
  if jsonb_typeof(p_questions) is distinct from 'array' then
    raise exception 'Questions must be an array' using errcode='22023';
  end if;
  if jsonb_array_length(p_questions)=0 then
    raise exception 'Add at least one question' using errcode='22023';
  end if;
  if p_title is null or length(trim(p_title))=0 or p_publish is null then
    raise exception 'Invalid quiz settings' using errcode='22023';
  end if;

  if p_quiz_id is null then
    insert into public.quizzes(teacher_id,title,category,difficulty,duration_minutes,passing_score,is_ai_generated)
      values(auth.uid(),trim(p_title),p_category,p_difficulty,p_duration_minutes,p_passing_score,p_is_ai_generated)
      returning id into v_quiz_id;
  else
    select id into v_quiz_id from public.quizzes
      where id=p_quiz_id and teacher_id=auth.uid() and status='draft' for update;
    if v_quiz_id is null then
      raise exception 'Only your own draft quiz can be edited' using errcode='42501';
    end if;
    update public.quizzes set title=trim(p_title),category=p_category,difficulty=p_difficulty,
      duration_minutes=p_duration_minutes,passing_score=p_passing_score where id=v_quiz_id;
    delete from public.quiz_questions where quiz_id=v_quiz_id;
  end if;

  for question in select value from jsonb_array_elements(p_questions) loop
    if jsonb_typeof(question->'question_text') is distinct from 'string' or
       length(trim(question->>'question_text'))=0 or
       jsonb_typeof(question->'options') is distinct from 'array' or
       jsonb_typeof(question->'correct_option_index') is distinct from 'number' or
       jsonb_typeof(question->'explanation') is distinct from 'string' then
      raise exception 'Invalid question' using errcode='22023';
    end if;
    if jsonb_array_length(question->'options') not between 2 and 6 or exists(
      select 1 from jsonb_array_elements(question->'options') as item(value)
        where jsonb_typeof(value)<>'string' or length(trim(value#>>'{}'))=0
    ) then raise exception 'Provide two to six non-empty options' using errcode='22023'; end if;
    if (question->>'correct_option_index') !~ '^[0-9]+$' or
       (question->>'correct_option_index')::numeric >= jsonb_array_length(question->'options') then
      raise exception 'Invalid correct answer' using errcode='22023';
    end if;
    select array_agg(value order by ordinal) into options
      from jsonb_array_elements_text(question->'options') with ordinality as item(value,ordinal);
    insert into public.quiz_questions(quiz_id,display_order,question_text,options)
      values(v_quiz_id,position,trim(question->>'question_text'),options) returning id into v_question_id;
    insert into public.quiz_answer_keys(question_id,correct_option_index,explanation)
      values(v_question_id,(question->>'correct_option_index')::integer,question->>'explanation');
    position := position+1;
  end loop;
  if p_publish then update public.quizzes set status='published' where id=v_quiz_id; end if;
  return v_quiz_id;
end;
$$;
revoke all on function public.save_teacher_quiz(uuid,text,text,text,integer,integer,boolean,boolean,jsonb) from public,anon;
grant execute on function public.save_teacher_quiz(uuid,text,text,text,integer,integer,boolean,boolean,jsonb) to authenticated;
