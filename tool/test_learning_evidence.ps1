param([switch]$RehearseMigrations)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$checks=Get-Content -LiteralPath (Join-Path $root 'supabase/tests/learning_evidence_phase3.sql') -Raw
$path=Join-Path $env:TEMP ('cboa-evidence-check-'+[guid]::NewGuid().ToString('N')+'.sql')
try {
  if($RehearseMigrations){
    $migrations=(Get-ChildItem -LiteralPath (Join-Path $root 'supabase/migrations') -Filter '2026102616*.sql' |
      Sort-Object Name | ForEach-Object {
        'begin execute $migration$'+(Get-Content -LiteralPath $_.FullName -Raw)+
          '$migration$; exception when others then get stacked diagnostics context=pg_exception_context; '+
          "raise exception 'Migration $($_.Name): % -- %',sqlerrm,context; end;"
      }) -join "`n"
    $sql='do $phase$ declare context text; begin begin '+$migrations+' execute $checks$'+$checks+
      '$checks$; raise exception using errcode=''ZX032'',message=''Rehearsal passed''; exception when sqlstate ''ZX032'' then null; end; '+
      'if to_regclass(''public.learning_evidence_sessions'') is not null then raise exception ''Rollback failed''; end if; end $phase$;'
  } else {$sql=$checks}
  Set-Content -LiteralPath $path -Value $sql -Encoding UTF8
  & (Join-Path $PSScriptRoot 'query_supabase.ps1') -File $path
  if($LASTEXITCODE -ne 0){throw 'Learning evidence checks failed.'}
  Write-Output 'PASS: automatic progress, access, replay and rollback checks.'
} finally {Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}
