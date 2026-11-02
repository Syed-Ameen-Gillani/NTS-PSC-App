-- Teacher-owned quizzes with separate answer keys and server-scored attempts.
create table public.quizzes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id),
  course_id uuid references public.courses (id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  category text not null default 'General',
  difficulty text not null default 'Medium' check (difficulty in ('Easy', 'Medium', 'Hard')),
  duration_minutes integer not null default 15 check (duration_minutes between 1 and 180),
  passing_score integer not null default 60 check (passing_score between 0 and 100),
  is_ai_generated boolean not null default false,
  status text not null default 'draft' check (status in ('draft', 'published')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((status = 'draft' and published_at is null) or
         (status = 'published' and published_at is not null))
);

create table public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes (id) on delete cascade,
  display_order integer not null check (display_order >= 0),
  question_text text not null check (length(trim(question_text)) > 0),
  options text[] not null check (array_length(options, 1) between 2 and 6),
  unique (quiz_id, display_order)
);

create table public.quiz_answer_keys (
  question_id uuid primary key references public.quiz_questions (id) on delete cascade,
  correct_option_index integer not null check (correct_option_index >= 0),
  explanation text not null default ''
);

create table public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes (id),
  student_id uuid not null references public.profiles (id) on delete cascade,
  score integer not null check (score >= 0),
  total_questions integer not null check (total_questions > 0),
  submitted_at timestamptz not null default now(),
  unique (quiz_id, student_id),
  check (score <= total_questions)
);

create table public.quiz_attempt_answers (
  attempt_id uuid not null references public.quiz_attempts (id) on delete cascade,
  question_id uuid not null references public.quiz_questions (id),
  selected_option_index integer,
  is_correct boolean not null,
  primary key (attempt_id, question_id)
);

create index quizzes_teacher_status_idx on public.quizzes (teacher_id, status, created_at desc);
create index quizzes_course_status_idx on public.quizzes (course_id, status);
create index quiz_questions_quiz_idx on public.quiz_questions (quiz_id, display_order);
create index quiz_attempts_student_idx on public.quiz_attempts (student_id, submitted_at desc);
create index quiz_attempts_quiz_idx on public.quiz_attempts (quiz_id, submitted_at desc);

create trigger quizzes_updated_at before update on public.quizzes
for each row execute function public.set_updated_at();

create function public.guard_quiz_publication()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and old.status = 'published' then
    if row(new.title, new.category, new.difficulty, new.duration_minutes,
      new.passing_score, new.course_id, new.status) is distinct from
      row(old.title, old.category, old.difficulty, old.duration_minutes,
      old.passing_score, old.course_id, old.status) then
      raise exception 'Published quizzes are immutable';
    end if;
  end if;
  if new.status = 'published' and (tg_op = 'INSERT' or old.status = 'draft') then
    if tg_op = 'INSERT' then
      raise exception 'Create a draft before publishing';
    end if;
    if not exists (select 1 from public.quiz_questions q where q.quiz_id = old.id) or
       exists (
         select 1 from public.quiz_questions q
         left join public.quiz_answer_keys k on k.question_id = q.id
         where q.quiz_id = old.id and
           (k.question_id is null or k.correct_option_index >= array_length(q.options, 1))
       ) then
      raise exception 'Quiz questions and answer keys must be complete';
    end if;
    new.published_at = now();
  else
    new.published_at = case when new.status = 'draft' then null else old.published_at end;
  end if;
  return new;
end;
$$;
create trigger quizzes_publication before insert or update on public.quizzes
for each row execute function public.guard_quiz_publication();

create function public.guard_quiz_child_edit()
returns trigger language plpgsql set search_path = '' as $$
declare v_quiz_id uuid;
begin
  if tg_table_name = 'quiz_questions' then
    v_quiz_id = case when tg_op = 'DELETE' then old.quiz_id else new.quiz_id end;
  else
    select q.quiz_id into v_quiz_id from public.quiz_questions q
    where q.id = case when tg_op = 'DELETE' then old.question_id else new.question_id end;
  end if;
  if exists (select 1 from public.quizzes q where q.id = v_quiz_id and q.status = 'published') then
    raise exception 'Published quiz questions are immutable';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;
