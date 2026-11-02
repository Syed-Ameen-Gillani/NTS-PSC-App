-- Read-only, aggregate baseline. No learner identities, titles or file paths.
select jsonb_build_object(
  'migrations', (select jsonb_agg(version order by version)
    from supabase_migrations.schema_migrations),
  'tables', (select jsonb_agg(jsonb_build_object('name', c.relname,
    'rls', c.relrowsecurity) order by c.relname)
    from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind='r'),
  'columns', (select jsonb_agg(jsonb_build_object('table', table_name,
    'column', column_name, 'type', data_type, 'nullable', is_nullable)
    order by table_name, ordinal_position) from information_schema.columns
    where table_schema='public' and table_name in
    ('courses','course_modules','lessons','curriculum_materials',
     'curriculum_assessment_links','enrollments','lesson_progress',
     'course_completions','certificates')),
  'policies', (select jsonb_agg(jsonb_build_object('table', tablename,
    'name', policyname, 'roles', roles, 'command', cmd,
    'using', qual, 'check', with_check) order by tablename, policyname)
    from pg_policies where schemaname in ('public','storage')),
  'functions', (select jsonb_agg(jsonb_build_object('name', p.proname,
    'arguments', pg_get_function_identity_arguments(p.oid),
    'definition', pg_get_functiondef(p.oid),
    'authenticated_execute', has_function_privilege('authenticated',p.oid,'EXECUTE'),
    'anonymous_execute', has_function_privilege('anon',p.oid,'EXECUTE'))
    order by p.proname, p.oid)
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f'
      and p.proname ~ '(lesson|curriculum|course|quiz|assignment|certificate|enroll)'),
  'grants', (select jsonb_agg(to_jsonb(g) order by table_name, grantee, privilege_type)
    from information_schema.role_table_grants g
    where table_schema='public' and grantee in ('anon','authenticated')),
  'buckets', (select jsonb_agg(jsonb_build_object('name',name,'public',public)
    order by name) from storage.buckets),
  'course_summary', (select jsonb_agg(to_jsonb(s)) from (
    select status,currency,count(*) courses,
      count(*) filter(where price_amount>0) paid_courses,
      min(price_amount) minimum_price,max(price_amount) maximum_price
    from public.courses group by status,currency order by status,currency) s),
  'published_outline', (select jsonb_agg(to_jsonb(s) order by course_key) from (
    select md5(c.id::text) course_key,
      (select count(*) from public.course_modules m where m.course_id=c.id) modules,
      (select count(*) from public.course_modules m where m.course_id=c.id
        and m.release_status='published') released_modules,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
        where m.course_id=c.id and l.status='published') published_lessons,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
        where m.course_id=c.id and l.status='draft') draft_lessons,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
        where m.course_id=c.id and l.status='draft'
        and l.video_path is null and l.external_video_url is null and trim(l.notes)=''
        and exists(select 1 from public.curriculum_assessment_links a where a.lesson_id=l.id))
        draft_assessment_only_lessons
    from public.courses c where c.status='published') s),
  'placement_scopes', (select jsonb_agg(to_jsonb(s)) from (
    select case when lesson_id is not null then 'lesson'
      when module_id is not null then 'module' else 'course' end scope,
      is_released,count(*) links from public.curriculum_assessment_links
    group by 1,2 order by 1,2) s),
  'baseline', jsonb_build_object(
    'enrollments',(select count(*) from public.enrollments),
    'progress_rows',(select count(*) from public.lesson_progress),
    'completed_lessons',(select count(*) from public.lesson_progress where completed_at is not null),
    'earned_completions',(select count(*) from public.course_completions),
    'quiz_attempts',(select count(*) from public.quiz_attempts),
    'assignment_submissions',(select count(*) from public.assignment_submissions)),
  'integrity',jsonb_build_object(
    'cross_course_progress',(select count(*) from public.lesson_progress p
      join public.enrollments e on e.id=p.enrollment_id
      join public.lessons l on l.id=p.lesson_id join public.course_modules m on m.id=l.module_id
      where e.course_id<>m.course_id),
    'incorrect_lesson_link_scope',(select count(*) from public.curriculum_assessment_links a
      join public.lessons l on l.id=a.lesson_id join public.course_modules m on m.id=l.module_id
      where a.course_id<>m.course_id or a.module_id is distinct from m.id))
) as learning_phase0_audit;
