-- Trusted delivery scheduler. The bearer value is read from Vault at runtime.
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

create function public.dispatch_notification_worker() returns bigint
language plpgsql security definer set search_path='' as $$
declare worker_secret text; request_id bigint;
begin
  select decrypted_secret into worker_secret from vault.decrypted_secrets
  where name in ('notification_worker_secret','NOTIFICATION_WORKER_SECRET')
  order by case when name='notification_worker_secret' then 0 else 1 end limit 1;
  if worker_secret is null then
    raise warning 'Notification worker secret is missing from Vault';
    return null;
  end if;
  select net.http_post(
    url:='https://rgpeouxesbemysmwbzmu.supabase.co/functions/v1/send-push',
    headers:=jsonb_build_object(
      'Content-Type','application/json',
      'Authorization','Bearer '||worker_secret
    ),
    body:='{}'::jsonb,
    timeout_milliseconds:=15000
  ) into request_id;
  return request_id;
end;
$$;
revoke all on function public.dispatch_notification_worker()
  from public,anon,authenticated;

do $$
declare existing_job bigint;
begin
  select jobid into existing_job from cron.job
    where jobname='nts-psc-push-worker' limit 1;
  if existing_job is not null then perform cron.unschedule(existing_job); end if;
end;
$$;
select cron.schedule(
  'nts-psc-push-worker','* * * * *',
  'select public.dispatch_notification_worker();'
);

do $$
declare existing_job bigint;
begin
  select jobid into existing_job from cron.job
    where jobname='nts-psc-notification-cleanup' limit 1;
  if existing_job is not null then perform cron.unschedule(existing_job); end if;
end;
$$;
select cron.schedule(
  'nts-psc-notification-cleanup','17 3 * * *',
  'select public.prune_notification_data();'
);
