param(
    [string]$Version = '1.0.1',
    [int]$BuildNumber = 2,
    [string]$ApiBaseUrl = 'https://creative.yozik.ru/api/v1',
    [switch]$AppBundle
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$jdkPath = 'C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot'
$keystoreProperties = Join-Path $projectRoot 'android\key.properties'
$distPath = Join-Path $projectRoot "dist\android\$Version+$BuildNumber"

if (-not (Test-Path -LiteralPath $jdkPath)) {
    throw 'Microsoft OpenJDK 21 is required. Install package Microsoft.OpenJDK.21.'
}

if ($AppBundle -and -not (Test-Path -LiteralPath $keystoreProperties)) {
    throw 'Google Play AAB requires android/key.properties and a private release keystore.'
}

$env:JAVA_HOME = $jdkPath
$env:Path = "$jdkPath\bin;$env:Path"
flutter config --jdk-dir="$jdkPath" | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Unable to configure Flutter to use OpenJDK 21.' }

Write-Host "Building Creative Collective Android $Version+$BuildNumber" -ForegroundColor Cyan
Write-Host "API: $ApiBaseUrl" -ForegroundColor DarkGray

Push-Location $projectRoot
try {
    & (Join-Path $projectRoot 'scripts\generate_mobile_icon.ps1') -ProjectRoot $projectRoot

    flutter build apk --release `
        --build-name=$Version `
        --build-number=$BuildNumber `
        --dart-define=API_BASE_URL=$ApiBaseUrl
    if ($LASTEXITCODE -ne 0) { throw 'Android APK build failed.' }

    New-Item -ItemType Directory -Path $distPath -Force | Out-Null
    $apkSource = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    $apkTarget = Join-Path $distPath "creative-collective-$Version+$BuildNumber.apk"
    Copy-Item -LiteralPath $apkSource -Destination $apkTarget -Force
    Write-Host "APK: $apkTarget" -ForegroundColor Green

    if ($AppBundle) {
        flutter build appbundle --release `
            --build-name=$Version `
            --build-number=$BuildNumber `
            --dart-define=API_BASE_URL=$ApiBaseUrl
        if ($LASTEXITCODE -ne 0) { throw 'Android App Bundle build failed.' }

        $aabSource = Join-Path $projectRoot 'build\app\outputs\bundle\release\app-release.aab'
        $aabTarget = Join-Path $distPath "creative-collective-$Version+$BuildNumber.aab"
        Copy-Item -LiteralPath $aabSource -Destination $aabTarget -Force
        Write-Host "AAB: $aabTarget" -ForegroundColor Green
    }
} finally {
    Pop-Location
}
