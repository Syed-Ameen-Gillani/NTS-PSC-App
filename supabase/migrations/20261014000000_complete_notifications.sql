-- Durable notification inbox, generalized push queue, and device-local reminder intent.

create table public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null,
  category text not null check(category in (
    'course_updates','messages_discussions','exam_results','promotions'
  )),
  title text not null check(length(trim(title)) between 1 and 120),
  body text not null check(length(trim(body)) between 1 and 240),
  route text not null check(length(trim(route)) between 1 and 80),
  resource_id uuid,
  course_id uuid references public.courses(id) on delete cascade,
  dedupe_key text not null check(length(dedupe_key) between 1 and 240),
  available_at timestamptz not null default now(),
  expires_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id,dedupe_key),
  check(expires_at is null or expires_at > available_at)
);
create index app_notifications_user_feed_idx
  on public.app_notifications(user_id,available_at desc);
create index app_notifications_unread_idx
  on public.app_notifications(user_id,available_at desc) where read_at is null;
alter table public.app_notifications enable row level security;
revoke all on public.app_notifications from anon,authenticated;
grant select on public.app_notifications to authenticated;
create policy app_notifications_owner_read on public.app_notifications
  for select to authenticated using(user_id=(select auth.uid()));

create function public.mark_notification_read(p_notification_id uuid) returns void
language sql security definer set search_path='' as $$
  update public.app_notifications set read_at=coalesce(read_at,now()),updated_at=now()
  where id=p_notification_id and user_id=(select auth.uid());
$$;
create function public.mark_all_notifications_read() returns void
language sql security definer set search_path='' as $$
  update public.app_notifications set read_at=now(),updated_at=now()
  where user_id=(select auth.uid()) and read_at is null and available_at<=now();
$$;
revoke all on function public.mark_notification_read(uuid) from public,anon;
revoke all on function public.mark_all_notifications_read() from public,anon;
grant execute on function public.mark_notification_read(uuid) to authenticated;
grant execute on function public.mark_all_notifications_read() to authenticated;

create table public.local_notification_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reminder_key text not null check(length(reminder_key) between 1 and 200),
  event_type text not null,
  resource_id uuid not null,
  course_id uuid references public.courses(id) on delete cascade,
  scheduled_at timestamptz not null,
  title text not null check(length(trim(title)) between 1 and 120),
  body text not null check(length(trim(body)) between 1 and 240),
  enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  unique(user_id,reminder_key)
);
alter table public.local_notification_reminders enable row level security;
grant select,insert,update,delete on public.local_notification_reminders to authenticated;
create policy local_reminders_owner_all on public.local_notification_reminders
  for all to authenticated using(user_id=(select auth.uid()))
  with check(user_id=(select auth.uid()));

create table public.course_announcements (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  instructor_id uuid not null references public.profiles(id),
  title text not null check(length(trim(title)) between 1 and 120),
  message text not null check(length(trim(message)) between 1 and 1000),
  is_urgent boolean not null default false,
  created_at timestamptz not null default now()
);
create index course_announcements_course_idx
  on public.course_announcements(course_id,created_at desc);
alter table public.course_announcements enable row level security;
grant select,insert on public.course_announcements to authenticated;
create policy announcement_read on public.course_announcements for select
to authenticated using(
  instructor_id=(select auth.uid()) or exists(
    select 1 from public.enrollments e
    where e.course_id=course_announcements.course_id
      and e.student_id=(select auth.uid()) and e.status='active'
  )
);
create policy announcement_teacher_insert on public.course_announcements for insert
to authenticated with check(
  instructor_id=(select auth.uid()) and exists(
    select 1 from public.courses c where c.id=course_announcements.course_id
      and c.instructor_id=(select auth.uid())
  )
);

alter table public.push_devices
  add column if not exists installation_id text,
  add column if not exists last_seen_at timestamptz not null default now();

drop function if exists public.register_push_device(text,text);
create function public.register_push_device(
  p_token text,p_platform text,p_installation_id text default null
) returns void language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if p_platform not in ('android','ios') or length(p_token) not between 20 and 4096 then
    raise exception 'Invalid device registration';
  end if;
  insert into public.push_devices(
    token,user_id,platform,installation_id,updated_at,last_seen_at
  ) values(
    p_token,auth.uid(),p_platform,nullif(trim(p_installation_id),''),now(),now()
  ) on conflict(token) do update set
    user_id=auth.uid(),platform=p_platform,
    installation_id=excluded.installation_id,updated_at=now(),last_seen_at=now();
