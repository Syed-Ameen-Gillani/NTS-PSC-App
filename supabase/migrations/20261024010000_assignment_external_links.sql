alter table public.assignments
  add column external_url text
  constraint assignment_external_url_https check (
    external_url is null or (
      length(external_url) <= 2048 and
      external_url ~ '^https://[^[:space:]]+$'
    )
  );

grant insert (external_url), update (external_url)
  on public.assignments to authenticated;
