-- The outbox sends at most 50 records, committing acknowledgements per batch.
-- Retain two full batches per session for lost-response retries, not every tick
-- forever. Durable coverage/completion is independent of these replay receipts.
alter function public.apply_learning_evidence(jsonb) rename to apply_learning_evidence_before_retention;
revoke all on function public.apply_learning_evidence_before_retention(jsonb) from public,anon,authenticated;
create function public.apply_learning_evidence(p_event jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 result:=public.apply_learning_evidence_before_retention(p_event);
 delete from public.learning_evidence_receipts r using public.learning_evidence_sessions s
   where s.id=(p_event->>'session_id')::uuid and s.student_id=auth.uid()
     and r.session_id=s.id and r.sequence<s.next_sequence-100;
 return result;
end;
$$;
revoke all on function public.apply_learning_evidence(jsonb) from public,anon,authenticated;