create trigger quiz_questions_guard before insert or update or delete on public.quiz_questions
for each row execute function public.guard_quiz_child_edit();
create trigger quiz_answer_keys_guard before insert or update or delete on public.quiz_answer_keys
for each row execute function public.guard_quiz_child_edit();

alter table public.quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_answer_keys enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.quiz_attempt_answers enable row level security;
revoke all on public.quizzes, public.quiz_questions, public.quiz_answer_keys,
  public.quiz_attempts, public.quiz_attempt_answers from anon, authenticated;
grant select on public.quizzes, public.quiz_questions, public.quiz_attempts,
  public.quiz_attempt_answers to authenticated;
grant select on public.quiz_answer_keys to authenticated;
grant insert (teacher_id, course_id, title, category, difficulty,
  duration_minutes, passing_score, is_ai_generated) on public.quizzes to authenticated;
grant update (title, category, difficulty, duration_minutes,
  passing_score, status) on public.quizzes to authenticated;
grant insert (quiz_id, display_order, question_text, options),
  update (display_order, question_text, options), delete on public.quiz_questions to authenticated;
grant insert (question_id, correct_option_index, explanation),
  update (correct_option_index, explanation), delete on public.quiz_answer_keys to authenticated;

create policy quizzes_read on public.quizzes for select to authenticated
using (teacher_id = (select auth.uid()) or (
  status = 'published' and (course_id is null or exists (
    select 1 from public.enrollments e where e.course_id = course_id
      and e.student_id = (select auth.uid()) and e.status = 'active'
  ))
));
create policy quizzes_teacher_insert on public.quizzes for insert to authenticated
with check (teacher_id = (select auth.uid()) and status = 'draft' and
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'teacher') and
  (course_id is null or exists (
    select 1 from public.courses c where c.id = course_id and c.instructor_id = (select auth.uid())
  )));
create policy quizzes_teacher_update on public.quizzes for update to authenticated
using (teacher_id = (select auth.uid()) and status = 'draft')
with check (teacher_id = (select auth.uid()) and
  (course_id is null or exists (
    select 1 from public.courses c where c.id = course_id and c.instructor_id = (select auth.uid())
  )));
create policy quiz_questions_read on public.quiz_questions for select to authenticated
using (exists (select 1 from public.quizzes q where q.id = quiz_id));
create policy quiz_questions_teacher_insert on public.quiz_questions for insert to authenticated
with check (exists (select 1 from public.quizzes q where q.id = quiz_id
  and q.teacher_id = (select auth.uid()) and q.status = 'draft'));
create policy quiz_questions_teacher_update on public.quiz_questions for update to authenticated
using (exists (select 1 from public.quizzes q where q.id = quiz_id
  and q.teacher_id = (select auth.uid()) and q.status = 'draft'))
with check (exists (select 1 from public.quizzes q where q.id = quiz_id
  and q.teacher_id = (select auth.uid()) and q.status = 'draft'));
create policy quiz_questions_teacher_delete on public.quiz_questions for delete to authenticated
using (exists (select 1 from public.quizzes q where q.id = quiz_id
  and q.teacher_id = (select auth.uid()) and q.status = 'draft'));
create policy quiz_keys_teacher_read on public.quiz_answer_keys for select to authenticated
using (exists (select 1 from public.quiz_questions qq join public.quizzes q on q.id = qq.quiz_id
  where qq.id = question_id and q.teacher_id = (select auth.uid())));
create policy quiz_keys_teacher_insert on public.quiz_answer_keys for insert to authenticated
with check (exists (select 1 from public.quiz_questions qq join public.quizzes q on q.id = qq.quiz_id
  where qq.id = question_id and q.teacher_id = (select auth.uid()) and q.status = 'draft'));
