-- Existing price_amount values are whole PKR, not minor units.
alter table public.courses add constraint course_price_range check(price_amount between 0 and 1000000) not valid;
alter table public.courses validate constraint course_price_range;

create function public.create_priced_course_draft(p_course_id uuid,p_category text,
  p_title text,p_description text,p_modules jsonb,p_price_amount integer)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_existing public.courses;
begin
  if p_price_amount is null or p_price_amount not between 0 and 1000000 then
    raise exception 'Enter a price between 1 and 1,000,000 PKR, or choose Free'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_course_id::text,1));
  select * into v_existing from public.courses where id=p_course_id;
  if found then
    if v_existing.instructor_id is distinct from auth.uid() then
      raise exception 'Course unavailable' using errcode='42501'; end if;
    if v_existing.price_amount<>p_price_amount then raise exception 'This draft was already saved with a different price'; end if;
    return v_existing.id;
  end if;
  v_id:=public.create_course_draft(p_course_id,p_category,p_title,p_description,p_modules);
  update public.courses set price_amount=p_price_amount where id=v_id;
  return v_id;
end;
$$;
revoke all on function public.create_priced_course_draft(uuid,text,text,text,jsonb,integer) from public,anon;
grant execute on function public.create_priced_course_draft(uuid,text,text,text,jsonb,integer) to authenticated;

create table public.enrollment_access_audit (
  request_id uuid primary key,
  enrollment_id uuid not null references public.enrollments(id),
  actor_reference text not null check(length(trim(actor_reference)) between 1 and 200),
  reason text not null check(length(trim(reason)) between 1 and 500),
  action text not null check(action in ('grant','revoke')),
  created_at timestamptz not null default now()
);
alter table public.enrollment_access_audit enable row level security;
revoke all on public.enrollment_access_audit from anon,authenticated;
-- No teacher/client can call this. A privileged operator is responsible for
-- verifying authorization; this endpoint does not claim a payment occurred.
create function public.admin_set_course_access(p_request_id uuid,p_student_id uuid,
  p_course_id uuid,p_granted boolean,p_actor_reference text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_saved public.enrollment_access_audit;
begin
  if p_request_id is null or p_granted is null then raise exception 'Request identity and action required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_request_id::text,2));
  select * into v_saved from public.enrollment_access_audit where request_id=p_request_id;
  if found then
    if v_saved.action<>(case when p_granted then 'grant' else 'revoke' end) or not exists(
      select 1 from public.enrollments e where e.id=v_saved.enrollment_id
        and e.student_id=p_student_id and e.course_id=p_course_id) then
      raise exception 'Request identity was already used for another operation'; end if;
    return v_saved.enrollment_id;
  end if;
  perform 1 from public.courses where id=p_course_id and (not p_granted or status='published') for share;
  if not found or not exists(select 1 from public.profiles where id=p_student_id and role='student') then
    raise exception 'Published course and student required'; end if;
  insert into public.enrollments(student_id,course_id,source,status)
    values(p_student_id,p_course_id,'manual',case when p_granted then 'active' else 'cancelled' end)
    on conflict(student_id,course_id) do update set status=excluded.status
    returning id into v_id;
  insert into public.enrollment_access_audit(request_id,enrollment_id,actor_reference,reason,action)
    values(p_request_id,v_id,p_actor_reference,p_reason,case when p_granted then 'grant' else 'revoke' end);
  return v_id;
end;
$$;
revoke all on function public.admin_set_course_access(uuid,uuid,uuid,boolean,text,text) from public,anon,authenticated;
grant execute on function public.admin_set_course_access(uuid,uuid,uuid,boolean,text,text) to service_role;

create function public.has_course_entitlement(p_course uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select auth.uid() is not null and exists(select 1 from public.enrollments e
    join public.courses c on c.id=e.course_id where c.id=p_course and c.status='published'
      and e.student_id=auth.uid() and e.status in ('active','completed'));
$$;
revoke all on function public.has_course_entitlement(uuid) from public;
grant execute on function public.has_course_entitlement(uuid) to anon,authenticated;

-- Prevent bypassing the audited/free RPCs through direct enrollment writes.
revoke insert,update,delete on public.enrollments from anon,authenticated;
