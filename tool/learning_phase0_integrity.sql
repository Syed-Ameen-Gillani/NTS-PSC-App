-- Read-only follow-up: durable-history fingerprints and historical outline gaps.
select jsonb_build_object(
  'history_fingerprints', (select jsonb_object_agg(name,fingerprint) from (
    select 'course_completions' name,
      md5(coalesce(string_agg(to_jsonb(t)::text,'' order by t.id),'')) fingerprint
      from public.course_completions t
    union all select 'lesson_progress',
      md5(coalesce(string_agg(to_jsonb(t)::text,'' order by t.id),''))
      from public.lesson_progress t
    union all select 'quiz_attempts',
      md5(coalesce(string_agg(to_jsonb(t)::text,'' order by t.id),''))
      from public.quiz_attempts t
    union all select 'assignment_submissions',
      md5(coalesce(string_agg(to_jsonb(t)::text,'' order by t.id),''))
      from public.assignment_submissions t
  ) s),
  'empty_published_course_enrollments', (select count(*) from public.enrollments e
    join public.courses c on c.id=e.course_id where c.status='published'
    and not exists(select 1 from public.course_modules m where m.course_id=c.id)),
  'stored_certificate_objects', (select count(*) from storage.objects
    where bucket_id='course-certificates'),
  'assignment_delete_granted',has_table_privilege('authenticated','public.assignments','DELETE'),
  'assignment_submission_fk', (select jsonb_agg(pg_get_constraintdef(oid))
    from pg_constraint where conrelid='public.assignment_submissions'::regclass
      and contype='f'),
  'assessment_only_draft_modules',(select count(distinct m.id)
    from public.course_modules m join public.lessons l on l.module_id=m.id
    join public.courses c on c.id=m.course_id
    where c.status='published' and m.release_status='draft'
      and l.status='draft' and l.video_path is null and l.external_video_url is null
      and trim(l.notes)='' and exists(select 1 from public.curriculum_assessment_links a
        where a.lesson_id=l.id)),
  'unreleased_link_statuses',(select jsonb_agg(to_jsonb(s)) from (
    select case when a.quiz_id is not null then 'quiz' else 'assignment' end kind,
      coalesce(q.status,x.status) assessment_status,l.status lesson_status,
      m.release_status module_status,count(*) placements
    from public.curriculum_assessment_links a
    left join public.quizzes q on q.id=a.quiz_id
    left join public.assignments x on x.id=a.assignment_id
    left join public.lessons l on l.id=a.lesson_id
    left join public.course_modules m on m.id=a.module_id
    where not a.is_released group by 1,2,3,4) s)
) as learning_phase0_integrity;
