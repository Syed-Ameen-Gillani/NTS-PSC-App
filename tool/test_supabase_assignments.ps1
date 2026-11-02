$ErrorActionPreference = 'Stop'
$envPath = Join-Path (Split-Path $PSScriptRoot -Parent) '.env'
$lines = Get-Content -LiteralPath $envPath
$urlLine = $lines | Where-Object { $_ -match '^SUPABASE_URL=' } | Select-Object -First 1
$keyLine = $lines | Where-Object { $_ -match '^SUPABASE_PUBLISHABLE_KEY=' } | Select-Object -First 1
if (-not $urlLine -or -not $keyLine) { throw 'Supabase public configuration is missing.' }
$url = ($urlLine -split '=', 2)[1].Trim().Trim('"')
$key = ($keyLine -split '=', 2)[1].Trim().Trim('"')
$runId = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$randomBytes = New-Object byte[] 24
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($randomBytes)
$rng.Dispose()
$password = [Convert]::ToBase64String($randomBytes) + 'aA1!'
$stage = 'setup'
$courseId = $null
$teacherA = $null

function Call-Api($method, $path, $token, $body = $null, $prefer = $null) {
  $headers = @{ apikey = $key }
  if ($token) { $headers.Authorization = "Bearer $token" }
  if ($prefer) { $headers.Prefer = $prefer }
  $params = @{
    Method = $method
    Uri = "$url$path"
    Headers = $headers
    ErrorAction = 'Stop'
  }
  if ($null -ne $body) {
    $params.ContentType = 'application/json'
    $params.Body = ConvertTo-Json -InputObject $body -Depth 8 -Compress
  }
  Invoke-RestMethod @params
}

function Sign-Up($suffix, $role) {
  $email = "nts-psc-rls-$suffix-$runId@example.com"
  $result = Call-Api 'POST' '/auth/v1/signup' $null @{
    email = $email
    password = $password
    data = @{ display_name = "RLS TEST $suffix"; requested_role = $role }
  }
  if (-not $result.access_token -or -not $result.user.id) {
    throw 'Immediate sign-in did not return a session.'
  }
  $result
}

function Read-Rows($path, $token) {
  @(Call-Api 'GET' $path $token)
}

function Assert-Empty($path, $token, $message) {
  if ((Read-Rows $path $token).Count -ne 0) { throw $message }
}

