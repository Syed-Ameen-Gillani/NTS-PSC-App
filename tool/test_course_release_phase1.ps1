param([switch]$RehearseMigrations)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$checks = Get-Content -LiteralPath (Join-Path $root 'supabase/tests/course_release_phase1.sql') -Raw
$queryPath = Join-Path $env:TEMP ('cboa-release-check-' + [guid]::NewGuid().ToString('N') + '.sql')
try {
  if ($RehearseMigrations) {
    $migrations = (Get-ChildItem -LiteralPath (Join-Path $root 'supabase/migrations') -Filter '2026102614*.sql' |
      Sort-Object Name | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
    $sql = 'do $phase$ declare baseline bigint; begin select count(*) into baseline from public.course_completions; begin execute $migration$' +
      $migrations + '$migration$; execute $checks$' + $checks + '$checks$; ' +
      'if (select count(*) from public.course_completions)<>baseline then raise exception ''Completion history changed''; end if; ' +
      'raise exception using errcode=''ZX002'',message=''SCHEMA_REHEARSAL_PASSED''; ' +
      'exception when sqlstate ''ZX002'' then null; end; ' +
      'if to_regclass(''public.course_releases'') is not null then raise exception ''Schema rollback failed''; end if; end $phase$;'
  } else {
    $sql = $checks
  }
  Set-Content -LiteralPath $queryPath -Value $sql -Encoding UTF8
  & (Join-Path $PSScriptRoot 'query_supabase.ps1') -File $queryPath
  if ($LASTEXITCODE -ne 0) { throw 'Phase 1 SQL checks failed.' }
  Write-Output 'PASS: Phase 1 publication, history safety, access contexts and rollback checks.'
} finally {
  Remove-Item -LiteralPath $queryPath -Force -ErrorAction SilentlyContinue
}
