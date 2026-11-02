-- Subscribe only to tables whose existing SELECT policies scope learner data.
do $$
declare name text;
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    foreach name in array array['assignment_submissions','quiz_attempts','course_completions','lesson_progress'] loop
      if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime'
        and schemaname='public' and tablename=name) then
        execute format('alter publication supabase_realtime add table public.%I',name);
      end if;
    end loop;
  end if;
end;
$$;
