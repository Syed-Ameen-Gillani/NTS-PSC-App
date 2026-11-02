-- The public lesson policy checks enrollments. Postgres requires table-level
-- SELECT permission to evaluate that check, even for anonymous preview reads.
-- No anon SELECT policy exists on enrollments, so RLS still returns zero rows.
grant select on public.enrollments to anon;
