do $$
declare
  v_teacher uuid;
  v_student uuid;
  v_overview jsonb;
  v_finance jsonb;
  v_expected_students integer;
begin
  select c.instructor_id into v_teacher
  from public.courses c
  join public.profiles p on p.id = c.instructor_id and p.role = 'teacher'
  limit 1;
  select p.id into v_student from public.profiles p
  where p.role = 'student' limit 1;
  if v_teacher is null or v_student is null then
    raise exception 'Retained teacher and student profiles are required';
  end if;

  perform set_config('request.jwt.claim.sub', v_teacher::text, true);
  execute 'set local role authenticated';
  v_overview := public.get_teacher_dashboard_overview(5);
  v_finance := public.get_teacher_financial_overview(50);

  select count(distinct e.student_id) into v_expected_students
  from public.enrollments e
  join public.courses c on c.id = e.course_id
  where c.instructor_id = v_teacher and e.status in ('active', 'completed');
  if (v_overview ->> 'total_students')::integer <> v_expected_students then
    raise exception 'Dashboard student aggregate is inaccurate';
  end if;
  if jsonb_typeof(v_overview -> 'recent_enrollments') <> 'array' then
    raise exception 'Recent enrollments must be an array';
  end if;
  if jsonb_typeof(v_finance -> 'payouts') <> 'array' or
     not v_finance ? 'available_balance_minor' then
    raise exception 'Financial overview contract is incomplete';
  end if;

  begin
    insert into public.teacher_payouts (
      teacher_id, amount_minor, method, account_mask
    ) values (v_teacher, 10000, 'bank', '****1234');
    raise exception 'Authenticated client inserted a payout';
  exception when insufficient_privilege then null;
  end;

  perform set_config('request.jwt.claim.sub', v_student::text, true);
  begin
    perform public.get_teacher_dashboard_overview(5);
    raise exception 'Student read teacher dashboard aggregate';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.get_teacher_financial_overview(50);
    raise exception 'Student read teacher financial aggregate';
  exception when insufficient_privilege then null;
  end;
end;
$$;
