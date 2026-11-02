-- Course publication depends on validated video bytes, not AI availability.
create function public.lesson_media_ready_for_release(p_media uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.lesson_media lm join storage.objects o
   on o.bucket_id='lesson-videos' and o.name=lm.object_path
   where lm.id=p_media and lm.status not in ('uploading','archived')
     and (o.metadata->>'size')::bigint=lm.byte_size and o.metadata->>'mimetype'=lm.mime_type
     and (lm.status='ready' or exists(select 1 from public.learning_video_metadata v
       where v.lesson_id=lm.lesson_id and v.source=lm.object_path)));
$$;
revoke all on function public.lesson_media_ready_for_release(uuid) from public,anon,authenticated;

create function public.released_lesson_video_access(p_path text)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.lesson_media lm join public.lessons l on l.id=lm.lesson_id
   join public.course_modules m on m.id=l.module_id join public.courses c on c.id=m.course_id
   join public.course_release_sources s on s.release_id=c.active_release_id and s.kind='video' and s.source_id=lm.id
   where lm.object_path=p_path and public.can_open_lesson(c.id,l.id)
     and public.lesson_media_ready_for_release(lm.id));
$$;
revoke all on function public.released_lesson_video_access(text) from public,anon;
grant execute on function public.released_lesson_video_access(text) to authenticated;
create policy released_video_read on storage.objects for select to authenticated
 using(bucket_id='lesson-videos' and public.released_lesson_video_access(name));

-- Raw draft transcripts remain owner-only under existing RLS. This projection
-- serves the published video while exposing captions only after teacher review.
create function public.get_student_lesson_media(p_lesson_id uuid)
returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',lm.id,'lesson_id',lm.lesson_id,
   'object_path',lm.object_path,'status','ready','byte_size',lm.byte_size,
   'transcript_segments',case when lm.status='ready' then lm.transcript_segments else '[]'::jsonb end,
   'processing_error',null)),'[]') from public.lesson_media lm
   where lm.lesson_id=p_lesson_id and public.released_lesson_video_access(lm.object_path);
