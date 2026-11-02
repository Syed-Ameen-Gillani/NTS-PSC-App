-- Private teaching materials and curriculum placement; assessment content remains
-- in the existing guarded quiz/assignment systems.
create function public.can_access_curriculum(
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
      and (p_lesson is null or exists(select 1 from public.lessons l
        where l.id=p_lesson and l.status='published'))))
  );
$$;
revoke all on function public.can_access_curriculum(uuid,uuid,uuid,boolean) from public,anon;
grant execute on function public.can_access_curriculum(uuid,uuid,uuid,boolean) to authenticated;

create function public.curriculum_context(
  p_course_id uuid default null,p_module_id uuid default null,p_lesson_id uuid default null
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_course uuid:=p_course_id; v_module uuid:=p_module_id; v_title text;
begin
  if p_lesson_id is not null then
    select coalesce(v_module,l.module_id),l.title into v_module,v_title
      from public.lessons l where l.id=p_lesson_id;
  end if;
  if v_module is not null then
    select coalesce(v_course,m.course_id),coalesce(v_title,m.title) into v_course,v_title
      from public.course_modules m where m.id=v_module;
  end if;
  if not public.can_access_curriculum(v_course,v_module,p_lesson_id) then
    raise exception 'Curriculum is unavailable' using errcode='42501';
  end if;
  return (select jsonb_build_object('course_id',c.id,'module_id',v_module,
    'lesson_id',p_lesson_id,'title',coalesce(v_title,c.title),'course_title',c.title,
    'can_manage',c.instructor_id=auth.uid()) from public.courses c where c.id=v_course);
end;
$$;
revoke all on function public.curriculum_context(uuid,uuid,uuid) from public,anon;
grant execute on function public.curriculum_context(uuid,uuid,uuid) to authenticated;

create table public.curriculum_materials (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  module_id uuid references public.course_modules(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete cascade,
  title text not null check(length(trim(title)) between 1 and 200),
  object_path text not null unique,
  mime_type text not null,
  size_bytes bigint not null check(size_bytes between 1 and 26214400),
  status text not null default 'uploading' check(status in ('uploading','ready')),
  created_at timestamptz not null default now(),
  check(lesson_id is null or module_id is not null)
);
create index curriculum_materials_scope on public.curriculum_materials(course_id,module_id,lesson_id);
alter table public.curriculum_materials enable row level security;
revoke all on public.curriculum_materials from anon,authenticated;
grant select,delete on public.curriculum_materials to authenticated;
create policy curriculum_materials_read on public.curriculum_materials for select to authenticated
using ((status='ready' and public.can_access_curriculum(course_id,module_id,lesson_id))
  or public.can_access_curriculum(course_id,module_id,lesson_id,true));
create policy curriculum_materials_delete on public.curriculum_materials for delete to authenticated
using(public.can_access_curriculum(course_id,module_id,lesson_id,true));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('course-materials','course-materials',false,26214400,array[
  'application/pdf','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation','text/plain']);
create policy curriculum_files_insert on storage.objects for insert to authenticated with check(
  bucket_id='course-materials' and exists(select 1 from public.curriculum_materials r
    where r.object_path=name and r.status='uploading'
    and public.can_access_curriculum(r.course_id,r.module_id,r.lesson_id,true)));
create policy curriculum_files_read on storage.objects for select to authenticated using(
  bucket_id='course-materials' and exists(select 1 from public.curriculum_materials r
    where r.object_path=name and ((r.status='ready' and
      public.can_access_curriculum(r.course_id,r.module_id,r.lesson_id)) or
      public.can_access_curriculum(r.course_id,r.module_id,r.lesson_id,true))));
create policy curriculum_files_delete on storage.objects for delete to authenticated using(
  bucket_id='course-materials' and exists(select 1 from public.curriculum_materials r
    where r.object_path=name and public.can_access_curriculum(r.course_id,r.module_id,r.lesson_id,true)));

create function public.begin_curriculum_material(
  p_course_id uuid,p_module_id uuid,p_lesson_id uuid,p_title text,p_extension text,p_size bigint
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_id uuid:=gen_random_uuid(); v_path text; v_mime text;
begin
  if not public.can_access_curriculum(p_course_id,p_module_id,p_lesson_id,true) then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  v_mime:=case p_extension when 'pdf' then 'application/pdf'
    when 'docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when 'pptx' then 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    when 'txt' then 'text/plain' else null end;
  if v_mime is null then raise exception 'Unsupported document type'; end if;
  v_path:=auth.uid()::text||'/'||p_course_id::text||'/'||v_id::text||'.'||p_extension;
  insert into public.curriculum_materials(id,course_id,module_id,lesson_id,title,object_path,mime_type,size_bytes)
  values(v_id,p_course_id,p_module_id,p_lesson_id,p_title,v_path,v_mime,p_size);
  return jsonb_build_object('id',v_id,'object_path',v_path,'mime_type',v_mime);
end;
$$;
create function public.finish_curriculum_material(p_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_row public.curriculum_materials;
begin
  select * into v_row from public.curriculum_materials where id=p_id for update;
  if not found or not public.can_access_curriculum(v_row.course_id,v_row.module_id,v_row.lesson_id,true) then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  if not exists(select 1 from storage.objects o where o.bucket_id='course-materials'
    and o.name=v_row.object_path and (o.metadata->>'size')::bigint=v_row.size_bytes) then
    raise exception 'Document upload is incomplete';
  end if;
  update public.curriculum_materials set status='ready' where id=p_id;
end;
$$;
revoke all on function public.begin_curriculum_material(uuid,uuid,uuid,text,text,bigint),
  public.finish_curriculum_material(uuid) from public,anon;
grant execute on function public.begin_curriculum_material(uuid,uuid,uuid,text,text,bigint),
  public.finish_curriculum_material(uuid) to authenticated;

create table public.curriculum_assessment_links (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  module_id uuid references public.course_modules(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete cascade,
  quiz_id uuid references public.quizzes(id) on delete cascade,
  assignment_id uuid references public.assignments(id) on delete cascade,
  created_at timestamptz not null default now(),
  check(num_nonnulls(quiz_id,assignment_id)=1),
  check(lesson_id is null or module_id is not null),
  unique nulls not distinct(course_id,module_id,lesson_id,quiz_id,assignment_id)
);
create index curriculum_assessments_scope on public.curriculum_assessment_links(course_id,module_id,lesson_id);
alter table public.curriculum_assessment_links enable row level security;
revoke all on public.curriculum_assessment_links from anon,authenticated;
grant select,delete on public.curriculum_assessment_links to authenticated;
create policy curriculum_links_read on public.curriculum_assessment_links for select to authenticated using(
  public.can_access_curriculum(course_id,module_id,lesson_id,true) or (
    public.can_access_curriculum(course_id,module_id,lesson_id) and (
      exists(select 1 from public.quizzes q where q.id=quiz_id and q.course_id=curriculum_assessment_links.course_id and q.status='published') or
      exists(select 1 from public.assignments a where a.id=assignment_id and a.course_id=curriculum_assessment_links.course_id and a.status='published'))));
create policy curriculum_links_delete on public.curriculum_assessment_links for delete to authenticated using(
  public.can_access_curriculum(course_id,module_id,lesson_id,true));

create function public.link_curriculum_assessment(
  p_course_id uuid,p_module_id uuid,p_lesson_id uuid,p_kind text,p_assessment_id uuid
) returns void language plpgsql security definer set search_path='' as $$
declare v_quiz public.quizzes;
begin
  if not public.can_access_curriculum(p_course_id,p_module_id,p_lesson_id,true) then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  if p_kind='quiz' then
    select * into v_quiz from public.quizzes where id=p_assessment_id for update;
    if not found or v_quiz.teacher_id<>auth.uid() or
      (v_quiz.course_id is not null and v_quiz.course_id<>p_course_id) or
      (v_quiz.course_id is null and v_quiz.status<>'draft') then
      raise exception 'Choose a draft quiz or a quiz already assigned to this course';
    end if;
    if v_quiz.course_id is null then
      update public.quizzes set course_id=p_course_id where id=v_quiz.id;
    end if;
    insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,quiz_id)
      values(p_course_id,p_module_id,p_lesson_id,p_assessment_id) on conflict do nothing;
  elsif p_kind='assignment' then
    if not exists(select 1 from public.assignments where id=p_assessment_id and course_id=p_course_id) then
      raise exception 'Choose an assignment from this course';
    end if;
    insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,assignment_id)
      values(p_course_id,p_module_id,p_lesson_id,p_assessment_id) on conflict do nothing;
  else raise exception 'Unknown assessment type'; end if;
end;
$$;
create function public.curriculum_assessment_candidates(p_course_id uuid)
returns table(id uuid,title text,kind text,status text)
language plpgsql stable security definer set search_path='' as $$
begin
  if not public.can_access_curriculum(p_course_id,null,null,true) then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  return query select q.id,q.title,'quiz'::text,q.status from public.quizzes q
    where q.teacher_id=auth.uid() and (q.course_id=p_course_id or (q.course_id is null and q.status='draft'))
  union all select a.id,a.title,'assignment'::text,a.status from public.assignments a where a.course_id=p_course_id;
end;
$$;
revoke all on function public.link_curriculum_assessment(uuid,uuid,uuid,text,uuid),
  public.curriculum_assessment_candidates(uuid) from public,anon;
grant execute on function public.link_curriculum_assessment(uuid,uuid,uuid,text,uuid),
  public.curriculum_assessment_candidates(uuid) to authenticated;
