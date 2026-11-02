select
  (select count(*)
   from vault.decrypted_secrets
   where name in ('notification_worker_secret', 'NOTIFICATION_WORKER_SECRET'))
    as worker_secret_count,
  (select count(*)
   from cron.job
   where active
     and jobname in ('nts-psc-push-worker', 'nts-psc-notification-cleanup'))
    as active_notification_jobs,
  (select status_code
   from net._http_response
   order by created desc
   limit 1) as latest_worker_status;
