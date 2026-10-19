$ErrorActionPreference = 'Stop'
# Kotlin's incremental compiler may fail when the Flutter Pub cache and project
# are on different Windows drives. Disable incremental compilation locally.
# https://kotlinlang.org/docs/gradle-compilation-and-caches.html
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$androidDir = Join-Path $root 'android'
if (-not (Test-Path $androidDir)) {
    throw 'Android platform missing. Run scripts/setup.ps1 first.'
}
$propertiesPath = Join-Path $androidDir 'gradle.properties'
if (Test-Path $propertiesPath) {
    $original = [System.IO.File]::ReadAllText($propertiesPath)
} else {
    $original = ''
}
$pattern = '(?m)^[ \t]*kotlin\.incremental[ \t]*=.*$'
if ([regex]::IsMatch($original, $pattern)) {
    $updated = [regex]::Replace($original, $pattern, 'kotlin.incremental=false')
} else {
    $updated = $original
    if ($updated.Length -gt 0 -and -not $updated.EndsWith([char]10)) {
        $updated += [Environment]::NewLine
    }
    $updated += '# Cross-drive Pub cache compatibility' + [Environment]::NewLine
    $updated += 'kotlin.incremental=false' + [Environment]::NewLine
}
if ($updated -cne $original) {
    [System.IO.File]::WriteAllText($propertiesPath, $updated,
        (New-Object System.Text.UTF8Encoding($false)))
    Write-Host 'Configured Android Kotlin cache workaround.' -ForegroundColor Yellow
} else {
    Write-Host 'Android Kotlin cache workaround already configured.' -ForegroundColor DarkGray
}
