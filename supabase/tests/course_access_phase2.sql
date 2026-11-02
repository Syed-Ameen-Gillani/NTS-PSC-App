-- All identities/content are synthetic and every fixture write rolls back.
do $test$
declare teacher uuid:=gen_random_uuid(); student uuid:=gen_random_uuid(); other_student uuid:=gen_random_uuid();
  course uuid:=gen_random_uuid(); paid uuid:=gen_random_uuid(); category text;
  mod1 uuid; mod2 uuid:=gen_random_uuid(); mod3 uuid:=gen_random_uuid();
  l1 uuid; l2 uuid:=gen_random_uuid(); l3 uuid:=gen_random_uuid(); l4 uuid:=gen_random_uuid();
  paid_lesson uuid; inserted uuid:=gen_random_uuid(); video uuid:=gen_random_uuid(); material uuid:=gen_random_uuid();
  qm uuid; ql uuid; later_module_quiz uuid;later_lesson_quiz uuid; assignment uuid; submission public.assignment_submissions;
  session jsonb; questions jsonb; cover text; prevented boolean; eid uuid; request uuid:=gen_random_uuid();
  v_price integer; initial jsonb;
begin
  begin
    insert into auth.users(id,email,raw_user_meta_data) values
      (teacher,'access-teacher-'||teacher||'@example.invalid','{"requested_role":"teacher"}'),
      (student,'access-student-'||student||'@example.invalid','{}'),
      (other_student,'access-other-'||other_student||'@example.invalid','{}');
    select name into category from public.categories where is_active order by id limit 1;
    initial:='[{"title":"Reading module","lessons":[{"title":"Start here","duration_seconds":300,"notes":"Required reading"}]}]';
    questions:='[{"question_text":"Choose A","options":["A","B"],"correct_option_index":0,"explanation":"A"}]';
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    execute 'set local role authenticated';
    perform public.create_priced_course_draft(course,category,'ACCESS FREE FIXTURE','Access validation',initial,0);
    perform public.create_priced_course_draft(paid,category,'ACCESS PAID FIXTURE','Paid access validation',initial,1000);
    if public.create_priced_course_draft(paid,category,'ACCESS PAID FIXTURE','Paid access validation',initial,1000)<>paid then
      raise exception 'Draft retry changed identity'; end if;
    foreach v_price in array array[-1,1000001,null] loop
      prevented:=false;
      begin perform public.create_priced_course_draft(gen_random_uuid(),category,'Invalid','Invalid price',initial,v_price);
        exception when raise_exception then prevented:=true; end;
      if not prevented then raise exception 'Invalid course price accepted'; end if;
    end loop;
    prevented:=false;
    begin perform public.admin_set_course_access(request,student,paid,true,'teacher','forged grant');
      exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Teacher could grant paid entitlement'; end if;
    execute 'reset role';
    if (select price_amount from public.courses where id=paid)<>1000 then raise exception 'Price units changed'; end if;
    select id into mod1 from public.course_modules where course_id=course;
    select id into l1 from public.lessons where module_id=mod1;
    select l.id into paid_lesson from public.lessons l join public.course_modules m on m.id=l.module_id where m.course_id=paid;
    insert into public.course_modules(id,course_id,title,display_order) values
      (mod2,course,'Quiz module',1),(mod3,course,'Assignment module',2);
    insert into public.lessons(id,module_id,title,notes,duration_seconds,display_order) values
      (l2,mod2,'Quiz only','',300,0),(l3,mod3,'Mixed assignment','Read the instructions',300,0),
      (l4,mod3,'Final reading','Finish this reading',300,1);
    qm:=public.save_teacher_quiz(null,'Module gate','General','Easy',10,60,false,false,questions);
    ql:=public.save_teacher_quiz(null,'Lesson gate','General','Easy',10,60,false,false,questions);
    perform public.link_curriculum_assessment(course,mod1,null,'quiz',qm);
    perform public.link_curriculum_assessment(course,mod2,l2,'quiz',ql);
    insert into public.assignments(course_id,title,instructions,due_at)
      values(course,'Review required','Submit a short response',now()+interval '30 days') returning id into assignment;
    perform public.link_curriculum_assessment(course,mod3,l3,'assignment',assignment);
    insert into public.lesson_media(id,lesson_id,teacher_id,object_path,byte_size,mime_type,status)
      values(video,l3,teacher,teacher||'/'||l3||'/'||video||'.mp4',10,'video/mp4','ready');
    insert into storage.objects(bucket_id,name,owner_id,metadata)
      values('lesson-videos',teacher||'/'||l3||'/'||video||'.mp4',teacher::text,'{"size":10,"mimetype":"video/mp4"}');
    insert into public.curriculum_materials(id,course_id,module_id,lesson_id,title,object_path,mime_type,size_bytes,status)
      values(material,course,mod3,l3,'Protected document',teacher||'/'||course||'/'||material||'.txt','text/plain',10,'ready');
    insert into storage.objects(bucket_id,name,owner_id,metadata)
      values('course-materials',teacher||'/'||course||'/'||material||'.txt',teacher::text,'{"size":10,"mimetype":"text/plain"}');
    foreach cover in array array[teacher||'/'||course||'/fixture.png',teacher||'/'||paid||'/fixture.png'] loop
      insert into storage.objects(bucket_id,name,owner_id,metadata)
        values('course-thumbnails',cover,teacher::text,'{"size":100,"mimetype":"image/png"}');
    end loop;
    update public.courses set image_path=teacher||'/'||id||'/fixture.png' where id in (course,paid);
    execute 'set local role authenticated';
    perform public.publish_course_changes(course);
    perform public.publish_course_changes(paid);
    execute 'reset role';
    perform set_config('request.jwt.claim.sub',student::text,true);
    execute 'set local role authenticated';
    if (select count(*) from public.get_public_course_outline(array[course]))<>4 then raise exception 'Full outline hidden'; end if;
    if exists(select 1 from public.lessons where id in (l1,l2,l3,l4,paid_lesson)) then raise exception 'Unenrolled content leaked'; end if;
    prevented:=false;
    begin perform public.enroll_free_course(paid); exception when raise_exception then prevented:=true; end;
    if not prevented then raise exception 'Paid course enrolled for free'; end if;
    prevented:=false;
    begin insert into public.enrollments(student_id,course_id,source) values(student,paid,'paid');
      exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Client forged paid enrollment'; end if;
    eid:=public.enroll_free_course(course);
    if public.enroll_free_course(course)<>eid then raise exception 'Free enrollment duplicated'; end if;
    if not public.has_course_entitlement(course) or not public.can_open_lesson(course,l1)
      or public.can_open_lesson(course,l2) then raise exception 'Initial sequential access incorrect'; end if;
    if public.can_open_lesson(paid,l1) then raise exception 'Cross-course lesson identity accepted'; end if;
    if exists(select 1 from public.lessons where id in (l2,l3,l4)) then raise exception 'Future content leaked'; end if;
    if exists(select 1 from public.quizzes where id in (qm,ql)) then raise exception 'Premature quiz content leaked'; end if;
    if exists(select 1 from public.assignments where id=assignment) then raise exception 'Future assignment leaked'; end if;
    if exists(select 1 from storage.objects where bucket_id='lesson-videos' and name=teacher||'/'||l3||'/'||video||'.mp4')
      or exists(select 1 from storage.objects where bucket_id='course-materials' and name=teacher||'/'||course||'/'||material||'.txt') then
      raise exception 'Future private storage objects leaked'; end if;
    prevented:=false;
    begin perform public.start_quiz_session(ql); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Future quiz started'; end if;
    prevented:=false;
    begin perform public.record_lesson_completion(course,l2,true); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Future completion bypass succeeded'; end if;
    prevented:=false;
    begin perform public.record_offline_lesson_completion(l3); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Offline completion bypass succeeded'; end if;
    prevented:=false;
    begin perform public.record_lesson_completion_before_access(course,l2,true); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Legacy completion endpoint exposed'; end if;
    prevented:=false;
    begin perform public.submit_assignment_request(gen_random_uuid(),assignment,'Early submission','[]');
      exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Future assignment submission accepted'; end if;

    -- Privileged fixture setup for access tests; the evidence contract is tested separately.
    execute 'reset role';
    insert into public.lesson_progress(enrollment_id,lesson_id,completed_at) values(eid,l1,now()) on conflict(enrollment_id,lesson_id) do update set completed_at=excluded.completed_at;
    execute 'set local role authenticated';
    if public.can_open_lesson(course,l2) then raise exception 'Module assessment gate bypassed'; end if;
    session:=public.start_quiz_session(qm);
    perform public.save_quiz_session((session->>'id')::uuid,
      jsonb_build_object(session->'questions'->0->>'id',0));
    perform public.finish_quiz_session((session->>'id')::uuid);
    if not public.can_open_lesson(course,l2) then raise exception 'Passed module gate did not unlock next module'; end if;
    session:=public.start_quiz_session(ql);
    perform public.save_quiz_session((session->>'id')::uuid,jsonb_build_object(session->'questions'->0->>'id',0));
    perform public.finish_quiz_session((session->>'id')::uuid);
    if not public.can_open_lesson(course,l3) then raise exception 'Passed quiz-only lesson did not unlock next lesson'; end if;
    if not exists(select 1 from storage.objects where bucket_id='lesson-videos' and name=teacher||'/'||l3||'/'||video||'.mp4') then
      raise exception 'Accessible video remains blocked'; end if;
    -- Privileged fixture setup for access tests; the evidence contract is tested separately.
    execute 'reset role';
    -- Seed verified activity outcomes, not a completed mixed lesson: approval must still gate it.
    insert into public.learning_video_metadata values(l3,teacher||'/'||l3||'/'||video||'.mp4',100000);
    insert into public.learning_activity_progress(enrollment_id,activity_id,content_version,completed_at)
      select eid,p.id,public.learning_activity_descriptor(l3,p.id)->>'version',now()
      from public.lesson_activity_placements p where p.lesson_id=l3 and p.kind in ('video','reading') and p.is_required;
    perform public.reconcile_course_completion(student);
    execute 'set local role authenticated';
    submission:=public.submit_assignment(assignment,'A complete response','[]');
    if public.can_open_lesson(course,l4) then raise exception 'Pending assignment treated as approved'; end if;
    execute 'reset role';
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    execute 'set local role authenticated';
    perform public.review_assignment(submission.id,'approved','Approved');
    execute 'reset role';
    perform set_config('request.jwt.claim.sub',student::text,true);
    execute 'set local role authenticated';
    if not public.can_open_lesson(course,l4) then raise exception 'Approval did not unlock next lesson'; end if;
    execute 'reset role';

    -- New earlier work cannot move an existing learner behind their frontier.
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    perform public.create_curriculum_lesson(inserted,mod1,'New earlier reading',300,null,'New reading');
    execute 'set local role authenticated';
    perform public.reorder_curriculum(course,mod1,array[inserted,l1]);
    perform public.publish_course_changes(course);
    execute 'reset role';
    perform set_config('request.jwt.claim.sub',student::text,true);
    if not public.can_open_lesson(course,l4) then raise exception 'New release reset established frontier'; end if;
    if exists(select 1 from public.lesson_progress where enrollment_id=eid and lesson_id=inserted) then raise exception 'Grandfathering fabricated progress'; end if;
    if public.lesson_access_state(course,inserted)<>'available' then raise exception 'Waiver was mislabeled as earned completion';end if;
    -- Add new requirements behind the frontier, without inventing attempts.
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    later_module_quiz:=public.save_teacher_quiz(null,'Later module requirement','General','Easy',10,60,false,false,questions);
    later_lesson_quiz:=public.save_teacher_quiz(null,'Later lesson requirement','General','Easy',10,60,false,false,questions);
    perform public.link_curriculum_assessment(course,mod1,null,'quiz',later_module_quiz);
    perform public.link_curriculum_assessment(course,mod1,l1,'quiz',later_lesson_quiz);
    execute 'set local role authenticated';
    perform public.publish_course_changes(course);
    execute 'reset role';
    perform set_config('request.jwt.claim.sub',student::text,true);
    if not public.can_open_lesson(course,l4) then raise exception 'New module assessment reset established frontier';end if;
    if (select quizzes_remaining from public.course_requirements(student) where course_id=course)<>0 then raise exception 'Waived link still counted as required';end if;
    if exists(select 1 from public.quiz_attempts where student_id=student and quiz_id in (later_module_quiz,later_lesson_quiz)) then raise exception 'Waiver fabricated grade';end if;
    perform set_config('request.jwt.claim.sub',other_student::text,true);
    execute 'set local role authenticated';
    perform public.enroll_free_course(course);
    if not public.can_open_lesson(course,inserted) or public.can_open_lesson(course,l1) then raise exception 'New learner skipped new required work'; end if;
    execute 'reset role';
    if (select quizzes_remaining from public.course_requirements(other_student) where course_id=course)<2 then raise exception 'New learner inherited assessment waivers';end if;

    execute 'set local role service_role';
    perform public.admin_set_course_access(request,student,paid,true,'fixture-operator','Authorized test enrollment');
    perform public.admin_set_course_access(request,student,paid,true,'fixture-operator','Authorized test enrollment');
    execute 'reset role';
    if (select count(*) from public.enrollment_access_audit where request_id=request)<>1 then raise exception 'Admin replay duplicated audit'; end if;
    perform set_config('request.jwt.claim.sub',student::text,true);
    execute 'set local role authenticated';
    if not public.has_course_entitlement(paid) or not public.can_open_lesson(paid,paid_lesson) then raise exception 'Authorized paid access unavailable'; end if;
    execute 'reset role';
    execute 'set local role service_role';
    perform public.admin_set_course_access(gen_random_uuid(),student,paid,false,'fixture-operator','Revoke test access');
    perform public.admin_set_course_access(gen_random_uuid(),student,course,false,'fixture-operator','Revoke test access');
    execute 'reset role';
    execute 'set local role authenticated';
    if public.has_course_entitlement(paid) or public.can_open_lesson(course,l1) then raise exception 'Revoked access remained usable'; end if;
    prevented:=false;
    begin perform public.save_quiz_session((session->>'id')::uuid,'{}'); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Revoked session still accepted writes'; end if;
    execute 'reset role';
    raise exception using errcode='ZX021',message='PHASE2_ACCESS_CHECKS_PASSED';
  exception when sqlstate 'ZX021' then raise notice 'Phase 2 access fixtures rolled back';
  end;
end;
$test$;


