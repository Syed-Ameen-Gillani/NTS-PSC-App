-- Assignment content is teacher-owned; submission and review writes use guarded RPCs.

create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  instructions text not null check (length(trim(instructions)) > 0),
  due_at timestamptz not null,
  status text not null default 'draft' check (status in ('draft', 'published')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint assignment_publication_time check (
    (status = 'draft' and published_at is null) or
    (status = 'published' and published_at is not null)
  )
);

create table public.assignment_submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'disapproved')),
  current_revision integer not null default 1 check (current_revision > 0),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewer_id uuid references public.profiles (id),
  feedback text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (assignment_id, student_id)
);

create table public.assignment_submission_revisions (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.assignment_submissions (id) on delete cascade,
  revision_number integer not null check (revision_number > 0),
  response text not null check (length(trim(response)) > 0),
  submitted_at timestamptz not null default now(),
  unique (submission_id, revision_number)
);

create table public.assignment_reviews (
  id uuid primary key default gen_random_uuid(),
  revision_id uuid not null unique references public.assignment_submission_revisions (id) on delete cascade,
  reviewer_id uuid not null references public.profiles (id),
  decision text not null check (decision in ('approved', 'disapproved')),
  feedback text not null default '',
  reviewed_at timestamptz not null default now(),
  check (decision <> 'disapproved' or length(trim(feedback)) > 0)
);

create index assignments_course_status_due_idx on public.assignments (course_id, status, due_at);
create index assignment_submissions_student_idx on public.assignment_submissions (student_id, submitted_at desc);
create index assignment_submissions_assignment_status_idx on public.assignment_submissions (assignment_id, status);
create index assignment_revisions_submission_idx on public.assignment_submission_revisions (submission_id, revision_number desc);

create trigger assignments_updated_at before update on public.assignments
for each row execute function public.set_updated_at();
create trigger assignment_submissions_updated_at before update on public.assignment_submissions
for each row execute function public.set_updated_at();

create function public.guard_assignment_publication()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'published' then
    if new.due_at <= now() then
      raise exception 'Assignment due date must be in the future';
    end if;
    if tg_op = 'INSERT' or old.status = 'draft' then
      new.published_at = now();
    end if;
  else
    if tg_op = 'UPDATE' and old.status = 'published' and exists (
      select 1 from public.assignment_submissions s where s.assignment_id = old.id
    ) then
      raise exception 'Assignments with submissions cannot be unpublished';
    end if;
    new.published_at = null;
  end if;
  return new;
end;
$$;

create trigger assignments_publication before insert or update on public.assignments
for each row execute function public.guard_assignment_publication();

alter table public.assignments enable row level security;
alter table public.assignment_submissions enable row level security;
alter table public.assignment_submission_revisions enable row level security;
alter table public.assignment_reviews enable row level security;

revoke all on public.assignments, public.assignment_submissions,
  public.assignment_submission_revisions, public.assignment_reviews from anon, authenticated;
grant select on public.assignments, public.assignment_submissions,
  public.assignment_submission_revisions, public.assignment_reviews to authenticated;
grant insert (course_id, title, instructions, due_at, status) on public.assignments to authenticated;
grant update (title, instructions, due_at, status) on public.assignments to authenticated;
grant delete on public.assignments to authenticated;

create policy assignments_read on public.assignments for select to authenticated
using (
  exists (
    select 1 from public.courses c where c.id = course_id
      and c.instructor_id = (select auth.uid())
  ) or (
    status = 'published' and exists (
      select 1 from public.enrollments e where e.course_id = course_id
        and e.student_id = (select auth.uid()) and e.status = 'active'
    )
  )
);
create policy assignments_teacher_insert on public.assignments for insert to authenticated
with check (exists (
  select 1 from public.courses c where c.id = course_id
    and c.instructor_id = (select auth.uid())
));
create policy assignments_teacher_update on public.assignments for update to authenticated
using (exists (
  select 1 from public.courses c where c.id = course_id
    and c.instructor_id = (select auth.uid())
)) with check (exists (
  select 1 from public.courses c where c.id = course_id
    and c.instructor_id = (select auth.uid())
));
create policy assignments_teacher_delete on public.assignments for delete to authenticated
using (exists (
  select 1 from public.courses c where c.id = course_id
    and c.instructor_id = (select auth.uid())
) and not exists (
  select 1 from public.assignment_submissions s where s.assignment_id = id
));

