-- Synthetic learner and course; the inner block rolls back every fixture write.
do $test$
declare
  teacher uuid:=gen_random_uuid(); student uuid:=gen_random_uuid();
  course uuid:=gen_random_uuid(); category text; enrollment uuid;
  first_lesson uuid; later_lesson uuid; waived_lesson uuid;
  first_activity uuid; later_activity uuid; waived_activity uuid;
begin
  begin
    insert into auth.users(id,email,raw_user_meta_data) values
      (teacher,'independent-teacher-'||teacher||'@example.invalid','{"requested_role":"teacher"}'),
      (student,'independent-student-'||student||'@example.invalid','{}');
    select name into category from public.categories where is_active order by id limit 1;
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    perform public.create_priced_course_draft(course,category,'INDEPENDENT LESSON FIXTURE',
      'Independent completion validation',
      '[{"title":"Module","lessons":[
        {"title":"First reading","duration_seconds":60,"notes":"Read the first lesson"},
        {"title":"Later reading","duration_seconds":60,"notes":"Read the later lesson"},
        {"title":"Waived reading","duration_seconds":60,"notes":"Read the waived lesson"}
      ]}]',0);
    select l.id into first_lesson from public.lessons l join public.course_modules m on m.id=l.module_id
      where m.course_id=course and l.title='First reading';
    select l.id into later_lesson from public.lessons l join public.course_modules m on m.id=l.module_id
      where m.course_id=course and l.title='Later reading';
    select l.id into waived_lesson from public.lessons l join public.course_modules m on m.id=l.module_id
      where m.course_id=course and l.title='Waived reading';
    insert into storage.objects(bucket_id,name,owner_id,metadata)
      values('course-thumbnails',teacher||'/'||course||'/fixture.png',teacher::text,
        '{"size":100,"mimetype":"image/png"}');
    update public.courses set image_path=teacher||'/'||course||'/fixture.png' where id=course;
    perform public.publish_course_changes(course);
    select id into first_activity from public.lesson_activity_placements where lesson_id=first_lesson and kind='reading';
    select id into later_activity from public.lesson_activity_placements where lesson_id=later_lesson and kind='reading';
    select id into waived_activity from public.lesson_activity_placements where lesson_id=waived_lesson and kind='reading';
    if first_activity is null or later_activity is null or waived_activity is null then
      raise exception 'Reading activities missing from release'; end if;
    perform set_config('request.jwt.claim.sub',student::text,true);
    execute 'set local role authenticated';
    enrollment:=public.enroll_free_course(course);
    if not public.can_open_lesson(course,first_lesson)
      or not public.can_open_lesson(course,later_lesson)
      or not public.can_open_lesson(course,waived_lesson) then
      raise exception 'Enrollment did not unlock released lessons'; end if;
    execute 'reset role';
    insert into public.learning_access_grandfathering(enrollment_id,lesson_id,reason)
      values(enrollment,waived_lesson,'fixture access waiver');
    perform public.reconcile_course_completion(student);
    if exists(select 1 from public.lesson_progress where enrollment_id=enrollment
      and lesson_id=waived_lesson and completed_at is not null) then
      raise exception 'Access waiver manufactured completion'; end if;
    insert into public.learning_activity_progress(enrollment_id,activity_id,content_version,completed_at)
      values(enrollment,later_activity,
        public.learning_activity_descriptor(later_lesson,later_activity)->>'version',now());
    perform public.reconcile_course_completion(student);
    if not exists(select 1 from public.lesson_progress where enrollment_id=enrollment
        and lesson_id=later_lesson and completed_at is not null)
      or exists(select 1 from public.lesson_progress where enrollment_id=enrollment
        and lesson_id=first_lesson and completed_at is not null)
      or exists(select 1 from public.course_completions where enrollment_id=enrollment) then
      raise exception 'Out-of-order completion or course gate incorrect'; end if;
    insert into public.learning_activity_progress(enrollment_id,activity_id,content_version,completed_at)
      values(enrollment,waived_activity,
        public.learning_activity_descriptor(waived_lesson,waived_activity)->>'version',now());
    perform public.reconcile_course_completion(student);
    if not exists(select 1 from public.lesson_progress where enrollment_id=enrollment
      and lesson_id=waived_lesson and completed_at is not null) then
      raise exception 'Real evidence could not complete waived lesson'; end if;
    insert into public.learning_activity_progress(enrollment_id,activity_id,content_version,completed_at)
      values(enrollment,first_activity,
        public.learning_activity_descriptor(first_lesson,first_activity)->>'version',now());
    perform public.reconcile_course_completion(student);
    if not exists(select 1 from public.course_completions where enrollment_id=enrollment) then
      raise exception 'All completed lessons did not finish the course'; end if;
    raise exception using errcode='ZX041',message='Fixture checks passed';
  exception when sqlstate 'ZX041' then null; end;
  if exists(select 1 from auth.users where id in (teacher,student)) then
    raise exception 'Fixture rollback failed'; end if;
end $test$;
