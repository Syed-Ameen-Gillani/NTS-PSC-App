create table public.live_sessions (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null check(length(trim(title)) between 1 and 200),
  meeting_url text not null check(meeting_url ~ '^https://[^/@[:space:]]+[^[:space:]]*$'),
  starts_at timestamptz not null,
  duration_minutes integer not null check(duration_minutes between 5 and 480),
  cancelled boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.live_sessions enable row level security;
grant select, insert, update on public.live_sessions to authenticated;
create policy live_session_read on public.live_sessions for select to authenticated using (
  exists(select 1 from public.courses c where c.id=live_sessions.course_id and c.instructor_id=auth.uid())
  or exists(select 1 from public.enrollments e where e.course_id=live_sessions.course_id
    and e.student_id=auth.uid() and e.status='active')
);
create policy live_session_insert on public.live_sessions for insert to authenticated with check (
  starts_at > now() and exists(select 1 from public.courses c
    where c.id=live_sessions.course_id and c.instructor_id=auth.uid())
);
create policy live_session_update on public.live_sessions for update to authenticated
using(exists(select 1 from public.courses c where c.id=live_sessions.course_id and c.instructor_id=auth.uid()))
with check(exists(select 1 from public.courses c where c.id=live_sessions.course_id and c.instructor_id=auth.uid()));

create table public.push_devices (
  token text primary key check(length(token) between 20 and 4096),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check(platform in ('android','ios')),
  updated_at timestamptz not null default now()
);
alter table public.push_devices enable row level security;
revoke all on public.push_devices from anon, authenticated;
grant delete on public.push_devices to authenticated;
create policy push_device_delete on public.push_devices for delete to authenticated using(user_id=auth.uid());
create function public.register_push_device(p_token text,p_platform text) returns void
language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  insert into public.push_devices(token,user_id,platform) values(p_token,auth.uid(),p_platform)
    on conflict(token) do update set user_id=auth.uid(),platform=p_platform,updated_at=now();
end;
$$;
revoke all on function public.register_push_device(text,text) from public, anon;
grant execute on function public.register_push_device(text,text) to authenticated;

create table public.push_outbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.live_sessions(id) on delete cascade,
  title text not null,
  body text not null,
  status text not null default 'pending' check(status in ('pending','sending','sent','failed')),
  attempts integer not null default 0,
  available_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
alter table public.push_outbox enable row level security;
revoke all on public.push_outbox from anon,authenticated;
create index push_outbox_pending on public.push_outbox(status,available_at);
create function public.queue_live_session_push() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  if tg_op='UPDATE' and new is not distinct from old then return new; end if;
  insert into public.push_outbox(user_id,session_id,title,body)
  select e.student_id,new.id,
    case when new.cancelled then 'Live class cancelled' else 'Live class scheduled' end,
    'Open the app to view your course schedule.'
  from public.enrollments e where e.course_id=new.course_id and e.status='active';
  return new;
end;
$$;
create trigger live_session_push after insert or update on public.live_sessions
for each row execute function public.queue_live_session_push();
create function public.claim_push_batch() returns setof public.push_outbox
language sql security definer set search_path='' as $$
  update public.push_outbox set status='sending',attempts=attempts+1,available_at=now()+interval '5 minutes'
  where id in (select id from public.push_outbox where status in ('pending','sending')
    and available_at<=now() and attempts<5 order by created_at for update skip locked limit 20)
  returning *;
$$;
revoke all on function public.claim_push_batch() from public,anon,authenticated;
grant execute on function public.claim_push_batch() to service_role;
