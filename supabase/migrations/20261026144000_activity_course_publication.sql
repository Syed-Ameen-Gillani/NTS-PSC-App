create function public.lesson_activities_ready(p_lesson uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.lesson_activity_placements p
    where p.lesson_id=p_lesson and not p.is_retired and p.is_required)
  and not exists(select 1 from public.lesson_activity_placements p
    left join public.curriculum_assessment_links x on x.id=p.assessment_link_id
    left join public.quizzes q on q.id=x.quiz_id
    left join public.assignments a on a.id=x.assignment_id
    left join public.curriculum_materials r on r.id=p.material_id
    where p.lesson_id=p_lesson and not p.is_retired and (
      (p.kind='quiz' and (q.id is null or q.status<>'published'
        or not exists(select 1 from public.quiz_questions z where z.quiz_id=q.id)))
      or (p.kind='assignment' and (a.id is null or a.status<>'published'))
      or (p.kind='material' and (r.id is null or r.status<>'ready' or not exists(
        select 1 from storage.objects o where o.bucket_id='course-materials' and o.name=r.object_path)))
      or (p.kind='video' and not exists(select 1 from public.lessons l where l.id=p_lesson
        and (nullif(trim(l.external_video_url),'') is not null or exists(
          select 1 from storage.objects o where o.bucket_id='lesson-videos' and o.name=l.video_path))))
    ));
$$;

create or replace function public.publish_course_changes(p_course_id uuid)
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
      where lm.lesson_id=l.id and lm.status='ready' order by lm.created_at desc,lm.id desc limit 1),
    external_video_url=null
    from public.course_modules m where l.module_id=m.id and m.course_id=p_course_id
      and exists(select 1 from public.lesson_media lm where lm.lesson_id=l.id and lm.status='ready')
      and l.video_path is distinct from (select lm.object_path from public.lesson_media lm
        where lm.lesson_id=l.id and lm.status='ready' order by lm.created_at desc,lm.id desc limit 1);
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
revoke all on function public.lesson_activities_ready(uuid) from public,anon,authenticated;

-- Complete safe outline, independent of protected lesson-row joins.
create function public.get_public_course_outline(p_course_ids uuid[])
returns table(course_id uuid,release_id uuid,module_id uuid,module_title text,module_order integer,
  lesson_id uuid,title text,duration_seconds integer,display_order integer,activities jsonb)
language plpgsql stable security definer set search_path='' as $$
begin
  if coalesce(cardinality(p_course_ids),0)>200 then raise exception 'Request at most 200 courses'; end if;
  return query select c.id,r.id,(m->>'id')::uuid,m->>'title',(m->>'display_order')::integer,
    (l->>'id')::uuid,l->>'title',(l->>'duration_seconds')::integer,(l->>'display_order')::integer,
    coalesce(l->'activities','[]'::jsonb)
    from public.courses c join public.course_releases r on r.id=c.active_release_id and r.course_id=c.id
    cross join lateral jsonb_array_elements(r.manifest->'modules') m
    left join lateral jsonb_array_elements(m->'lessons') l on true
    where c.id=any(coalesce(p_course_ids,'{}'::uuid[])) and c.status='published'
    order by c.id,(m->>'display_order')::integer,m->>'id',(l->>'display_order')::integer,l->>'id';
end;
$$;
revoke all on function public.get_public_course_outline(uuid[]) from public;
grant execute on function public.get_public_course_outline(uuid[]) to anon,authenticated;

-- Keep old clients compatible while deriving metadata from the same release.
create or replace function public.get_public_course_syllabus(p_course_ids uuid[])
returns table(course_id uuid,module_id uuid,lesson_id uuid,title text,duration_seconds integer,display_order integer)
language sql stable security definer set search_path='' as $$
  select o.course_id,o.module_id,o.lesson_id,o.title,o.duration_seconds,o.display_order
    from public.get_public_course_outline(p_course_ids) o where o.lesson_id is not null;
$$;
