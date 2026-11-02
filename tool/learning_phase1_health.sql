select jsonb_build_object(
  'phase1_migrations',(select count(*) from supabase_migrations.schema_migrations
    where version between '20261026140000' and '20261026145000'),
  'published_courses',(select count(*) from public.courses where status='published'),
  'active_releases',(select count(*) from public.courses c join public.course_releases r
    on r.id=c.active_release_id and r.course_id=c.id where c.status='published'),
  'placements',(select count(*) from public.lesson_activity_placements),
  'draft_changes',(select count(*) from public.curriculum_draft_changes),
  'duplicate_source_placements',(select count(*) from (select lesson_id,source_key
    from public.lesson_activity_placements group by 1,2 having count(*)>1) x),
  'fixture_accounts_remaining',(select count(*) from auth.users
    where email like 'release-%@example.invalid'),
  'completions',(select count(*) from public.course_completions),
  'enrollments',(select count(*) from public.enrollments),
  'private_rls_tables',(select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname in ('course_releases','course_release_sources',
      'curriculum_draft_changes','lesson_activity_placements') and c.relrowsecurity)
) as phase1_health;
