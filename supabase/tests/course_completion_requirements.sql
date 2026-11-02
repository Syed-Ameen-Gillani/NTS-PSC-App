do $$
declare teacher uuid; student uuid; category uuid; course uuid:=gen_random_uuid();
  module uuid; lesson uuid; quiz uuid; question uuid; assignment uuid; enrollment uuid;
  s jsonb; result jsonb; complete boolean; issuance uuid;
begin
  select id into teacher from public.profiles where role='teacher' and display_name like '%TEST%' limit 1;
  select id into student from public.profiles where role='student' and display_name like '%TEST%' limit 1;
  select id into category from public.categories where is_active limit 1;
  if teacher is null or student is null then raise exception 'TEST profiles required'; end if;
  insert into public.courses(id,instructor_id,category_id,title,description)
    values(course,teacher,category,'COMPLETION TEST','Test description');
  insert into storage.objects(bucket_id,name,owner_id,metadata)
    values('course-thumbnails',teacher::text||'/'||course::text||'/test.png',teacher::text,
      '{"size":100,"mimetype":"image/png"}');
  insert into public.course_modules(course_id,title,display_order) values(course,'Module',0) returning id into module;
  insert into public.lessons(module_id,title,duration_seconds,external_video_url,status,display_order)
    values(module,'Lesson',60,'https://example.com/test.mp4','published',0) returning id into lesson;
  insert into public.quizzes(teacher_id,title) values(teacher,'QUIZ') returning id into quiz;
  insert into public.quiz_questions(quiz_id,display_order,question_text,options)
    values(quiz,0,'Test?',array['Yes','No']) returning id into question;
  insert into public.quiz_answer_keys(question_id,correct_option_index) values(question,0);
  update public.quizzes set course_id=course,status='published' where id=quiz;
  insert into public.assignments(course_id,title,instructions,due_at,status)
    values(course,'ASSIGNMENT','Respond',now()+interval '1 day','published') returning id into assignment;
  insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,quiz_id)
    values(course,module,lesson,quiz);
  insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,assignment_id)
    values(course,module,lesson,assignment);
  update public.courses set image_path=teacher::text||'/'||course::text||'/test.png',status='published' where id=course;
  perform set_config('request.jwt.claim.sub',student::text,true);
  execute 'set local role authenticated';
  enrollment:=public.enroll_free_course(course);
  if public.enroll_free_course(course)<>enrollment then raise exception 'Duplicate enrollment'; end if;
  perform public.record_lesson_completion(course,lesson,true);
  select is_complete into complete from public.get_my_course_eligibility() where course_id=course;
  if complete then raise exception 'Lessons alone completed course'; end if;
  s:=public.start_quiz_session(quiz);
  perform public.save_quiz_session((s->>'id')::uuid,jsonb_build_object(question::text,0));
  perform public.finish_quiz_session((s->>'id')::uuid);
  select is_complete into complete from public.get_my_course_eligibility() where course_id=course;
  if complete then raise exception 'Missing assignment completed course'; end if;
  result:=public.submit_assignment_request(gen_random_uuid(),assignment,'Response','[]');
  select is_complete into complete from public.get_my_course_eligibility() where course_id=course;
  if complete then raise exception 'Pending assignment completed course'; end if;
  perform set_config('request.jwt.claim.sub',teacher::text,true);
  perform public.review_assignment((result->>'id')::uuid,'approved','Accepted');
  perform set_config('request.jwt.claim.sub',student::text,true);
  select is_complete into complete from public.get_my_course_eligibility() where course_id=course;
  if not complete then raise exception 'All requirements did not complete course'; end if;
  select id into issuance from public.course_completions where course_id=course;
  perform public.record_lesson_completion(course,lesson,true);
  if (select count(*) from public.course_completions where course_id=course)<>1 then
    raise exception 'Duplicate completion'; end if;
  perform set_config('request.jwt.claim.sub',teacher::text,true);
  if not exists(select 1 from public.get_teacher_learner_roster(50,0,null,course)
    where student_id=student and enrollment_status='completed') then
    raise exception 'Teacher roster disagrees with student completion'; end if;
  perform set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
  if exists(select 1 from public.course_completions where id=issuance) then
    raise exception 'Completion leaked to another student'; end if;
  execute 'reset role';
end;
$$;
