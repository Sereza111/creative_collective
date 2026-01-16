# Build script for Creative Collective iOS
# Usage: .\build_ios.ps1 1.0.0
# NOTE: This requires macOS with Xcode installed!

param(
    [Parameter(Mandatory=$true)]
    [string]$version
)

Write-Host "Build Creative Collective iOS v$version" -ForegroundColor Green
Write-Host "WARNING: iOS builds require macOS with Xcode!" -ForegroundColor Yellow

# Check if running on macOS (this will fail on Windows, but script is for documentation)
if ($IsWindows) {
    Write-Host ""
    Write-Host "ERROR: iOS builds can only be done on macOS!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To build for iOS on macOS, run these commands:" -ForegroundColor Cyan
    Write-Host "1. flutter clean" -ForegroundColor White
    Write-Host "2. flutter pub get" -ForegroundColor White
    Write-Host "3. cd ios && pod install && cd .." -ForegroundColor White
    Write-Host "4. flutter build ios --release" -ForegroundColor White
    Write-Host "5. Open Xcode and archive the app" -ForegroundColor White
    Write-Host "6. Upload to App Store Connect" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use Flutter's IPA build (for distribution):" -ForegroundColor Cyan
    Write-Host "flutter build ipa --release" -ForegroundColor White
    Write-Host ""
    exit 1
}

# If on macOS, proceed with build
Write-Host "Cleaning old builds..." -ForegroundColor Yellow
flutter clean

Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Installing CocoaPods dependencies..." -ForegroundColor Yellow
Set-Location ios
pod install
Set-Location ..

Write-Host "Building iOS IPA..." -ForegroundColor Yellow
flutter build ipa --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

$ipaPath = "build/ios/ipa/*.ipa"
$outputIpa = "creative_collective-v$version-ios.ipa"

if (Test-Path $ipaPath) {
    Copy-Item $ipaPath $outputIpa -Force
    $ipaSize = (Get-Item $outputIpa).Length / 1MB
    Write-Host "IPA created: $outputIpa (${ipaSize:N2} MB)" -ForegroundColor Green
}

Write-Host "Creating git tag v$version-ios..." -ForegroundColor Yellow
git tag -a "v$version-ios" -m "iOS Release v$version"
git push origin "v$version-ios"

Write-Host ""
Write-Host "DONE!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Test IPA: $outputIpa"
Write-Host "2. Upload to App Store Connect via Xcode or Transporter"
Write-Host "3. Submit for App Store review"
Write-Host ""

