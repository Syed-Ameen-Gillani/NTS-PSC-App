-- Relationship/RLS tests only: all fixture metadata is rolled back. This does
-- not replace an HTTP Storage upload/download smoke test on native devices.
do $$
declare t uuid; s uuid; category uuid; ca uuid:=gen_random_uuid(); cb uuid:=gen_random_uuid();
  ma uuid:=gen_random_uuid(); mb uuid:=gen_random_uuid(); la uuid:=gen_random_uuid();
  lb uuid:=gen_random_uuid(); q uuid; qb uuid; a uuid; question uuid; reservation jsonb;
  cover text; rejected boolean; draft_id uuid:=gen_random_uuid(); created jsonb;
begin
  select id into t from public.profiles where role='teacher' and display_name like '%TEST%' limit 1;
  select id into s from public.profiles where role='student' and display_name like '%TEST%' limit 1;
  select id into category from public.categories where is_active limit 1;
  if t is null or s is null then raise exception 'Retained TEST teacher/student required'; end if;
  begin
    insert into public.courses(id,instructor_id,category_id,title,description) values
      (ca,t,category,'CURRICULUM TEST A','Temporary test'),(cb,t,category,'CURRICULUM TEST B','Temporary test');
    insert into public.course_modules(id,course_id,title,display_order) values(ma,ca,'A',0),(mb,cb,'B',0);
    insert into public.lessons(id,module_id,title,duration_seconds,external_video_url,status,display_order)
      values(la,ma,'A',60,'https://example.invalid/test.mp4','published',0),
            (lb,mb,'B',60,'https://example.invalid/test.mp4','published',0);
    cover:=t::text||'/'||ca::text||'/test.png';
    insert into storage.objects(bucket_id,name,metadata) values('course-thumbnails',cover,
      jsonb_build_object('size',128,'mimetype','image/png'));
    update public.courses set image_path=cover,status='published' where id=ca;
    insert into public.enrollments(student_id,course_id) values(s,ca);
    insert into public.quizzes(teacher_id,title) values(t,'Draft to link') returning id into q;
    insert into public.quizzes(teacher_id,course_id,title) values(t,cb,'Wrong course') returning id into qb;
    insert into public.assignments(course_id,title,instructions,due_at)
      values(ca,'Linked task','Read and answer',now()+interval '1 day') returning id into a;
    perform set_config('request.jwt.claim.sub',t::text,true);
    execute 'set local role authenticated';
    created:=public.create_curriculum_lesson(draft_id,mb,'Idempotent lesson',120,null,'Notes');
    created:=public.create_curriculum_lesson(draft_id,mb,'Ignored retry title',120,null,'Notes');
    if created->>'title'<>'Idempotent lesson' or
      (select count(*) from public.lessons where id=draft_id)<>1 then
      raise exception 'Lesson creation retry was not idempotent'; end if;
    reservation:=public.begin_curriculum_material(ca,ma,la,'Study handout.pdf','pdf',128);
    rejected:=false;
    begin
      perform public.finish_curriculum_material((reservation->>'id')::uuid);
    exception when raise_exception then
      if sqlerrm<>'Document upload is incomplete' then raise; end if;
      rejected:=true;
    end;
    if not rejected then raise exception 'Missing object was finalized'; end if;
    rejected:=false;
    begin
      perform public.begin_curriculum_material(ca,mb,lb,'Wrong.pdf','pdf',128);
    exception when insufficient_privilege then rejected:=true; end;
    if not rejected then raise exception 'Cross-course lesson accepted'; end if;
    perform public.link_curriculum_assessment(ca,ma,la,'quiz',q);
    perform public.link_curriculum_assessment(ca,ma,la,'quiz',q);
    if (select count(*) from public.curriculum_assessment_links where quiz_id=q)<>1 then
      raise exception 'Duplicate link was created'; end if;
    rejected:=false;
    begin
      perform public.link_curriculum_assessment(ca,ma,la,'quiz',qb);
    exception when raise_exception then
      if sqlerrm not like 'Choose a draft quiz%' then raise; end if;
      rejected:=true;
    end;
    if not rejected then raise exception 'Cross-course quiz accepted'; end if;
    perform public.link_curriculum_assessment(ca,ma,la,'assignment',a);
    execute 'reset role';
    insert into storage.objects(bucket_id,name,metadata) values('course-materials',reservation->>'object_path',
      jsonb_build_object('size',128,'mimetype','application/pdf'));
    perform set_config('request.jwt.claim.sub',s::text,true);
    execute 'set local role authenticated';
    if exists(select 1 from public.curriculum_materials where id=(reservation->>'id')::uuid) then
      raise exception 'Student can read an unfinished document'; end if;
    if exists(select 1 from public.curriculum_assessment_links where course_id=ca) then
      raise exception 'Student can read draft assessments'; end if;
    if not public.can_access_curriculum(ca,ma,la) or public.can_access_curriculum(cb,mb,lb) then
      raise exception 'Enrollment access is incorrect'; end if;
    rejected:=false;
    begin
      perform public.begin_curriculum_material(ca,ma,la,'Student.pdf','pdf',128);
    exception when insufficient_privilege then rejected:=true; end;
    if not rejected then raise exception 'Student can upload teaching material'; end if;
    execute 'reset role';
    perform set_config('request.jwt.claim.sub',t::text,true);
    execute 'set local role authenticated';
    perform public.finish_curriculum_material((reservation->>'id')::uuid);
    insert into public.quiz_questions(quiz_id,display_order,question_text,options)
      values(q,0,'Test?',array['A','B']) returning id into question;
    insert into public.quiz_answer_keys(question_id,correct_option_index) values(question,0);
    update public.quizzes set status='published' where id=q;
    update public.assignments set status='published' where id=a;
    perform set_config('request.jwt.claim.sub',s::text,true);
    if not exists(select 1 from public.curriculum_materials where id=(reservation->>'id')::uuid) then
      raise exception 'Enrolled student cannot read finalized document'; end if;
    if (select count(*) from public.curriculum_assessment_links where course_id=ca)<>2 then
      raise exception 'Published linked assessments are missing'; end if;
    if exists(select 1 from public.quiz_answer_keys where question_id=question) then
      raise exception 'Quiz answer key leaked'; end if;
    delete from public.curriculum_assessment_links where course_id=ca;
    if (select count(*) from public.curriculum_assessment_links where course_id=ca)<>2 then
      raise exception 'Student can unlink an assessment'; end if;
    raise exception 'ROLLBACK CURRICULUM TEST';
  exception when raise_exception then
    if sqlerrm<>'ROLLBACK CURRICULUM TEST' then raise; end if;
  end;
end;
$$;
