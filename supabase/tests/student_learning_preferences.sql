-- Run in a transaction with the migration installed. All fixtures roll back.
begin;
select set_config('test.interests_student', gen_random_uuid()::text, true);
select set_config('test.interests_other', gen_random_uuid()::text, true);
select set_config('test.interests_teacher', gen_random_uuid()::text, true);
insert into auth.users(id, email, raw_user_meta_data)
values
  (current_setting('test.interests_student')::uuid, 'interest-test-one@example.invalid', '{"display_name":"Interest test one","requested_role":"student"}'),
  (current_setting('test.interests_other')::uuid, 'interest-test-two@example.invalid', '{"display_name":"Interest test two","requested_role":"student"}'),
  (current_setting('test.interests_teacher')::uuid, 'interest-test-teacher@example.invalid', '{"display_name":"Interest test teacher","requested_role":"teacher"}');

do $$ begin
  assert not exists(select 1 from public.student_learning_preferences where user_id = current_setting('test.interests_student')::uuid), 'New users must require the survey';
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('test.interests_student'), true);
insert into public.student_learning_preferences(user_id, categories, interests, skills)
values (auth.uid(), array['Competitive Exams'], array['CSS'], array['Essay Writing']);
do $$ begin
  assert (select completed_at is not null from public.student_learning_preferences where user_id=auth.uid()), 'Completion must persist';
  begin
    insert into public.student_learning_preferences(user_id, categories, interests)
    values (current_setting('test.interests_other')::uuid, array['Education'], array['Teaching']);
    raise exception 'Cross-account insert was allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.student_learning_preferences set categories=array['Education'], interests=array['CSS'] where user_id=auth.uid();
    raise exception 'An interest from another category was accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    update public.student_learning_preferences set categories='{}', interests='{}' where user_id=auth.uid();
    raise exception 'Empty survey was accepted';
  exception when invalid_parameter_value then null;
  end;
  assert not exists(select 1 from public.recommended_course_ids(100,0) r join public.courses c on c.id=r.course_id where c.status <> 'published'), 'Recommendations exposed drafts';
end $$;

update public.student_learning_preferences
set categories=array['Education'], interests=array['Pedagogy'], skills=array['Lesson Planning']
where user_id=auth.uid();
do $$ begin
  assert (select categories=array['Education'] and interests=array['Pedagogy'] from public.student_learning_preferences where user_id=auth.uid()), 'Pedagogy preferences did not save';
end $$;
update public.student_learning_preferences
set categories=array['Education','Competitions','Competitive Exams']
where user_id=auth.uid();

select set_config('request.jwt.claim.sub', current_setting('test.interests_other'), true);
do $$ begin
  assert not exists(select 1 from public.student_learning_preferences), 'Another student can read preferences';
  update public.student_learning_preferences set skills=array['Changed'] where user_id=current_setting('test.interests_student')::uuid;
  assert not found, 'Another student can update preferences';
end $$;

select set_config('request.jwt.claim.sub', current_setting('test.interests_teacher'), true);
do $$ begin
  begin
    insert into public.student_learning_preferences(user_id,categories,interests)
    values(auth.uid(),array['Education'],array['Teaching']);
    raise exception 'Teacher onboarding was accepted';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select * from public.recommended_course_ids(3,0);
rollback;
