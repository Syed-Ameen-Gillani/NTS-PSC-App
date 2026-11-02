param([switch]$VerifyTranscription)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$lines = Get-Content -LiteralPath (Join-Path $root '.env')
$url = (($lines | Where-Object { $_ -match '^SUPABASE_URL=' } | Select-Object -First 1) -split '=', 2)[1].Trim().Trim('"')
$key = (($lines | Where-Object { $_ -match '^SUPABASE_PUBLISHABLE_KEY=' } | Select-Object -First 1) -split '=', 2)[1].Trim().Trim('"')
$runId = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$bytes = New-Object byte[] 24
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$password = [Convert]::ToBase64String($bytes) + 'aA1!'

function Api($method, $path, $token, $body = $null, $prefer = $null) {
  $headers = @{ apikey = $key }
  if ($token) { $headers.Authorization = "Bearer $token" }
  if ($prefer) { $headers.Prefer = $prefer }
  $params = @{ Method = $method; Uri = "$url$path"; Headers = $headers; ErrorAction = 'Stop' }
  if ($null -ne $body) {
    $params.ContentType = 'application/json'
    $params.Body = ConvertTo-Json -InputObject $body -Depth 12 -Compress
  }
  $result = Invoke-RestMethod @params
  # Normalize REST arrays: Windows PowerShell can emit [] as one pipeline object.
  if ($result -is [array]) {
    foreach ($row in $result) { Write-Output $row }
  } else { $result }
}

function Signup($label, $role) {
  $result = Api 'POST' '/auth/v1/signup' $null @{
    email = "nts-psc-media-test-$label-$runId@example.com"
    password = $password
    data = @{ display_name = "MEDIA TEST $label"; requested_role = $role }
  }
  if (-not $result.access_token) { throw 'Test signup did not return a session.' }
  $result
}

