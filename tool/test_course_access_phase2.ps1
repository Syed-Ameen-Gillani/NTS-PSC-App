param([switch]$RehearseMigrations)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$checks=Get-Content -LiteralPath (Join-Path $root 'supabase/tests/course_access_phase2.sql') -Raw
$phase1Checks=Get-Content -LiteralPath (Join-Path $root 'supabase/tests/course_release_phase1.sql') -Raw
$checks='do $runner$ begin execute $phase2$'+$checks+'$phase2$; execute $phase1$'+$phase1Checks+'$phase1$; end $runner$;'
$path=Join-Path $env:TEMP ('cboa-access-check-'+[guid]::NewGuid().ToString('N')+'.sql')
try {
  if($RehearseMigrations){
    $migrations=(Get-ChildItem -LiteralPath (Join-Path $root 'supabase/migrations') -Filter '2026102615*.sql' |
      Sort-Object Name | ForEach-Object {
        'begin execute $migration$'+(Get-Content -LiteralPath $_.FullName -Raw)+
          '$migration$; exception when others then get stacked diagnostics context=pg_exception_context; '+
          "raise exception 'Migration $($_.Name): % -- %',sqlerrm,context; end;"
      }) -join "`n"
    $sql='do $phase$ declare context text; begin begin '+$migrations+' execute $checks$'+$checks+
      '$checks$; raise exception using errcode=''ZX022'',message=''Rehearsal passed''; exception when sqlstate ''ZX022'' then null; end; '+
      'if to_regclass(''public.enrollment_access_audit'') is not null then raise exception ''Rollback failed''; end if; end $phase$;'
  } else {$sql=$checks}
  Set-Content -LiteralPath $path -Value $sql -Encoding UTF8
  & (Join-Path $PSScriptRoot 'query_supabase.ps1') -File $path
  if($LASTEXITCODE -ne 0){throw 'Phase 2 access checks failed.'}
  Write-Output 'PASS: Phase 2 pricing, entitlement, sequential access, protected storage and rollback checks.'
} finally {Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}
