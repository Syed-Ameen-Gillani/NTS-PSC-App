-- Draft creation is atomic and retryable. Cover artwork is intentionally public.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('course-thumbnails', 'course-thumbnails', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy course_cover_owner_insert on storage.objects for insert to authenticated
with check (bucket_id = 'course-thumbnails' and exists (
  select 1 from public.courses c where c.instructor_id = (select auth.uid())
  and split_part(name, '/', 1) = c.instructor_id::text
  and split_part(name, '/', 2) = c.id::text));
create policy course_cover_owner_read on storage.objects for select to authenticated
using (bucket_id = 'course-thumbnails' and split_part(name, '/', 1) = (select auth.uid())::text);

create function public.create_course_draft(p_course_id uuid, p_category text,
  p_title text, p_description text, p_modules jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_category uuid; v_id uuid; v_owner uuid; v_module jsonb; v_lesson jsonb;
  v_module_id uuid; v_m integer := 0; v_l integer;
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'teacher') then
    raise exception 'Teacher account required';
  end if;
  select id into v_category from public.categories where name = p_category and is_active;
  if v_category is null or length(trim(p_title)) = 0 or length(trim(p_description)) = 0
    or jsonb_typeof(p_modules) is distinct from 'array' or jsonb_array_length(p_modules) = 0 then
    raise exception 'Complete the course details and initial curriculum';
  end if;
  insert into public.courses(id, instructor_id, category_id, title, description, status)
  values(p_course_id, auth.uid(), v_category, trim(p_title), trim(p_description), 'draft')
  on conflict(id) do nothing returning id into v_id;
  if v_id is null then
    select instructor_id into v_owner from public.courses where id = p_course_id;
    if v_owner is distinct from auth.uid() then raise exception 'Course ID is unavailable'; end if;
    return p_course_id;
  end if;
  for v_module in select value from jsonb_array_elements(p_modules) loop
    if jsonb_typeof(v_module->'lessons') is distinct from 'array'
      or jsonb_array_length(v_module->'lessons') = 0 then
      raise exception 'Each initial module needs a lesson';
    end if;
    insert into public.course_modules(course_id, title, display_order)
    values(v_id, trim(v_module->>'title'), v_m) returning id into v_module_id;
    v_l := 0;
    for v_lesson in select value from jsonb_array_elements(v_module->'lessons') loop
      if coalesce((v_lesson->>'duration_seconds')::integer, 0) <= 0 then
        raise exception 'Lesson duration must be above zero';
      end if;
      insert into public.lessons(module_id, title, duration_seconds, notes, display_order, status)
      values(v_module_id, trim(v_lesson->>'title'), (v_lesson->>'duration_seconds')::integer,
        coalesce(v_lesson->>'notes', ''), v_l, 'draft');
      v_l := v_l + 1;
    end loop;
    v_m := v_m + 1;
  end loop;
  return v_id;
end;
$$;
revoke all on function public.create_course_draft(uuid,text,text,text,jsonb) from public, anon;
grant execute on function public.create_course_draft(uuid,text,text,text,jsonb) to authenticated;

create function public.guard_course_publication()
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
  if exists(select 1 from public.course_modules m join public.lessons l on l.module_id = m.id
    where m.course_id = new.id and (l.status <> 'published' or l.duration_seconds <= 0 or not (
      coalesce(l.external_video_url ~ '^https://[^/[:space:]]+/.+', false) or exists (
        select 1 from public.lesson_media lm join storage.objects o
          on o.bucket_id = 'lesson-videos' and o.name = lm.object_path
        where lm.lesson_id = l.id and lm.status = 'ready' and lm.object_path = l.video_path
      )))) then
    raise exception 'Upload, review and publish every lesson video before publishing the course';
  end if;
  return new;
end;
$$;
create trigger course_readiness before insert or update on public.courses
for each row execute function public.guard_course_publication();

-- Lock the parent row so curriculum changes cannot race a publication request.
create function public.guard_course_curriculum()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_course uuid; v_status text;
begin
  if tg_table_name = 'course_modules' then
    v_course := case when tg_op = 'DELETE' then old.course_id else new.course_id end;
    if tg_op = 'UPDATE' and new.course_id <> old.course_id then raise exception 'Cannot move modules between courses'; end if;
  else
    select course_id into v_course from public.course_modules
      where id = case when tg_op = 'DELETE' then old.module_id else new.module_id end;
    if tg_op = 'UPDATE' and new.module_id <> old.module_id then raise exception 'Cannot move lessons between modules'; end if;
  end if;
  select status into v_status from public.courses where id = v_course for update;
  if v_status = 'published' then raise exception 'Move the course to drafts before changing its curriculum'; end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
create trigger modules_draft_edit before insert or update or delete on public.course_modules
for each row execute function public.guard_course_curriculum();
create trigger lessons_draft_edit before insert or update or delete on public.lessons
for each row execute function public.guard_course_curriculum();

create or replace function public.publish_lesson_media(p_media_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_media public.lesson_media;
begin
  select * into v_media from public.lesson_media where id = p_media_id for update;
  if not found or v_media.teacher_id is distinct from auth.uid() or
    v_media.status <> 'needs_review' or jsonb_array_length(v_media.transcript_segments) = 0 then
    raise exception 'Reviewed transcript required';
  end if;
  if not exists(select 1 from storage.objects where bucket_id = 'lesson-videos' and name = v_media.object_path) then
    raise exception 'The uploaded video is missing';
  end if;
  update public.lesson_media set status = 'ready' where id = p_media_id;
  update public.lessons set video_path = v_media.object_path, external_video_url = null, status = 'published'
  where id = v_media.lesson_id;
end;
$$;

-- Deleting an attached cover would break the catalog; replacement must commit first.
create function public.course_cover_is_unused(p_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select not exists(select 1 from public.courses where image_path = p_name);
$$;
revoke all on function public.course_cover_is_unused(text) from public, anon;
grant execute on function public.course_cover_is_unused(text) to authenticated;
create policy course_cover_owner_delete on storage.objects for delete to authenticated
using (bucket_id = 'course-thumbnails' and split_part(name, '/', 1) = auth.uid()::text
  and public.course_cover_is_unused(name));