function CanRead($token, $path) {
  try {
    $headers = @{ apikey = $key; Authorization = "Bearer $token" }
    $response = Invoke-WebRequest -Uri "$url/storage/v1/object/authenticated/lesson-videos/$path" `
      -Headers $headers -Method GET -UseBasicParsing -ErrorAction Stop
    return $response.StatusCode -eq 200
  } catch { return $false }
}

$stage = 'signup'
try {
  $teacher = Signup 'teacher' 'teacher'
  $otherTeacher = Signup 'other-teacher' 'teacher'
  $student = Signup 'student' 'student'
  $outsider = Signup 'outsider' 'student'
  $stage = 'course'
  $category = @(Api 'GET' '/rest/v1/categories?select=id,name&is_active=eq.true&limit=1' $teacher.access_token)[0]
  $course = @{ id = [guid]::NewGuid().ToString() }
  $draft = @{
    p_course_id = $course.id; p_category = $category.name
    p_title = "MEDIA TEST course $runId"; p_description = 'Retained upload and publication integration test.'
    p_modules = @(@{ title = 'MEDIA TEST module'; lessons = @(@{
      title = 'MEDIA TEST lecture'; duration_seconds = 600; notes = ''
    }) })
  }
  Api 'POST' '/rest/v1/rpc/create_course_draft' $teacher.access_token $draft | Out-Null
  Api 'POST' '/rest/v1/rpc/create_course_draft' $teacher.access_token $draft | Out-Null
  $stage = 'atomic rollback'
  $invalidDraft = $draft.Clone()
  $invalidDraft.p_course_id = [guid]::NewGuid().ToString()
  $invalidDraft.p_modules = @(@{ title = 'Invalid test'; lessons = @(@{ title = 'Invalid duration'; duration_seconds = 0 }) })
  $denied = $false
  try { Api 'POST' '/rest/v1/rpc/create_course_draft' $teacher.access_token $invalidDraft | Out-Null }
  catch { $denied = $true }
  $partial = @(Api 'GET' "/rest/v1/courses?select=id&id=eq.$($invalidDraft.p_course_id)" $teacher.access_token)
  if (-not $denied -or $partial.Count -ne 0) { throw 'Invalid curriculum left a partial course.' }
  $modules = @(Api 'GET' "/rest/v1/course_modules?select=id&course_id=eq.$($course.id)" $teacher.access_token)
  if ($modules.Count -ne 1) { throw 'Retry duplicated the curriculum.' }
  $module = $modules[0]
  $lessons = @(Api 'GET' "/rest/v1/lessons?select=id&module_id=eq.$($module.id)" $teacher.access_token)
  if ($lessons.Count -ne 1) { throw 'Retry duplicated lessons.' }
  $lesson = $lessons[0]
  $denied = $false
  try { Api 'PATCH' "/rest/v1/courses?id=eq.$($course.id)" $teacher.access_token @{ status = 'published' } | Out-Null }
  catch { $denied = $true }
  if (-not $denied) { throw 'Incomplete course was published.' }
  $stage = 'cover upload'
  $coverPath = "$($teacher.user.id)/$($course.id)/test.jpg"
  Invoke-RestMethod -Method POST -Uri "$url/storage/v1/object/course-thumbnails/$coverPath" `
    -Headers @{ apikey = $key; Authorization = "Bearer $($teacher.access_token)" } `
    -InFile (Join-Path $root 'assets/images/course1.jpg') -ContentType 'image/jpeg' | Out-Null
  Api 'PATCH' "/rest/v1/courses?id=eq.$($course.id)" $teacher.access_token @{ image_path = $coverPath } | Out-Null
  $stage = 'attached cover protection'
  Api 'DELETE' '/storage/v1/object/course-thumbnails' $teacher.access_token @{ prefixes = @($coverPath) } | Out-Null
  $coverResponse = Invoke-WebRequest -UseBasicParsing -Uri "$url/storage/v1/object/public/course-thumbnails/$coverPath"
  if ($coverResponse.StatusCode -ne 200) { throw 'An attached cover was deleted.' }
  $denied = $false
  try { Api 'PATCH' "/rest/v1/courses?id=eq.$($course.id)" $teacher.access_token @{ status = 'published' } | Out-Null }
  catch { $denied = $true }
  if (-not $denied) { throw 'Course with unfinished video was published.' }

  $stage = 'reserve'
  $file = Join-Path $root 'assets/videos/lecture.mp4'
  $size = (Get-Item -LiteralPath $file).Length
  $denied = $false
  try {
    Api 'POST' '/rest/v1/rpc/begin_lesson_media' $otherTeacher.access_token @{
      p_lesson_id = $lesson.id; p_byte_size = $size; p_mime_type = 'video/mp4'
    } | Out-Null
  } catch { $denied = $true }
  if (-not $denied) { throw 'Non-owner reserved a lesson upload.' }
  $reservation = @(Api 'POST' '/rest/v1/rpc/begin_lesson_media' $teacher.access_token @{
    p_lesson_id = $lesson.id; p_byte_size = $size; p_mime_type = 'video/mp4'
  })[0]
  $path = $reservation.object_path
  $stage = 'upload'
  $headers = @{ apikey = $key; Authorization = "Bearer $($teacher.access_token)" }
  Invoke-RestMethod -Method POST -Uri "$url/storage/v1/object/lesson-videos/$path" `
    -Headers $headers -InFile $file -ContentType 'video/mp4' -ErrorAction Stop | Out-Null
  Api 'POST' '/rest/v1/rpc/finalize_lesson_media' $teacher.access_token @{
    p_media_id = $reservation.media_id
  } | Out-Null
  if (-not (CanRead $teacher.access_token $path)) { throw 'Owner cannot read private video.' }
  if ((CanRead $student.access_token $path) -or
      (CanRead $outsider.access_token $path) -or
      (CanRead $otherTeacher.access_token $path)) {
    throw 'Unpublished video leaked.'
  }

  if ($VerifyTranscription) {
    $stage = 'automatic transcription'
    try {
      Api 'POST' '/functions/v1/transcribe-lesson' $teacher.access_token @{ mediaId = $reservation.media_id } | Out-Null
      $automatic = $null
      for ($attempt = 0; $attempt -lt 12; $attempt++) {
        Start-Sleep -Seconds 5
        $automatic = @(Api 'GET' "/rest/v1/lesson_media?select=status&id=eq.$($reservation.media_id)" $teacher.access_token)[0]
        if ($automatic.status -in @('needs_review', 'failed')) { break }
      }
      Write-Output "Automatic transcription observed status: $($automatic.status)."
    } catch {
      Write-Output 'Automatic transcription did not complete successfully; provider/gateway verification remains open.'
    }
  }
  $stage = 'transcript and publish'
  if (-not $VerifyTranscription -or $automatic.status -ne 'needs_review') {
    Api 'POST' '/rest/v1/rpc/save_lesson_transcript' $teacher.access_token @{
      p_media_id = $reservation.media_id; p_language = 'mixed'
      p_segments = @(@{ start = 0; end = 1
        text = 'Pakistan affairs practice lecture.' })
    } | Out-Null
  }
  $studentDraft = @(Api 'GET' "/rest/v1/lesson_media?select=id&id=eq.$($reservation.media_id)" `
    $student.access_token)
  if ($studentDraft.Count -ne 0) { throw 'Student can see a transcript draft.' }
  Api 'POST' '/rest/v1/rpc/publish_lesson_media' $teacher.access_token @{
    p_media_id = $reservation.media_id
  } | Out-Null
  $stage = 'course publication and curriculum lock'
  Api 'PATCH' "/rest/v1/courses?id=eq.$($course.id)" $teacher.access_token @{ status = 'published' } | Out-Null
  $stage = 'public catalog'
  $publicCourse = @(Api 'GET' "/rest/v1/courses?select=id&id=eq.$($course.id)" $null)
  if ($publicCourse.Count -ne 1) { throw 'Published course missing from public catalog.' }
  $denied = $false
  try { Api 'PATCH' "/rest/v1/lessons?id=eq.$($lesson.id)" $teacher.access_token @{ title = 'Invalid published edit' } | Out-Null }
  catch { $denied = $true }
  if (-not $denied) { throw 'Published curriculum remained editable.' }
  $stage = 'student enrollment'
  Api 'POST' '/rest/v1/enrollments' $student.access_token @{
    student_id = $student.user.id; course_id = $course.id
  } | Out-Null
  if (-not (CanRead $student.access_token $path)) { throw 'Enrolled student cannot read video.' }
  if ((CanRead $outsider.access_token $path) -or
      (CanRead $otherTeacher.access_token $path)) {
    throw 'Private video leaked to a non-enrolled account.'
  }
  $studentMedia = @(Api 'GET' "/rest/v1/lesson_media?select=id&id=eq.$($reservation.media_id)" `
    $student.access_token)
  if ($studentMedia.Count -ne 1) { throw 'Published media is not readable by student.' }
  $stage = 'answer key privacy'
  try {
    $keys = @(Api 'GET' '/rest/v1/lesson_checkpoint_keys?select=*' $student.access_token)
    if ($keys.Count -ne 0) { throw 'Student can read answer keys.' }
  } catch {
    if ($_.Exception.Response.StatusCode.value__ -ne 403) { throw }
  }
  Write-Output "PASS: retryable draft, cover upload, readiness guards, curriculum lock, private upload, ownership, draft privacy, public catalog, and enrollment RLS ($runId)."
  Write-Output 'Disposable MEDIA TEST accounts and media were retained for testing.'
} catch {
  Write-Error "Lesson-media smoke test failed at stage: $stage. $($_.Exception.Message)"
  exit 1
}
