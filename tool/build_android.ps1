# Builds MioAni for Android with the translation key wired in.
#
# The translation service signs every request with a secret, and a secret that
# reaches the app is a secret someone can read back out of the APK. So the key is
# injected at build time and never lives in the repository: this script reads it
# from the environment, where the owner keeps it, and hands it to the compiler
# as a --dart-define, which is the only way a value gets into the binary.
#
#   powershell -File tool/build_android.ps1                 # debug APK
#   powershell -File tool/build_android.ps1 -Release        # release APK
#   powershell -File tool/build_android.ps1 -Release -Install
#
# A build with no key in the environment still succeeds: it simply has no
# translations, and the pages it draws offer none.
#
# Debug is 2.4x slower than profile on the same device (4.7s vs 1.9s to first
# frame, measured on the emulator), because debug runs every line of Dart
# interpreted. Use this script or --profile when judging how fast the app feels.

[CmdletBinding()]
param(
  [switch] $Release,
  [switch] $Install,
  # Android device serial for -Install; the only emulator is the default.
  [string] $Serial = 'emulator-5554'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
# .bat, because PowerShell leaves the exit code of an extensionless native
# command unset, which would read as a build that never reported back.
$flutter = 'D:/PSoftware/DevTools/flutter/bin/flutter.bat'
$adb = 'D:/PSoftware/DevTools/AndroidSdk/platform-tools/adb.exe'
$appId = 'com.example.mio_ani/.MainActivity'

# The environment of this process first, then the user scope: a shell started
# before the variables were set does not have them.
function Get-Secret([string] $name) {
  $value = [Environment]::GetEnvironmentVariable($name, 'Process')
  if ([string]::IsNullOrWhiteSpace($value)) {
    $value = [Environment]::GetEnvironmentVariable($name, 'User')
  }
  if ([string]::IsNullOrWhiteSpace($value)) { return $null }
  return $value.Trim()
}

$secretId = Get-Secret 'TencentCloudSecretId'
$secretKey = Get-Secret 'TencentCloudSecretKey'

$defines = @()
if ($secretId -and $secretKey) {
  $defines += "--dart-define=MIO_ANI_TRANSLATE_SECRET_ID=$secretId"
  $defines += "--dart-define=MIO_ANI_TRANSLATE_SECRET_KEY=$secretKey"
  $idLength = $secretId.Length
  Write-Host "translation key: found (SecretId $idLength chars)" -ForegroundColor Green
} else {
  # Not an error: a build without the feature is a build without the feature.
  Write-Host 'translation key: not set, building without translations' -ForegroundColor Yellow
}

$mode = '--debug'
$apk = 'build/app/outputs/flutter-apk/app-debug.apk'
if ($Release) {
  $mode = '--release'
  $apk = 'build/app/outputs/flutter-apk/app-release.apk'
}

Push-Location $root
try {
  Write-Host "building ($mode)..." -ForegroundColor Cyan
  & $flutter build apk $mode @defines
  if ($LASTEXITCODE -ne 0) { throw "flutter build failed (exit $LASTEXITCODE)" }

  if ($Install) {
    Write-Host 'installing...' -ForegroundColor Cyan
    $env:MSYS_NO_PATHCONV = '1'
    & $adb -s $Serial install -r $apk
    if ($LASTEXITCODE -ne 0) { throw "adb install failed with $LASTEXITCODE" }
    & $adb -s $Serial shell am start -n $appId | Out-Null
    Write-Host 'installed and launched' -ForegroundColor Green
  }
} finally {
  Pop-Location
}
