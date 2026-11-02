-- Placements reference existing sources; assessment content/history stays put.
alter table public.curriculum_materials add column pending_removal boolean not null default false;
alter table public.curriculum_materials add column is_retired boolean not null default false;
alter table public.curriculum_assessment_links add column pending_removal boolean not null default false;
alter table public.curriculum_assessment_links add column is_retired boolean not null default false;
-- Draft reading text cannot live on publicly readable module/lesson rows.
create table public.curriculum_draft_changes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  module_id uuid references public.course_modules(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete cascade,
  changes jsonb not null check(jsonb_typeof(changes)='object'),
  check(num_nonnulls(module_id,lesson_id)=1),
  unique nulls not distinct(course_id,module_id,lesson_id)
);
alter table public.curriculum_draft_changes enable row level security;
revoke all on public.curriculum_draft_changes from anon,authenticated;
grant select on public.curriculum_draft_changes to authenticated;
create policy curriculum_draft_owner_read on public.curriculum_draft_changes
for select to authenticated using(public.can_access_curriculum(course_id,null,null,true));

create table public.lesson_activity_placements (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete restrict,
  kind text not null check(kind in ('video','reading','material','quiz','assignment')),
  source_key text not null,
  material_id uuid references public.curriculum_materials(id) on delete restrict,
  assessment_link_id uuid references public.curriculum_assessment_links(id) on delete restrict,
  display_order integer not null check(display_order>=0),
  is_required boolean not null,
  rule_version integer not null default 1 check(rule_version>0),
  is_retired boolean not null default false,
  unique(lesson_id,source_key),
  constraint lesson_activity_order unique(lesson_id,display_order) deferrable initially deferred,
  check((kind in ('video','reading') and material_id is null and assessment_link_id is null)
    or (kind='material' and material_id is not null and assessment_link_id is null)
    or (kind in ('quiz','assignment') and assessment_link_id is not null and material_id is null))
);
create index lesson_activity_source_material on public.lesson_activity_placements(material_id);
create index lesson_activity_source_assessment on public.lesson_activity_placements(assessment_link_id);
alter table public.lesson_activity_placements enable row level security;
revoke all on public.lesson_activity_placements from anon,authenticated;
grant select on public.lesson_activity_placements to authenticated;
create policy lesson_activity_owner_read on public.lesson_activity_placements
for select to authenticated using(exists(select 1 from public.lessons l
  join public.course_modules m on m.id=l.module_id
  where l.id=lesson_id and public.can_access_curriculum(m.course_id,m.id,l.id,true)));

create function public.sync_lesson_activity_placements(p_lesson uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_lesson public.lessons; v_source record; v_order integer;
begin
  select * into v_lesson from public.lessons where id=p_lesson for update;
  if not found then return; end if;
  -- Existing IDs/order/required choices survive source refresh and backfill reruns.
  for v_source in
    select 'video'::text kind,'video'::text source_key,null::uuid material_id,
      null::uuid assessment_link_id,true required,0 rank
    where (v_lesson.video_path is not null and not v_lesson.pending_video_removal)
      or nullif(trim(v_lesson.external_video_url),'') is not null
      or exists(select 1 from public.lesson_media lm where lm.lesson_id=p_lesson
        and lm.status='ready' and not (v_lesson.pending_video_removal
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
        and lm.status='ready' and not (v_lesson.pending_video_removal and lm.object_path=v_lesson.video_path))))
    or (p.kind='reading' and nullif(trim(v_lesson.notes),'') is null)
    or (p.kind='material' and not exists(select 1 from public.curriculum_materials r
      where r.id=p.material_id and r.status='ready' and not r.pending_removal and not r.is_retired))
    or (p.kind in ('quiz','assignment') and not exists(select 1 from public.curriculum_assessment_links a
      where a.id=p.assessment_link_id and not a.pending_removal and not a.is_retired))
  );
end;
$$;

create function public.refresh_lesson_activity_placements()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_table_name='lessons' then
    perform public.sync_lesson_activity_placements(new.id);
  else
    if new.lesson_id is not null then
      perform public.sync_lesson_activity_placements(new.lesson_id);
    end if;
  end if;
  return new;
end;
$$;
create trigger lesson_activity_refresh after insert or update on public.lessons
for each row execute function public.refresh_lesson_activity_placements();
create trigger material_activity_refresh after insert or update on public.curriculum_materials
for each row execute function public.refresh_lesson_activity_placements();
create trigger assessment_activity_refresh after insert or update on public.curriculum_assessment_links
for each row execute function public.refresh_lesson_activity_placements();
create trigger media_activity_refresh after insert or update on public.lesson_media
for each row execute function public.refresh_lesson_activity_placements();
select public.sync_lesson_activity_placements(id) from public.lessons order by id;

create function public.configure_lesson_activities(p_lesson_id uuid,p_items jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare v_course uuid; v_item jsonb; v_index integer:=0; v_count integer;
begin
  select m.course_id into v_course from public.lessons l
    join public.course_modules m on m.id=l.module_id where l.id=p_lesson_id;
  perform 1 from public.courses where id=v_course and instructor_id=auth.uid() for update;
  if not found then raise exception 'Teacher access required' using errcode='42501'; end if;
  if jsonb_typeof(p_items) is distinct from 'array' then raise exception 'Choose lesson activities'; end if;
  select count(*) into v_count from public.lesson_activity_placements
    where lesson_id=p_lesson_id and not is_retired;
  if jsonb_array_length(p_items)<>v_count or (select count(distinct x->>'id')
    from jsonb_array_elements(p_items) x)<>v_count then
    raise exception 'Include every active activity once';
  end if;
  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item->'required') is distinct from 'boolean' then
      raise exception 'Choose whether the activity is required'; end if;
    update public.lesson_activity_placements set display_order=v_index,
      is_required=(v_item->>'required')::boolean
      where id=(v_item->>'id')::uuid and lesson_id=p_lesson_id and not is_retired;
    if not found then raise exception 'Activity is unavailable'; end if;
    v_index:=v_index+1;
  end loop;
  -- Retired slots remain distinct without occupying an active position.
  with retired as(select id,row_number() over(order by display_order,id) n
    from public.lesson_activity_placements where lesson_id=p_lesson_id and is_retired)
  update public.lesson_activity_placements p set display_order=v_count+r.n::integer
    from retired r where r.id=p.id;
end;
$$;
revoke all on function public.sync_lesson_activity_placements(uuid),
  public.refresh_lesson_activity_placements() from public,anon,authenticated;
revoke all on function public.configure_lesson_activities(uuid,jsonb) from public,anon;
grant execute on function public.configure_lesson_activities(uuid,jsonb) to authenticated;