end;
$$;
revoke all on function public.register_push_device(text,text,text) from public,anon;
grant execute on function public.register_push_device(text,text,text) to authenticated;

alter table public.push_outbox alter column session_id drop not null;
alter table public.push_outbox
  add column notification_id uuid references public.app_notifications(id) on delete cascade,
  add column event_type text,
  add column category text,
  add column route text,
  add column resource_id uuid,
  add column course_id uuid references public.courses(id) on delete cascade,
  add column expires_at timestamptz,
  add column dedupe_key text;
create unique index push_outbox_notification_unique
  on public.push_outbox(notification_id) where notification_id is not null;

create table public.push_delivery_receipts (
  outbox_id uuid not null references public.push_outbox(id) on delete cascade,
  token text not null references public.push_devices(token) on delete cascade,
  delivered_at timestamptz not null default now(),
  primary key(outbox_id,token)
);
alter table public.push_delivery_receipts enable row level security;
revoke all on public.push_delivery_receipts from anon,authenticated;

update public.push_outbox set
  event_type='live_class_updated',category='course_updates',route='live_classes',
  resource_id=session_id,dedupe_key='legacy-live:'||id::text
where event_type is null;

create or replace function public.enqueue_app_notification(
  p_user_id uuid,p_event_type text,p_category text,p_title text,p_body text,
  p_route text,p_resource_id uuid,p_course_id uuid,p_dedupe_key text,
  p_available_at timestamptz default now(),p_expires_at timestamptz default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_outbox_id uuid;
begin
  if p_available_at is null or (p_expires_at is not null and p_expires_at<=p_available_at) then
    return null;
  end if;
  insert into public.app_notifications(
    user_id,event_type,category,title,body,route,resource_id,course_id,
    dedupe_key,available_at,expires_at
  ) values(
    p_user_id,p_event_type,p_category,left(trim(p_title),120),left(trim(p_body),240),
    p_route,p_resource_id,p_course_id,p_dedupe_key,p_available_at,p_expires_at
  ) on conflict(user_id,dedupe_key) do update set
    event_type=excluded.event_type,category=excluded.category,title=excluded.title,
    body=excluded.body,route=excluded.route,resource_id=excluded.resource_id,
    course_id=excluded.course_id,available_at=excluded.available_at,
    expires_at=excluded.expires_at,read_at=null,updated_at=now()
  returning id into v_id;

  insert into public.push_outbox(
    user_id,session_id,title,body,status,attempts,available_at,notification_id,
    event_type,category,route,resource_id,course_id,expires_at,dedupe_key
  ) values(
    p_user_id,case when p_event_type like 'live_class_%' then p_resource_id else null end,
    left(trim(p_title),120),left(trim(p_body),240),'pending',0,p_available_at,v_id,
    p_event_type,p_category,p_route,p_resource_id,p_course_id,p_expires_at,p_dedupe_key
  ) on conflict(notification_id) where notification_id is not null do update set
    title=excluded.title,body=excluded.body,status='pending',attempts=0,
    available_at=excluded.available_at,event_type=excluded.event_type,
    category=excluded.category,route=excluded.route,resource_id=excluded.resource_id,
    course_id=excluded.course_id,expires_at=excluded.expires_at,
    dedupe_key=excluded.dedupe_key
  returning id into v_outbox_id;
  delete from public.push_delivery_receipts where outbox_id=v_outbox_id;
  return v_id;
end;
$$;
revoke all on function public.enqueue_app_notification(
  uuid,text,text,text,text,text,uuid,uuid,text,timestamptz,timestamptz
) from public,anon,authenticated;

create or replace function public.queue_live_session_push() returns trigger
language plpgsql security definer set search_path='' as $$
declare v_event text; v_title text; v_body text; recipient record;
begin
  if tg_op='UPDATE' and new is not distinct from old then return new; end if;
  if new.cancelled then
    delete from public.local_notification_reminders
      where event_type='live_class_reminder' and resource_id=new.id;
  elsif tg_op='UPDATE' and new.starts_at is distinct from old.starts_at then
    update public.local_notification_reminders
      set scheduled_at=new.starts_at-interval '15 minutes',updated_at=now()
      where event_type='live_class_reminder' and resource_id=new.id
        and new.starts_at-interval '15 minutes'>now();
    delete from public.local_notification_reminders
      where event_type='live_class_reminder' and resource_id=new.id
        and new.starts_at-interval '15 minutes'<=now();
  end if;
  v_event:=case when new.cancelled then 'live_class_cancelled'
    when tg_op='INSERT' then 'live_class_scheduled' else 'live_class_updated' end;
  v_title:=case when new.cancelled then 'Live class cancelled'
    when tg_op='INSERT' then 'Live class scheduled' else 'Live class updated' end;
  v_body:='Open the app to view the latest class schedule.';
  for recipient in select e.student_id from public.enrollments e
    where e.course_id=new.course_id and e.status='active'
  loop
    perform public.enqueue_app_notification(
      recipient.student_id,v_event,'course_updates',v_title,v_body,'live_classes',
      new.id,new.course_id,'live-session:'||new.id::text,now(),
      new.starts_at+make_interval(mins=>new.duration_minutes)
    );
  end loop;
  return new;
end;
$$;

create function public.queue_assignment_notifications() returns trigger
language plpgsql security definer set search_path='' as $$
declare recipient record; reminder_at timestamptz;
begin
  if new.status='published' and (
    tg_op='INSERT' or old.status='draft' or
    (new.title,new.due_at) is distinct from (old.title,old.due_at)
  ) then
    reminder_at:=new.due_at-interval '24 hours';
    for recipient in select e.student_id from public.enrollments e
      where e.course_id=new.course_id and e.status='active'
    loop
      perform public.enqueue_app_notification(
        recipient.student_id,'assignment_published','course_updates',
        'New assignment available','Open the app to review the assignment and due date.',
        'student_assignment',new.id,new.course_id,'assignment:'||new.id::text,
        now(),new.due_at
      );
      if reminder_at>now() then
        perform public.enqueue_app_notification(
          recipient.student_id,'assignment_due_reminder','course_updates',
          'Assignment due tomorrow','Open the app to finish your assignment.',
          'student_assignment',new.id,new.course_id,
          'assignment-due:'||new.id::text,reminder_at,new.due_at
        );
      end if;
    end loop;
  end if;
  return new;
end;
$$;
create trigger assignment_notifications after insert or update on public.assignments
for each row execute function public.queue_assignment_notifications();

create function public.queue_submission_notifications() returns trigger
language plpgsql security definer set search_path='' as $$
declare v_course uuid; v_teacher uuid;
begin
  select a.course_id,c.instructor_id into v_course,v_teacher
  from public.assignments a join public.courses c on c.id=a.course_id
  where a.id=new.assignment_id;
  if tg_op='INSERT' or new.current_revision is distinct from old.current_revision then
    perform public.enqueue_app_notification(
      v_teacher,'assignment_submitted','course_updates','Assignment submitted',
      'A learner submitted work for review.','teacher_review_assignment',
      new.assignment_id,v_course,
      'assignment-submission:'||new.id::text||':'||new.current_revision::text,
      now(),null
    );
  end if;
  if tg_op='UPDATE' and new.status in ('approved','disapproved')
    and new.status is distinct from old.status then
    perform public.enqueue_app_notification(
      new.student_id,'assignment_reviewed','exam_results','Assignment reviewed',
      'Your instructor reviewed your assignment. Open the app for details.',
      'student_assignment',new.assignment_id,v_course,
      'assignment-review:'||new.id::text||':'||new.current_revision::text,
      now(),null
    );
  end if;
  return new;
end;
$$;
create trigger submission_notifications after insert or update
on public.assignment_submissions for each row
execute function public.queue_submission_notifications();

create function public.queue_quiz_notifications() returns trigger
language plpgsql security definer set search_path='' as $$
declare recipient record;
begin
  if new.status='published' and new.course_id is not null and
    (tg_op='INSERT' or old.status='draft') then
    for recipient in select e.student_id from public.enrollments e
      where e.course_id=new.course_id and e.status='active'
    loop
      perform public.enqueue_app_notification(
        recipient.student_id,'quiz_published','course_updates','New quiz available',
        'Open the app when you are ready to begin.','active_quiz',new.id,
        new.course_id,'quiz:'||new.id::text,now(),null
      );
    end loop;
  end if;
  return new;
end;
$$;
create trigger quiz_notifications after insert or update on public.quizzes
for each row execute function public.queue_quiz_notifications();

create function public.queue_lesson_notifications() returns trigger
language plpgsql security definer set search_path='' as $$
declare v_course uuid; recipient record;
begin
  if new.status='published' and (tg_op='INSERT' or old.status='draft') then
    select m.course_id into v_course from public.course_modules m where m.id=new.module_id;
    for recipient in select e.student_id from public.enrollments e
      where e.course_id=v_course and e.status='active'
    loop
      perform public.enqueue_app_notification(
        recipient.student_id,'lesson_published','course_updates','New lesson available',
        'A new lesson was added to one of your courses.','lesson_player',new.id,
        v_course,'lesson:'||new.id::text,now(),null
      );
    end loop;
  end if;
  return new;
end;
$$;
create trigger lesson_notifications after insert or update on public.lessons
for each row execute function public.queue_lesson_notifications();

create function public.queue_announcement_notifications() returns trigger
language plpgsql security definer set search_path='' as $$
declare recipient record;
begin
  for recipient in select e.student_id from public.enrollments e
    where e.course_id=new.course_id and e.status='active'
  loop
    perform public.enqueue_app_notification(
      recipient.student_id,'announcement','messages_discussions',new.title,
      'Your instructor posted a course announcement.','course_detail',new.id,
      new.course_id,'announcement:'||new.id::text,now(),null
    );
  end loop;
  return new;
end;
$$;
create trigger announcement_notifications after insert on public.course_announcements
for each row execute function public.queue_announcement_notifications();

create function public.notification_delivery_allowed(p_notification_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare n public.app_notifications; pref public.user_notification_preferences;
begin
  select * into n from public.app_notifications where id=p_notification_id;
  if not found or n.available_at>now() or (n.expires_at is not null and n.expires_at<=now()) then
    return false;
  end if;
  select * into pref from public.user_notification_preferences where user_id=n.user_id;
  if not found or not pref.push_enabled then return false; end if;
  if n.category='course_updates' and not pref.course_updates_enabled then return false; end if;
  if n.category='messages_discussions' and not pref.messages_discussions_enabled then return false; end if;
  if n.category='exam_results' and not pref.exam_results_enabled then return false; end if;
  if n.category='promotions' and not pref.promotions_enabled then return false; end if;

  if n.event_type like 'live_class_%' then
    return exists(select 1 from public.live_sessions s join public.enrollments e
      on e.course_id=s.course_id and e.student_id=n.user_id and e.status='active'
      where s.id=n.resource_id);
  elsif n.event_type in ('assignment_published','assignment_due_reminder','assignment_reviewed') then
    return exists(select 1 from public.assignments a join public.enrollments e
      on e.course_id=a.course_id and e.student_id=n.user_id and e.status='active'
      where a.id=n.resource_id and a.status='published')
      and (n.event_type<>'assignment_due_reminder' or not exists(
        select 1 from public.assignment_submissions s
        where s.assignment_id=n.resource_id and s.student_id=n.user_id
      ));
  elsif n.event_type='assignment_submitted' then
    return exists(select 1 from public.assignments a join public.courses c on c.id=a.course_id
      where a.id=n.resource_id and c.instructor_id=n.user_id);
  elsif n.event_type='quiz_published' then
    return exists(select 1 from public.quizzes q join public.enrollments e
      on e.course_id=q.course_id and e.student_id=n.user_id and e.status='active'
      where q.id=n.resource_id and q.status='published');
  elsif n.event_type='lesson_published' then
    return exists(select 1 from public.lessons l join public.course_modules m on m.id=l.module_id
      join public.enrollments e on e.course_id=m.course_id and e.student_id=n.user_id
      and e.status='active' where l.id=n.resource_id and l.status='published');
  elsif n.course_id is not null then
    return exists(select 1 from public.enrollments e where e.course_id=n.course_id
      and e.student_id=n.user_id and e.status='active');
  end if;
  return n.event_type='promotion';
end;
$$;
revoke all on function public.notification_delivery_allowed(uuid)
  from public,anon,authenticated;
grant execute on function public.notification_delivery_allowed(uuid) to service_role;

create or replace function public.claim_push_batch() returns setof public.push_outbox
language plpgsql security definer set search_path='' as $$
begin
  update public.push_outbox set status='failed'
    where status='sending' and available_at<=now() and attempts>=5;
  update public.push_outbox set status='skipped'
    where status in ('pending','sending') and expires_at is not null and expires_at<=now();
  return query update public.push_outbox set
    status='sending',attempts=attempts+1,available_at=now()+interval '15 minutes'
    where id in (select id from public.push_outbox where status in ('pending','sending')
      and available_at<=now() and attempts<5
      and (expires_at is null or expires_at>now())
      order by available_at for update skip locked limit 20)
    returning *;
end;
$$;

create or replace function public.prune_notification_data() returns void
language sql security definer set search_path='' as $$
  delete from public.push_devices where last_seen_at<now()-interval '60 days';
  delete from public.app_notifications where
    coalesce(expires_at,created_at+interval '90 days')<now();
  delete from public.local_notification_reminders where scheduled_at<now()-interval '1 day';
$$;
revoke all on function public.prune_notification_data() from public,anon,authenticated;
grant execute on function public.prune_notification_data() to service_role;
