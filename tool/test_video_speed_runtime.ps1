param([Parameter(Mandatory=$true)][string]$VmService)
$ErrorActionPreference = 'Stop'
if ([uri]$VmService -and ([uri]$VmService).Host -notin @('127.0.0.1', 'localhost')) {
  throw 'Only a local Flutter debug service is supported.'
}
function Rpc($method, $parameters = @{}) {
  $query = ($parameters.GetEnumerator() | ForEach-Object {
    [uri]::EscapeDataString($_.Key) + '=' + [uri]::EscapeDataString([string]$_.Value)
  }) -join '&'
  $response = Invoke-RestMethod ($VmService.TrimEnd('/') + '/' + $method + '?' + $query)
  if ($response.error) { throw "Flutter debug service rejected $method (code $($response.error.code))." }
  return $response.result
}
$isolate = (Rpc 'getVM').isolates | Where-Object name -eq 'main' | Select-Object -First 1
if (!$isolate) { throw 'No main Flutter isolate found.' }
$classes = (Rpc 'getClassList' @{isolateId=$isolate.id}).classes
function Instance($name) {
  $class = $classes | Where-Object name -eq $name | Select-Object -First 1
  if (!$class) { throw 'Open a lesson video before running the playback check.' }
  $instances = Rpc 'getInstances' @{isolateId=$isolate.id;objectId=$class.id;limit=10}
  if ($instances.instances.Count -ne 1) { throw 'Expected one active lesson player.' }
  return $instances.instances[0].id
}
$video = Instance 'VideoPlayerController'
function Field($object, $name) {
  return ($object.fields | Where-Object { $_.decl.name -eq $name } | Select-Object -First 1).value
}
# Read only playback fields; no evaluation, URLs or account data are required.
for ($sample=0; $sample -lt 10; $sample++) {
  $controller = Rpc 'getObject' @{isolateId=$isolate.id;objectId=$video}
  $valueId = (Field $controller '_value').id
  $value = Rpc 'getObject' @{isolateId=$isolate.id;objectId=$valueId}
  $position = Rpc 'getObject' @{isolateId=$isolate.id;objectId=(Field $value 'position').id}
  [pscustomobject]@{
    playing=(Field $value 'isPlaying').valueAsString
    buffering=(Field $value 'isBuffering').valueAsString
    speed=(Field $value 'playbackSpeed').valueAsString
    positionUs=(Field $position '_duration').valueAsString
  } | ConvertTo-Json -Compress
  Start-Sleep -Milliseconds 500
}
