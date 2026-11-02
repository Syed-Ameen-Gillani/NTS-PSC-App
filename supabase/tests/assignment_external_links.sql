do $$
declare
  teacher uuid;
  course uuid;
  assignment uuid;
begin
  begin
    select c.id, c.instructor_id into course, teacher
      from public.courses c
      join public.profiles p on p.id = c.instructor_id
      where p.role = 'teacher' and p.display_name like '%TEST%'
      limit 1;
    if teacher is null then raise exception 'Retained test teacher course required'; end if;
    if not has_column_privilege('authenticated', 'public.assignments', 'external_url', 'INSERT') or
       not has_column_privilege('authenticated', 'public.assignments', 'external_url', 'UPDATE') then
      raise exception 'Assignment link write grants are missing';
    end if;

    perform set_config('request.jwt.claim.sub', teacher::text, true);
    execute 'set local role authenticated';
    insert into public.assignments (course_id, title, instructions, external_url, due_at)
      values (course, 'Link test', 'Review the source.', 'https://example.com/task', now() + interval '2 days')
      returning id into assignment;
    if (select external_url from public.assignments where id = assignment) <> 'https://example.com/task' then
      raise exception 'Assignment link was not saved';
    end if;
    update public.assignments set external_url = 'https://example.com/revised' where id = assignment;
    update public.assignments set status = 'published' where id = assignment;
    if (select external_url from public.assignments where id = assignment) <> 'https://example.com/revised' then
      raise exception 'Published assignment lost its link';
    end if;
    begin
      insert into public.assignments (course_id, title, instructions, external_url, due_at)
        values (course, 'Invalid link', 'Review the source.', 'http://example.com', now() + interval '2 days');
      raise exception 'Non-HTTPS assignment link was accepted';
    exception when check_violation then null;
    end;
    raise exception 'Rollback assignment link tests';
  exception when raise_exception then
    if sqlerrm <> 'Rollback assignment link tests' then raise; end if;
  end;
end;
$$;