try {
  $stage = 'signup'
  $teacherA = Sign-Up 'teacher-a' 'teacher'
  $teacherB = Sign-Up 'teacher-b' 'teacher'
  $studentA = Sign-Up 'student-a' 'student'
  $studentB = Sign-Up 'student-b' 'student'
  Write-Output 'Four disposable RLS TEST accounts signed in.'

  $stage = 'course creation'
  $category = @(Read-Rows '/rest/v1/categories?select=id&limit=1' $teacherA.access_token)[0]
  $course = @(Call-Api 'POST' '/rest/v1/courses?select=id' $teacherA.access_token @{
    instructor_id = $teacherA.user.id
    category_id = $category.id
    title = "RLS TEST course $runId"
    description = 'Disposable authorization test'
    price_amount = 0
    status = 'draft'
  } 'return=representation')[0]
  $courseId = $course.id
  if (-not $courseId) { throw 'Course creation did not return an ID.' }

  $stage = 'assignment draft isolation'
  $assignment = @(Call-Api 'POST' '/rest/v1/assignments?select=id' $teacherA.access_token @{
    course_id = $courseId
    title = 'RLS TEST essay'
    instructions = 'Write a test answer.'
    due_at = [DateTime]::UtcNow.AddDays(2).ToString('o')
  } 'return=representation')[0]
  $assignmentId = $assignment.id
  Assert-Empty "/rest/v1/assignments?select=id&id=eq.$assignmentId" $teacherB.access_token 'Other teacher read a draft.'
  Assert-Empty "/rest/v1/assignments?select=id&id=eq.$assignmentId" $studentA.access_token 'Student read a draft.'
  $otherTeacherUpdate = @(Call-Api 'PATCH' "/rest/v1/assignments?id=eq.$assignmentId&select=id" $teacherB.access_token @{ title = 'Unauthorized' } 'return=representation')
  $ownerView = @(Read-Rows "/rest/v1/assignments?select=title&id=eq.$assignmentId" $teacherA.access_token)[0]
  if ($ownerView.title -ne 'RLS TEST essay') { throw 'Other teacher edited a draft.' }

  $stage = 'publication and enrollment'
  Call-Api 'PATCH' "/rest/v1/courses?id=eq.$courseId" $teacherA.access_token @{ status = 'published' } | Out-Null
  Call-Api 'PATCH' "/rest/v1/assignments?id=eq.$assignmentId" $teacherA.access_token @{ status = 'published' } | Out-Null
  Assert-Empty "/rest/v1/assignments?select=id&id=eq.$assignmentId" $studentA.access_token 'Unenrolled student read an assignment.'
  Call-Api 'POST' '/rest/v1/enrollments' $studentA.access_token @{
    student_id = $studentA.user.id
    course_id = $courseId
  } | Out-Null
  if ((Read-Rows "/rest/v1/assignments?select=id&id=eq.$assignmentId" $studentA.access_token).Count -ne 1) {
    throw 'Enrolled student could not read the assignment.'
  }

  $stage = 'submit and review'
  $first = Call-Api 'POST' '/rest/v1/rpc/submit_assignment' $studentA.access_token @{
    p_assignment_id = $assignmentId
    p_response = 'First answer'
  }
  $changedAfterSubmission = $false
  try {
    Call-Api 'PATCH' "/rest/v1/assignments?id=eq.$assignmentId" $teacherA.access_token @{
      instructions = 'Changed after submission'
    } | Out-Null
    $changedAfterSubmission = $true
  } catch { }
  if ($changedAfterSubmission) { throw 'Submitted assignment content was changed.' }
  Assert-Empty "/rest/v1/assignment_submissions?select=id&id=eq.$($first.id)" $studentB.access_token 'Other student read a submission.'
  Assert-Empty "/rest/v1/assignment_submissions?select=id&id=eq.$($first.id)" $teacherB.access_token 'Other teacher read a submission.'
  $otherTeacherReviewed = $false
  try {
    Call-Api 'POST' '/rest/v1/rpc/review_assignment' $teacherB.access_token @{
      p_submission_id = $first.id
      p_decision = 'approved'
      p_feedback = ''
    } | Out-Null
    $otherTeacherReviewed = $true
  } catch { }
  if ($otherTeacherReviewed) { throw 'Other teacher reviewed a submission.' }
  $rejected = Call-Api 'POST' '/rest/v1/rpc/review_assignment' $teacherA.access_token @{
    p_submission_id = $first.id
    p_decision = 'disapproved'
    p_feedback = 'Add a citation.'
  }
  if ($rejected.status -ne 'disapproved') { throw 'Review did not reject.' }
  $revised = Call-Api 'POST' '/rest/v1/rpc/submit_assignment' $studentA.access_token @{
    p_assignment_id = $assignmentId
    p_response = 'Revised answer with citation'
  }
  if ($revised.current_revision -ne 2) { throw 'Resubmission did not preserve revision history.' }
  $revisionRows = Read-Rows "/rest/v1/assignment_submission_revisions?select=id&submission_id=eq.$($first.id)" $studentA.access_token
  if ($revisionRows.Count -ne 2) { throw 'Expected two immutable revisions.' }
  $approved = Call-Api 'POST' '/rest/v1/rpc/review_assignment' $teacherA.access_token @{
    p_submission_id = $first.id
    p_decision = 'approved'
    p_feedback = ''
  }
  if ($approved.status -ne 'approved') { throw 'Review did not approve.' }
  Write-Output 'Assignment RLS and submit/review/resubmit journey passed.'

  $stage = 'quiz draft and answer-key isolation'
  $quiz = @(Call-Api 'POST' '/rest/v1/quizzes?select=id' $teacherA.access_token @{
    teacher_id = $teacherA.user.id
    course_id = $courseId
    title = 'RLS TEST quiz'
    category = 'General'
  } 'return=representation')[0]
  $quizId = $quiz.id
  $question = @(Call-Api 'POST' '/rest/v1/quiz_questions?select=id' $teacherA.access_token @{
    quiz_id = $quizId
    display_order = 0
    question_text = 'Which choice is correct?'
    options = @('First', 'Second')
  } 'return=representation')[0]
  $questionId = $question.id
  Call-Api 'POST' '/rest/v1/quiz_answer_keys' $teacherA.access_token @{
    question_id = $questionId
    correct_option_index = 1
    explanation = 'The second choice is correct.'
  } | Out-Null
  Assert-Empty "/rest/v1/quizzes?select=id&id=eq.$quizId" $studentA.access_token 'Student read a draft quiz.'
  Assert-Empty "/rest/v1/quiz_answer_keys?select=question_id&question_id=eq.$questionId" $teacherB.access_token 'Other teacher read an answer key.'
  Call-Api 'PATCH' "/rest/v1/quizzes?id=eq.$quizId" $teacherA.access_token @{ status = 'published' } | Out-Null
  if ((Read-Rows "/rest/v1/quiz_questions?select=id&id=eq.$questionId" $studentA.access_token).Count -ne 1) {
    throw 'Enrolled student could not read a published question.'
  }
  Assert-Empty "/rest/v1/quiz_answer_keys?select=question_id&question_id=eq.$questionId" $studentA.access_token 'Student read an answer key before submission.'

  $stage = 'quiz scoring and immutability'
  $answers = @{}
  $answers[$questionId] = 1
  $scored = Call-Api 'POST' '/rest/v1/rpc/submit_quiz' $studentA.access_token @{
    p_quiz_id = $quizId
    p_answers = $answers
  }
  if ($scored.score -ne 1 -or $scored.total_questions -ne 1 -or
      $scored.questions[0].correct_option_index -ne 1) {
    throw 'Server-side scoring or post-submit review failed.'
  }
  Assert-Empty "/rest/v1/quiz_attempts?select=id&quiz_id=eq.$quizId" $studentB.access_token 'Other student read a quiz attempt.'
  try {
    Call-Api 'PATCH' "/rest/v1/quiz_questions?id=eq.$questionId" $teacherA.access_token @{
      question_text = 'Changed after publication'
    } | Out-Null
  } catch { }
  $storedQuestion = @(Read-Rows "/rest/v1/quiz_questions?select=question_text&id=eq.$questionId" $teacherA.access_token)[0]
  if ($storedQuestion.question_text -ne 'Which choice is correct?') {
    throw 'Published quiz question was edited.'
  }
  Write-Output 'Quiz answer-key isolation, scoring, and publication lock passed.'

  $stage = 'AI generation quota and draft persistence'
  $studentReserved = $false
  try {
    Call-Api 'POST' '/rest/v1/rpc/reserve_ai_quiz_generation' $studentA.access_token @{
      p_topic = 'RLS TEST AI topic'
      p_difficulty = 'Medium'
      p_question_count = 1
      p_duration_minutes = 5
      p_model = 'rls-test-model'
    } | Out-Null
    $studentReserved = $true
  } catch { }
  if ($studentReserved) { throw 'Student reserved an AI generation request.' }
  $requestId = Call-Api 'POST' '/rest/v1/rpc/reserve_ai_quiz_generation' $teacherA.access_token @{
    p_topic = 'RLS TEST AI topic'
    p_difficulty = 'Medium'
    p_question_count = 1
    p_duration_minutes = 5
    p_model = 'rls-test-model'
  }
  $aiDraftId = Call-Api 'POST' '/rest/v1/rpc/create_ai_quiz_draft' $teacherA.access_token @{
    p_request_id = $requestId
    p_questions = @(@{
      question = 'Which test choice is correct?'
      options = @('One', 'Two', 'Three', 'Four')
      correct_index = 1
      explanation = 'Two is correct.'
    })
  }
  if (-not $aiDraftId) { throw 'AI draft was not saved.' }
  for ($i = 0; $i -lt 4; $i++) {
    Call-Api 'POST' '/rest/v1/rpc/reserve_ai_quiz_generation' $teacherA.access_token @{
      p_topic = 'RLS TEST AI topic'
      p_difficulty = 'Medium'
      p_question_count = 1
      p_duration_minutes = 5
      p_model = 'rls-test-model'
    } | Out-Null
  }
  $sixthReserved = $false
  try {
    Call-Api 'POST' '/rest/v1/rpc/reserve_ai_quiz_generation' $teacherA.access_token @{
      p_topic = 'RLS TEST AI topic'
      p_difficulty = 'Medium'
      p_question_count = 1
      p_duration_minutes = 5
      p_model = 'rls-test-model'
    } | Out-Null
    $sixthReserved = $true
  } catch { }
  if ($sixthReserved) { throw 'Daily AI quiz limit was not enforced.' }
  Write-Output 'Teacher-only AI draft and five-per-day quota passed.'
} catch {
  $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 'n/a' }
  $detail = $_.Exception.Message.Replace($password, '<redacted>').Replace($key, '<redacted>')
  foreach ($session in @($teacherA, $teacherB, $studentA, $studentB)) {
    if ($session -and $session.access_token) {
      $detail = $detail.Replace($session.access_token, '<redacted>')
    }
  }
  Write-Error "RLS test failed at $stage (HTTP $status): $detail"
  exit 1
} finally {
  if ($courseId -and $teacherA) {
    try {
      Call-Api 'DELETE' "/rest/v1/courses?id=eq.$courseId" $teacherA.access_token | Out-Null
    } catch {
      Write-Warning 'Client cleanup deferred to the scoped database cleanup.'
    }
  }
  & (Join-Path $PSScriptRoot 'cleanup_supabase_rls_tests.ps1')
  if ($LASTEXITCODE -ne 0) {
    throw 'Scoped RLS test cleanup failed.'
  }
}
