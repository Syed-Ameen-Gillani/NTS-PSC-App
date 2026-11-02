select jsonb_build_object(
 'migration_count',(select count(*) from supabase_migrations.schema_migrations),
 'history_counts',jsonb_build_object('enrollments',(select count(*) from public.enrollments),
   'lesson_progress',(select count(*) from public.lesson_progress),
   'course_completions',(select count(*) from public.course_completions),
   'quiz_attempts',(select count(*) from public.quiz_attempts),
   'assignment_submissions',(select count(*) from public.assignment_submissions)),
 'private_table_access',(select jsonb_object_agg(name,has_table_privilege('authenticated','public.'||name,'SELECT'))
   from unnest(array['learning_video_metadata','learning_activity_progress','learning_evidence_sessions',
     'learning_evidence_receipts','learning_engagement_clocks','course_reviews','learning_assessment_waivers']) name),
 'private_helper_execute',(select jsonb_object_agg(signature,has_function_privilege('authenticated','public.'||signature,'EXECUTE'))
   from unnest(array['apply_learning_evidence(jsonb)','apply_learning_evidence_before_retention(jsonb)',
     'learning_activity_descriptor(uuid,uuid)','begin_learning_evidence_before_source(uuid,uuid)',
     'get_learning_outcome_before_state(uuid)','reconcile_course_completion(uuid)',
     'lesson_prerequisites_met(uuid,uuid,uuid)','assessment_link_requirement_met(uuid,uuid)',
     'get_learning_outcome_before_waivers(uuid)']) signature),
 'direct_progress_write',has_table_privilege('authenticated','public.lesson_progress','INSERT,UPDATE,DELETE'),
 'oversized_receipt_windows',(select count(*) from (select session_id from public.learning_evidence_receipts group by session_id having count(*)>100) s),
 'released_required_readings_needing_preparation',(select count(distinct f.id) from public.courses c
   join public.course_releases r on r.id=c.active_release_id
   cross join lateral jsonb_array_elements(r.manifest->'modules') m cross join lateral jsonb_array_elements(m->'lessons') l
   cross join lateral jsonb_array_elements(l->'activities') a join public.curriculum_materials f on f.id=(a->>'material_id')::uuid
   where (a->>'required')::boolean and f.reading_hash is null),
 'installed_extensions',(select jsonb_agg(extname) from pg_extension where extname in ('pg_cron','pg_net')),
 'evidence_cleanup_job',(select jsonb_agg(jsonb_build_object('schedule',schedule,'active',active))
   from cron.job where jobname='cboa-learning-evidence-retention-v1')
) as learning_phase7_health;
