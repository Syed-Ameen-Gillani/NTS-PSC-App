do $$
declare teacher uuid; student uuid; category uuid; course_a uuid:=gen_random_uuid();
  course_b uuid:=gen_random_uuid(); session_a uuid; session_b uuid;
begin
  begin
    select id into teacher from public.profiles where role='teacher' and display_name like '%TEST%' limit 1;
    select id into student from public.profiles where role='student' and display_name like '%TEST%' limit 1;
    select id into category from public.categories where is_active limit 1;
    if teacher is null or student is null then raise exception 'Retained test profiles required'; end if;
    insert into public.courses(id,instructor_id,category_id,title) values
      (course_a,teacher,category,'LIVE TEST A'),(course_b,teacher,category,'LIVE TEST B');
    insert into public.enrollments(student_id,course_id) values(student,course_a);
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    execute 'set local role authenticated';
    insert into public.live_sessions(course_id,title,meeting_url,starts_at,duration_minutes)
      values(course_a,'Test A','https://meet.google.com/test',now()+interval '1 hour',60) returning id into session_a;
    insert into public.live_sessions(course_id,title,meeting_url,starts_at,duration_minutes)
      values(course_b,'Test B','https://meet.google.com/test',now()+interval '1 hour',60) returning id into session_b;
    execute 'reset role';
    if not exists(select 1 from public.push_outbox where session_id=session_a and user_id=student) then
      raise exception 'Enrolled student notification was not queued';
    end if;
    if exists(select 1 from public.push_outbox where session_id=session_b and user_id=student) then
      raise exception 'Non-enrolled student notification was queued';
    end if;
    perform set_config('request.jwt.claim.sub',student::text,true);
    execute 'set local role authenticated';
    if not exists(select 1 from public.live_sessions where id=session_a) or
       exists(select 1 from public.live_sessions where id=session_b) then
      raise exception 'Live session enrollment isolation failed';
    end if;
    update public.live_sessions set cancelled=true where id=session_a;
    if found then raise exception 'Student cancelled teacher session'; end if;
    perform public.register_push_device('audit-test-token-not-a-real-device','android');
    raise exception 'Rollback live tests';
  exception when raise_exception then
    if sqlerrm <> 'Rollback live tests' then raise; end if;
  end;
end;
$$;
