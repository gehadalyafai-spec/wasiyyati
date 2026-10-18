$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
Write-Host "Preparing Wasiyyati Flutter Android host..." -ForegroundColor Cyan
flutter create . --platforms=android --project-name wasiyyati --org com.gehadalyafai
if ($LASTEXITCODE -ne 0) { throw 'flutter create failed' }

# Important: local vault key is in Android Keystore. Restoring app files without
# the Keystore key would make encrypted local records inaccessible.
$manifest = 'android\app\src\main\AndroidManifest.xml'
$xml = Get-Content $manifest -Raw
if ($xml -notmatch 'android:allowBackup') {
    $xml = $xml -replace '<application\s+', '<application android:allowBackup="false" android:fullBackupContent="false" '
}
[System.IO.File]::WriteAllText((Resolve-Path $manifest), $xml, (New-Object System.Text.UTF8Encoding($false)))

$gradleKts = 'android\app\build.gradle.kts'
if (Test-Path $gradleKts) {
    $content = Get-Content $gradleKts -Raw
    if ($content -notmatch 'minSdk\s*=\s*24') {
        $content = $content -replace 'minSdk\s*=\s*flutter.minSdkVersion', 'minSdk = 24'
    }
    [System.IO.File]::WriteAllText((Resolve-Path $gradleKts), $content, (New-Object System.Text.UTF8Encoding($false)))
}
# Some Flutter templates add a default widget_test that references template MyApp.
# Our real tests are test/vault_data_test.dart.
if (Test-Path 'test\widget_test.dart') { Remove-Item 'test\widget_test.dart' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed; review the output above' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }
Write-Host 'Project setup completed successfully.' -ForegroundColor Green
