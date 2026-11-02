param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$envPath = Join-Path (Split-Path $PSScriptRoot -Parent) '.env'
if (-not (Test-Path -LiteralPath $envPath)) {
  throw 'Create a local .env with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.'
}

$client = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
  if ($line -match '^\s*(SUPABASE_URL|SUPABASE_PUBLISHABLE_KEY)\s*=\s*(.*)\s*$') {
    $client[$Matches[1]] = $Matches[2].Trim().Trim('"', "'")
  }
}
foreach ($name in @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY')) {
  if ([string]::IsNullOrWhiteSpace($client[$name])) {
    throw "$name is missing from .env."
  }
}

$runArgs = @(
  "--dart-define=SUPABASE_URL=$($client['SUPABASE_URL'])"
  "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($client['SUPABASE_PUBLISHABLE_KEY'])"
)
flutter run @runArgs @FlutterArgs
