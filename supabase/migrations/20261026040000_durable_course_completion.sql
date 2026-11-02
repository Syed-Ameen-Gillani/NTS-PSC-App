-- Authoritative current eligibility; issuance/history is a separate concern.
create function public.course_requirements(p_student_id uuid)
returns table(course_id uuid,lessons_remaining bigint,quizzes_remaining bigint,
  assignments_remaining bigint,is_complete boolean)
language sql stable security definer set search_path='' as $$
  with enrolled as (
    select e.id,e.course_id from public.enrollments e
    where e.student_id=p_student_id and e.status in ('active','completed')
  ), counts as (
    select e.course_id,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
       where m.course_id=e.course_id and l.status='published') as lesson_total,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
       where m.course_id=e.course_id and l.status='published' and not exists(
         select 1 from public.lesson_progress p where p.enrollment_id=e.id
           and p.lesson_id=l.id and p.completed_at is not null)) as lessons_remaining,
      (select count(distinct q.id) from public.curriculum_assessment_links links
       join public.quizzes q on q.id=links.quiz_id
       where links.course_id=e.course_id and not exists(
         select 1 from public.quiz_attempts a where a.quiz_id=q.id and a.student_id=p_student_id
           and a.score::numeric*100/a.total_questions >= a.passing_score)) as quizzes_remaining,
      (select count(distinct a.id) from public.curriculum_assessment_links links
       join public.assignments a on a.id=links.assignment_id
       where links.course_id=e.course_id and not exists(
         select 1 from public.assignment_submissions s where s.assignment_id=a.id
           and s.student_id=p_student_id and s.status='approved')) as assignments_remaining
    from enrolled e
  ) select course_id,lessons_remaining,quizzes_remaining,assignments_remaining,
      lesson_total>0 and lessons_remaining=0 and quizzes_remaining=0 and assignments_remaining=0
    from counts;
$$;
revoke all on function public.course_requirements(uuid) from public,anon,authenticated;

create table public.course_completions (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null unique references public.enrollments(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  completed_at timestamptz not null default now(),
  policy_version integer not null default 1,
  student_name text not null, course_title text not null, instructor_name text not null,
  unique(student_id,course_id)
);
alter table public.course_completions enable row level security;
revoke all on public.course_completions from anon,authenticated;
grant select on public.course_completions to authenticated;
create policy course_completion_owner on public.course_completions for select to authenticated
  using(student_id=(select auth.uid()) or exists(select 1 from public.courses c
    where c.id=course_id and c.instructor_id=(select auth.uid())));

create function public.reconcile_course_completion(p_student_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
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
revoke all on function public.reconcile_course_completion(uuid) from public,anon,authenticated;

create or replace function public.get_my_course_eligibility()
returns table(course_id uuid,lessons_remaining bigint,quizzes_remaining bigint,
  assignments_remaining bigint,is_complete boolean)
language plpgsql security definer set search_path='' as $$
begin
  perform public.reconcile_course_completion(auth.uid());
  return query select r.course_id,
    case when c.id is null then r.lessons_remaining else 0::bigint end,
    case when c.id is null then r.quizzes_remaining else 0::bigint end,
    case when c.id is null then r.assignments_remaining else 0::bigint end,
    c.id is not null
  from public.course_requirements(auth.uid()) r left join public.course_completions c
    on c.course_id=r.course_id and c.student_id=auth.uid();
end;
$$;

create function public.on_learning_requirement_changed()
returns trigger language plpgsql security definer set search_path='' as $$
declare student uuid;
begin
  if tg_table_name='lesson_progress' then
    select student_id into student from public.enrollments where id=new.enrollment_id;
  else student:=new.student_id; end if;
  perform public.reconcile_course_completion(student);
  return new;
end;
$$;
revoke all on function public.on_learning_requirement_changed() from public,anon,authenticated;
create trigger completion_after_lesson after insert or update on public.lesson_progress
  for each row execute function public.on_learning_requirement_changed();
create trigger completion_after_quiz after insert or update on public.quiz_attempts
  for each row execute function public.on_learning_requirement_changed();
create trigger completion_after_assignment after insert or update on public.assignment_submissions
  for each row execute function public.on_learning_requirement_changed();

create or replace function public.get_teacher_learner_roster(
  p_limit integer default 50,
  p_offset integer default 0,
  p_query text default null,
  p_course_id uuid default null
)
returns table(
  enrollment_id uuid,
  student_id uuid,
  student_name text,
  course_id uuid,
  course_title text,
  enrolled_at timestamptz,
  enrollment_status text
)
language plpgsql stable security definer set search_path = '' as $$
declare
  v_query text := nullif(left(trim(coalesce(p_query, '')), 100), '');
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'teacher'
  ) then
    raise exception 'Teacher account required' using errcode = '42501';
  end if;

  return query
    select e.id, e.student_id, p.display_name, c.id, c.title,
      e.enrolled_at, case when e.completed_at is not null then 'completed' else e.status end
    from public.enrollments e
    join public.courses c on c.id = e.course_id
    join public.profiles p on p.id = e.student_id
    where c.instructor_id = auth.uid()
      and e.status in ('active', 'completed')
      and (p_course_id is null or c.id = p_course_id)
      and (v_query is null or p.display_name ilike '%' || v_query || '%'
        or c.title ilike '%' || v_query || '%')
    order by e.enrolled_at desc, e.id desc
    limit least(greatest(coalesce(p_limit, 50), 1), 100)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;
