$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$config = @{}
Get-Content (Join-Path $root '.env') |
  Where-Object { $_ -match '^(SUPABASE_URL|SUPABASE_PUBLISHABLE_KEY|SUPABASE_SERVICE_ROLE_KEY)=' } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    $config[$name] = $value.Trim('"', "'")
  }
foreach ($name in 'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_SERVICE_ROLE_KEY') {
  if (-not $config[$name]) { throw "$name is missing" }
}

function Invoke-Api($method, $path, $token, $body = $null, $prefer = $null) {
  $headers = @{ apikey = $config.SUPABASE_PUBLISHABLE_KEY }
  if ($token) { $headers.Authorization = "Bearer $token" }
  if ($prefer) { $headers.Prefer = $prefer }
  $request = @{
    Method = $method
    Uri = "$($config.SUPABASE_URL)$path"
    Headers = $headers
    TimeoutSec = 25
  }
  if ($null -ne $body) {
    $request.ContentType = 'application/json'
    $request.Body = ConvertTo-Json -InputObject $body -Depth 12 -Compress
  }
  Invoke-RestMethod @request
}

$stamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$bytes = New-Object byte[] 24
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$password = [Convert]::ToBase64String($bytes) + 'Aa1!'
$userId = $courseId = $assignmentId = $quizId = $briefPath = $null
$failure = $null
try {
  $auth = Invoke-Api 'POST' '/auth/v1/signup' $null @{
    email = "live-persistence-test-$stamp@example.com"
    password = $password
    data = @{ display_name = 'LIVE PERSISTENCE TEST'; requested_role = 'teacher' }
  }
  $userId = $auth.user.id
  $teacherToken = $auth.access_token
  if (-not $userId -or -not $teacherToken) { throw 'Teacher signup returned no session' }

  $category = @(Invoke-Api 'GET' '/rest/v1/categories?select=id&limit=1' $teacherToken)[0]
  $course = @(Invoke-Api 'POST' '/rest/v1/courses?select=id' $teacherToken @{
    instructor_id = $userId
    category_id = $category.id
    title = "LIVE PERSISTENCE TEST $stamp"
    description = 'Temporary persistence check'
    price_amount = 0
    status = 'draft'
  } 'return=representation')[0]
  $courseId = $course.id

  $assignment = @(Invoke-Api 'POST' '/rest/v1/assignments?select=id' $teacherToken @{
    course_id = $courseId
    title = 'LIVE PERSISTENCE TEST assignment'
    instructions = 'Temporary test'
    external_url = 'https://example.com/task'
    due_at = [DateTime]::UtcNow.AddDays(2).ToString('o')
  } 'return=representation')[0]
  $assignmentId = $assignment.id
  $assignmentRead = @(Invoke-Api 'GET' "/rest/v1/assignments?select=id,external_url,status&id=eq.$assignmentId" $teacherToken)[0]
  if ($assignmentRead.external_url -ne 'https://example.com/task' -or $assignmentRead.status -ne 'draft') {
    throw 'Assignment write/read mismatch'
  }
  $briefBytes = [Text.Encoding]::UTF8.GetBytes('Temporary assignment brief')
  $reservation = Invoke-Api 'POST' '/rest/v1/rpc/begin_assignment_brief' $teacherToken @{
    p_assignment_id = $assignmentId
    p_name = 'brief.txt'
    p_extension = 'txt'
    p_size = $briefBytes.Length
  }
  $briefPath = $reservation.object_path
  $uploadHeaders = @{
    apikey = $config.SUPABASE_PUBLISHABLE_KEY
    Authorization = "Bearer $teacherToken"
  }
  Invoke-RestMethod -Method Post -Uri "$($config.SUPABASE_URL)/storage/v1/object/assignment-briefs/$briefPath" `
    -Headers $uploadHeaders -ContentType 'text/plain' -Body $briefBytes -TimeoutSec 25 | Out-Null
  Invoke-Api 'POST' '/rest/v1/rpc/finish_assignment_brief' $teacherToken @{
    p_id = $reservation.id
  } | Out-Null
  $briefs = @(Invoke-Api 'GET' "/rest/v1/assignment_brief_attachments?select=object_path,status&assignment_id=eq.$assignmentId" $teacherToken)
  if ($briefs.Count -ne 1 -or $briefs[0].status -ne 'ready' -or $briefs[0].object_path -ne $briefPath) {
    throw 'Assignment brief readback mismatch'
  }

  $questions = @(
    @{ question_text = 'First question?'; options = @('A', 'B', 'C', 'D'); correct_option_index = 1; explanation = 'B' },
    @{ question_text = 'Second question?'; options = @('E', 'F', 'G', 'H'); correct_option_index = 2; explanation = 'G' }
  )
  $quizId = [string](Invoke-Api 'POST' '/rest/v1/rpc/save_teacher_quiz' $teacherToken @{
    p_quiz_id = $null
    p_title = 'LIVE PERSISTENCE TEST quiz'
    p_category = 'General'
    p_difficulty = 'Medium'
    p_duration_minutes = 15
    p_passing_score = 60
    p_is_ai_generated = $false
    p_publish = $false
    p_questions = $questions
  })
  $quiz = @(Invoke-Api 'GET' "/rest/v1/quizzes?select=id,status,quiz_questions(id,display_order,question_text,options)&id=eq.$quizId" $teacherToken)[0]
  if ($quiz.status -ne 'draft' -or @($quiz.quiz_questions).Count -ne 2) {
    throw 'Quiz question write/read mismatch'
  }
  $questionIds = @($quiz.quiz_questions | ForEach-Object { $_.id })
  $keys = @(Invoke-Api 'GET' '/rest/v1/quiz_answer_keys?select=question_id,correct_option_index' $teacherToken)
  if ($keys.Count -eq 1 -and $keys[0] -is [array]) {
    $keys = $keys[0]
  }
  $savedKeys = @($keys | Where-Object { $_.question_id -in $questionIds })
  if ($savedKeys.Count -ne 2) {
    throw "Quiz answer-key readback mismatch (teacher-visible=$($keys.Count), matching=$($savedKeys.Count))"
  }
  Write-Output 'PASS: authenticated teacher assignment, private brief, and two-question quiz persisted with answer keys.'
} catch {
  $failure = $_.Exception.Message
  Write-Output "FAIL: $failure"
} finally {
  foreach ($entry in @(
    @{ name = 'brief object'; path = "/storage/v1/object/assignment-briefs/$briefPath"; id = $briefPath },
    @{ name = 'quiz'; path = "/rest/v1/quizzes?id=eq.$quizId"; id = $quizId },
    @{ name = 'assignment'; path = "/rest/v1/assignments?id=eq.$assignmentId"; id = $assignmentId },
    @{ name = 'course'; path = "/rest/v1/courses?id=eq.$courseId"; id = $courseId },
    @{ name = 'test user'; path = "/auth/v1/admin/users/$userId"; id = $userId }
  )) {
    if (-not $entry.id) { continue }
    try {
      Invoke-Api 'DELETE' $entry.path $config.SUPABASE_SERVICE_ROLE_KEY | Out-Null
      Write-Output "Cleaned up $($entry.name)."
    } catch {
      Write-Output "Cleanup failed for $($entry.name): $($_.Exception.Message)"
      $failure = 'Cleanup failed'
    }
  }
}
if ($failure) { exit 1 }
