do $$
declare
  v_student uuid;
  v_teacher uuid;
  v_course uuid;
  v_assignment uuid;
  v_bad_assignment uuid;
  v_submission public.assignment_submissions%rowtype;
  v_count integer;
  v_bucket storage.buckets%rowtype;
begin
  select * into v_bucket from storage.buckets where id = 'assignment-submissions';
  if not found or v_bucket.public or v_bucket.file_size_limit <> 26214400 then
    raise exception 'Private assignment bucket is not configured';
  end if;
  select e.student_id, c.instructor_id, c.id into v_student, v_teacher, v_course
  from public.enrollments e join public.courses c on c.id = e.course_id
  join public.profiles p on p.id = e.student_id
  where e.status = 'active' and p.role = 'student'
  limit 1;
  if v_student is null then
    raise exception 'A retained active student enrollment is required';
  end if;
  begin
    insert into public.assignments (course_id, title, instructions, due_at, status)
    values (v_course, 'RLS history test', 'Temporary test', now() + interval '1 day', 'published')
    returning id into v_assignment;
    insert into public.assignments (course_id, title, instructions, due_at, status)
    values (v_course, 'RLS invalid object test', 'Temporary test', now() + interval '1 day', 'published')
    returning id into v_bad_assignment;
    perform set_config('request.jwt.claim.sub', v_student::text, true);
    execute 'set local role authenticated';
    v_submission := public.submit_assignment(v_assignment, 'First version', '[]'::jsonb);
    perform set_config('request.jwt.claim.sub', v_teacher::text, true);
    perform public.review_assignment(v_submission.id, 'disapproved', 'Revise');
    perform set_config('request.jwt.claim.sub', v_student::text, true);
    v_submission := public.submit_assignment(v_assignment, 'Second version', '[]'::jsonb);
    select count(*) into v_count from public.assignment_submission_revisions
      where submission_id = v_submission.id;
    if v_count <> 2 then
      raise exception 'Resubmission erased revision history';
    end if;
    begin
      perform public.submit_assignment(v_bad_assignment, '', '[]'::jsonb);
      raise exception 'Empty submission was accepted';
    exception when raise_exception then
      if sqlerrm <> 'Provide a response or up to three attachments' then raise; end if;
    end;
    begin
      perform public.submit_assignment(v_bad_assignment, '', jsonb_build_array(
        jsonb_build_object('path', v_student::text || '/' || v_bad_assignment::text || '/' || gen_random_uuid()::text || '.pdf', 'name', 'missing.pdf')
      ));
      raise exception 'Missing Storage object was accepted';
    exception when raise_exception then
      if sqlerrm <> 'Attachment is unavailable' then raise; end if;
    end;
    raise exception 'Rollback attachment test writes';
  exception when raise_exception then
    if sqlerrm <> 'Rollback attachment test writes' then raise; end if;
  end;
end;
$$;
