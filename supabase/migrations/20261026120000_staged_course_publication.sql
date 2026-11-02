-- Published courses remain available while an instructor prepares additions.
alter table public.course_modules
  add column release_status text not null default 'draft'
  check (release_status in ('draft', 'published'));

alter table public.courses add column pending_image_path text;
alter table public.lessons
  add column pending_video_removal boolean not null default false;
grant update (pending_image_path) on public.courses to authenticated;
revoke update (status) on public.courses from authenticated;
revoke update (status) on public.lessons from authenticated;
create or replace function public.course_cover_is_unused(p_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select not exists(select 1 from public.courses
    where image_path=p_name or pending_image_path=p_name);
$$;
alter table public.curriculum_materials
  add column is_released boolean not null default false;
alter table public.curriculum_assessment_links
  add column is_released boolean not null default false;

drop policy modules_read on public.course_modules;
create policy modules_read on public.course_modules for select to anon, authenticated
using (exists (
  select 1 from public.courses c where c.id = course_id and (
    c.instructor_id = (select auth.uid()) or
    (c.status = 'published' and release_status = 'published')
  )
));

create or replace function public.can_access_curriculum(
  p_course uuid, p_module uuid default null, p_lesson uuid default null,
  p_manage boolean default false
) returns boolean language sql stable security definer set search_path='' as $$
  select auth.uid() is not null and exists (
    select 1 from public.courses c where c.id=p_course
    and (p_module is null or exists(select 1 from public.course_modules m
      where m.id=p_module and m.course_id=c.id))
    and (p_lesson is null or exists(select 1 from public.lessons l
      where l.id=p_lesson and l.module_id=p_module))
    and (c.instructor_id=auth.uid() or (not p_manage and c.status='published'
      and exists(select 1 from public.enrollments e where e.course_id=c.id
        and e.student_id=auth.uid() and e.status='active')
      and (p_module is null or exists(select 1 from public.course_modules m
        where m.id=p_module and m.release_status='published'))
      and (p_lesson is null or exists(select 1 from public.lessons l
        where l.id=p_lesson and l.status='published'))))
  );
$$;

create or replace function public.guard_course_publication()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.image_path is not null and (tg_op = 'INSERT' or new.image_path is distinct from old.image_path
    or new.status = 'published') then
    if not exists (select 1 from storage.objects o where o.bucket_id = 'course-thumbnails'
      and o.name = new.image_path and split_part(o.name, '/', 1) = new.instructor_id::text
      and split_part(o.name, '/', 2) = new.id::text
      and (o.metadata->>'size')::bigint between 1 and 5242880
      and o.metadata->>'mimetype' in ('image/jpeg', 'image/png', 'image/webp')) then
      raise exception 'Upload a valid course cover before publishing';
    end if;
  end if;
  if new.status <> 'published' then return new; end if;
  if length(trim(new.description)) = 0 or new.image_path is null then
    raise exception 'Add a course description and upload a cover before publishing';
  end if;
  if not exists(select 1 from public.categories where id = new.category_id and is_active) then
    raise exception 'Choose an active course category';
  end if;
  if not exists(select 1 from public.course_modules m join public.lessons l on l.module_id = m.id
    where m.course_id = new.id) then raise exception 'Add a lesson before publishing'; end if;
  return new;
end;
$$;

-- Draft additions may be edited; already released curriculum stays immutable.
create or replace function public.guard_course_curriculum()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_course uuid; v_status text;
begin
  if tg_table_name = 'course_modules' then
    v_course := case when tg_op = 'DELETE' then old.course_id else new.course_id end;
    if tg_op = 'UPDATE' and new.course_id <> old.course_id then
      raise exception 'Cannot move modules between courses';
    end if;
  else
    select course_id into v_course from public.course_modules
      where id = case when tg_op = 'DELETE' then old.module_id else new.module_id end;
    if tg_op = 'UPDATE' and new.module_id <> old.module_id then
      raise exception 'Cannot move lessons between modules';
    end if;
  end if;
  select status into v_status from public.courses where id = v_course for update;
  if v_status = 'published' and current_setting('app.course_release', true) is distinct from 'on' then
    if tg_table_name = 'lessons' then
      if tg_op = 'INSERT' then
        if new.status <> 'draft' then
          raise exception 'New lessons must remain drafts until course changes are published';
        end if;
      elsif old.status = 'published' then
        raise exception 'Published lessons cannot be edited directly';
      end if;
    elsif tg_op <> 'INSERT' then
      if old.release_status = 'published' then
        raise exception 'Published modules cannot be edited directly';
      end if;
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

update public.course_modules m set release_status = 'published'
where exists (
  select 1 from public.courses c where c.id = m.course_id and c.status = 'published'
) and exists (
  select 1 from public.lessons l where l.module_id = m.id and l.status = 'published'
);
update public.curriculum_materials r set is_released = true
where r.status = 'ready' and exists (
  select 1 from public.courses c where c.id = r.course_id and c.status = 'published'
) and (r.module_id is null or exists(select 1 from public.course_modules m
  where m.id=r.module_id and m.release_status='published'))
  and (r.lesson_id is null or exists(select 1 from public.lessons l
    where l.id=r.lesson_id and l.status='published'));
update public.curriculum_assessment_links r set is_released = true
where exists (
  select 1 from public.courses c where c.id = r.course_id and c.status = 'published'
) and (r.module_id is null or exists(select 1 from public.course_modules m
  where m.id=r.module_id and m.release_status='published'))
  and (r.lesson_id is null or exists(select 1 from public.lessons l
    where l.id=r.lesson_id and l.status='published'));

create or replace function public.create_curriculum_lesson(
  p_id uuid,p_module_id uuid,p_title text,p_duration_seconds integer,
  p_external_video_url text default null,p_notes text default ''
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_course uuid; v_owner uuid; v_status text; v_lesson public.lessons; v_order integer;
begin
  select c.id,c.instructor_id,c.status into v_course,v_owner,v_status
    from public.course_modules m join public.courses c on c.id=m.course_id
    where m.id=p_module_id for update of c;
  if v_owner is distinct from auth.uid() or auth.uid() is null then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  select * into v_lesson from public.lessons where id=p_id;
  if found then
    if v_lesson.module_id<>p_module_id then raise exception 'Lesson ID is unavailable'; end if;
    return to_jsonb(v_lesson);
  end if;
  if p_id is null or length(trim(p_title))=0 or p_duration_seconds not between 60 and 36000
    or (nullif(trim(p_external_video_url),'') is not null and
      p_external_video_url !~ '^https://[^/[:space:]]+/.+') then
    raise exception 'Complete the lesson details';
  end if;
  select coalesce(max(display_order),-1)+1 into v_order from public.lessons where module_id=p_module_id;
  insert into public.lessons(id,module_id,title,duration_seconds,external_video_url,notes,display_order,status)
  values(p_id,p_module_id,trim(p_title),p_duration_seconds,nullif(trim(p_external_video_url),''),coalesce(p_notes,''),v_order,
    case when v_status='published' or nullif(trim(p_external_video_url),'') is null
      then 'draft' else 'published' end)
  returning * into v_lesson;
  return to_jsonb(v_lesson);
end;
$$;

-- Reviewed media on a live course is ready to release, but cannot replace
-- the student's currently published video until Publish changes is tapped.
create or replace function public.publish_lesson_media(p_media_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media; v_course_status text;
begin
  select * into v_media from public.lesson_media where id = p_media_id for update;
  if not found or v_media.teacher_id is distinct from auth.uid() or
    v_media.status <> 'needs_review' or jsonb_array_length(v_media.transcript_segments) = 0 then
    raise exception 'Reviewed transcript required';
  end if;
  if not exists(select 1 from storage.objects where bucket_id='lesson-videos'
    and name=v_media.object_path) then raise exception 'The uploaded video is missing'; end if;
  select c.status into v_course_status from public.lessons l
    join public.course_modules m on m.id=l.module_id
    join public.courses c on c.id=m.course_id where l.id=v_media.lesson_id;
  update public.lesson_media set status = 'ready' where id = p_media_id;
  if v_course_status='draft' then
    update public.lessons set video_path=v_media.object_path,
      external_video_url=null,status='published' where id=v_media.lesson_id;
  end if;
end;
$$;

create or replace function public.archive_lesson_media(p_media_id uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media; v_course uuid; v_status text; v_path text;
begin
  select * into v_media from public.lesson_media where id=p_media_id for update;
  if not found or v_media.teacher_id is distinct from auth.uid() or
    not public.can_access_lesson_media(v_media.lesson_id,true) then
    raise exception 'Video is unavailable' using errcode='42501';
  end if;
  if v_media.status='uploading' then
    raise exception 'Wait for the upload to finish before deleting the video';
  end if;
  if v_media.status='archived' then return v_media.object_path; end if;
  select c.id,c.status,l.video_path into v_course,v_status,v_path
  from public.lessons l join public.course_modules m on m.id=l.module_id
  join public.courses c on c.id=m.course_id
  where l.id=v_media.lesson_id for update of c;
  if v_status='published' and v_path=v_media.object_path then
    perform set_config('app.course_release','on',true);
    update public.lessons set pending_video_removal=true where id=v_media.lesson_id;
    return '';
  end if;
  if v_path=v_media.object_path then
    update public.lessons set video_path=null,status='draft'
      where id=v_media.lesson_id;
  end if;
  update public.lesson_media set status='archived' where id=p_media_id;
  return v_media.object_path;
end;
$$;

drop policy lesson_checkpoints_read on public.lesson_checkpoints;
create policy lesson_checkpoints_read on public.lesson_checkpoints for select to authenticated
using (exists(select 1 from public.lesson_media lm where lm.id=media_id and (
  public.can_access_lesson_media(lm.lesson_id,true) or
  (lm.status='ready' and public.lesson_checkpoints.status='approved'
    and exists(select 1 from public.lessons l
      where l.id=lm.lesson_id and l.video_path=lm.object_path)
    and public.can_access_lesson_media(lm.lesson_id)))));

drop policy curriculum_materials_read on public.curriculum_materials;
create policy curriculum_materials_read on public.curriculum_materials for select to authenticated
using ((status='ready' and is_released and
  public.can_access_curriculum(course_id,module_id,lesson_id))
  or public.can_access_curriculum(course_id,module_id,lesson_id,true));
drop policy curriculum_files_read on storage.objects;
create policy curriculum_files_read on storage.objects for select to authenticated using(
  bucket_id='course-materials' and exists(select 1 from public.curriculum_materials r
    where r.object_path=name and ((r.status='ready' and r.is_released and
      public.can_access_curriculum(r.course_id,r.module_id,r.lesson_id)) or
      public.can_access_curriculum(r.course_id,r.module_id,r.lesson_id,true))));

drop policy curriculum_links_read on public.curriculum_assessment_links;
create policy curriculum_links_read on public.curriculum_assessment_links for select to authenticated using(
  public.can_access_curriculum(course_id,module_id,lesson_id,true) or (
    is_released and public.can_access_curriculum(course_id,module_id,lesson_id) and (
      exists(select 1 from public.quizzes q where q.id=quiz_id
        and q.course_id=curriculum_assessment_links.course_id and q.status='published') or
      exists(select 1 from public.assignments a where a.id=assignment_id
        and a.course_id=curriculum_assessment_links.course_id and a.status='published'))));

create or replace function public.course_requirements(p_student_id uuid)
returns table(course_id uuid,lessons_remaining bigint,quizzes_remaining bigint,
  assignments_remaining bigint,is_complete boolean)
language sql stable security definer set search_path='' as $$
  with enrolled as (
    select e.id,e.course_id from public.enrollments e
    where e.student_id=p_student_id and e.status in ('active','completed')
  ), counts as (
    select e.course_id,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
       where m.course_id=e.course_id and l.status='published') as lesson_total,
      (select count(*) from public.lessons l join public.course_modules m on m.id=l.module_id
       where m.course_id=e.course_id and l.status='published' and not exists(
         select 1 from public.lesson_progress p where p.enrollment_id=e.id
           and p.lesson_id=l.id and p.completed_at is not null)) as lessons_remaining,
      (select count(distinct q.id) from public.curriculum_assessment_links links
       join public.quizzes q on q.id=links.quiz_id
       where links.course_id=e.course_id and links.is_released and q.status='published'
         and not exists(select 1 from public.quiz_attempts a
           where a.quiz_id=q.id and a.student_id=p_student_id
           and a.score::numeric*100/a.total_questions >= a.passing_score)) as quizzes_remaining,
      (select count(distinct a.id) from public.curriculum_assessment_links links
       join public.assignments a on a.id=links.assignment_id
       where links.course_id=e.course_id and links.is_released and a.status='published'
         and not exists(select 1 from public.assignment_submissions s
           where s.assignment_id=a.id and s.student_id=p_student_id
             and s.status='approved')) as assignments_remaining
    from enrolled e
  ) select course_id,lessons_remaining,quizzes_remaining,assignments_remaining,
      lesson_total>0 and lessons_remaining=0 and quizzes_remaining=0 and assignments_remaining=0
    from counts;
$$;

-- One transaction changes the student-facing release. Unready drafts stay hidden.
create function public.publish_course_changes(p_course_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare v_course public.courses; v_changed boolean := false;
begin
  select * into v_course from public.courses where id=p_course_id for update;
  if not found or v_course.instructor_id is distinct from auth.uid() then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  perform set_config('app.course_release','on',true);
  if v_course.status='draft' then
    update public.courses set status='published' where id=p_course_id;
    v_changed := true;
  end if;

  update public.lesson_media lm set status='archived'
  from public.lessons l join public.course_modules m on m.id=l.module_id
  where m.course_id=p_course_id and l.pending_video_removal
    and lm.lesson_id=l.id and lm.object_path=l.video_path;
  update public.lessons l set video_path=null,
    status=case when nullif(trim(l.notes),'') is not null or
      nullif(trim(l.external_video_url),'') is not null or
      exists(select 1 from public.curriculum_materials r
        where r.lesson_id=l.id and r.status='ready')
      then 'published' else 'draft' end,
    pending_video_removal=false
  from public.course_modules m
  where l.module_id=m.id and m.course_id=p_course_id and l.pending_video_removal;
  if found then v_changed := true; end if;

  update public.lessons l set video_path=(select lm.object_path
      from public.lesson_media lm where lm.lesson_id=l.id and lm.status='ready'
      order by lm.created_at desc,lm.id desc limit 1),
    external_video_url=null,status='published'
  from public.course_modules m
  where l.module_id=m.id and m.course_id=p_course_id
    and exists(select 1 from public.lesson_media lm
      where lm.lesson_id=l.id and lm.status='ready')
    and (l.status<>'published' or l.video_path is distinct from
      (select lm.object_path from public.lesson_media lm
        where lm.lesson_id=l.id and lm.status='ready'
        order by lm.created_at desc,lm.id desc limit 1));
  if found then v_changed := true; end if;

  update public.lessons l set status='published'
  from public.course_modules m
  where l.module_id=m.id and m.course_id=p_course_id and l.status='draft'
    and (nullif(trim(l.external_video_url),'') is not null
      or nullif(trim(l.notes),'') is not null
      or exists(select 1 from public.curriculum_materials r
        where r.lesson_id=l.id and r.status='ready'));
  if found then v_changed := true; end if;

  update public.course_modules m set release_status='published'
  where m.course_id=p_course_id and m.release_status='draft'
    and exists(select 1 from public.lessons l
      where l.module_id=m.id and l.status='published');
  if found then v_changed := true; end if;
  update public.course_modules m set release_status='draft'
  where m.course_id=p_course_id and m.release_status='published'
    and not exists(select 1 from public.lessons l
      where l.module_id=m.id and l.status='published');
  if found then v_changed := true; end if;

  if not exists(select 1 from public.course_modules m
    join public.lessons l on l.module_id=m.id
    where m.course_id=p_course_id and l.status='published') then
    raise exception 'Add a video, notes or handout to at least one lesson before publishing';
  end if;

  update public.curriculum_materials set is_released=true
  where course_id=p_course_id and status='ready' and not is_released
    and (module_id is null or exists(select 1 from public.course_modules m
      where m.id=module_id and m.release_status='published'))
    and (lesson_id is null or exists(select 1 from public.lessons l
      where l.id=lesson_id and l.status='published'));
  if found then v_changed := true; end if;

  update public.curriculum_assessment_links set is_released=true
  where course_id=p_course_id and not is_released
    and (module_id is null or exists(select 1 from public.course_modules m
      where m.id=module_id and m.release_status='published'))
    and (lesson_id is null or exists(select 1 from public.lessons l
      where l.id=lesson_id and l.status='published'))
    and (exists(select 1 from public.quizzes q where q.id=quiz_id and q.status='published')
      or exists(select 1 from public.assignments a
        where a.id=assignment_id and a.status='published'));
  if found then v_changed := true; end if;

  if v_course.pending_image_path is not null then
    update public.courses set image_path=pending_image_path,
      pending_image_path=null where id=p_course_id;
    v_changed := true;
  end if;
  return v_changed;
end;
$$;
revoke all on function public.publish_course_changes(uuid) from public,anon;
grant execute on function public.publish_course_changes(uuid) to authenticated;
