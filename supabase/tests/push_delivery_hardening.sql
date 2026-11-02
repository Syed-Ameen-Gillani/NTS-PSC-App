do $$
declare
  student uuid;
  teacher uuid;
  category uuid;
  course uuid := gen_random_uuid();
  meeting uuid;
  expired_id uuid := gen_random_uuid();
  retry_id uuid := gen_random_uuid();
  active_id uuid := gen_random_uuid();
  claimed_ids uuid[];
begin
  begin
    select id into student from public.profiles
      where role='student' and display_name like '%TEST%' limit 1;
    if student is null then raise exception 'Retained test student required'; end if;
    select id into teacher from public.profiles
      where role='teacher' and display_name like '%TEST%' limit 1;
    select id into category from public.categories where is_active limit 1;
    if teacher is null then raise exception 'Retained test teacher required'; end if;
    insert into public.courses(id,instructor_id,category_id,title)
      values(course,teacher,category,'QUEUE TEST');
    insert into public.live_sessions(course_id,title,meeting_url,starts_at,duration_minutes)
      values(course,'QUEUE TEST','https://meet.google.com/test',now()+interval '1 day',60)
      returning id into meeting;

    -- Isolate queue fixtures within this rolled-back subtransaction.
    lock table public.push_outbox in exclusive mode;
    update public.push_outbox set available_at=now()+interval '1 day';
    insert into public.push_outbox(id,user_id,session_id,title,body,status,attempts,available_at)
      values
        (expired_id,student,meeting,'QUEUE TEST','Expired lease','sending',5,now()-interval '1 minute'),
        (retry_id,student,meeting,'QUEUE TEST','Retry lease','sending',1,now()-interval '1 minute'),
        (active_id,student,meeting,'QUEUE TEST','Active lease','sending',1,now()+interval '1 minute');
    execute 'set local role service_role';
    select array_agg(id) into claimed_ids from public.claim_push_batch();
    execute 'reset role';
    if claimed_ids is distinct from array[retry_id] then
      raise exception 'Worker did not exclusively reclaim expired retryable job';
    end if;
    if not exists(select 1 from public.push_outbox where id=expired_id and status='failed') then
      raise exception 'Exhausted job remained stuck';
    end if;
    if not exists(select 1 from public.push_outbox where id=retry_id and attempts=2
      and available_at>now()+interval '14 minutes') then
      raise exception 'Retry count or lease duration is incorrect';
    end if;
    update public.push_outbox set status='skipped' where id=retry_id;
    execute 'set local role authenticated';
    begin
      perform public.claim_push_batch();
      raise exception 'Authenticated user claimed service queue';
    exception when insufficient_privilege then null;
    end;
    raise exception 'Rollback queue tests';
  exception when raise_exception then
    if sqlerrm <> 'Rollback queue tests' then raise; end if;
  end;
end;
$$;
