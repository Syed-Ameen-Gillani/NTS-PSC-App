-- No retained records are changed. Fixtures are rolled back on success or failure.
do $$
declare
  teacher uuid; student uuid; category uuid;
  course_a uuid := gen_random_uuid(); course_b uuid := gen_random_uuid();
  assignment_a uuid; assignment_b uuid; quiz_a uuid; quiz_b uuid; question uuid;
  q uuid;
begin
  begin
  select id into teacher from public.profiles where role = 'teacher' and display_name like '%TEST%' limit 1;
  select id into student from public.profiles where role = 'student' and display_name like '%TEST%' limit 1;
  select id into category from public.categories where is_active limit 1;
  if teacher is null or student is null then raise exception 'Retained TEST teacher/student required'; end if;
  insert into public.courses(id,instructor_id,category_id,title) values
    (course_a,teacher,category,'AUDIT TEST A'),(course_b,teacher,category,'AUDIT TEST B');
  insert into public.enrollments(student_id,course_id) values(student,course_a);
  insert into public.assignments(course_id,title,instructions,due_at,status)
    values(course_a,'A','Test',now()+interval '1 day','published') returning id into assignment_a;
  insert into public.assignments(course_id,title,instructions,due_at,status)
    values(course_b,'B','Test',now()+interval '1 day','published') returning id into assignment_b;
  insert into public.quizzes(teacher_id,course_id,title) values(teacher,course_a,'A') returning id into quiz_a;
  insert into public.quizzes(teacher_id,course_id,title) values(teacher,course_b,'B') returning id into quiz_b;
  foreach q in array array[quiz_a,quiz_b] loop
    insert into public.quiz_questions(quiz_id,display_order,question_text,options)
      values(q,0,'Test?',array['Yes','No']) returning id into question;
    insert into public.quiz_answer_keys(question_id,correct_option_index) values(question,0);
    update public.quizzes set status='published' where id=q;
  end loop;
  perform set_config('request.jwt.claim.sub',student::text,true);
  execute 'set local role authenticated';
  if not exists(select 1 from public.assignments where id=assignment_a) or
     not exists(select 1 from public.quizzes where id=quiz_a) then
    raise exception 'Enrolled student cannot read own assessments';
  end if;
  if exists(select 1 from public.assignments where id=assignment_b) or
     exists(select 1 from public.quizzes where id=quiz_b) then
    raise exception 'Cross-course assessment leak: enrollment in A authorized B';
  end if;
  execute 'reset role';
  perform set_config('request.jwt.claim.sub',teacher::text,true);
  execute 'set local role authenticated';
  if not exists(select 1 from public.assignments where id=assignment_b) or
     not exists(select 1 from public.quizzes where id=quiz_b) then
    raise exception 'Owner cannot read own assessments';
  end if;
  raise exception 'Rollback audit fixtures';
  exception when raise_exception then
    if sqlerrm <> 'Rollback audit fixtures' then raise; end if;
  end;
end;
$$;
