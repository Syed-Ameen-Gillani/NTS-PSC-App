create table public.course_releases (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete restrict,
  version integer not null check(version>0),
  manifest jsonb not null,
  created_at timestamptz not null default now(),
  unique(course_id,version)
);
alter table public.courses add column active_release_id uuid
  references public.course_releases(id) on delete restrict;
create table public.course_release_sources (
  release_id uuid not null references public.course_releases(id) on delete restrict,
  kind text not null,
  source_id uuid not null,
  object_path text,
  primary key(release_id,kind,source_id)
);
create index course_release_source_path on public.course_release_sources(object_path);
alter table public.course_releases enable row level security;
alter table public.course_release_sources enable row level security;
revoke all on public.course_releases,public.course_release_sources from anon,authenticated;
grant select on public.course_releases to authenticated;
create policy course_releases_owner_read on public.course_releases for select to authenticated
using(exists(select 1 from public.courses c where c.id=course_id and c.instructor_id=auth.uid()));

create or replace function public.guard_course_publication()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  -- Bootstrapping release identity must not rewrite or reject legacy courses.
  if tg_op='UPDATE' and (to_jsonb(new)-'active_release_id'-'updated_at')
    is not distinct from (to_jsonb(old)-'active_release_id'-'updated_at') then return new; end if;
  if new.image_path is not null and (tg_op='INSERT'
    or new.image_path is distinct from old.image_path or new.status='published') then
    if not exists(select 1 from storage.objects o where o.bucket_id='course-thumbnails'
      and o.name=new.image_path and split_part(o.name,'/',1)=new.instructor_id::text
      and split_part(o.name,'/',2)=new.id::text
      and (o.metadata->>'size')::bigint between 1 and 5242880
      and o.metadata->>'mimetype' in ('image/jpeg','image/png','image/webp')) then
      raise exception 'Upload a valid course cover before publishing';
    end if;
  end if;
  if new.status<>'published' then return new; end if;
  if length(trim(new.description))=0 or new.image_path is null then
    raise exception 'Add a course description and upload a cover before publishing'; end if;
  if not exists(select 1 from public.categories where id=new.category_id and is_active) then
    raise exception 'Choose an active course category'; end if;
  if not exists(select 1 from public.course_modules m join public.lessons l on l.module_id=m.id
    where m.course_id=new.id) then raise exception 'Add a lesson before publishing'; end if;
  return new;
end;
$$;

create function public.build_course_release_manifest(p_course uuid)
returns jsonb language sql stable security definer set search_path='' as $$
  select jsonb_build_object('modules',coalesce((select jsonb_agg(jsonb_build_object(
    'id',m.id,'title',m.title,'display_order',m.display_order,
    'lessons',coalesce((select jsonb_agg(jsonb_build_object(
      'id',l.id,'title',l.title,'display_order',l.display_order,
      'duration_seconds',l.duration_seconds,'notes',l.notes,
      'video_path',l.video_path,'external_video_url',l.external_video_url,
      'activities',coalesce((select jsonb_agg(jsonb_build_object(
        'id',p.id,'kind',p.kind,'display_order',p.display_order,
        'required',p.is_required,'rule_version',p.rule_version,
        'material_id',p.material_id,'assessment_link_id',p.assessment_link_id,
        'title',case p.kind when 'video' then 'Video' when 'reading' then 'Reading'
          when 'material' then r.title when 'quiz' then q.title else a.title end)
        order by p.display_order,p.id)
        from public.lesson_activity_placements p
        left join public.curriculum_materials r on r.id=p.material_id
        left join public.curriculum_assessment_links x on x.id=p.assessment_link_id
        left join public.quizzes q on q.id=x.quiz_id
        left join public.assignments a on a.id=x.assignment_id
        where p.lesson_id=l.id and not p.is_retired
          and (p.material_id is null or (r.is_released and not r.is_retired))
          and (p.assessment_link_id is null or (x.is_released and not x.is_retired))), '[]'::jsonb))
      order by l.display_order,l.id) from public.lessons l
      where l.module_id=m.id and l.status='published'),'[]'::jsonb))
    order by m.display_order,m.id) from public.course_modules m
    where m.course_id=p_course and m.release_status='published'),'[]'::jsonb),
    'materials',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,
      'module_id',r.module_id,'lesson_id',r.lesson_id,'object_path',r.object_path)
      order by r.id) from public.curriculum_materials r
      where r.course_id=p_course and r.is_released and not r.is_retired),'[]'::jsonb),
    'assessments',coalesce((select jsonb_agg(jsonb_build_object('id',x.id,
      'module_id',x.module_id,'lesson_id',x.lesson_id,'quiz_id',x.quiz_id,
      'assignment_id',x.assignment_id) order by x.id)
      from public.curriculum_assessment_links x where x.course_id=p_course
        and x.is_released and not x.is_retired),'[]'::jsonb));
