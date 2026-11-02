-- Public syllabus metadata is separate from enrollment-protected lesson content.
create or replace function public.get_public_course_syllabus(p_course_ids uuid[])
returns table (
  course_id uuid, module_id uuid, lesson_id uuid, title text,
  duration_seconds integer, display_order integer
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if coalesce(cardinality(p_course_ids), 0) > 200 then
    raise exception 'Request at most 200 courses at a time';
  end if;
  return query
    select c.id, m.id, l.id, l.title, l.duration_seconds, l.display_order
    from public.courses c
    join public.course_modules m on m.course_id = c.id
    join public.lessons l on l.module_id = m.id
    where c.id = any(coalesce(p_course_ids, '{}'::uuid[]))
      and c.status = 'published' and l.status = 'published'
    order by c.id, m.display_order, l.display_order, l.id;
end;
$$;
revoke all on function public.get_public_course_syllabus(uuid[]) from public;
grant execute on function public.get_public_course_syllabus(uuid[]) to anon, authenticated;
comment on function public.get_public_course_syllabus(uuid[]) is
  'Published syllabus titles and durations only; never returns video paths, URLs, notes, or transcripts.';
