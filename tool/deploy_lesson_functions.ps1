$envPath = Join-Path (Split-Path $PSScriptRoot -Parent) '.env'
$line = Get-Content -LiteralPath $envPath |
  Where-Object { $_ -match '^SUPABASE_ACCESS_TOKEN_SECRET=' } |
  Select-Object -First 1
if (-not $line) { throw 'SUPABASE_ACCESS_TOKEN_SECRET is missing.' }
$env:SUPABASE_ACCESS_TOKEN = ($line -replace '^SUPABASE_ACCESS_TOKEN_SECRET=', '').Trim().Trim('"', "'")

try {
  foreach ($name in @('transcribe-lesson', 'lesson-transcript-callback', 'generate-lesson-checkpoints')) {
    $args = @('--yes', 'supabase', 'functions', 'deploy', $name,
      '--project-ref', 'rgpeouxesbemysmwbzmu')
    if ($name -eq 'lesson-transcript-callback') { $args += '--no-verify-jwt' }
    & npx.cmd @args 2>&1 | ForEach-Object {
      $_.ToString().Replace($env:SUPABASE_ACCESS_TOKEN, '<redacted>')
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
} finally {
  Remove-Item Env:SUPABASE_ACCESS_TOKEN -ErrorAction SilentlyContinue
}
