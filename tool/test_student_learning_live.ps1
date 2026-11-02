$ErrorActionPreference = 'Stop'
$configuration = @{}
Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) '.env') |
  Where-Object { $_ -match '^(SUPABASE_URL|SUPABASE_PUBLISHABLE_KEY|SUPABASE_SERVICE_ROLE_KEY|SUPABASE_ACCESS_TOKEN_SECRET)=' } |
  ForEach-Object { $name, $value = $_ -split '=', 2; $configuration[$name] = $value.Trim('"', "'") }
foreach ($name in 'SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY','SUPABASE_SERVICE_ROLE_KEY','SUPABASE_ACCESS_TOKEN_SECRET') {
  if (-not $configuration[$name]) { throw "Missing $name" }
}
function Invoke-Api($method,$path,$token,$body=$null) {
  $parameters = @{
    Method=$method; Uri="$($configuration.SUPABASE_URL)$path"; TimeoutSec=60
    Headers=@{ apikey=$configuration.SUPABASE_PUBLISHABLE_KEY; Authorization="Bearer $token" }
  }
  if ($null -ne $body) { $parameters.ContentType='application/json'; $parameters.Body=ConvertTo-Json -InputObject $body -Depth 12 -Compress }
  Invoke-RestMethod @parameters
}
function Invoke-Sql([string]$sql) {
  $result = Invoke-RestMethod -Method POST -Uri 'https://api.supabase.com/v1/projects/rgpeouxesbemysmwbzmu/database/query' `
    -Headers @{Authorization="Bearer $($configuration.SUPABASE_ACCESS_TOKEN_SECRET)"} `
    -ContentType 'application/json' -Body (ConvertTo-Json @{query=$sql} -Compress) -TimeoutSec 60
  return $result
}
$accounts = @()
$courseId = [guid]::NewGuid().ToString()
$coverPath = $null
$certificatePath = $null
$service = $configuration.SUPABASE_SERVICE_ROLE_KEY
$password = [guid]::NewGuid().ToString('N') + 'Aa1!'
$failure = $null
try {
  foreach ($role in @('teacher','student')) {
    $email = "learning-$role-$([guid]::NewGuid().ToString('N'))@example.invalid"
    $account = Invoke-Api POST '/auth/v1/admin/users' $service @{
      email=$email; password=$password; email_confirm=$true
      user_metadata=@{display_name="LEARNING FLOW TEST $role"; requested_role=$role}
    }
    $accounts += @{id=$account.id; email=$email}
  }
  $teacherId=$accounts[0].id; $studentId=$accounts[1].id
  $session = Invoke-Api POST '/auth/v1/token?grant_type=password' $configuration.SUPABASE_PUBLISHABLE_KEY @{
    email=$accounts[1].email; password=$password
  }
  $studentToken=$session.access_token
  $teacherSession=Invoke-Api POST '/auth/v1/token?grant_type=password' $configuration.SUPABASE_PUBLISHABLE_KEY @{
    email=$accounts[0].email; password=$password
  }
  $coverPath="$teacherId/$courseId/test.png"
  $png=[Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jF1sAAAAASUVORK5CYII=')
  Invoke-RestMethod -Method POST -Uri "$($configuration.SUPABASE_URL)/storage/v1/object/course-thumbnails/$coverPath" `
    -Headers @{apikey=$configuration.SUPABASE_PUBLISHABLE_KEY; Authorization="Bearer $service"} `
    -ContentType 'image/png' -Body $png -TimeoutSec 30 | Out-Null
  $fixture=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot '../supabase/tests/course_completion_requirements.sql')
  $fixture=$fixture.Replace('course uuid:=gen_random_uuid()',"course uuid:='$courseId'")
  $fixture=$fixture -replace "select id into teacher from public.profiles[^;]+;", "teacher:='$teacherId';"
  $fixture=$fixture -replace "select id into student from public.profiles[^;]+;", "student:='$studentId';"
  $fixture=$fixture -replace '(?s)  insert into storage.objects\(bucket_id,name,owner_id,metadata\).*?;\s*', ''
  Invoke-Sql $fixture | Out-Null
  Write-Output 'PASS: scoped enrollment, lesson, quiz, assignment approval and durable completion on deployed functions.'
  $certificate=Invoke-Api POST '/functions/v1/course-certificate' $studentToken @{courseId=$courseId}
  if (-not $certificate.url -or $certificate.completion.student_id -ne $studentId) { throw 'Certificate ownership mismatch' }
  $certificatePath="$studentId/$($certificate.completion.id).pdf"
  Invoke-WebRequest -UseBasicParsing -Uri $certificate.url -OutFile (Join-Path $env:TEMP 'cboa-live-certificate.pdf') -TimeoutSec 30 | Out-Null
  $bytes=[IO.File]::ReadAllBytes((Join-Path $env:TEMP 'cboa-live-certificate.pdf'))
  if ($bytes.Length -lt 1000 -or [Text.Encoding]::ASCII.GetString($bytes,0,4) -ne '%PDF') { throw 'Certificate is not a valid PDF response' }
  $repeat=Invoke-Api POST '/functions/v1/course-certificate' $studentToken @{courseId=$courseId}
  if ($repeat.completion.id -ne $certificate.completion.id) { throw 'Repeated certificate changed identity' }
  Write-Output 'PASS: eligible learner received a real private PDF with stable certificate identity.'
  foreach ($probe in @(@{token=$studentToken; course=[guid]::NewGuid().ToString()},@{token=$teacherSession.access_token; course=$courseId})) {
    try {
      Invoke-Api POST '/functions/v1/course-certificate' $probe.token @{courseId=$probe.course} | Out-Null
      throw 'Ineligible caller received a certificate'
    } catch {
      $status=[int]$_.Exception.Response.StatusCode
      if ($status -notin @(401,403)) { throw }
    }
  }
  Write-Output 'PASS: ineligible and cross-account requests were rejected.'
} catch {
  $failure=$_.Exception.Message
  Write-Output "FAIL: $failure"
  Write-Output $_.InvocationInfo.PositionMessage
  if ($_.ErrorDetails.Message) { Write-Output $_.ErrorDetails.Message }
} finally {
  try {
    if (-not $certificatePath -and $studentId) {
      $saved=@(Invoke-Api GET "/rest/v1/course_completions?select=id&student_id=eq.$studentId&course_id=eq.$courseId" $service)
      if ($saved.Count -eq 1) { $certificatePath="$studentId/$($saved[0].id).pdf" }
    }
    Invoke-Sql @"
begin;
delete from public.course_completions where course_id='$courseId';
delete from public.quiz_sessions where quiz_id in(select id from public.quizzes where course_id='$courseId');
delete from public.quiz_attempts where quiz_id in(select id from public.quizzes where course_id='$courseId');
delete from public.assignment_submissions where assignment_id in(select id from public.assignments where course_id='$courseId');
update public.courses set status='draft' where id='$courseId';
delete from public.courses where id='$courseId';
commit;
"@ | Out-Null
    foreach ($object in @(@{bucket='course-thumbnails';path=$coverPath},@{bucket='course-certificates';path=$certificatePath})) {
      if ($object.path) { Invoke-Api DELETE "/storage/v1/object/$($object.bucket)" $service @{prefixes=@($object.path)} | Out-Null }
    }
    foreach ($account in $accounts) { Invoke-Api DELETE "/auth/v1/admin/users/$($account.id)" $service | Out-Null }
    Write-Output 'Cleaned up isolated test accounts, course, uploads and certificate.'
  } catch {
    Write-Output "Cleanup failed: $($_.Exception.Message)"
    $failure='Cleanup failed'
  }
}
if ($failure) { exit 1 }
