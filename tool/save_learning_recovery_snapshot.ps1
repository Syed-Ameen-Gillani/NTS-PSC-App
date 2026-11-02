param([string]$Label='learning')
$ErrorActionPreference='Stop'
if($Label -notmatch '^[a-z0-9-]+$'){throw 'Use a simple snapshot label.'}
$inventory=Join-Path $env:TEMP ('cboa-inventory-'+[guid]::NewGuid().ToString('N')+'.sql')
$query=Join-Path $env:TEMP ('cboa-backup-'+[guid]::NewGuid().ToString('N')+'.sql')
try {
  Set-Content -LiteralPath $inventory -Value "select jsonb_agg(c.relname order by c.relname) tables from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r';"
  $raw=(& (Join-Path $PSScriptRoot 'query_supabase.ps1') -File $inventory) -join "`n"
  if($LASTEXITCODE -ne 0){throw 'Snapshot inventory failed.'}
  $tables=($raw.Substring($raw.IndexOf('{')) | ConvertFrom-Json).rows[0].tables
  $parts=@(foreach($table in $tables){
    if($table -notmatch '^[a-z_]+$'){throw 'Unexpected table name.'}
    "select '$table' name,coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) rows from public.$table t"
  })
  $sql="select jsonb_build_object('public_data',(select jsonb_object_agg(name,rows) from ("+($parts -join ' union all ')+") data),"+
    "'functions',(select jsonb_agg(pg_get_functiondef(p.oid)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prokind='f'),"+
    "'policies',(select jsonb_agg(to_jsonb(p)) from pg_policies p where schemaname in ('public','storage')),"+
    "'constraints',(select jsonb_agg(jsonb_build_object('table',conrelid::regclass::text,'name',conname,'definition',pg_get_constraintdef(oid))) from pg_constraint where connamespace='public'::regnamespace),"+
    "'triggers',(select jsonb_agg(pg_get_triggerdef(t.oid)) from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and not t.tgisinternal),"+
    "'table_grants',(select jsonb_agg(to_jsonb(g)) from information_schema.role_table_grants g where table_schema='public'),"+
    "'column_grants',(select jsonb_agg(to_jsonb(g)) from information_schema.role_column_grants g where table_schema='public'),"+
    "'migrations',(select jsonb_agg(to_jsonb(m)) from supabase_migrations.schema_migrations m)) recovery_snapshot;"
  Set-Content -LiteralPath $query -Value $sql -Encoding UTF8
  $backupPath=Join-Path $env:TEMP ('cboa-'+$Label+'-recovery-'+(Get-Date -Format yyyyMMdd_HHmmss)+'.json')
  & (Join-Path $PSScriptRoot 'query_supabase.ps1') -File $query > $backupPath
  if($LASTEXITCODE -ne 0){throw 'Snapshot export failed.'}
  $saved=Get-Content -LiteralPath $backupPath -Raw
  $snapshot=($saved.Substring($saved.IndexOf('{')) | ConvertFrom-Json).rows[0].recovery_snapshot
  if(-not $snapshot.public_data -or -not $snapshot.functions){throw 'Snapshot verification failed.'}
  Set-Content -LiteralPath (Join-Path $env:TEMP ('cboa-'+$Label+'-backup-path.txt')) -Value $backupPath
  [pscustomobject]@{SnapshotSaved=$true;Tables=@($tables).Count;Bytes=(Get-Item -LiteralPath $backupPath).Length;
    SHA256=(Get-FileHash -LiteralPath $backupPath -Algorithm SHA256).Hash} | ConvertTo-Json -Compress
} finally {
  Remove-Item -LiteralPath $inventory,$query -Force -ErrorAction SilentlyContinue
}
