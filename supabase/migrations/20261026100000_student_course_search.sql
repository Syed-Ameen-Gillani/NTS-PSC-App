-- Public course search returns IDs only. Course details remain protected by
-- the normal courses/modules/lessons policies when the client loads each page.
create function public.search_published_courses(
  p_query text default '',
  p_limit integer default 20,
  p_offset integer default 0
)
returns table(course_id uuid)
language sql stable security invoker set search_path = '' as $$
  select c.id
  from public.courses c
  join public.categories category on category.id = c.category_id
  left join public.public_teacher_profiles teacher on teacher.id = c.instructor_id
  cross join (select lower(trim(coalesce(p_query, ''))) as text) search
  where c.status = 'published'
    and (
      search.text = ''
      or position(search.text in lower(c.title)) > 0
      or position(search.text in lower(c.description)) > 0
      or position(search.text in lower(category.name)) > 0
      or position(search.text in lower(coalesce(teacher.display_name, ''))) > 0
    )
  order by c.published_at desc, c.id
  limit least(greatest(coalesce(p_limit, 20), 1), 50)
  offset greatest(coalesce(p_offset, 0), 0)
$$;

revoke all on function public.search_published_courses(text, integer, integer)
  from public;
grant execute on function public.search_published_courses(text, integer, integer)
  to anon, authenticated;
