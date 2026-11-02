-- Privacy-safe teacher dashboard aggregates and provider-owned financial ledger.

create table public.teacher_earning_entries (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id),
  course_id uuid references public.courses (id) on delete set null,
  enrollment_id uuid references public.enrollments (id) on delete set null,
  gross_amount_minor bigint not null check (gross_amount_minor >= 0),
  platform_fee_minor bigint not null check (platform_fee_minor >= 0),
  net_amount_minor bigint not null check (net_amount_minor >= 0),
  currency char(3) not null default 'PKR' check (currency = 'PKR'),
  status text not null default 'pending'
    check (status in ('pending', 'available', 'paid', 'reversed')),
  provider_reference text unique,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check (gross_amount_minor = platform_fee_minor + net_amount_minor)
);

create table public.teacher_payouts (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id),
  amount_minor bigint not null check (amount_minor > 0),
  currency char(3) not null default 'PKR' check (currency = 'PKR'),
  method text not null check (method in ('bank', 'easypaisa', 'jazzcash')),
  account_mask text not null check (length(trim(account_mask)) > 0),
  status text not null default 'processing'
    check (status in ('processing', 'completed', 'failed', 'cancelled')),
  provider_reference text unique,
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create index teacher_earning_entries_owner_status_idx
  on public.teacher_earning_entries (teacher_id, status, occurred_at desc);
create index teacher_payouts_owner_requested_idx
  on public.teacher_payouts (teacher_id, requested_at desc);

alter table public.teacher_earning_entries enable row level security;
alter table public.teacher_payouts enable row level security;

revoke all on public.teacher_earning_entries, public.teacher_payouts
  from anon, authenticated;
grant select on public.teacher_earning_entries, public.teacher_payouts
  to authenticated;

create policy teacher_earning_entries_owner_read
on public.teacher_earning_entries for select to authenticated
using (teacher_id = (select auth.uid()));

create policy teacher_payouts_owner_read
on public.teacher_payouts for select to authenticated
using (teacher_id = (select auth.uid()));

create or replace function public.get_teacher_dashboard_overview(
  p_recent_limit integer default 5
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_teacher_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_recent_limit, 5), 1), 20);
begin
  if v_teacher_id is null or not exists (
    select 1 from public.profiles p
    where p.id = v_teacher_id and p.role = 'teacher'
  ) then
    raise exception 'Teacher account required' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'total_students', (
      select count(distinct e.student_id)
      from public.enrollments e
      join public.courses c on c.id = e.course_id
      where c.instructor_id = v_teacher_id
        and e.status in ('active', 'completed')
    ),
    'active_courses', (
      select count(*) from public.courses c
      where c.instructor_id = v_teacher_id and c.status = 'published'
    ),
    'recent_enrollments', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', recent.id,
        'student_name', recent.student_name,
        'course_title', recent.course_title,
        'enrolled_at', recent.enrolled_at
      ) order by recent.enrolled_at desc)
      from (
        select e.id, p.display_name as student_name, c.title as course_title,
          e.enrolled_at
        from public.enrollments e
        join public.courses c on c.id = e.course_id
        join public.profiles p on p.id = e.student_id
        where c.instructor_id = v_teacher_id
          and e.status in ('active', 'completed')
        order by e.enrolled_at desc
        limit v_limit
      ) recent
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.get_teacher_financial_overview(
  p_history_limit integer default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_teacher_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_history_limit, 50), 1), 100);
begin
  if v_teacher_id is null or not exists (
    select 1 from public.profiles p
    where p.id = v_teacher_id and p.role = 'teacher'
  ) then
    raise exception 'Teacher account required' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'currency', 'PKR',
    'gross_sales_minor', coalesce((
      select sum(e.gross_amount_minor) from public.teacher_earning_entries e
      where e.teacher_id = v_teacher_id and e.status <> 'reversed'
    ), 0),
    'platform_fee_minor', coalesce((
      select sum(e.platform_fee_minor) from public.teacher_earning_entries e
      where e.teacher_id = v_teacher_id and e.status <> 'reversed'
    ), 0),
    'net_earnings_minor', coalesce((
      select sum(e.net_amount_minor) from public.teacher_earning_entries e
      where e.teacher_id = v_teacher_id and e.status <> 'reversed'
    ), 0),
    'available_balance_minor', coalesce((
      select sum(e.net_amount_minor) from public.teacher_earning_entries e
      where e.teacher_id = v_teacher_id and e.status = 'available'
    ), 0),
    'pending_balance_minor', coalesce((
      select sum(e.net_amount_minor) from public.teacher_earning_entries e
      where e.teacher_id = v_teacher_id and e.status = 'pending'
    ), 0),
    'total_withdrawn_minor', coalesce((
      select sum(p.amount_minor) from public.teacher_payouts p
      where p.teacher_id = v_teacher_id and p.status = 'completed'
    ), 0),
    'payouts', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', history.id,
        'amount_minor', history.amount_minor,
        'currency', history.currency,
        'method', history.method,
        'account_mask', history.account_mask,
        'status', history.status,
        'provider_reference', history.provider_reference,
        'requested_at', history.requested_at,
        'processed_at', history.processed_at
      ) order by history.requested_at desc)
      from (
        select p.* from public.teacher_payouts p
        where p.teacher_id = v_teacher_id
        order by p.requested_at desc
        limit v_limit
      ) history
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_teacher_dashboard_overview(integer)
  from public, anon;
revoke all on function public.get_teacher_financial_overview(integer)
  from public, anon;
grant execute on function public.get_teacher_dashboard_overview(integer)
  to authenticated;
grant execute on function public.get_teacher_financial_overview(integer)
  to authenticated;
