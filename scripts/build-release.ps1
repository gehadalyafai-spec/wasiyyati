$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not (Test-Path 'android')) {
    throw 'Android host missing. Run: powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1'
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'pub get failed' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'analyze failed' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'tests failed' }
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'APK build failed' }
Write-Host 'Output: build\app\outputs\flutter-apk\app-release.apk' -ForegroundColor Green
