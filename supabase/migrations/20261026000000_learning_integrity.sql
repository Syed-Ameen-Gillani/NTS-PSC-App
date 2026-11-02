-- Additive learning fixes. Existing enrollment outcomes remain unchanged.
begin;

create function public.enroll_free_course(p_course_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_enrollment public.enrollments; v_course public.courses;
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='student') then
    raise exception 'Student access required' using errcode='42501';
  end if;
  select * into v_course from public.courses where id=p_course_id for share;
  if not found or v_course.status<>'published' or v_course.price_amount<>0 then
    raise exception 'Course unavailable for free enrollment';
  end if;
  insert into public.enrollments(student_id,course_id)
    values(auth.uid(),p_course_id) on conflict(student_id,course_id) do nothing;
  select * into v_enrollment from public.enrollments
    where student_id=auth.uid() and course_id=p_course_id for update;
  if v_enrollment.status='cancelled' then
    raise exception 'Enrollment access has been cancelled' using errcode='42501';
  end if;
  return v_enrollment.id;
end;
$$;
revoke all on function public.enroll_free_course(uuid) from public,anon;
grant execute on function public.enroll_free_course(uuid) to authenticated;

-- Preserve the configured pass threshold for historical results.
alter table public.quiz_attempts add column passing_score integer;
update public.quiz_attempts a set passing_score=q.passing_score
  from public.quizzes q where q.id=a.quiz_id;
alter table public.quiz_attempts alter column passing_score set not null;
alter table public.quiz_attempts add constraint quiz_attempt_pass_range
  check(passing_score between 0 and 100);
create function public.snapshot_quiz_pass_threshold()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  select passing_score into new.passing_score from public.quizzes where id=new.quiz_id;
  return new;
end;
$$;
revoke all on function public.snapshot_quiz_pass_threshold() from public,anon,authenticated;
create trigger quiz_attempt_threshold before insert on public.quiz_attempts
  for each row execute function public.snapshot_quiz_pass_threshold();

alter function public.get_quiz_attempt_review(uuid) rename to get_quiz_attempt_review_internal;
revoke all on function public.get_quiz_attempt_review_internal(uuid) from public,anon,authenticated;
create function public.get_quiz_attempt_review(p_attempt_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_result jsonb; v_attempt public.quiz_attempts;
begin
  v_result := public.get_quiz_attempt_review_internal(p_attempt_id);
  select * into v_attempt from public.quiz_attempts
    where id=p_attempt_id and student_id=auth.uid();
  return v_result || jsonb_build_object('passing_score',v_attempt.passing_score,
    'passed',v_attempt.score::numeric*100/v_attempt.total_questions >= v_attempt.passing_score);
end;
$$;
revoke all on function public.get_quiz_attempt_review(uuid) from public,anon;
grant execute on function public.get_quiz_attempt_review(uuid) to authenticated;

-- The existing single-attempt policy is retained; retrying a committed request
-- recovers its result instead of creating another attempt or reporting failure.
alter function public.submit_quiz(uuid,jsonb) rename to submit_quiz_internal;
revoke all on function public.submit_quiz_internal(uuid,jsonb) from public,anon,authenticated;
create function public.submit_quiz(p_quiz_id uuid,p_answers jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_attempt uuid; v_result jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
  perform 1 from public.quizzes where id=p_quiz_id for update;
  select id into v_attempt from public.quiz_attempts
    where quiz_id=p_quiz_id and student_id=auth.uid();
  if v_attempt is null then
    v_result := public.submit_quiz_internal(p_quiz_id,p_answers);
    v_attempt := (v_result->>'attempt_id')::uuid;
  end if;
  return public.get_quiz_attempt_review(v_attempt);
end;
$$;
revoke all on function public.submit_quiz(uuid,jsonb) from public,anon;
grant execute on function public.submit_quiz(uuid,jsonb) to authenticated;

create function public.record_lesson_completion(p_course_id uuid,p_lesson_id uuid,p_completed boolean)
returns void language plpgsql security definer set search_path='' as $$
declare v_enrollment uuid;
begin
  if p_completed is null then raise exception 'Completion is required'; end if;
  select id into v_enrollment from public.enrollments
    where student_id=auth.uid() and course_id=p_course_id and status='active' for update;
  if v_enrollment is null or not exists(select 1 from public.lessons l
    join public.course_modules m on m.id=l.module_id join public.courses c on c.id=m.course_id
    where l.id=p_lesson_id and c.id=p_course_id and l.status='published' and c.status='published') then
    raise exception 'Lesson access unavailable' using errcode='42501';
  end if;
  insert into public.lesson_progress(enrollment_id,lesson_id,completed_at,last_viewed_at)
    values(v_enrollment,p_lesson_id,case when p_completed then now() end,now())
    on conflict(enrollment_id,lesson_id) do update
    set completed_at=case when p_completed then coalesce(public.lesson_progress.completed_at,excluded.completed_at) end,
        last_viewed_at=excluded.last_viewed_at;
end;
$$;
revoke all on function public.record_lesson_completion(uuid,uuid,boolean) from public,anon;
grant execute on function public.record_lesson_completion(uuid,uuid,boolean) to authenticated;
-- Keep completion timestamps and membership checks under the guarded RPC.
revoke insert(enrollment_id,lesson_id,resume_seconds,watched_seconds,completed_at,last_viewed_at)
  on public.lesson_progress from authenticated;
revoke update(resume_seconds,watched_seconds,completed_at,last_viewed_at)
  on public.lesson_progress from authenticated;
commit;
