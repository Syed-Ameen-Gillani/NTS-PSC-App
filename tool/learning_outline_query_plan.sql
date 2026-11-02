-- Read-only plan/timing output; no course content or student identities returned.
explain (analyze,buffers,format json)
select * from public.get_public_course_outline(array(
 select id from public.courses where status='published' order by id limit 200
));
