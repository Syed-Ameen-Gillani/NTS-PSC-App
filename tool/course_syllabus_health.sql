select json_build_object(
  'migrations', (select json_agg(version order by version) from supabase_migrations.schema_migrations),
  'published_courses', (select count(*) from public.courses where status='published'),
  'published_lessons', (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
    join public.courses c on c.id=m.course_id where c.status='published' and l.status='published')
) as syllabus_health;
