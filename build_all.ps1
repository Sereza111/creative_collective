# Build script for ALL platforms
# Usage: .\build_all.ps1 1.0.0

param(
    [Parameter(Mandatory=$true)]
    [string]$version
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Creative Collective v$version" -ForegroundColor Cyan
Write-Host "ALL PLATFORMS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Windows
Write-Host ">>> Building Windows..." -ForegroundColor Magenta
.\build_release.ps1 $version

if ($LASTEXITCODE -ne 0) {
    Write-Host "Windows build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host ">>> Windows build complete!" -ForegroundColor Green
Write-Host ""

# 2. Android
Write-Host ">>> Building Android..." -ForegroundColor Magenta
.\build_android.ps1 $version

if ($LASTEXITCODE -ne 0) {
    Write-Host "Android build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host ">>> Android build complete!" -ForegroundColor Green
Write-Host ""

# 3. iOS (skip if on Windows)
if ($IsWindows) {
    Write-Host ">>> Skipping iOS (requires macOS)" -ForegroundColor Yellow
} else {
    Write-Host ">>> Building iOS..." -ForegroundColor Magenta
    .\build_ios.ps1 $version
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "iOS build failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host ">>> iOS build complete!" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ALL BUILDS COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Get-ChildItem -Filter "creative_collective-v$version-*" | ForEach-Object {
    $size = $_.Length / 1MB
    Write-Host "  - $($_.Name) (${size:N2} MB)" -ForegroundColor White
}
Write-Host ""

