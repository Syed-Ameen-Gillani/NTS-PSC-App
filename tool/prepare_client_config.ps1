$root = Split-Path $PSScriptRoot -Parent
$envPath = Join-Path $root '.env'
if (-not (Test-Path -LiteralPath $envPath)) {
  throw 'Local .env file is missing.'
}

$public = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
  if ($line -match '^\s*(SUPABASE_URL|SUPABASE_PUBLISHABLE_KEY)\s*=\s*(.*)\s*$') {
    $public[$Matches[1]] = $Matches[2].Trim().Trim('"', "'")
  }
}
foreach ($name in @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY')) {
  if ([string]::IsNullOrWhiteSpace($public[$name])) {
    throw "$name is missing from .env."
  }
}
if (-not $public['SUPABASE_URL'].StartsWith('https://') -or
    -not $public['SUPABASE_PUBLISHABLE_KEY'].StartsWith('sb_publishable_')) {
  throw 'Supabase public configuration is invalid.'
}

$target = Join-Path $root 'assets/config/supabase_public.json'
[System.IO.File]::WriteAllText(
  $target,
  ($public | ConvertTo-Json),
  [System.Text.UTF8Encoding]::new($false)
)
Write-Output 'Public-only Supabase client config is ready for the next app build.'
