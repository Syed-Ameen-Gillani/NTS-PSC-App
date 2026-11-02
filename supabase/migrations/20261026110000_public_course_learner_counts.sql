-- Public aggregate only: no learner identity or enrollment row is exposed.
create function public.get_public_course_learner_counts(p_course_ids uuid[])
returns table(course_id uuid, learner_count bigint)
language plpgsql stable security definer set search_path = '' as $$
begin
  if coalesce(cardinality(p_course_ids), 0) > 200 then
    raise exception 'Request at most 200 courses at a time';
  end if;
  return query
    select c.id, count(e.id)
    from public.courses c
    left join public.enrollments e on e.course_id = c.id
      and e.status in ('active', 'completed')
    where c.id = any(coalesce(p_course_ids, '{}'::uuid[]))
      and c.status = 'published'
    group by c.id;
end;
$$;

revoke all on function public.get_public_course_learner_counts(uuid[])
  from public;
grant execute on function public.get_public_course_learner_counts(uuid[])
  to anon, authenticated;
