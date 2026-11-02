$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$config = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $root '.env')) {
  if ($line -match '^(SUPABASE_URL|SUPABASE_PUBLISHABLE_KEY)=(.*)$') {
    $config[$Matches[1]] = $Matches[2].Trim().Trim('"', "'")
  }
}
$url = $config['SUPABASE_URL']
$headers = @{ apikey = $config['SUPABASE_PUBLISHABLE_KEY'] }
$stage = 'catalog'
try {
  $courseResult = Invoke-RestMethod -Method Get -Uri "$url/rest/v1/courses?select=id&status=eq.published" -Headers $headers
  $courses = @(foreach ($row in $courseResult) { $row })
  $metadata = @()
  $stage = 'syllabus'
  for ($offset = 0; $offset -lt $courses.Count; $offset += 200) {
    $ids = @($courses | Select-Object -Skip $offset -First 200 | ForEach-Object { $_.id })
    $body = @{ p_course_ids = $ids } | ConvertTo-Json -Compress
    $result = Invoke-RestMethod -Method Post -Uri "$url/rest/v1/rpc/get_public_course_syllabus" `
      -Headers $headers -ContentType 'application/json' -Body $body
    $metadata += @(foreach ($row in $result) { $row })
  }
  $stage = 'metadata-validation'
  $allowed = @('course_id', 'module_id', 'lesson_id', 'title', 'duration_seconds', 'display_order')
  foreach ($entry in $metadata) {
    foreach ($name in $entry.PSObject.Properties.Name) {
      if ($name -notin $allowed) { throw 'Unexpected syllabus field.' }
    }
    if ($entry.course_id -notin @($courses.id)) { throw 'Unexpected course visibility.' }
  }
  $lessonResult = Invoke-RestMethod -Method Get -Uri "$url/rest/v1/lessons?select=id" -Headers $headers
  $lessons = @(foreach ($row in $lessonResult) { $row })
  [pscustomobject]@{
    publishedCourses = $courses.Count
    publicSyllabusLessons = $metadata.Count
    directlyVisibleLessonRows = $lessons.Count
    privateFieldsExposed = $false
    passed = $true
  } | ConvertTo-Json -Compress
} catch {
  $status = $_.Exception.Response.StatusCode.value__
  throw "Public syllabus verification failed at $stage (HTTP $status). No credentials were logged."
}
