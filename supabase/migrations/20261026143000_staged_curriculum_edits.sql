create or replace function public.guard_course_curriculum()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_course uuid; v_status text;
begin
  if tg_table_name='course_modules' then
    v_course:=case when tg_op='DELETE' then old.course_id else new.course_id end;
    if tg_op='UPDATE' and new.course_id<>old.course_id then raise exception 'Cannot move modules between courses'; end if;
  else
    select course_id into v_course from public.course_modules
      where id=case when tg_op='DELETE' then old.module_id else new.module_id end;
    if tg_op='UPDATE' and new.module_id<>old.module_id then raise exception 'Cannot move lessons between modules'; end if;
  end if;
  select status into v_status from public.courses where id=v_course for update;
  if v_status='published' and current_setting('app.course_release',true) is distinct from 'on' then
    if tg_table_name='lessons' then
      if tg_op='INSERT' then
        if new.status<>'draft' then raise exception 'New lessons must remain drafts until published'; end if;
      elsif old.status='published' then raise exception 'Stage changes before publishing'; end if;
    elsif tg_op<>'INSERT' and old.release_status='published' then
      raise exception 'Stage changes before publishing';
    end if;
  end if;
  if tg_op='DELETE' then return old; end if;
  return new;
end;
$$;

create function public.stage_curriculum_details(p_kind text,p_id uuid,p_changes jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare v_course uuid; v_allowed text[];
begin
  if p_kind='module' then
    select course_id into v_course from public.course_modules where id=p_id;
    v_allowed:=array['title'];
  elsif p_kind='lesson' then
    select m.course_id into v_course from public.lessons l
      join public.course_modules m on m.id=l.module_id where l.id=p_id;
    v_allowed:=array['title','notes','duration_seconds','external_video_url'];
  else raise exception 'Choose a module or lesson'; end if;
  perform 1 from public.courses where id=v_course and instructor_id=auth.uid() for update;
  if not found then raise exception 'Teacher access required' using errcode='42501'; end if;
  if jsonb_typeof(p_changes) is distinct from 'object' or exists(
    select 1 from jsonb_object_keys(p_changes) k where not k=any(v_allowed)) then
    raise exception 'Invalid curriculum changes'; end if;
  if p_changes ? 'title' and (jsonb_typeof(p_changes->'title') is distinct from 'string'
    or length(trim(p_changes->>'title')) not between 1 and 200) then raise exception 'Enter a title'; end if;
  if p_changes ? 'notes' and jsonb_typeof(p_changes->'notes') is distinct from 'string' then
    raise exception 'Enter valid reading text'; end if;
  if p_changes ? 'duration_seconds' and ((p_changes->>'duration_seconds')::integer not between 60 and 36000
    or jsonb_typeof(p_changes->'duration_seconds') is distinct from 'number') then
    raise exception 'Enter a valid duration'; end if;
  if p_changes ? 'external_video_url' and jsonb_typeof(p_changes->'external_video_url') is distinct from 'string' then
    raise exception 'Enter a valid video URL'; end if;
  if p_changes ? 'external_video_url' and nullif(trim(p_changes->>'external_video_url'),'') is not null
    and p_changes->>'external_video_url' !~ '^https://[^/[:space:]]+/.+' then raise exception 'Use a secure video URL'; end if;
  if p_kind='module' then
    insert into public.curriculum_draft_changes(course_id,module_id,changes)
      values(v_course,p_id,p_changes)
      on conflict(course_id,module_id,lesson_id) do update
        set changes=public.curriculum_draft_changes.changes||excluded.changes;
  else
    insert into public.curriculum_draft_changes(course_id,lesson_id,changes)
      values(v_course,p_id,p_changes)
      on conflict(course_id,module_id,lesson_id) do update
        set changes=public.curriculum_draft_changes.changes||excluded.changes;
  end if;
end;
$$;

alter table public.course_modules drop constraint course_modules_course_id_display_order_key;
alter table public.course_modules add constraint course_modules_course_id_display_order_key
  unique(course_id,display_order) deferrable initially deferred;
alter table public.lessons drop constraint lessons_module_id_display_order_key;
alter table public.lessons add constraint lessons_module_id_display_order_key
  unique(module_id,display_order) deferrable initially deferred;

create function public.reorder_curriculum(p_course_id uuid,p_module_id uuid,p_ids uuid[])
returns void language plpgsql security definer set search_path='' as $$
declare v_count integer; v_id uuid; v_order integer:=0;
begin
  perform 1 from public.courses where id=p_course_id and instructor_id=auth.uid() for update;
  if not found then raise exception 'Teacher access required' using errcode='42501'; end if;
  if p_module_id is null then
    select count(*) into v_count from public.course_modules where course_id=p_course_id;
  else
    if not exists(select 1 from public.course_modules where id=p_module_id and course_id=p_course_id) then
      raise exception 'Module unavailable'; end if;
    select count(*) into v_count from public.lessons where module_id=p_module_id;
  end if;
  if cardinality(p_ids) is distinct from v_count
    or (select count(distinct x) from unnest(p_ids) x)<>v_count then
    raise exception 'Include every item once'; end if;
  foreach v_id in array p_ids loop
    if p_module_id is null then
      if not exists(select 1 from public.course_modules where id=v_id and course_id=p_course_id) then
        raise exception 'Curriculum item unavailable'; end if;
      insert into public.curriculum_draft_changes(course_id,module_id,changes)
        values(p_course_id,v_id,jsonb_build_object('display_order',v_order))
        on conflict(course_id,module_id,lesson_id) do update
          set changes=public.curriculum_draft_changes.changes||excluded.changes;
    else
      if not exists(select 1 from public.lessons where id=v_id and module_id=p_module_id) then
        raise exception 'Curriculum item unavailable'; end if;
      insert into public.curriculum_draft_changes(course_id,lesson_id,changes)
        values(p_course_id,v_id,jsonb_build_object('display_order',v_order))
        on conflict(course_id,module_id,lesson_id) do update
          set changes=public.curriculum_draft_changes.changes||excluded.changes;
    end if;
    if not found then raise exception 'Curriculum item unavailable'; end if;
    v_order:=v_order+1;
  end loop;
end;
$$;

create function public.stage_curriculum_removal(p_kind text,p_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_course uuid; v_released boolean;
begin
  if p_kind='material' then select course_id,is_released into v_course,v_released from public.curriculum_materials where id=p_id;
  elsif p_kind='assessment' then select course_id,is_released into v_course,v_released from public.curriculum_assessment_links where id=p_id;
  else raise exception 'Unknown resource type'; end if;
  perform 1 from public.courses where id=v_course and instructor_id=auth.uid() for update;
  if not found then raise exception 'Teacher access required' using errcode='42501'; end if;
  if p_kind='material' then
    update public.curriculum_materials set pending_removal=v_released,is_retired=not v_released where id=p_id;
  else
    update public.curriculum_assessment_links set pending_removal=v_released,is_retired=not v_released where id=p_id;
  end if;
end;
$$;
create or replace function public.unlink_curriculum_assessment(p_link_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform public.stage_curriculum_removal('assessment',p_link_id);
end;
$$;
revoke delete on public.curriculum_assessment_links from authenticated;
-- Failed upload cleanup still removes unreferenced upload reservations only.
drop policy curriculum_materials_delete on public.curriculum_materials;
create policy curriculum_materials_delete on public.curriculum_materials for delete to authenticated using(
  status='uploading' and not is_released
  and public.can_access_curriculum(course_id,module_id,lesson_id,true));

create function public.restore_curriculum_link()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  select id into v_id from public.curriculum_assessment_links x
    where x.course_id=new.course_id and x.module_id is not distinct from new.module_id
      and x.lesson_id is not distinct from new.lesson_id
      and x.quiz_id is not distinct from new.quiz_id and x.assignment_id is not distinct from new.assignment_id;
  if v_id is not null then
    update public.curriculum_assessment_links set pending_removal=false,is_retired=false where id=v_id;
    return null;
  end if;
  return new;
end;
$$;
create trigger restore_curriculum_link before insert on public.curriculum_assessment_links
for each row execute function public.restore_curriculum_link();

drop policy curriculum_materials_read on public.curriculum_materials;
create policy curriculum_materials_read on public.curriculum_materials for select to authenticated using(
  not is_retired and case when public.can_access_curriculum(course_id,module_id,lesson_id,true)
    then not pending_removal else status='ready' and is_released
      and public.can_access_curriculum(course_id,module_id,lesson_id) end);
drop policy curriculum_links_read on public.curriculum_assessment_links;
create policy curriculum_links_read on public.curriculum_assessment_links for select to authenticated using(
  not is_retired and case when public.can_access_curriculum(course_id,module_id,lesson_id,true)
    then not pending_removal else is_released and public.can_access_curriculum(course_id,module_id,lesson_id)
      and (exists(select 1 from public.quizzes q where q.id=quiz_id and q.status='published')
        or exists(select 1 from public.assignments a where a.id=assignment_id and a.status='published')) end);

revoke all on function public.stage_curriculum_details(text,uuid,jsonb),
  public.reorder_curriculum(uuid,uuid,uuid[]),public.stage_curriculum_removal(text,uuid) from public,anon;
grant execute on function public.stage_curriculum_details(text,uuid,jsonb),
  public.reorder_curriculum(uuid,uuid,uuid[]),public.stage_curriculum_removal(text,uuid) to authenticated;
revoke all on function public.restore_curriculum_link() from public,anon,authenticated;