create policy quiz_keys_teacher_update on public.quiz_answer_keys for update to authenticated
using (exists (select 1 from public.quiz_questions qq join public.quizzes q on q.id = qq.quiz_id
  where qq.id = question_id and q.teacher_id = (select auth.uid()) and q.status = 'draft'));
create policy quiz_keys_teacher_delete on public.quiz_answer_keys for delete to authenticated
using (exists (select 1 from public.quiz_questions qq join public.quizzes q on q.id = qq.quiz_id
  where qq.id = question_id and q.teacher_id = (select auth.uid()) and q.status = 'draft'));
create policy quiz_attempts_read on public.quiz_attempts for select to authenticated
using (student_id = (select auth.uid()) or exists (
  select 1 from public.quizzes q where q.id = quiz_id and q.teacher_id = (select auth.uid())
));
create policy quiz_attempt_answers_read on public.quiz_attempt_answers for select to authenticated
using (exists (select 1 from public.quiz_attempts a where a.id = attempt_id));

create function public.submit_quiz(p_quiz_id uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_quiz public.quizzes%rowtype;
  v_attempt_id uuid;
  v_score integer := 0;
  v_total integer := 0;
  v_selected integer;
  v_question record;
  v_review jsonb := '[]'::jsonb;
begin
  if v_user is null or not exists (
    select 1 from public.profiles p where p.id = v_user and p.role = 'student'
  ) or jsonb_typeof(p_answers) is distinct from 'object' then
    raise exception 'A signed-in student and answer map are required';
  end if;
  select * into v_quiz from public.quizzes where id = p_quiz_id for update;
  if not found or v_quiz.status <> 'published' or (
    v_quiz.course_id is not null and not exists (
      select 1 from public.enrollments e where e.course_id = v_quiz.course_id
        and e.student_id = v_user and e.status = 'active'
    )
  ) then
    raise exception 'Quiz unavailable';
  end if;
  if exists (select 1 from public.quiz_attempts a where a.quiz_id = p_quiz_id and a.student_id = v_user) then
    raise exception 'Quiz has already been submitted';
  end if;
  select count(*) into v_total from public.quiz_questions where quiz_id = p_quiz_id;
  if v_total = 0 then raise exception 'Quiz has no questions'; end if;
  insert into public.quiz_attempts (quiz_id, student_id, score, total_questions)
  values (p_quiz_id, v_user, 0, v_total) returning id into v_attempt_id;
  for v_question in
    select q.id, q.question_text, q.options, q.display_order,
      k.correct_option_index, k.explanation
    from public.quiz_questions q join public.quiz_answer_keys k on k.question_id = q.id
    where q.quiz_id = p_quiz_id order by q.display_order
  loop
    v_selected := null;
    if p_answers ? v_question.id::text then
      v_selected := (p_answers ->> v_question.id::text)::integer;
      if v_selected < 0 or v_selected >= array_length(v_question.options, 1) then
        raise exception 'Answer option is out of range';
      end if;
    end if;
    if v_selected = v_question.correct_option_index then v_score := v_score + 1; end if;
    insert into public.quiz_attempt_answers
      (attempt_id, question_id, selected_option_index, is_correct)
    values (v_attempt_id, v_question.id, v_selected,
      coalesce(v_selected = v_question.correct_option_index, false));
    v_review := v_review || jsonb_build_array(jsonb_build_object(
      'id', v_question.id, 'question_text', v_question.question_text,
      'options', v_question.options, 'correct_option_index', v_question.correct_option_index,
      'explanation', v_question.explanation, 'selected_option_index', v_selected
    ));
  end loop;
  update public.quiz_attempts set score = v_score where id = v_attempt_id;
  return jsonb_build_object('attempt_id', v_attempt_id, 'quiz_id', p_quiz_id,
    'quiz_title', v_quiz.title, 'score', v_score, 'total_questions', v_total,
    'questions', v_review);
end;
$$;
revoke all on function public.submit_quiz(uuid, jsonb) from public, anon, authenticated;
grant execute on function public.submit_quiz(uuid, jsonb) to authenticated;