$$;
revoke all on function public.get_student_lesson_media(uuid) from public,anon;
grant execute on function public.get_student_lesson_media(uuid) to authenticated;
create or replace function public.publish_course_changes_before_reading_validation(p_course_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare v_course public.courses; v_changed boolean:=false; v_lesson record;
  v_previous_setting text:=current_setting('app.course_release',true);
begin
  select * into v_course from public.courses where id=p_course_id for update;
  if not found or v_course.instructor_id is distinct from auth.uid() then
    raise exception 'Teacher access required' using errcode='42501'; end if;
  perform set_config('app.course_release','on',true);

  update public.course_modules m set
    title=coalesce(d.changes->>'title',m.title),
    display_order=coalesce((d.changes->>'display_order')::integer,m.display_order)
    from public.curriculum_draft_changes d where d.module_id=m.id and d.course_id=p_course_id;
  if found then v_changed:=true; end if;
  update public.lessons l set title=coalesce(d.changes->>'title',l.title),
    notes=coalesce(d.changes->>'notes',l.notes),
    duration_seconds=coalesce((d.changes->>'duration_seconds')::integer,l.duration_seconds),
    display_order=coalesce((d.changes->>'display_order')::integer,l.display_order),
    video_path=case when d.changes ? 'external_video_url' then null else l.video_path end,
    external_video_url=case when d.changes ? 'external_video_url'
      then nullif(trim(d.changes->>'external_video_url'),'') else l.external_video_url end
    from public.curriculum_draft_changes d where d.lesson_id=l.id and d.course_id=p_course_id;
  if found then v_changed:=true; end if;
  delete from public.curriculum_draft_changes where course_id=p_course_id;

  update public.curriculum_materials set is_retired=true,is_released=false,pending_removal=false
    where course_id=p_course_id and pending_removal;
  if found then v_changed:=true; end if;
  update public.curriculum_assessment_links set is_retired=true,is_released=false,pending_removal=false
    where course_id=p_course_id and pending_removal;
  if found then v_changed:=true; end if;

  update public.lesson_media lm set status='archived'
    from public.lessons l join public.course_modules m on m.id=l.module_id
    where m.course_id=p_course_id and l.pending_video_removal
      and lm.lesson_id=l.id and lm.object_path=l.video_path;
  update public.lessons l set video_path=null,pending_video_removal=false
    from public.course_modules m where l.module_id=m.id and m.course_id=p_course_id
      and l.pending_video_removal;
  if found then v_changed:=true; end if;
  update public.lessons l set video_path=(select lm.object_path from public.lesson_media lm
      where lm.lesson_id=l.id and public.lesson_media_ready_for_release(lm.id) order by lm.created_at desc,lm.id desc limit 1),
    external_video_url=null
    from public.course_modules m where l.module_id=m.id and m.course_id=p_course_id
      and exists(select 1 from public.lesson_media lm where lm.lesson_id=l.id and public.lesson_media_ready_for_release(lm.id))
      and l.video_path is distinct from (select lm.object_path from public.lesson_media lm
        where lm.lesson_id=l.id and public.lesson_media_ready_for_release(lm.id) order by lm.created_at desc,lm.id desc limit 1);
  if found then v_changed:=true; end if;

  for v_lesson in select l.id,l.status from public.lessons l
    join public.course_modules m on m.id=l.module_id where m.course_id=p_course_id order by l.id loop
    perform public.sync_lesson_activity_placements(v_lesson.id);
    if public.lesson_activities_ready(v_lesson.id) then
      update public.lessons set status='published' where id=v_lesson.id and status='draft';
      if found then v_changed:=true; end if;
    elsif v_lesson.status='published' then
      raise exception 'Each released lesson needs ready activities and at least one required activity';
    end if;
  end loop;
  update public.course_modules m set release_status='published'
    where m.course_id=p_course_id and m.release_status='draft'
      and exists(select 1 from public.lessons l where l.module_id=m.id and l.status='published');
  if found then v_changed:=true; end if;
  if not exists(select 1 from public.course_modules m join public.lessons l on l.module_id=m.id
    where m.course_id=p_course_id and m.release_status='published' and l.status='published') then
    raise exception 'Add a ready lesson before publishing'; end if;

  update public.curriculum_materials r set is_released=true
    where r.course_id=p_course_id and r.status='ready' and not r.is_released and not r.is_retired
      and (r.module_id is null or exists(select 1 from public.course_modules m
        where m.id=r.module_id and m.release_status='published'))
      and (r.lesson_id is null or exists(select 1 from public.lessons l where l.id=r.lesson_id and l.status='published'));
  if found then v_changed:=true; end if;
  update public.curriculum_assessment_links x set is_released=true
    where x.course_id=p_course_id and not x.is_released and not x.is_retired
      and (x.module_id is null or exists(select 1 from public.course_modules m
        where m.id=x.module_id and m.release_status='published'))
      and (x.lesson_id is null or exists(select 1 from public.lessons l where l.id=x.lesson_id and l.status='published'))
      and (exists(select 1 from public.quizzes q where q.id=x.quiz_id and q.status='published')
        or exists(select 1 from public.assignments a where a.id=x.assignment_id and a.status='published'));
  if found then v_changed:=true; end if;
  if v_course.status='draft' or v_course.pending_image_path is not null then
    update public.courses set status='published',
      image_path=coalesce(pending_image_path,image_path),pending_image_path=null where id=p_course_id;
    v_changed:=true;
  end if;
  if public.capture_course_release(p_course_id) then v_changed:=true; end if;
  perform set_config('app.course_release',coalesce(v_previous_setting,''),true);
  return v_changed;
end;
$$;

create or replace function public.sync_lesson_activity_placements(p_lesson uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_lesson public.lessons; v_source record; v_order integer; v_draft jsonb;
begin
  select * into v_lesson from public.lessons where id=p_lesson for update;
  if not found then return; end if;
  select changes into v_draft from public.curriculum_draft_changes where lesson_id=p_lesson;
  if v_draft ? 'notes' then v_lesson.notes:=v_draft->>'notes'; end if;
  if v_draft ? 'external_video_url' then
    v_lesson.external_video_url:=nullif(trim(v_draft->>'external_video_url'),'');
    v_lesson.video_path:=null;
  end if;
  -- Existing IDs/order/required choices survive source refresh and backfill reruns.
  for v_source in
    select 'video'::text kind,'video'::text source_key,null::uuid material_id,
      null::uuid assessment_link_id,true required,0 rank
    where (v_lesson.video_path is not null and not v_lesson.pending_video_removal)
      or nullif(trim(v_lesson.external_video_url),'') is not null
      or exists(select 1 from public.lesson_media lm where lm.lesson_id=p_lesson
        and public.lesson_media_ready_for_release(lm.id) and not (v_lesson.pending_video_removal
          and lm.object_path=v_lesson.video_path))
    union all select 'reading','reading',null,null,true,1
      where nullif(trim(v_lesson.notes),'') is not null
    union all select 'material','material:'||r.id,r.id,null,
      v_lesson.video_path is null and nullif(trim(v_lesson.external_video_url),'') is null
        and nullif(trim(v_lesson.notes),'') is null and not exists(
          select 1 from public.curriculum_assessment_links x where x.lesson_id=p_lesson
            and not x.is_retired and not x.pending_removal),2
      from public.curriculum_materials r where r.lesson_id=p_lesson
        and r.status='ready' and not r.is_retired and not r.pending_removal
    union all select case when a.quiz_id is not null then 'quiz' else 'assignment' end,
      'assessment:'||a.id,null,a.id,true,3
      from public.curriculum_assessment_links a where a.lesson_id=p_lesson
        and not a.is_retired and not a.pending_removal
    order by rank,source_key
  loop
    select coalesce(max(display_order),-1)+1 into v_order
      from public.lesson_activity_placements where lesson_id=p_lesson;
    insert into public.lesson_activity_placements(lesson_id,kind,source_key,
      material_id,assessment_link_id,display_order,is_required)
    values(p_lesson,v_source.kind,v_source.source_key,v_source.material_id,
      v_source.assessment_link_id,v_order,v_source.required)
    on conflict(lesson_id,source_key) do update set is_retired=false;
  end loop;
  update public.lesson_activity_placements p set is_retired=true
  where p.lesson_id=p_lesson and (
    (p.kind='video' and not ((v_lesson.video_path is not null and not v_lesson.pending_video_removal)
      or nullif(trim(v_lesson.external_video_url),'') is not null
      or exists(select 1 from public.lesson_media lm where lm.lesson_id=p_lesson
        and public.lesson_media_ready_for_release(lm.id) and not (v_lesson.pending_video_removal and lm.object_path=v_lesson.video_path))))
    or (p.kind='reading' and nullif(trim(v_lesson.notes),'') is null)
    or (p.kind='material' and not exists(select 1 from public.curriculum_materials r
      where r.id=p.material_id and r.status='ready' and not r.pending_removal and not r.is_retired))
    or (p.kind in ('quiz','assignment') and not exists(select 1 from public.curriculum_assessment_links a
      where a.id=p.assessment_link_id and not a.pending_removal and not a.is_retired))
  );
end;
$$;



