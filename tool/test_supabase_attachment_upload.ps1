$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$lines = Get-Content -LiteralPath (Join-Path $root '.env')
$url = (($lines | Where-Object { $_ -match '^SUPABASE_URL=' } | Select-Object -First 1) -split '=', 2)[1].Trim().Trim('"')
$key = (($lines | Where-Object { $_ -match '^SUPABASE_PUBLISHABLE_KEY=' } | Select-Object -First 1) -split '=', 2)[1].Trim().Trim('"')
if (-not $url -or -not $key) { throw 'Public Supabase configuration is missing.' }
$runId = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$random = New-Object byte[] 24
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($random)
$password = [Convert]::ToBase64String($random) + 'aA1!'
$tokens = @()
$stage = 'signup'

function Api($method, $path, $token, $body = $null, $prefer = $null) {
  $headers = @{ apikey = $key }
  if ($token) { $headers.Authorization = "Bearer $token" }
  if ($prefer) { $headers.Prefer = $prefer }
  $params = @{ Method = $method; Uri = "$url$path"; Headers = $headers; ErrorAction = 'Stop' }
  if ($null -ne $body) {
    $params.ContentType = 'application/json'
    $params.Body = ConvertTo-Json -InputObject $body -Depth 8 -Compress
  }
  Invoke-RestMethod @params
}

function Signup($label, $role) {
  $result = Api 'POST' '/auth/v1/signup' $null @{
    email = "nts-psc-attachment-test-$label-$runId@example.com"
    password = $password
    data = @{ display_name = "ATTACHMENT TEST $label"; requested_role = $role }
  }
  if (-not $result.access_token) { throw 'Test signup did not return a session.' }
  $script:tokens += $result.access_token
  $result
}

function Download($token, $objectPath) {
  $headers = @{ apikey = $key; Authorization = "Bearer $token" }
  Invoke-WebRequest -Uri "$url/storage/v1/object/authenticated/assignment-submissions/$objectPath" -Headers $headers -Method GET -UseBasicParsing -ErrorAction Stop
}

try {
  $teacher = Signup 'teacher' 'teacher'
  $otherTeacher = Signup 'other-teacher' 'teacher'
  $student = Signup 'student' 'student'
  $outsider = Signup 'outsider' 'student'
  $stage = 'course and enrollment'
  $category = @(Api 'GET' '/rest/v1/categories?select=id&limit=1' $teacher.access_token)[0]
  $course = @(Api 'POST' '/rest/v1/courses?select=id' $teacher.access_token @{
    instructor_id = $teacher.user.id
    category_id = $category.id
    title = "ATTACHMENT TEST course $runId"
    description = 'Private attachment smoke test'
    price_amount = 0
    status = 'draft'
  } 'return=representation')[0]
  Api 'PATCH' "/rest/v1/courses?id=eq.$($course.id)" $teacher.access_token @{ status = 'published' } | Out-Null
  Api 'POST' '/rest/v1/enrollments' $student.access_token @{
    student_id = $student.user.id
    course_id = $course.id
  } | Out-Null
  $assignment = @(Api 'POST' '/rest/v1/assignments?select=id' $teacher.access_token @{
    course_id = $course.id
    title = 'ATTACHMENT TEST submission'
    instructions = 'Upload a document.'
    due_at = [DateTime]::UtcNow.AddDays(2).ToString('o')
    status = 'published'
  } 'return=representation')[0]

  $stage = 'first private upload'
  $path1 = "$($student.user.id)/$($assignment.id)/$([guid]::NewGuid()).txt"
  $headers = @{ apikey = $key; Authorization = "Bearer $($student.access_token)"; 'x-upsert' = 'false' }
  $bytes = [Text.Encoding]::UTF8.GetBytes('Retained attachment revision one')
  Invoke-RestMethod -Method POST -Uri "$url/storage/v1/object/assignment-submissions/$path1" -Headers $headers -Body $bytes -ContentType 'text/plain' -ErrorAction Stop | Out-Null
  $submitted = Api 'POST' '/rest/v1/rpc/submit_assignment' $student.access_token @{
    p_assignment_id = $assignment.id
    p_response = ''
    p_attachments = @(@{ path = $path1; name = 'first.txt' })
  }
  if (-not $submitted.id) { throw 'Attachment-only submission failed.' }
  if ((Download $student.access_token $path1).StatusCode -ne 200 -or
      (Download $teacher.access_token $path1).StatusCode -ne 200) {
    throw 'Student or owning teacher could not read the private object.'
  }
  $outsiderRead = $false
  try { Download $outsider.access_token $path1 | Out-Null; $outsiderRead = $true } catch { }
  if ($outsiderRead) { throw 'Another student downloaded a private object.' }
  $otherTeacherRead = $false
  try { Download $otherTeacher.access_token $path1 | Out-Null; $otherTeacherRead = $true } catch { }
  if ($otherTeacherRead) { throw 'Another teacher downloaded a private object.' }

  $stage = 'revision history'
  Api 'POST' '/rest/v1/rpc/review_assignment' $teacher.access_token @{
    p_submission_id = $submitted.id
    p_decision = 'disapproved'
    p_feedback = 'Please revise.'
  } | Out-Null
  $path2 = "$($student.user.id)/$($assignment.id)/$([guid]::NewGuid()).txt"
  $bytes = [Text.Encoding]::UTF8.GetBytes('Retained attachment revision two')
  Invoke-RestMethod -Method POST -Uri "$url/storage/v1/object/assignment-submissions/$path2" -Headers $headers -Body $bytes -ContentType 'text/plain' -ErrorAction Stop | Out-Null
  Api 'POST' '/rest/v1/rpc/submit_assignment' $student.access_token @{
    p_assignment_id = $assignment.id
    p_response = 'Revised answer'
    p_attachments = @(@{ path = $path2; name = 'second.txt' })
  } | Out-Null
  $attachments = @(Api 'GET' '/rest/v1/assignment_submission_attachments?select=object_path,revision_id' $teacher.access_token)
  $ownRows = @(
    foreach ($group in $attachments) {
      foreach ($item in $group) {
        if ($item.object_path -eq $path1 -or $item.object_path -eq $path2) { $item }
      }
    }
  )
  $earlierDownload = Download $teacher.access_token $path1
  if ($ownRows.Count -ne 2 -or $earlierDownload.StatusCode -ne 200) {
    throw "Earlier revision unavailable (visible metadata $($ownRows.Count), download status $($earlierDownload.StatusCode))."
  }
  $outsiderRows = @(Api 'GET' '/rest/v1/assignment_submission_attachments?select=id' $outsider.access_token)
  foreach ($group in $outsiderRows) {
    foreach ($item in $group) {
      if ($null -ne $item) { throw 'Another student read attachment metadata.' }
    }
  }
  $otherTeacherRows = @(Api 'GET' '/rest/v1/assignment_submission_attachments?select=id' $otherTeacher.access_token)
  foreach ($group in $otherTeacherRows) {
    foreach ($item in $group) {
      if ($null -ne $item) { throw 'Another teacher read attachment metadata.' }
    }
  }
  Write-Output "Attachment smoke test passed; retained test run $runId."
} catch {
  $message = $_.Exception.Message.Replace($password, '<redacted>').Replace($key, '<redacted>')
  foreach ($token in $tokens) { $message = $message.Replace($token, '<redacted>') }
  Write-Error "Attachment smoke test failed at $stage`: $message"
  exit 1
}
