alter table public.curriculum_materials add column reading_units integer check(reading_units between 1 and 5000);
alter table public.curriculum_materials add column reading_min_ms bigint check(reading_min_ms between 1000 and 86400000);
alter table public.curriculum_materials add column reading_hash text;
alter table public.curriculum_materials add column reading_text text;

create table public.learning_video_metadata (
  lesson_id uuid not null references public.lessons(id),source text not null,
  duration_ms bigint not null check(duration_ms between 1000 and 86400000),
  primary key(lesson_id,source)
);
create table public.learning_activity_progress (
  enrollment_id uuid not null references public.enrollments(id),
  activity_id uuid not null references public.lesson_activity_placements(id),
  content_version text not null,
  coverage int8multirange not null default '{}'::int8multirange,
  page_times jsonb not null default '{}',engaged_ms bigint not null default 0,
  completed_at timestamptz,
  primary key(enrollment_id,activity_id,content_version)
);
create table public.learning_evidence_sessions (
  id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id),
  enrollment_id uuid not null references public.enrollments(id),lesson_id uuid not null references public.lessons(id),
  activity_id uuid not null references public.lesson_activity_placements(id),release_id uuid not null references public.course_releases(id),
  content_version text not null,kind text not null,units bigint not null,min_ms bigint not null,
  started_at timestamptz not null default clock_timestamp(),expires_at timestamptz not null default clock_timestamp()+interval '7 days',
  next_sequence integer not null default 1,engaged_ms bigint not null default 0,
  unique(id,student_id)
);
create index learning_evidence_owner on public.learning_evidence_sessions(student_id,lesson_id);
create table public.learning_evidence_receipts (
  session_id uuid not null references public.learning_evidence_sessions(id),sequence integer not null,
  payload_hash text not null,primary key(session_id,sequence)
);
create table public.learning_engagement_clocks (
  student_id uuid primary key references public.profiles(id),
  started_at timestamptz not null default clock_timestamp(),engaged_ms bigint not null default 0
);
alter table public.learning_video_metadata enable row level security;
alter table public.learning_activity_progress enable row level security;
alter table public.learning_evidence_sessions enable row level security;
alter table public.learning_evidence_receipts enable row level security;
alter table public.learning_engagement_clocks enable row level security;
revoke all on public.learning_video_metadata,public.learning_activity_progress,public.learning_evidence_sessions,
  public.learning_evidence_receipts,public.learning_engagement_clocks from anon,authenticated;

create function public.confirm_learning_video(p_source text,p_duration_ms bigint,p_lesson_id uuid default null)
returns void language plpgsql security definer set search_path='' as $$
declare v_lesson uuid:=p_lesson_id;
begin
  if v_lesson is null then select lesson_id into v_lesson from public.lesson_media
    where object_path=p_source and teacher_id=auth.uid(); end if;
  if not public.can_access_lesson_media(v_lesson,true) or not exists(select 1 from public.lessons l where l.id=v_lesson
    and (l.external_video_url=p_source or exists(select 1 from public.lesson_media m where m.lesson_id=l.id and m.object_path=p_source))) then
    raise exception 'Teacher video access required' using errcode='42501'; end if;
  insert into public.learning_video_metadata values(v_lesson,p_source,p_duration_ms)
    on conflict(lesson_id,source) do update set duration_ms=excluded.duration_ms;
end;
$$;

