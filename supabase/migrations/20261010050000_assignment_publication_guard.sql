-- Preserve the assignment students answered after the first submission.
create or replace function public.guard_assignment_publication()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and old.status = 'published' and exists (
    select 1 from public.assignment_submissions s where s.assignment_id = old.id
  ) and (
    new.status is distinct from old.status or
    new.title is distinct from old.title or
    new.instructions is distinct from old.instructions or
    new.due_at is distinct from old.due_at
  ) then
    raise exception 'Assignments with submissions cannot be changed';
  end if;
  if new.status = 'published' then
    if new.due_at <= now() then
      raise exception 'Assignment due date must be in the future';
    end if;
    if tg_op = 'INSERT' or old.status = 'draft' then
      new.published_at = now();
    end if;
  else
    new.published_at = null;
  end if;
  return new;
end;
$$;
