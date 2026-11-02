select jsonb_build_object(
  'phase2_migrations',(select count(*) from supabase_migrations.schema_migrations
    where version between '20261026150000' and '20261026153000'),
  'enrollments',(select count(*) from public.enrollments),
  'completions',(select count(*) from public.course_completions),
  'audited_access_operations',(select count(*) from public.enrollment_access_audit),
  'frontier_waivers',(select count(*) from public.learning_access_grandfathering),
  'fixture_accounts_remaining',(select count(*) from auth.users where email like 'access-%@example.invalid'),
  'anonymous_admin_execute',has_function_privilege('anon','public.admin_set_course_access(uuid,uuid,uuid,boolean,text,text)','EXECUTE'),
  'authenticated_admin_execute',has_function_privilege('authenticated','public.admin_set_course_access(uuid,uuid,uuid,boolean,text,text)','EXECUTE'),
  'legacy_completion_execute',has_function_privilege('authenticated','public.record_lesson_completion_before_access(uuid,uuid,boolean)','EXECUTE'),
  'client_enrollment_insert',has_table_privilege('authenticated','public.enrollments','INSERT'),
  'client_enrollment_update',has_table_privilege('authenticated','public.enrollments','UPDATE'),
  'course_price_summary',(select jsonb_agg(to_jsonb(s)) from (
    select currency,count(*) courses,min(price_amount) minimum_price,max(price_amount) maximum_price
    from public.courses group by currency) s)
) as phase2_health;
