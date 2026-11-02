create or replace function public.finish_quiz_session(p_session_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.quiz_sessions; q public.quizzes; question record; review jsonb:='[]';
  attempt uuid; total integer; v_score integer:=0; selected integer;
begin
  -- Lock the parent first, matching start/resume and avoiding lock inversion.
  select * into s from public.quiz_sessions where id=p_session_id and student_id=auth.uid();
  if not found then raise exception 'Attempt unavailable' using errcode='42501'; end if;
  select * into q from public.quizzes where id=s.quiz_id for share;
  select * into s from public.quiz_sessions where id=p_session_id and student_id=auth.uid() for update;
  if not found then raise exception 'Attempt unavailable' using errcode='42501'; end if;
  if s.attempt_id is not null then return public.get_quiz_attempt_review(s.attempt_id); end if;
  if q.status<>'published' or (q.course_id is not null and not exists(select 1 from public.enrollments
    where course_id=q.course_id and student_id=auth.uid() and status in ('active','completed'))) then
    raise exception 'Quiz unavailable' using errcode='42501';
  end if;
  total:=jsonb_array_length(s.question_snapshot);
  if total=0 then raise exception 'Quiz unavailable'; end if;
  insert into public.quiz_attempts(quiz_id,student_id,score,total_questions)
    values(q.id,auth.uid(),0,total) returning id into attempt;
  for question in select * from jsonb_to_recordset(s.question_snapshot)
    as x(id uuid,question_text text,options jsonb,correct_option_index integer,explanation text) loop
    selected:=(s.answers->>question.id::text)::integer;
    if selected=question.correct_option_index then v_score:=v_score+1; end if;
    insert into public.quiz_attempt_answers(attempt_id,question_id,selected_option_index,is_correct)
      select attempt,question.id,selected,coalesce(selected=question.correct_option_index,false)
      where exists(select 1 from public.quiz_questions where id=question.id);
    review:=review||jsonb_build_array(to_jsonb(question)||jsonb_build_object('selected_option_index',selected));
  end loop;
  update public.quiz_attempts a set score=v_score,passing_score=s.passing_score,
    review_snapshot=jsonb_build_object('quiz_title',s.quiz_title,'questions',review) where a.id=attempt;
  update public.quiz_sessions set attempt_id=attempt where id=s.id;
  return public.get_quiz_attempt_review(attempt);
end;
$$;

create or replace function public.reconcile_course_completion(p_student_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  -- Serialize requirement events so a concurrently approved final requirement
  -- observes committed lesson/quiz progress before deciding completion.
  perform e.id from public.enrollments e where e.student_id=p_student_id
    and e.status in ('active','completed') order by e.id for update;
  -- Access status remains active: completion is a separate durable achievement.
  -- This preserves media, assessment and download access after completion.
  insert into public.course_completions(enrollment_id,student_id,course_id,
    student_name,course_title,instructor_name)
  select e.id,e.student_id,e.course_id,s.display_name,c.title,t.display_name
    from public.course_requirements(p_student_id) r
    join public.enrollments e on e.course_id=r.course_id and e.student_id=p_student_id
    join public.courses c on c.id=e.course_id
    join public.profiles s on s.id=e.student_id join public.profiles t on t.id=c.instructor_id
    where r.is_complete and c.status='published'
    on conflict(student_id,course_id) do nothing;
  update public.enrollments e set completed_at=c.completed_at
    from public.course_completions c where e.id=c.enrollment_id and e.completed_at is null;
end;
$$;
