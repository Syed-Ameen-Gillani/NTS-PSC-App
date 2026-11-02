create function public.apply_learning_evidence(p_event jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.learning_evidence_sessions; p public.learning_activity_progress; c public.learning_engagement_clocks;
  v_course uuid;spec jsonb;seq integer;wall bigint;v_start bigint;v_end bigint;speed numeric;v_hash text;covered bigint;dwell bigint;
begin
  seq:=(p_event->>'sequence')::integer;wall:=(p_event->>'wall_ms')::bigint;
  v_start:=(p_event->>'start')::bigint;v_end:=(p_event->>'end')::bigint;speed:=(p_event->>'speed')::numeric;
  if seq is null or wall is null or v_start is null or v_end is null or speed is null
    or seq<1 or wall not between 1 and 10000 or v_start<0 or v_end<=v_start or speed not between 0.5 and 2 then
    raise exception 'Invalid learning sample' using errcode='22023'; end if;
  select * into s from public.learning_evidence_sessions where id=(p_event->>'session_id')::uuid and student_id=auth.uid() for update;
  if not found then raise exception 'Learning session unavailable' using errcode='42501'; end if;
  v_hash:=md5(p_event::text);
  if seq<s.next_sequence then
    if not exists(select 1 from public.learning_evidence_receipts where session_id=s.id and sequence=seq and payload_hash=v_hash) then
      raise exception 'Sample identity conflict' using errcode='22023'; end if;
    return jsonb_build_object('accepted',true,'duplicate',true,'lesson_id',s.lesson_id,
      'activity_completed',exists(select 1 from public.learning_activity_progress where enrollment_id=s.enrollment_id
        and activity_id=s.activity_id and content_version=s.content_version and completed_at is not null),
      'lesson_completed',exists(select 1 from public.lesson_progress where enrollment_id=s.enrollment_id
        and lesson_id=s.lesson_id and completed_at is not null));
  end if;
  if seq<>s.next_sequence then raise exception 'Samples must sync in order' using errcode='22023'; end if;
  select course_id into v_course from public.enrollments where id=s.enrollment_id;
  if not public.has_course_entitlement(v_course) or not public.can_open_lesson(v_course,s.lesson_id)
    or clock_timestamp()>s.expires_at then raise exception 'Learning session expired or access changed' using errcode='42501'; end if;
  spec:=public.learning_activity_descriptor(s.lesson_id,s.activity_id);
  if spec->>'version'<>s.content_version then raise exception 'Content changed. Continue the current lesson version' using errcode='22023'; end if;
  select * into c from public.learning_engagement_clocks where student_id=auth.uid() for update;
  if s.engaged_ms+wall>extract(epoch from(clock_timestamp()-s.started_at))*1000+2000
    or c.engaged_ms+wall>extract(epoch from(clock_timestamp()-c.started_at))*1000+2000 then
    raise exception 'Learning time exceeds the session clock' using errcode='22023'; end if;
  if v_end>s.units or (s.kind='video' and v_end-v_start>wall*speed+300)
    or (s.kind<>'video' and v_end<>v_start+1) then
    raise exception 'Seeking or invalid page coverage cannot complete an activity' using errcode='22023'; end if;
  insert into public.learning_activity_progress(enrollment_id,activity_id,content_version)
    values(s.enrollment_id,s.activity_id,s.content_version) on conflict do nothing;
  select * into p from public.learning_activity_progress where enrollment_id=s.enrollment_id
    and activity_id=s.activity_id and content_version=s.content_version for update;
  if s.kind='video' then p.coverage:=p.coverage+int8multirange(int8range(v_start,v_end,'[)'));
  else
    dwell:=coalesce((p.page_times->>v_start::text)::bigint,0)+wall;
    p.page_times:=p.page_times||jsonb_build_object(v_start::text,dwell);
    if dwell>=least(2000,greatest(1000,s.min_ms/s.units)) then
      p.coverage:=p.coverage+int8multirange(int8range(v_start,v_end,'[)')); end if;
  end if;
  p.engaged_ms:=p.engaged_ms+wall;
  select coalesce(sum(upper(r)-lower(r)),0) into covered from unnest(p.coverage) r;
  if (s.kind='video' and covered>=ceil(s.units*0.90)) or
    (s.kind<>'video' and covered>=s.units and p.engaged_ms>=s.min_ms) then p.completed_at:=coalesce(p.completed_at,now()); end if;
  update public.learning_activity_progress set coverage=p.coverage,page_times=p.page_times,
    engaged_ms=p.engaged_ms,completed_at=p.completed_at where enrollment_id=s.enrollment_id
      and activity_id=s.activity_id and content_version=s.content_version;
  update public.learning_evidence_sessions set next_sequence=next_sequence+1,engaged_ms=engaged_ms+wall where id=s.id;
  update public.learning_engagement_clocks set engaged_ms=engaged_ms+wall where student_id=auth.uid();
  insert into public.learning_evidence_receipts values(s.id,seq,v_hash);
  perform public.reconcile_course_completion(auth.uid());
  return jsonb_build_object('accepted',true,'activity_completed',p.completed_at is not null,'lesson_id',s.lesson_id,
    'lesson_completed',exists(select 1 from public.lesson_progress where enrollment_id=s.enrollment_id and lesson_id=s.lesson_id and completed_at is not null));
end;
$$;
create function public.record_learning_evidence(p_events jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_event jsonb;v_results jsonb:='[]';v_result jsonb;
begin
  if auth.uid() is null or jsonb_typeof(p_events) is distinct from 'array' or jsonb_array_length(p_events)>50 then
    raise exception 'Sign in and send up to 50 samples' using errcode='22023'; end if;
  -- Same lock order as grade/completion reconciliation; one account budget.
  perform e.id from public.enrollments e where e.student_id=auth.uid() and e.status in ('active','completed') order by e.id for update;
  for v_event in select value from jsonb_array_elements(p_events) loop
    begin v_result:=public.apply_learning_evidence(v_event);
    exception when sqlstate '42501' or sqlstate '22023' or invalid_text_representation or numeric_value_out_of_range then
      v_result:=jsonb_build_object('accepted',false,'message',sqlerrm); end;
    v_results:=v_results||jsonb_build_array(v_result);
  end loop;
  return v_results;
end;
$$;
revoke all on function public.apply_learning_evidence(jsonb) from public,anon,authenticated;
revoke all on function public.record_learning_evidence(jsonb) from public,anon;
grant execute on function public.record_learning_evidence(jsonb) to authenticated;
