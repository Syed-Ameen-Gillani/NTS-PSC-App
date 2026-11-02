$ErrorActionPreference = 'Stop'
$line = Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) '.env') |
  Where-Object { $_ -match '^SUPABASE_ACCESS_TOKEN_SECRET=' } | Select-Object -First 1
if (-not $line) { throw 'Management access token is missing.' }
$env:SUPABASE_ACCESS_TOKEN = ($line -split '=', 2)[1].Trim().Trim('"', "'")
try {
  $ErrorActionPreference = 'Continue'
  & npx.cmd --yes supabase functions deploy send-push --project-ref rgpeouxesbemysmwbzmu --no-verify-jwt 2>&1 |
    ForEach-Object { $_.ToString().Replace($env:SUPABASE_ACCESS_TOKEN, '<redacted>') }
  $deployExit = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($deployExit -ne 0) { throw 'Push function deployment failed.' }
} finally { Remove-Item Env:SUPABASE_ACCESS_TOKEN -ErrorAction SilentlyContinue }
