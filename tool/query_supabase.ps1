param([Parameter(Mandatory = $true)][string]$File)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$envPath = Join-Path $root '.env'
$line = Get-Content -LiteralPath $envPath |
  Where-Object { $_ -match '^DATABASE_URL=' } |
  Select-Object -First 1
if (-not $line -or $line -match '\[YOUR-PASSWORD\]') {
  throw 'DATABASE_URL is missing or incomplete in .env.'
}
$filePath = (Resolve-Path -LiteralPath $File).Path
$raw = ($line -replace '^DATABASE_URL=', '').Trim().Trim('"', "'")
$schemeEnd = $raw.IndexOf('://') + 3
$at = $raw.LastIndexOf('@')
$colon = $raw.IndexOf(':', $schemeEnd)
if ($schemeEnd -lt 3 -or $colon -lt 0 -or $at -le $colon) {
  throw 'DATABASE_URL is malformed.'
}
$password = $raw.Substring($colon + 1, $at - $colon - 1)
$encodedPassword = [Uri]::EscapeDataString($password)
$dbUrl = $raw.Substring(0, $colon + 1) + $encodedPassword + $raw.Substring($at)

$ErrorActionPreference = 'Continue'
npx.cmd --yes supabase db query --db-url $dbUrl --file $filePath 2>&1 |
  ForEach-Object {
    $_.ToString().Replace($raw, '<redacted-db-url>').
      Replace($dbUrl, '<redacted-db-url>').
      Replace($password, '<redacted>').
      Replace($encodedPassword, '<redacted>')
  }
exit $LASTEXITCODE
