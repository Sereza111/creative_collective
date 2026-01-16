# Build script for Creative Collective Android APK
# Usage: .\build_android.ps1 1.0.0

param(
    [Parameter(Mandatory=$true)]
    [string]$version
)

Write-Host "Build Creative Collective Android APK v$version" -ForegroundColor Green

# 1. Clean previous builds
Write-Host "Cleaning old builds..." -ForegroundColor Yellow
flutter clean

# 2. Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Build Android APK
Write-Host "Building Android APK..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# 4. Build Android App Bundle (for Google Play)
Write-Host "Building Android App Bundle..." -ForegroundColor Yellow
flutter build appbundle --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "App Bundle build failed!" -ForegroundColor Red
}

# 5. Copy and rename files
Write-Host "Organizing files..." -ForegroundColor Yellow
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
$aabPath = "build\app\outputs\bundle\release\app-release.aab"
$outputApk = "creative_collective-v$version-android.apk"
$outputAab = "creative_collective-v$version-android.aab"

if (Test-Path $apkPath) {
    Copy-Item $apkPath $outputApk -Force
    $apkSize = (Get-Item $outputApk).Length / 1MB
    Write-Host "APK created: $outputApk (${apkSize:N2} MB)" -ForegroundColor Green
}

if (Test-Path $aabPath) {
    Copy-Item $aabPath $outputAab -Force
    $aabSize = (Get-Item $outputAab).Length / 1MB
    Write-Host "AAB created: $outputAab (${aabSize:N2} MB)" -ForegroundColor Green
}

# 6. Create git tag
Write-Host "Creating git tag v$version-android..." -ForegroundColor Yellow
git tag -a "v$version-android" -m "Android Release v$version"
git push origin "v$version-android"

Write-Host ""
Write-Host "DONE!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Test APK: $outputApk"
Write-Host "2. Upload AAB to Google Play Console: $outputAab"
Write-Host "3. Or create GitHub Release with APK for direct download"
Write-Host ""

