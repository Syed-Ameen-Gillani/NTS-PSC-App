create table public.lesson_checkpoint_generation_attempts (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  media_id uuid not null references public.lesson_media(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index lesson_generation_teacher_day_idx on
  public.lesson_checkpoint_generation_attempts(teacher_id, created_at desc);
alter table public.lesson_checkpoint_generation_attempts enable row level security;
revoke all on public.lesson_checkpoint_generation_attempts from anon, authenticated;

create function public.reserve_lesson_checkpoint_generation(p_media_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_teacher uuid := auth.uid();
begin
  if not exists (select 1 from public.lesson_media lm where lm.id = p_media_id
    and lm.teacher_id = v_teacher and lm.status = 'needs_review') then
    raise exception 'Reviewable teacher media required';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_teacher::text, 0));
  if exists (select 1 from public.lesson_checkpoints c where c.media_id = p_media_id) then
    raise exception 'Review existing checks before generating more';
  end if;
  if (select count(*) from public.lesson_checkpoint_generation_attempts a
    where a.teacher_id = v_teacher and
      a.created_at >= date_trunc('day', now() at time zone 'UTC') at time zone 'UTC') >= 5 then
    raise exception 'Daily in-video check generation limit reached';
  end if;
  insert into public.lesson_checkpoint_generation_attempts(teacher_id, media_id)
  values (v_teacher, p_media_id);
end;
$$;
revoke all on function public.reserve_lesson_checkpoint_generation(uuid)
  from public, anon;
grant execute on function public.reserve_lesson_checkpoint_generation(uuid)
  to authenticated;