create policy assignment_submissions_read on public.assignment_submissions
for select to authenticated using (
  student_id = (select auth.uid()) or exists (
    select 1 from public.assignments a join public.courses c on c.id = a.course_id
    where a.id = assignment_id and c.instructor_id = (select auth.uid())
  )
);
create policy assignment_revisions_read on public.assignment_submission_revisions
for select to authenticated using (exists (
  select 1 from public.assignment_submissions s where s.id = submission_id
));
create policy assignment_reviews_read on public.assignment_reviews
for select to authenticated using (exists (
  select 1 from public.assignment_submission_revisions r where r.id = revision_id
));

create function public.submit_assignment(p_assignment_id uuid, p_response text)
returns public.assignment_submissions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_assignment public.assignments%rowtype;
  v_submission public.assignment_submissions%rowtype;
begin
  if v_user is null or length(trim(coalesce(p_response, ''))) = 0 then
    raise exception 'Sign in and provide a response';
  end if;
  select * into v_assignment from public.assignments where id = p_assignment_id for update;
  if not found or v_assignment.status <> 'published' or v_assignment.due_at <= now() then
    raise exception 'Assignment is unavailable';
  end if;
  if not exists (
    select 1 from public.profiles p where p.id = v_user and p.role = 'student'
  ) or not exists (
    select 1 from public.enrollments e where e.course_id = v_assignment.course_id
      and e.student_id = v_user and e.status = 'active'
  ) then
    raise exception 'Active student enrollment required';
  end if;

  select * into v_submission from public.assignment_submissions
  where assignment_id = p_assignment_id and student_id = v_user for update;
  if found then
    if v_submission.status <> 'disapproved' then
      raise exception 'Submission cannot be revised';
    end if;
    update public.assignment_submissions
    set status = 'pending', current_revision = current_revision + 1,
      submitted_at = now(), reviewed_at = null, reviewer_id = null, feedback = ''
    where id = v_submission.id returning * into v_submission;
  else
    insert into public.assignment_submissions (assignment_id, student_id)
    values (p_assignment_id, v_user) returning * into v_submission;
  end if;
  insert into public.assignment_submission_revisions
    (submission_id, revision_number, response)
  values (v_submission.id, v_submission.current_revision, trim(p_response));
  return v_submission;
end;
$$;

create function public.review_assignment(
  p_submission_id uuid, p_decision text, p_feedback text default ''
)
returns public.assignment_submissions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_submission public.assignment_submissions%rowtype;
  v_revision_id uuid;
begin
  if v_user is null or p_decision not in ('approved', 'disapproved') or
     (p_decision = 'disapproved' and length(trim(coalesce(p_feedback, ''))) = 0) then
    raise exception 'A valid decision and feedback are required';
  end if;
  select s.* into v_submission from public.assignment_submissions s
  join public.assignments a on a.id = s.assignment_id
  join public.courses c on c.id = a.course_id
  where s.id = p_submission_id and c.instructor_id = v_user
  for update of s;
  if not found or v_submission.status <> 'pending' then
    raise exception 'Pending submission unavailable';
  end if;
  select id into v_revision_id from public.assignment_submission_revisions
  where submission_id = v_submission.id
    and revision_number = v_submission.current_revision;
  insert into public.assignment_reviews (revision_id, reviewer_id, decision, feedback)
  values (v_revision_id, v_user, p_decision, trim(coalesce(p_feedback, '')));
  update public.assignment_submissions
  set status = p_decision, reviewed_at = now(), reviewer_id = v_user,
    feedback = trim(coalesce(p_feedback, ''))
  where id = v_submission.id returning * into v_submission;
  return v_submission;
end;
$$;

revoke all on function public.submit_assignment(uuid, text) from public, anon, authenticated;
revoke all on function public.review_assignment(uuid, text, text) from public, anon, authenticated;
grant execute on function public.submit_assignment(uuid, text) to authenticated;
grant execute on function public.review_assignment(uuid, text, text) to authenticated;
