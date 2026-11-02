create function public.prune_learning_evidence()
returns void language plpgsql security definer set search_path='' as $$
declare expired uuid[];
begin
 select array_agg(id) into expired from (select id from public.learning_evidence_sessions
   where expires_at<now()-interval '1 day' order by expires_at,id limit 1000 for update skip locked) s;
 if expired is null then return; end if;
 delete from public.learning_evidence_receipts where session_id=any(expired);
 delete from public.learning_evidence_sessions where id=any(expired);
 -- Activity coverage, grades, completion and certificate history are retained.
end;
$$;
revoke all on function public.prune_learning_evidence() from public,anon,authenticated;
grant execute on function public.prune_learning_evidence() to service_role;
select cron.schedule('cboa-learning-evidence-retention-v1','23 * * * *',
  'select public.prune_learning_evidence();');

-- Older in-flight AI jobs must not later resurrect a replaced video. Retain
-- the row/files when referenced by release history; only retire its processing.
create or replace function public.archive_replaced_lesson_media()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.video_path is distinct from old.video_path then
   update public.lesson_media set status='archived'
     where lesson_id=new.id and status not in ('uploading','archived') and object_path is distinct from new.video_path;
 end if;
 return new;
end;
$$;
