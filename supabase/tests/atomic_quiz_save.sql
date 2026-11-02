do $$
declare
  teacher uuid;
  student uuid;
  draft uuid;
  unlinked uuid;
  original_question uuid;
  before_count integer;
  good jsonb := '[{"question_text":"Test question","options":["A","B"],"correct_option_index":1,"explanation":"B is correct"}]';
  bad jsonb := '[{"question_text":"Invalid second question","options":["A","B"],"correct_option_index":9,"explanation":"Invalid"}]';
begin
  begin
    select id into teacher from public.profiles where role='teacher' and display_name like '%TEST%' limit 1;
    select id into student from public.profiles where role='student' and display_name like '%TEST%' limit 1;
    if teacher is null or student is null then raise exception 'Retained test profiles required'; end if;
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    execute 'set local role authenticated';
    draft := public.save_teacher_quiz(null,'ATOMIC TEST','General','Medium',15,60,false,false,good);
    select id into original_question from public.quiz_questions where quiz_id=draft;
    begin
      perform public.save_teacher_quiz(draft,'Changed','General','Medium',15,60,false,false,good||bad);
      raise exception 'Invalid update succeeded';
    exception when invalid_parameter_value then null;
    end;
    if not exists(select 1 from public.quizzes where id=draft and title='ATOMIC TEST') or
       not exists(select 1 from public.quiz_questions where id=original_question) or
       not exists(select 1 from public.quiz_answer_keys where question_id=original_question) then
      raise exception 'Failed update did not restore original draft and keys';
    end if;
    select count(*) into before_count from public.quizzes where teacher_id=teacher;
    begin
      perform public.save_teacher_quiz(null,'Invalid','General','Medium',15,60,false,true,good||bad);
      raise exception 'Invalid creation succeeded';
    exception when invalid_parameter_value then null;
    end;
    if (select count(*) from public.quizzes where teacher_id=teacher)<>before_count then
      raise exception 'Failed creation left partial quiz';
    end if;
    unlinked := public.save_teacher_quiz(null,'UNLINKED TEST','General','Medium',15,60,false,true,good);
    if not exists(select 1 from public.quizzes where id=unlinked and status='draft' and course_id is null) then
      raise exception 'Unlinked quiz was exposed as published';
    end if;
    perform public.save_teacher_quiz(draft,'Updated draft','General','Hard',20,70,false,false,good||good);
    if (select count(*) from public.quiz_questions where quiz_id=draft)<>2 then
      raise exception 'Valid replacement did not save all questions';
    end if;
    perform set_config('request.jwt.claim.sub',student::text,true);
    begin
      perform public.save_teacher_quiz(draft,'Unauthorized','General','Medium',15,60,false,false,good);
      raise exception 'Student edited teacher draft';
    exception when insufficient_privilege then null;
    end;
    begin
      perform public.save_teacher_quiz(null,'Unauthorized','General','Medium',15,60,false,false,good);
      raise exception 'Student created teacher quiz';
    exception when insufficient_privilege then null;
    end;
    raise exception 'Rollback atomic quiz tests';
  exception when raise_exception then
    if sqlerrm <> 'Rollback atomic quiz tests' then raise; end if;
  end;
end;
$$;