create function public.learning_activity_descriptor(p_lesson uuid,p_activity uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_item jsonb; v_lesson jsonb; v_source text; v_units bigint; v_min bigint; v_hash text; v_material public.curriculum_materials;
begin
  select l.value into v_lesson from public.courses c join public.course_releases r on r.id=c.active_release_id
    cross join lateral jsonb_array_elements(r.manifest->'modules') m
    cross join lateral jsonb_array_elements(m->'lessons') l(value)
    where (l.value->>'id')::uuid=p_lesson;
  select value into v_item from jsonb_array_elements(v_lesson->'activities') where (value->>'id')::uuid=p_activity;
  if v_item is null then raise exception 'Activity is no longer in this lesson' using errcode='42501'; end if;
  if v_item->>'kind'='video' then
    v_source:=coalesce(nullif(v_lesson->>'video_path',''),v_lesson->>'external_video_url');
    select coalesce((select duration_ms from public.learning_video_metadata where lesson_id=p_lesson and source=v_source),
      (select (duration_seconds*1000)::bigint from public.lesson_media where lesson_id=p_lesson and object_path=v_source)) into v_units;
    if v_units is null then raise exception 'The instructor needs to preview this video once to confirm its duration' using errcode='22023'; end if;
    v_min:=0; v_hash:=md5(v_source||':'||v_units);
  elsif v_item->>'kind'='reading' then
    v_source:=v_lesson->>'notes';
    v_units:=greatest(1,ceil(cardinality(regexp_split_to_array(trim(v_source),'\s+'))/80.0)::integer);
    v_min:=greatest(5000,cardinality(regexp_split_to_array(trim(v_source),'\s+'))*300);
    v_hash:=md5(v_source);
  elsif v_item->>'kind'='material' then
    select * into v_material from public.curriculum_materials where id=(v_item->>'material_id')::uuid;
    if v_material.reading_hash is null then raise exception 'Prepare this reading in the app first' using errcode='22023'; end if;
    v_units:=v_material.reading_units;v_min:=v_material.reading_min_ms;v_hash:=v_material.reading_hash;
  else raise exception 'This activity is completed by its assessment result' using errcode='22023'; end if;
  return jsonb_build_object('id',p_activity,'kind',v_item->>'kind','units',v_units,'min_ms',v_min,
    'version',md5((v_item->>'kind')||':'||v_hash||':'||coalesce(v_item->>'rule_version','1')));
end;
$$;
create function public.begin_learning_evidence(p_lesson_id uuid,p_activity_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_course uuid;v_enrollment uuid;v_spec jsonb;v_session public.learning_evidence_sessions;
begin
  perform e.id from public.enrollments e where e.student_id=auth.uid()
    and e.status in ('active','completed') order by e.id for update;
  select m.course_id into v_course from public.lessons l join public.course_modules m on m.id=l.module_id where l.id=p_lesson_id;
  if not public.has_course_entitlement(v_course) or not public.can_open_lesson(v_course,p_lesson_id)
    or not exists(select 1 from public.profiles where id=auth.uid() and role='student') then
    raise exception 'Lesson access required' using errcode='42501'; end if;
  select id into v_enrollment from public.enrollments where course_id=v_course and student_id=auth.uid();
  v_spec:=public.learning_activity_descriptor(p_lesson_id,p_activity_id);
  if (select count(*) from public.learning_evidence_sessions where student_id=auth.uid()
      and started_at>now()-interval '1 day')>=200 then
    raise exception 'Too many learning sessions. Try again later' using errcode='22023'; end if;
  insert into public.learning_engagement_clocks(student_id) values(auth.uid()) on conflict do nothing;
  insert into public.learning_evidence_sessions(student_id,enrollment_id,lesson_id,activity_id,release_id,content_version,kind,units,min_ms)
    select auth.uid(),v_enrollment,p_lesson_id,p_activity_id,c.active_release_id,v_spec->>'version',v_spec->>'kind',
      (v_spec->>'units')::bigint,(v_spec->>'min_ms')::bigint from public.courses c where c.id=v_course returning * into v_session;
  return to_jsonb(v_session)-'student_id'-'enrollment_id'||jsonb_build_object('course_id',v_course);
end;
$$;
revoke all on function public.learning_activity_descriptor(uuid,uuid) from public,anon,authenticated;
revoke all on function public.begin_learning_evidence(uuid,uuid),public.confirm_learning_video(text,bigint,uuid) from public,anon;
grant execute on function public.begin_learning_evidence(uuid,uuid),public.confirm_learning_video(text,bigint,uuid) to authenticated;
