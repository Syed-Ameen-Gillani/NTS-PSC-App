do $$
declare
  teacher uuid;
  student uuid;
  course uuid;
  expected bigint;
  actual bigint;
begin
  select c.id,c.instructor_id into course,teacher from public.courses c
    join public.profiles p on p.id=c.instructor_id
    where p.role='teacher' and p.display_name like '%TEST%' limit 1;
  select p.id into student from public.profiles p
    where p.role='student' and p.display_name like '%TEST%' limit 1;
  if teacher is null or student is null then
    raise exception 'Retained teacher and student test profiles required';
  end if;

  perform set_config('request.jwt.claim.sub',teacher::text,true);
  execute 'set local role authenticated';
  select count(distinct e.student_id) into expected from public.enrollments e
    where e.course_id=course and e.status in ('active','completed');
  select c.learner_count into actual
    from public.get_teacher_course_learner_counts() c where c.course_id=course;
  if actual is distinct from expected then
    raise exception 'Course learner count does not match active enrollments';
  end if;
  if exists(
    select 1 from public.get_teacher_learner_roster(100,0,null,null) r
    join public.courses c on c.id=r.course_id
    where c.instructor_id<>teacher
  ) then
    raise exception 'Teacher roster exposed another instructor course';
  end if;

  perform set_config('request.jwt.claim.sub',student::text,true);
  begin
    perform 1 from public.get_teacher_learner_roster(50,0,null,null);
    raise exception 'Student read teacher roster';
  exception when insufficient_privilege then null;
  end;
end;
$$;
