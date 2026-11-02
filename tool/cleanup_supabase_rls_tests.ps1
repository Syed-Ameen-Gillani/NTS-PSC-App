$ErrorActionPreference = 'Stop'
$envPath = Join-Path (Split-Path $PSScriptRoot -Parent) '.env'
$line = Get-Content -LiteralPath $envPath |
  Where-Object { $_ -match '^DATABASE_URL=' } |
  Select-Object -First 1
if (-not $line -or $line -match '\[YOUR-PASSWORD\]') {
  throw 'DATABASE_URL is missing or incomplete in .env.'
}
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

$queries = @(
  @'
delete from public.ai_quiz_generation_requests r using public.profiles p
where r.teacher_id = p.id and p.display_name = 'RLS TEST teacher-a'
  and r.topic = 'RLS TEST AI topic'
'@,
  @'
delete from public.quiz_attempts a
using public.quizzes q, public.profiles p
where a.quiz_id = q.id and q.teacher_id = p.id
  and p.display_name = 'RLS TEST teacher-a' and q.title like 'RLS TEST %'
'@,
  @'
delete from public.quizzes q using public.profiles p
where q.teacher_id = p.id and p.display_name = 'RLS TEST teacher-a'
  and q.title = 'RLS TEST AI topic' and q.is_ai_generated
'@,
  @'
delete from public.courses c using public.profiles p
where c.instructor_id = p.id and c.title like 'RLS TEST course %'
  and p.display_name = 'RLS TEST teacher-a'
'@,
  @'
delete from auth.users u
where u.email like 'nts-psc-rls-%@example.com'
  and u.raw_user_meta_data ->> 'display_name' like 'RLS TEST %'
'@,
  @'
select count(*) as remaining_rls_test_users from auth.users u
where u.email like 'nts-psc-rls-%@example.com'
  and u.raw_user_meta_data ->> 'display_name' like 'RLS TEST %'
'@
)

$ErrorActionPreference = 'Continue'
foreach ($sql in $queries) {
  npx --yes supabase db query --db-url $dbUrl $sql 2>&1 |
    ForEach-Object {
      $_.ToString().Replace($raw, '<redacted-db-url>').
        Replace($dbUrl, '<redacted-db-url>').
        Replace($password, '<redacted>').
        Replace($encodedPassword, '<redacted>')
    }
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
