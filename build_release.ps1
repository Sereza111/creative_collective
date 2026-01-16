# Скрипт для создания релизной сборки Creative Collective
# Использование: .\build_release.ps1 1.0.0

param(
    [Parameter(Mandatory=$true)]
    [string]$version
)

Write-Host "🚀 Сборка Creative Collective v$version" -ForegroundColor Green

# 1. Очистка предыдущих сборок
Write-Host "🧹 Очистка старых билдов..." -ForegroundColor Yellow
if (Test-Path "build\windows") {
    Remove-Item -Path "build\windows\x64\runner\Release" -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Сборка Flutter приложения
Write-Host "📦 Сборка Flutter приложения..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка сборки!" -ForegroundColor Red
    exit 1
}

# 3. Создание архива
Write-Host "📁 Создание архива..." -ForegroundColor Yellow
$releasePath = "build\windows\x64\runner\Release"
$outputName = "creative_collective-v$version-windows.zip"

if (Test-Path $outputName) {
    Remove-Item $outputName -Force
}

# Используем встроенный Compress-Archive
Compress-Archive -Path "$releasePath\*" -DestinationPath $outputName -CompressionLevel Optimal

# 4. Проверка размера
$size = (Get-Item $outputName).Length / 1MB
Write-Host "✅ Архив создан: $outputName (${size:N2} MB)" -ForegroundColor Green

# 5. Создание git тега
Write-Host "🏷️  Создание git тега v$version..." -ForegroundColor Yellow
git tag -a "v$version" -m "Release v$version"
git push origin "v$version"

Write-Host ""
Write-Host "✅ ГОТОВО!" -ForegroundColor Green
Write-Host ""
Write-Host "Следующие шаги:" -ForegroundColor Cyan
Write-Host "1. Зайди на GitHub → Releases → Draft a new release"
Write-Host "2. Выбери тег v$version"
Write-Host "3. Прикрепи файл: $outputName"
Write-Host "4. Опубликуй релиз"
Write-Host ""

