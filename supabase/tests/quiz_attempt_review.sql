do $$
declare
  v_attempt_id uuid;
  v_student_id uuid;
  v_review jsonb;
begin
  select id, student_id into v_attempt_id, v_student_id
  from public.quiz_attempts order by submitted_at desc limit 1;
  if v_attempt_id is null then
    raise exception 'A retained quiz attempt is required for this test';
  end if;

  perform set_config('request.jwt.claim.sub', v_student_id::text, true);
  execute 'set local role authenticated';
  v_review := public.get_quiz_attempt_review(v_attempt_id);
  if v_review ->> 'attempt_id' <> v_attempt_id::text or
     jsonb_array_length(v_review -> 'questions') = 0 then
    raise exception 'Owner review is incomplete';
  end if;
  raise notice 'Quiz attempt owner can retrieve the saved review';

  perform set_config('request.jwt.claim.sub', gen_random_uuid()::text, true);
  begin
    perform public.get_quiz_attempt_review(v_attempt_id);
    raise exception 'Another student read the review';
  exception when raise_exception then
    if sqlerrm <> 'Quiz attempt unavailable' then
      raise;
    end if;
  end;
  raise notice 'Another student cannot retrieve the saved review';
end;
$$;
