param([string]$AvdName='CBOA_Learning_Pixel_5')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$sdk=Join-Path $env:LOCALAPPDATA 'Android/Sdk'
$adb=Join-Path $sdk 'platform-tools/adb.exe'
$emulator=Join-Path $sdk 'emulator/emulator.exe'
$started=$false
function Read-Boot {
  $ErrorActionPreference='Continue'
  return (& $adb -s emulator-5556 shell getprop sys.boot_completed 2>$null) -join ''
}
try {
  $devices=& $adb devices
  if(-not ($devices -match '^emulator-5556\s+device')) {
    Start-Process -FilePath $emulator -ArgumentList @('-avd',$AvdName,'-port','5556','-no-window',
      '-no-snapshot-load','-no-snapshot-save','-no-boot-anim','-no-audio','-memory','1536','-cores','2') `
      -WindowStyle Hidden -RedirectStandardOutput (Join-Path $env:TEMP 'cboa-pixel5-native-stdout.log') `
      -RedirectStandardError (Join-Path $env:TEMP 'cboa-pixel5-native-stderr.log') | Out-Null
    $started=$true
  }
  $ready=$false
  for($attempt=0;$attempt -lt 90;$attempt++) {
    $boot=Read-Boot
    if($boot -match '^1'){$ready=$true;break}
    if($attempt%10 -eq 0){Write-Output 'Waiting for isolated Pixel 5 on port 5556...'}
    Start-Sleep -Seconds 2
  }
  if(-not $ready){throw 'Pixel 5 did not finish booting.'}
  $ErrorActionPreference='Continue'
  & C:/flutter/bin/flutter.bat test integration_test/learning_media_native_test.dart -d emulator-5556 --reporter expanded `
    *> (Join-Path $root 'tool/learning_native_result.txt')
  $testExit=$LASTEXITCODE
  $ErrorActionPreference='Stop'
  Get-Content (Join-Path $root 'tool/learning_native_result.txt') -Tail 35
  exit $testExit
} finally {
  if($started) {
    $ErrorActionPreference='Continue'
    $name=(& $adb -s emulator-5556 emu avd name 2>$null) -join ''
    if($name.Contains($AvdName)){& $adb -s emulator-5556 emu kill 2>$null | Out-Null}
  }
}
