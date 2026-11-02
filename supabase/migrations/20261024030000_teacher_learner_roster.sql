create function public.get_teacher_course_learner_counts()
returns table(course_id uuid, learner_count bigint)
language plpgsql stable security definer set search_path = '' as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'teacher'
  ) then
    raise exception 'Teacher account required' using errcode = '42501';
  end if;

  return query
    select c.id, count(distinct e.student_id)
    from public.courses c
    left join public.enrollments e on e.course_id = c.id
      and e.status in ('active', 'completed')
    where c.instructor_id = auth.uid()
    group by c.id;
end;
$$;

create function public.get_teacher_learner_roster(
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
      e.enrolled_at, e.status
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

revoke all on function public.get_teacher_course_learner_counts(),
  public.get_teacher_learner_roster(integer,integer,text,uuid)
  from public, anon;
grant execute on function public.get_teacher_course_learner_counts(),
  public.get_teacher_learner_roster(integer,integer,text,uuid)
  to authenticated;
