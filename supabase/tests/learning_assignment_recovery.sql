do $$
declare teacher uuid; student uuid; category uuid; course uuid:=gen_random_uuid();
  assignment uuid; request uuid:=gen_random_uuid(); result jsonb; again jsonb;
begin
  select id into teacher from public.profiles where role='teacher' and display_name like '%TEST%' limit 1;
  select id into student from public.profiles where role='student' and display_name like '%TEST%' limit 1;
  select id into category from public.categories where is_active limit 1;
  if teacher is null or student is null then raise exception 'TEST profiles required'; end if;
  insert into public.courses(id,instructor_id,category_id,title) values(course,teacher,category,'RECOVERY TEST');
  insert into public.enrollments(student_id,course_id) values(student,course);
  insert into public.assignments(course_id,title,instructions,due_at,status)
    values(course,'RECOVERY TEST','Write a response',now()+interval '1 day','published') returning id into assignment;
  perform set_config('request.jwt.claim.sub',student::text,true);
  execute 'set local role authenticated';
  result:=public.submit_assignment_request(request,assignment,'First response','[]');
  again:=public.submit_assignment_request(request,assignment,'First response','[]');
  if result->>'id'<>again->>'id' or (again->>'current_revision')::int<>1 then
    raise exception 'Repeated request created a new submission'; end if;
  perform set_config('request.jwt.claim.sub',teacher::text,true);
  perform public.review_assignment((result->>'id')::uuid,'disapproved','Please revise');
  perform set_config('request.jwt.claim.sub',student::text,true);
  again:=public.submit_assignment_request(gen_random_uuid(),assignment,'Revised response','[]');
  if (again->>'current_revision')::int<>2 or
    (select count(*) from public.assignment_submission_revisions where submission_id=(result->>'id')::uuid)<>2 then
    raise exception 'Revision history was not retained'; end if;
  perform set_config('request.jwt.claim.sub',teacher::text,true);
  perform public.review_assignment((result->>'id')::uuid,'approved','Accepted');
  perform set_config('request.jwt.claim.sub',student::text,true);
  begin
    perform public.submit_assignment_request(gen_random_uuid(),assignment,'Third response','[]');
    raise exception 'Approved submission was revised';
  exception when raise_exception then
    if sqlerrm<>'Submission cannot be revised' then raise; end if;
  end;
  execute 'reset role';
end;
$$;
