-- Run within a transaction and roll back: no retained student data is changed.
do $$
declare teacher uuid; student uuid; category uuid; course uuid:=gen_random_uuid();
  quiz uuid; question uuid; s jsonb; resumed jsonb; result jsonb; again jsonb;
begin
  select id into teacher from public.profiles where role='teacher' and display_name like '%TEST%' limit 1;
  select id into student from public.profiles where role='student' and display_name like '%TEST%' limit 1;
  select id into category from public.categories where is_active limit 1;
  if teacher is null or student is null then raise exception 'TEST profiles required'; end if;
  insert into public.courses(id,instructor_id,category_id,title) values(course,teacher,category,'SESSION TEST');
  insert into public.enrollments(student_id,course_id) values(student,course);
  insert into public.quizzes(teacher_id,title,passing_score)
    values(teacher,'SESSION TEST',80) returning id into quiz;
  insert into public.quiz_questions(quiz_id,display_order,question_text,options)
    values(quiz,0,'Test?',array['Yes','No']) returning id into question;
  insert into public.quiz_answer_keys(question_id,correct_option_index) values(question,0);
  update public.quizzes set course_id=course,status='published' where id=quiz;
  perform set_config('request.jwt.claim.sub',student::text,true);
  execute 'set local role authenticated';
  s:=public.start_quiz_session(quiz);
  if s ? 'question_snapshot' or exists(select 1 from jsonb_array_elements(s->'questions') v
    where v ? 'correct_option_index' or v ? 'explanation') then
    raise exception 'Session exposed answer keys'; end if;
  resumed:=public.start_quiz_session(quiz);
  if public.get_quiz_session_status((s->>'id')::uuid)->>'id'<>s->>'id' then
    raise exception 'Owned session status unavailable'; end if;
  if s->>'id'<>resumed->>'id' or s->>'expires_at'<>resumed->>'expires_at' then
    raise exception 'Resume reset the session or deadline'; end if;
  perform public.save_quiz_session((s->>'id')::uuid,jsonb_build_object(question::text,1));
  result:=public.finish_quiz_session((s->>'id')::uuid);
  if result->'questions'->0->>'question_text'<>'Test?' then raise exception 'Review snapshot missing'; end if;
  again:=public.finish_quiz_session((s->>'id')::uuid);
  if result->>'attempt_id'<>again->>'attempt_id' or (result->>'passed')::boolean
    or (result->>'passing_score')::integer<>80 then raise exception 'Scoring or idempotency failed'; end if;
  s:=public.start_quiz_session(quiz);
  perform public.save_quiz_session((s->>'id')::uuid,jsonb_build_object(question::text,0));
  again:=public.finish_quiz_session((s->>'id')::uuid);
  if result->>'attempt_id'=again->>'attempt_id' or not (again->>'passed')::boolean then
    raise exception 'Retake did not create a passing historical attempt'; end if;
  perform set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
  begin
    perform public.finish_quiz_session((s->>'id')::uuid);
    raise exception 'Another account submitted the session';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
end;
$$;
