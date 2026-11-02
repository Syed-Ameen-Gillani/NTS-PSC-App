-- Serialize inserts for the same course, including direct table writes.
-- Existing modules above the limit remain readable/editable but cannot grow.
create function public.guard_module_lesson_limit()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform 1 from public.course_modules m
    join public.courses c on c.id = m.course_id
    where m.id = new.module_id for update of c;
  if (select count(*) from public.lessons l where l.module_id = new.module_id) >= 10 then
    raise exception 'A module can have up to 10 lessons' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger lessons_module_limit
before insert on public.lessons
for each row execute function public.guard_module_lesson_limit();