$$;

create function public.capture_course_release(p_course uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare v_manifest jsonb; v_previous jsonb; v_release uuid; v_version integer;
begin
  perform 1 from public.courses where id=p_course for update;
  v_manifest:=public.build_course_release_manifest(p_course);
  select r.manifest into v_previous from public.courses c
    join public.course_releases r on r.id=c.active_release_id where c.id=p_course;
  if v_previous is not distinct from v_manifest then return false; end if;
  select coalesce(max(version),0)+1 into v_version from public.course_releases where course_id=p_course;
  insert into public.course_releases(course_id,version,manifest)
    values(p_course,v_version,v_manifest) returning id into v_release;
  insert into public.course_release_sources(release_id,kind,source_id,object_path)
    select v_release,'material',r.id,r.object_path from public.curriculum_materials r
      where r.course_id=p_course and r.is_released and not r.is_retired
    union all select v_release,'assessment_link',a.id,null
      from public.curriculum_assessment_links a where a.course_id=p_course
        and a.is_released and not a.is_retired
    union all select v_release,'video',lm.id,lm.object_path from public.lesson_media lm
      join public.lessons l on l.id=lm.lesson_id join public.course_modules m on m.id=l.module_id
      where m.course_id=p_course and l.status='published' and lm.object_path=l.video_path;
  update public.courses set active_release_id=v_release where id=p_course;
  return true;
end;
$$;
select public.capture_course_release(id) from public.courses where status='published' order by id;

create function public.course_source_is_released(p_kind text,p_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.course_release_sources where kind=p_kind and source_id=p_id);
$$;
revoke all on function public.build_course_release_manifest(uuid),
  public.capture_course_release(uuid) from public,anon,authenticated;
revoke all on function public.course_source_is_released(text,uuid) from public,anon;
grant execute on function public.course_source_is_released(text,uuid) to authenticated;

-- Old release files must survive replacement, unlinking and client cleanup.
drop policy curriculum_files_delete on storage.objects;
create policy curriculum_files_delete on storage.objects for delete to authenticated using(
  bucket_id='course-materials' and exists(select 1 from public.curriculum_materials r
    where r.object_path=name and not public.course_source_is_released('material',r.id)
      and public.can_access_curriculum(r.course_id,r.module_id,r.lesson_id,true)));
drop policy lesson_video_teacher_archive_delete on storage.objects;
create policy lesson_video_teacher_archive_delete on storage.objects for delete to authenticated using(
  bucket_id='lesson-videos' and exists(select 1 from public.lesson_media lm
    where lm.object_path=name and lm.teacher_id=auth.uid() and lm.status='archived'
      and not public.course_source_is_released('video',lm.id)));

-- Published assignment definitions cannot change under an active release.
create function public.guard_released_assignment_definition()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if exists(select 1 from public.curriculum_assessment_links x
    where x.assignment_id=old.id and public.course_source_is_released('assessment_link',x.id))
    and row(new.title,new.instructions,new.due_at,new.external_url,new.status,new.course_id)
      is distinct from row(old.title,old.instructions,old.due_at,old.external_url,old.status,old.course_id) then
    raise exception 'Create a new assignment version before changing released instructions';
  end if;
  return new;
end;
$$;
create trigger released_assignment_definition before update on public.assignments
for each row execute function public.guard_released_assignment_definition();
revoke all on function public.guard_released_assignment_definition() from public,anon,authenticated;
