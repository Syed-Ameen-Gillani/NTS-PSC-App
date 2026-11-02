-- Synthetic identities only. Deliberate privileged clock adjustments simulate
-- elapsed time without sleeping or changing any actual learner's records.
do $test$
declare teacher uuid:=gen_random_uuid();student uuid:=gen_random_uuid();other_student uuid:=gen_random_uuid();
  course uuid:=gen_random_uuid();category text;module uuid;lesson uuid;next_lesson uuid:=gen_random_uuid();
  activity uuid;reading uuid;media_id uuid:=gen_random_uuid();ticket jsonb;event jsonb;result jsonb;eid uuid;prevented boolean;i integer;
  final_quiz uuid;final_assignment uuid;submission jsonb;quiz_session jsonb;issuance uuid;
  reused_lesson uuid:=gen_random_uuid();
begin
 begin
  insert into auth.users(id,email,raw_user_meta_data) values
    (teacher,'evidence-teacher-'||teacher||'@example.invalid','{"requested_role":"teacher"}'),
    (student,'evidence-student-'||student||'@example.invalid','{}'),
    (other_student,'evidence-other-'||other_student||'@example.invalid','{}');
  select name into category from public.categories where is_active order by id limit 1;
  perform set_config('request.jwt.claim.sub',teacher::text,true);
  perform public.create_priced_course_draft(course,category,'EVIDENCE FIXTURE','Evidence validation',
    '[{"title":"Module","lessons":[{"title":"Mixed lesson","duration_seconds":100,"notes":"Read this short text"}]}]',0);
  select id into module from public.course_modules where course_id=course;
  select id into lesson from public.lessons where module_id=module;
  update public.lessons set external_video_url='https://example.invalid/video.mp4' where id=lesson;
  insert into public.lessons(id,module_id,title,notes,duration_seconds,display_order)
    values(next_lesson,module,'Next reading','Read the final text',100,1);
  final_quiz:=public.save_teacher_quiz(null,'Final knowledge check','General','Easy',10,60,false,false,
    '[{"question_text":"Choose A","options":["A","B"],"correct_option_index":0,"explanation":"A"}]');
  perform public.link_curriculum_assessment(course,module,next_lesson,'quiz',final_quiz);
  insert into public.lessons(id,module_id,title,notes,duration_seconds,display_order)
    values(reused_lesson,module,'Reused knowledge check','',100,2);
  perform public.link_curriculum_assessment(course,module,reused_lesson,'quiz',final_quiz);
  insert into public.assignments(course_id,title,instructions,due_at)
    values(course,'Final response','Explain what you learned',now()+interval '30 days') returning id into final_assignment;
  perform public.link_curriculum_assessment(course,module,next_lesson,'assignment',final_assignment);
  insert into storage.objects(bucket_id,name,owner_id,metadata)
    values('course-thumbnails',teacher||'/'||course||'/fixture.png',teacher::text,'{"size":100,"mimetype":"image/png"}');
  update public.courses set image_path=teacher||'/'||course||'/fixture.png' where id=course;
  perform public.confirm_learning_video('https://example.invalid/video.mp4',100000,lesson);
  if to_regprocedure('public.lesson_media_ready_for_release(uuid)') is not null then
    update public.lessons set external_video_url=null where id=lesson;
    insert into public.lesson_media(id,lesson_id,teacher_id,object_path,byte_size,mime_type,status,transcript_segments)
      values(media_id,lesson,teacher,teacher||'/'||lesson||'/'||media_id||'.mp4',10,'video/mp4','transcribing','[{"start":0,"end":2,"text":"DRAFT TRANSCRIPT"}]');
    insert into storage.objects(bucket_id,name,owner_id,metadata)
      values('lesson-videos',teacher||'/'||lesson||'/'||media_id||'.mp4',teacher::text,'{"size":10,"mimetype":"video/mp4"}');
    perform public.confirm_learning_video(teacher||'/'||lesson||'/'||media_id||'.mp4',100000,lesson);
  end if;
  perform public.publish_course_changes(course);
  select id into activity from public.lesson_activity_placements where lesson_id=lesson and kind='video';
  select id into reading from public.lesson_activity_placements where lesson_id=lesson and kind='reading';
  if to_regprocedure('public.get_teacher_lesson_activities(uuid)') is not null then
    if jsonb_array_length(public.get_teacher_lesson_activities(lesson))<>2 then raise exception 'Authoring omitted activities'; end if;
    perform public.configure_lesson_activities(lesson,jsonb_build_array(
      jsonb_build_object('id',reading,'required',false),jsonb_build_object('id',activity,'required',true)));
    if not exists(select 1 from public.released_course_lessons(course) l cross join lateral jsonb_array_elements(l.activities) a
      where l.lesson_id=lesson and a->>'id'=reading::text and (a->>'required')::boolean) then
      raise exception 'Draft requirement change altered active release'; end if;
    perform public.configure_lesson_activities(lesson,jsonb_build_array(
      jsonb_build_object('id',reading,'required',true),jsonb_build_object('id',activity,'required',true)));
  end if;
  perform set_config('request.jwt.claim.sub',student::text,true);
  execute 'set local role authenticated';
  eid:=public.enroll_free_course(course);
  if to_regprocedure('public.get_student_lesson_media(uuid)') is not null then
    if exists(select 1 from public.lesson_media where id=media_id) then raise exception 'Unreviewed raw transcript leaked'; end if;
    result:=public.get_student_lesson_media(lesson);
    if jsonb_array_length(result)<>1 or jsonb_array_length(result->0->'transcript_segments')<>0 then
      raise exception 'Published video projection leaked drafts or hid the video'; end if;
    if not exists(select 1 from storage.objects where bucket_id='lesson-videos' and name=teacher||'/'||lesson||'/'||media_id||'.mp4') then
      raise exception 'Published video signing still depends on transcript review'; end if;
  end if;
  if to_regprocedure('public.save_course_review(uuid,integer,text)') is not null then
    prevented:=false;
    begin perform public.save_course_review(course,5,'Too early'); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Review accepted without confirmed progress'; end if;
  end if;
  if to_regprocedure('public.get_teacher_lesson_activities(uuid)') is not null then
    prevented:=false;
    begin perform public.get_teacher_lesson_activities(lesson); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Student accessed teacher activity configuration'; end if;
  end if;
  prevented:=false;
  begin perform public.record_lesson_completion(course,lesson,true); exception when insufficient_privilege then prevented:=true; end;
  if not prevented then raise exception 'Manual completion remains enabled'; end if;
  prevented:=false;
  begin insert into public.lesson_progress(enrollment_id,lesson_id,completed_at) values(eid,lesson,now());
    exception when insufficient_privilege then prevented:=true; end;
  if not prevented then raise exception 'Direct completion remains enabled'; end if;
  ticket:=public.begin_learning_evidence(lesson,activity);
  execute 'reset role';
  update public.learning_evidence_sessions set started_at=now()-interval '10 minutes' where id=(ticket->>'id')::uuid;
  update public.learning_engagement_clocks set started_at=now()-interval '10 minutes' where student_id=student;
  execute 'set local role authenticated';
  event:=jsonb_build_object('session_id',ticket->>'id','sequence',1,'wall_ms',1000,'start',0,'end',90000,'speed',1);
  result:=public.record_learning_evidence(jsonb_build_array(event));
  if result->0->>'accepted'<>'false' then raise exception 'Seeking was credited'; end if;
  for i in 1..9 loop
    event:=jsonb_build_object('session_id',ticket->>'id','sequence',i,'wall_ms',10000,'start',(i-1)*10000,'end',i*10000,'speed',1);
    result:=public.record_learning_evidence(jsonb_build_array(event));
    if result->0->>'accepted'<>'true' then raise exception 'Valid video rejected: %',result; end if;
  end loop;
  if result->0->>'activity_completed'<>'true' or result->0->>'lesson_completed'<>'false' then
    raise exception 'Mixed lesson criteria incorrect'; end if;
  if public.can_open_lesson(course,next_lesson) then raise exception 'Reading requirement bypassed'; end if;
  -- Publishing a removed activity must evaluate the previous frontier against
  -- the OLD manifest. Roll this publication back before continuing evidence.
  begin
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    perform public.stage_curriculum_details('lesson',lesson,'{"notes":""}');
    perform public.publish_course_changes(course);
    raise exception using errcode='ZX033',message='Removed-reading publication passed';
  exception when sqlstate 'ZX033' then null;end;
  perform set_config('request.jwt.claim.sub',student::text,true);
  result:=public.record_learning_evidence(jsonb_build_array(event));
  if result->0->>'duplicate'<>'true' then raise exception 'Retry duplicated evidence'; end if;
  event:=event||'{"end":99999}';
  if public.record_learning_evidence(jsonb_build_array(event))->0->>'accepted'<>'false' then raise exception 'Conflicting retry accepted'; end if;
  perform set_config('request.jwt.claim.sub',other_student::text,true);
  if public.record_learning_evidence(jsonb_build_array(event))->0->>'accepted'<>'false' then raise exception 'Cross-account evidence accepted'; end if;
  perform set_config('request.jwt.claim.sub',student::text,true);
  ticket:=public.begin_learning_evidence(lesson,reading);
  execute 'reset role';
  update public.learning_evidence_sessions set started_at=now()-interval '1 minute' where id=(ticket->>'id')::uuid;
  execute 'set local role authenticated';
  event:=jsonb_build_object('session_id',ticket->>'id','sequence',1,'wall_ms',5000,'start',0,'end',1,'speed',1);
  result:=public.record_learning_evidence(jsonb_build_array(event));
  if result->0->>'lesson_completed'<>'true' or not public.can_open_lesson(course,next_lesson) then
    raise exception 'Verified mixed lesson did not unlock next: %',result; end if;
  if to_regprocedure('public.save_course_review(uuid,integer,text)') is not null then
    perform public.save_course_review(course,4,'A useful learning experience');
    perform public.save_course_review(course,2,'Updated review after more practice');
    result:=public.get_course_reviews(course,0,null);
    if (result->>'count')::integer<>1 or (result->>'average')::numeric<>2
      or result->'own_review'->>'rating'<>'2' then raise exception 'Review upsert/aggregates failed: %',result; end if;
    prevented:=false;
    begin perform public.save_course_review(course,6,'Invalid rating'); exception when sqlstate '22023' then prevented:=true; end;
    if not prevented then raise exception 'Invalid rating accepted'; end if;
    prevented:=false;
    begin insert into public.course_reviews(course_id,student_id,rating,body) values(course,other_student,5,'Forged reviewer');
      exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Direct review identity forgery accepted'; end if;
    perform set_config('request.jwt.claim.sub',other_student::text,true);
    prevented:=false;
    begin perform public.save_course_review(course,5,'Unenrolled review'); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Unenrolled review accepted'; end if;
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    prevented:=false;
    begin perform public.save_course_review(course,5,'Self promotion'); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Instructor reviewed own course'; end if;
    perform set_config('request.jwt.claim.sub','',true);
    execute 'set local role anon';
    result:=public.get_course_reviews(course,0,5);
    if jsonb_array_length(result->'items')<>0 or result->>'can_review'<>'false'
      or result->'own_review'<>'null'::jsonb or (result->>'count')::integer<>1 then
      raise exception 'Public review filter/privacy failed'; end if;
    execute 'reset role';
    perform set_config('request.jwt.claim.sub',student::text,true);
    execute 'set local role authenticated';
  end if;
  -- Complete the final mixed reading/quiz/assignment lesson through real RPCs.
  select (a->>'id')::uuid into reading from jsonb_array_elements(public.get_learning_outcome(next_lesson)->'activities') a where a->>'kind'='reading';
  ticket:=public.begin_learning_evidence(next_lesson,reading);
  execute 'reset role';
  update public.learning_evidence_sessions set started_at=now()-interval '1 minute' where id=(ticket->>'id')::uuid;
  execute 'set local role authenticated';
  result:=public.record_learning_evidence(jsonb_build_array(jsonb_build_object('session_id',ticket->>'id',
    'sequence',1,'wall_ms',5000,'start',0,'end',1,'speed',1)));
  if result->0->>'accepted'<>'true' or result->0->>'lesson_completed'<>'false' then
    raise exception 'Required assessments did not block lesson completion'; end if;
  quiz_session:=public.start_quiz_session(final_quiz);
  perform public.save_quiz_session((quiz_session->>'id')::uuid,jsonb_build_object(quiz_session->'questions'->0->>'id',0));
  perform public.finish_quiz_session((quiz_session->>'id')::uuid);
  if public.can_open_lesson(course,reused_lesson) then raise exception 'Reused quiz bypassed an earlier pending assignment'; end if;
  if exists(select 1 from public.lesson_progress where enrollment_id=eid and lesson_id=reused_lesson and completed_at is not null) then
    raise exception 'Future reused assessment manufactured premature completion'; end if;
  submission:=public.submit_assignment_request(gen_random_uuid(),final_assignment,'A complete learning response','[]');
  if exists(select 1 from public.get_my_course_eligibility() where course_id=course and is_complete) then
    raise exception 'Pending assignment granted a certificate'; end if;
  perform set_config('request.jwt.claim.sub',teacher::text,true);
  perform public.review_assignment((submission->>'id')::uuid,'approved','Good work');
  perform set_config('request.jwt.claim.sub',student::text,true);
  if not exists(select 1 from public.get_my_course_eligibility() where course_id=course and is_complete) then
    raise exception 'Approved course requirements did not grant completion'; end if;
  select id into issuance from public.course_completions where enrollment_id=eid;
  perform public.get_my_course_eligibility();
  if issuance is null or (select count(*) from public.course_completions where enrollment_id=eid)<>1 then
    raise exception 'Certificate eligibility duplicated or was not issued'; end if;
  perform set_config('request.jwt.claim.sub',other_student::text,true);
  if exists(select 1 from public.course_completions where id=issuance) then raise exception 'Certificate history leaked'; end if;
  perform set_config('request.jwt.claim.sub',teacher::text,true);
  if not exists(select 1 from public.get_teacher_learner_roster(50,0,null,course)
    where student_id=student and enrollment_status='completed') then raise exception 'Teacher roster disagrees with completion'; end if;
  execute 'reset role';
  if (select engaged_ms from public.learning_activity_progress where activity_id=activity and enrollment_id=eid)<>90000 then
    raise exception 'Duplicate changed credited time'; end if;
  raise exception using errcode='ZX031',message='Fixture checks passed';
 exception when sqlstate 'ZX031' then null; end;
 if exists(select 1 from auth.users where id in (teacher,student,other_student)) then raise exception 'Fixture rollback failed'; end if;
end $test$;


