-- A correlated outer reference is essential: unqualified id resolved to s.id.
-- The definer helper also avoids assignments -> submissions -> assignments RLS recursion.
create function public.assignment_has_submission_history(p_assignment uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.assignment_submissions s where s.assignment_id=p_assignment);
$$;
revoke all on function public.assignment_has_submission_history(uuid) from public,anon;
grant execute on function public.assignment_has_submission_history(uuid) to authenticated;
drop policy assignments_teacher_delete on public.assignments;
create policy assignments_teacher_delete on public.assignments
for delete to authenticated using (
  exists(select 1 from public.courses c where c.id=assignments.course_id
    and c.instructor_id=(select auth.uid()))
  and not public.assignment_has_submission_history(assignments.id)
);

create function public.guard_assessment_history_delete()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_table_name='assignments' then
    if exists(select 1 from public.assignment_submissions s where s.assignment_id=old.id) then
      raise exception 'Assignments with submissions must be retained' using errcode='23503';
    end if;
  elsif exists(select 1 from public.quiz_attempts a where a.quiz_id=old.id)
    or exists(select 1 from public.quiz_sessions s where s.quiz_id=old.id) then
    raise exception 'Quizzes with learning history must be retained' using errcode='23503';
  end if;
  return old;
end;
$$;
create trigger assignment_history_delete before delete on public.assignments
for each row execute function public.guard_assessment_history_delete();
create trigger quiz_history_delete before delete on public.quizzes
for each row execute function public.guard_assessment_history_delete();
revoke all on function public.guard_assessment_history_delete() from public,anon,authenticated;
