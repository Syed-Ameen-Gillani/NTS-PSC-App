alter table public.push_outbox drop constraint push_outbox_status_check;
alter table public.push_outbox add constraint push_outbox_status_check
  check(status in ('pending','sending','sent','failed','skipped'));

create or replace function public.claim_push_batch() returns setof public.push_outbox
language plpgsql security definer set search_path='' as $$
begin
  update public.push_outbox set status='failed'
    where status='sending' and available_at<=now() and attempts>=5;
  return query update public.push_outbox set status='sending',attempts=attempts+1,available_at=now()+interval '15 minutes'
    where id in (select id from public.push_outbox where status in ('pending','sending')
      and available_at<=now() and attempts<5 order by created_at for update skip locked limit 5)
    returning *;
end;
$$;
