-- Deferred PDF opens must identify the version actually opened, including
-- offline replay. Never credit a replacement file using an old cached ticket.
create function public.confirm_learning_material_session_opened(p_session_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  s public.learning_evidence_sessions;
  spec jsonb;
begin
  -- Match the enrollment lock order used by evidence and grading.
  perform e.id from public.enrollments e where e.student_id=auth.uid()
    and e.status in ('active','completed') order by e.id for update;
  select * into s from public.learning_evidence_sessions
    where id=p_session_id and student_id=auth.uid() for update;
  if not found or s.kind<>'material' or clock_timestamp()>s.expires_at then
    raise exception 'Reopen this handout online' using errcode='42501';
  end if;
  spec:=public.learning_activity_descriptor(s.lesson_id,s.activity_id);
  if spec->>'version' is distinct from s.content_version then
    raise exception 'Handout changed. Open the current version' using errcode='22023';
  end if;
  return public.confirm_learning_material_opened(s.lesson_id,s.activity_id);
end;
$$;
revoke all on function public.confirm_learning_material_session_opened(uuid)
  from public,anon;
grant execute on function public.confirm_learning_material_session_opened(uuid)
  to authenticated;
