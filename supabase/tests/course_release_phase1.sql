-- Isolated identities and all fixture writes roll back, including on failure.
do $test$
declare teacher uuid:=gen_random_uuid(); student uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid();
  course uuid:=gen_random_uuid(); mod1 uuid:=gen_random_uuid(); mod2 uuid:=gen_random_uuid();
  reading uuid:=gen_random_uuid(); mixed uuid:=gen_random_uuid(); quiz uuid; assignment uuid;
  link uuid; material uuid:=gen_random_uuid(); category uuid; cover text; release1 uuid;
  before_manifest jsonb; items jsonb; n integer; prevented boolean; activity_count integer;
  combination integer; combo_lesson uuid; combo_module uuid:=gen_random_uuid();
begin
  begin
    insert into auth.users(id,email,raw_user_meta_data) values
      (teacher,'release-teacher-'||teacher||'@example.invalid','{"requested_role":"teacher"}'),
      (student,'release-student-'||student||'@example.invalid','{}'),
      (outsider,'release-other-'||outsider||'@example.invalid','{"requested_role":"teacher"}');
    select id into category from public.categories where is_active order by id limit 1;
    if category is null then raise exception 'An active category is required'; end if;
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    insert into public.courses(id,instructor_id,category_id,title,description)
      values(course,teacher,category,'PHASE1 ROLLBACK FIXTURE','Release validation');
    cover:=teacher||'/'||course||'/fixture.png';
    insert into storage.objects(bucket_id,name,owner_id,metadata)
      values('course-thumbnails',cover,teacher::text,'{"size":100,"mimetype":"image/png"}');
    update public.courses set image_path=cover where id=course;
    insert into public.course_modules(id,course_id,title,display_order) values
      (mod1,course,'Reading module',0),(mod2,course,'Assessment module',1);
    insert into public.lessons(id,module_id,title,notes,duration_seconds,display_order) values
      (reading,mod1,'Reading','Original published reading',300,0),
      (mixed,mod2,'Quiz and assignment','',300,0);
    quiz:=public.save_teacher_quiz(null,'Fixture quiz','General','Easy',10,60,false,false,
      '[{"question_text":"Choose A","options":["A","B"],"correct_option_index":0,"explanation":"A"}]');
    insert into public.assignments(course_id,title,instructions,due_at)
      values(course,'Fixture assignment','Read and respond',now()+interval '30 days') returning id into assignment;
    perform public.link_curriculum_assessment(course,mod2,mixed,'quiz',quiz);
    perform public.link_curriculum_assessment(course,mod2,mixed,'assignment',assignment);
    select id into link from public.curriculum_assessment_links where lesson_id=mixed and quiz_id=quiz;
    insert into public.curriculum_materials(id,course_id,module_id,lesson_id,title,object_path,mime_type,size_bytes,status)
      values(material,course,mod1,reading,'Fixture text',teacher||'/'||course||'/'||material||'.txt','text/plain',10,'ready');
    insert into storage.objects(bucket_id,name,owner_id,metadata)
      select 'course-materials',object_path,teacher::text,'{"size":10,"mimetype":"text/plain"}' from public.curriculum_materials where id=material;
    insert into public.enrollments(student_id,course_id) values(student,course);

    execute 'set local role authenticated';
    if not public.publish_course_changes(course) then raise exception 'Initial publish did not change release'; end if;
    execute 'reset role';
    select active_release_id into release1 from public.courses where id=course;
    select manifest into before_manifest from public.course_releases where id=release1;
    -- Student inspection below is of their current module after the first reading.
    insert into public.lesson_progress(enrollment_id,lesson_id,completed_at)
      select e.id,reading,now() from public.enrollments e where e.student_id=student and e.course_id=course;
    if jsonb_array_length(before_manifest->'modules')<>2 then raise exception 'Assessment-only module not released'; end if;
    if (select count(*) from public.get_public_course_outline(array[course]))<>2 then raise exception 'Outline is incomplete'; end if;
    select count(*) into activity_count from public.lesson_activity_placements where lesson_id=mixed;
    perform public.sync_lesson_activity_placements(mixed);
    if (select count(*) from public.lesson_activity_placements where lesson_id=mixed)<>activity_count then
      raise exception 'Backfill is not idempotent'; end if;

    -- Draft ordering/required edits are invisible until the next release.
    select jsonb_agg(jsonb_build_object('id',id,'required',kind='quiz') order by display_order desc)
      into items from public.lesson_activity_placements where lesson_id=mixed and not is_retired;
    execute 'set local role authenticated';
    perform public.configure_lesson_activities(mixed,items);
    perform public.stage_curriculum_details('lesson',reading,'{"notes":"Private draft reading"}');
    perform public.stage_curriculum_details('module',mod2,'{"title":"Updated assessment module"}');
    perform public.reorder_curriculum(course,null,array[mod2,mod1]);
    perform public.unlink_curriculum_assessment(link);
    perform public.stage_curriculum_removal('material',material);
    if (select count(*) from public.get_teacher_lesson_activity_drafts(array[course]))<>2 then
      raise exception 'Owner activity projection is incomplete'; end if;
    if exists(select 1 from public.curriculum_assessment_links where id=link) then raise exception 'Owner still sees pending unlink'; end if;
    execute 'reset role';

    perform set_config('request.jwt.claim.sub',student::text,true);
    execute 'set local role authenticated';
    if exists(select 1 from public.curriculum_draft_changes where course_id=course) then raise exception 'Draft reading leaked'; end if;
    if exists(select 1 from public.get_teacher_lesson_activity_drafts(array[course])) then
      raise exception 'Owner activity drafts leaked to student'; end if;
    if not exists(select 1 from public.lessons where id=reading and notes='Original published reading') then raise exception 'Student lost previous reading'; end if;
    if not exists(select 1 from public.curriculum_assessment_links where id=link) then raise exception 'Pending unlink changed student release'; end if;
    if not exists(select 1 from public.curriculum_materials where id=material) then raise exception 'Pending material removal changed student release'; end if;
    prevented:=false;
    begin perform public.publish_course_changes(course); exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Student published teacher content'; end if;
    execute 'reset role';

    perform set_config('request.jwt.claim.sub',outsider::text,true);
    execute 'set local role authenticated';
    prevented:=false;
    begin perform public.stage_curriculum_details('lesson',reading,'{"notes":"Unauthorized"}');
      exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Other teacher changed course'; end if;
    execute 'reset role';
    if (select manifest from public.course_releases where id=release1)<>before_manifest then
      raise exception 'Draft editing changed immutable release'; end if;

    perform set_config('request.jwt.claim.sub',teacher::text,true);
    execute 'set local role authenticated';
    prevented:=false;
    begin perform public.publish_course_changes(course);
      exception when raise_exception then
        if sqlerrm like 'Each released lesson%' then prevented:=true; else raise; end if;
    end;
    if not prevented then raise exception 'Lesson without required work was released'; end if;
    execute 'reset role';
    if (select active_release_id from public.courses where id=course)<>release1 then
      raise exception 'Failed publish did not roll back'; end if;
    select jsonb_agg(jsonb_build_object('id',id,'required',true) order by display_order)
      into items from public.lesson_activity_placements where lesson_id=mixed and not is_retired;
    execute 'set local role authenticated';
    perform public.configure_lesson_activities(mixed,items);
    perform public.publish_course_changes(course);
    execute 'reset role';
    set constraints all immediate;
    set constraints all deferred;
    if (select title from public.get_public_course_outline(array[course]) where lesson_id=reading)<>'Reading' then
      raise exception 'Unexpected outline title'; end if;
    if (select notes from public.lessons where id=reading)<>'Private draft reading' then raise exception 'Reading changes not published'; end if;
    if (select module_order from public.get_public_course_outline(array[course]) where lesson_id=mixed)<>0 then
      raise exception 'Staged order not published'; end if;
    if not exists(select 1 from public.curriculum_assessment_links where id=link and is_retired and not is_released) then
      raise exception 'Unlink was not committed at publication'; end if;
    if not public.course_source_is_released('material',material) then raise exception 'Historical file reference lost'; end if;

    -- Relinking restores the same placement; previous release stays immutable.
    execute 'set local role authenticated';
    perform public.link_curriculum_assessment(course,mod2,mixed,'quiz',quiz);
    perform public.publish_course_changes(course);
    if public.publish_course_changes(course) then raise exception 'No-op publish created a release'; end if;
    execute 'reset role';
    if (select count(*) from public.curriculum_assessment_links where lesson_id=mixed and quiz_id=quiz)<>1 then
      raise exception 'Relink duplicated placement'; end if;

    -- Both RLS and privileged delete paths preserve real submission records.
    insert into public.assignment_submissions(assignment_id,student_id) values(assignment,student);
    execute 'set local role authenticated';
    delete from public.assignments where id=assignment;
    get diagnostics n=row_count;
    if n<>0 then raise exception 'Owner deleted submitted assignment'; end if;
    execute 'reset role';
    prevented:=false;
    begin delete from public.assignments where id=assignment; exception when foreign_key_violation then prevented:=true; end;
    if not prevented then raise exception 'Privileged delete removed submission history'; end if;
    prevented:=false;
    begin update public.course_releases set manifest='{}' where id=release1;
      exception when check_violation then prevented:=true; end;
    if not prevented then raise exception 'Published manifest was mutable'; end if;
    prevented:=false;
    begin insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,quiz_id)
      values(course,mod1,mixed,quiz);
      exception when check_violation then prevented:=true; end;
    if not prevented then raise exception 'Mismatched lesson scope was accepted'; end if;

    -- All supported source combinations use the same authoring/release path.
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    insert into public.course_modules(id,course_id,title,display_order)
      values(combo_module,course,'Activity combinations',2);
    for combination in 1..7 loop
      combo_lesson:=gen_random_uuid();
      perform public.create_curriculum_lesson(combo_lesson,combo_module,'Combination '||combination,300,
        case when combination in (1,4,7) then 'https://example.invalid/fixture.mp4' else null end,
        case when combination in (2,5,7) then 'Required reading' else '' end);
      if combination in (3,4,5,6,7) then
        perform public.link_curriculum_assessment(course,combo_module,combo_lesson,'quiz',quiz);
      end if;
      if combination in (6,7) then
        perform public.link_curriculum_assessment(course,combo_module,combo_lesson,'assignment',assignment);
      end if;
    end loop;
    execute 'set local role authenticated';
    perform public.publish_course_changes(course);
    execute 'reset role';
    if (select count(*) from public.get_public_course_outline(array[course]) where module_id=combo_module)<>7 then
      raise exception 'A supported activity combination failed publication'; end if;

    execute 'set local role anon';
    if (select count(*) from public.get_public_course_outline(array[course]))<>9 then raise exception 'Anonymous outline incomplete'; end if;
    prevented:=false;
    begin perform manifest from public.course_releases where id=release1;
      exception when insufficient_privilege then prevented:=true; end;
    if not prevented then raise exception 'Anonymous user read private manifest'; end if;
    execute 'reset role';
    raise exception using errcode='ZX001',message='PHASE1_RELEASE_TESTS_PASSED';
  exception when sqlstate 'ZX001' then
    raise notice 'PHASE1_RELEASE_TESTS_PASSED — isolated fixtures rolled back';
  end;
end;
$test$;
