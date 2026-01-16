# Build script for Creative Collective Windows release
# Usage: .\build_release.ps1 1.0.0

param(
    [Parameter(Mandatory=$true)]
    [string]$version
)

Write-Host "Build Creative Collective v$version" -ForegroundColor Green

# 1. Clean previous builds
Write-Host "Cleaning old builds..." -ForegroundColor Yellow
if (Test-Path "build\windows") {
    Remove-Item -Path "build\windows\x64\runner\Release" -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Build Flutter app
Write-Host "Building Flutter application..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# 3. Create archive
Write-Host "Creating archive..." -ForegroundColor Yellow
$releasePath = "build\windows\x64\runner\Release"
$outputName = "creative_collective-v$version-windows.zip"

if (Test-Path $outputName) {
    Remove-Item $outputName -Force
}

# Use built-in Compress-Archive
Compress-Archive -Path "$releasePath\*" -DestinationPath $outputName -CompressionLevel Optimal

# 4. Check size
$size = (Get-Item $outputName).Length / 1MB
Write-Host "Archive created: $outputName (${size:N2} MB)" -ForegroundColor Green

# 5. Create git tag
Write-Host "Creating git tag v$version..." -ForegroundColor Yellow
git tag -a "v$version" -m "Release v$version"
git push origin "v$version"

Write-Host ""
Write-Host "DONE!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to GitHub -> Releases -> Draft a new release"
Write-Host "2. Select tag v$version"
Write-Host "3. Attach file: $outputName"
Write-Host "4. Publish release"
Write-Host ""
