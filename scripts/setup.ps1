$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
Write-Host "Preparing Wasiyyati Flutter Android host..." -ForegroundColor Cyan
flutter create . --no-pub --platforms=android --project-name wasiyyati --org com.gehadalyafai
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
# AppCompat is required by the local_auth biometric prompt theme on Android.
if (Test-Path $gradleKts) {
    $content = Get-Content $gradleKts -Raw
    if ($content -notmatch 'androidx.appcompat:appcompat') {
        $content += "`n// Required for local_auth on Android 8 and older.`ndependencies {`n    implementation(`"androidx.appcompat:appcompat:1.7.1`")`n}`n"
        [System.IO.File]::WriteAllText((Resolve-Path $gradleKts), $content, (New-Object System.Text.UTF8Encoding($false)))
    }
}
# local_auth requires a FragmentActivity and the biometric manifest permission.
if ($xml -notmatch 'android.permission.USE_BIOMETRIC') {
    $permission = '$1' + "`n    <uses-permission android:name=`"android.permission.USE_BIOMETRIC`"/>"
    $xml = $xml -replace '(<manifest[^>]*>)', $permission
}
[System.IO.File]::WriteAllText((Resolve-Path $manifest), $xml, (New-Object System.Text.UTF8Encoding($false)))

# Flutter generates MainActivity as FlutterActivity; local_auth needs FragmentActivity.
$activityFiles = Get-ChildItem 'android\app\src\main' -Recurse -File | Where-Object {
    $_.Name -eq 'MainActivity.kt' -or $_.Name -eq 'MainActivity.java'
}
foreach ($activity in $activityFiles) {
    $source = Get-Content $activity.FullName -Raw
    $source = $source.Replace('FlutterActivity', 'FlutterFragmentActivity')
    [System.IO.File]::WriteAllText($activity.FullName, $source, (New-Object System.Text.UTF8Encoding($false)))
}

# The biometric prompt requires an AppCompat launch theme on older Android.
$themeFiles = @('android\app\src\main\res\values\styles.xml', 'android\app\src\main\res\values-night\styles.xml')
foreach ($themeFile in $themeFiles) {
    if (Test-Path $themeFile) {
        $style = Get-Content $themeFile -Raw
        $style = $style -replace '(<style\s+name="LaunchTheme"\s+parent=")[^"]+("[^>]*>)', '$1Theme.AppCompat.DayNight$2'
        [System.IO.File]::WriteAllText((Resolve-Path $themeFile), $style, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# Some Flutter templates add a default widget_test that references template MyApp.
# Our real tests are test/vault_data_test.dart.
if (Test-Path 'test\widget_test.dart') { Remove-Item 'test\widget_test.dart' }
Write-Host 'Resolving Flutter dependencies...' -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed; resolve dependency constraints above' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed; review the output above' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }
Write-Host 'Project setup completed successfully.' -ForegroundColor Green
