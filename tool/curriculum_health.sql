select (select jsonb_agg(version) from
  (select version from supabase_migrations.schema_migrations order by version desc limit 3) v) as latest_versions,
  to_regclass('public.curriculum_materials') is not null as materials_installed,
  to_regclass('public.curriculum_assessment_links') is not null as links_installed;
