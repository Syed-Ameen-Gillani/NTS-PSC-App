$ErrorActionPreference = 'Stop'
$configuration = @{}
Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) '.env') |
  Where-Object { $_ -match '^(SUPABASE_URL|SUPABASE_PUBLISHABLE_KEY)=' } |
  ForEach-Object { $name,$value=$_ -split '=',2; $configuration[$name]=$value.Trim().Trim('"',"'") }
$url=$configuration.SUPABASE_URL
$headers=@{apikey=$configuration.SUPABASE_PUBLISHABLE_KEY}
$courseResult=Invoke-RestMethod -Method Get -Uri "$url/rest/v1/courses?select=id&status=eq.published" -Headers $headers
$courses=@(foreach($course in $courseResult){$course})
$outline=@()
for($offset=0;$offset -lt $courses.Count;$offset+=200) {
  $ids=@($courses | Select-Object -Skip $offset -First 200 | ForEach-Object {$_.id})
  $result=Invoke-RestMethod -Method Post -Uri "$url/rest/v1/rpc/get_public_course_outline" `
    -Headers $headers -ContentType 'application/json' -Body (ConvertTo-Json @{p_course_ids=$ids} -Compress)
  $outline+=@(foreach($entry in $result){$entry})
}
$allowed=@('course_id','release_id','module_id','module_title','module_order','lesson_id','title','duration_seconds','display_order','activities')
$activityFields=@('id','kind','title','display_order','required','rule_version','material_id','assessment_link_id')
foreach($entry in $outline) {
  foreach($field in $entry.PSObject.Properties.Name) {
    if($field -notin $allowed) {throw 'Unexpected public outline field'}
  }
  foreach($activity in $entry.activities) {
    foreach($field in $activity.PSObject.Properties.Name) {
      if($field -notin $activityFields) {throw 'Unexpected public activity field'}
    }
  }
}
$privateTables=@('course_releases','curriculum_draft_changes','lesson_activity_placements',
  'enrollment_access_audit','learning_access_grandfathering')
foreach($table in $privateTables) {
  $denied=$false
  try { Invoke-RestMethod -Method Get -Uri "$url/rest/v1/${table}?select=*&limit=1" -Headers $headers | Out-Null }
  catch { if($_.Exception.Response.StatusCode.value__ -in @(401,403)) {$denied=$true} else {throw} }
  if(-not $denied) {throw "Anonymous access was not denied for $table"}
}
[pscustomobject]@{Passed=$true;PublishedCourses=$courses.Count;OutlineLessons=$outline.Count;PrivateTablesDenied=$privateTables.Count} | ConvertTo-Json -Compress
