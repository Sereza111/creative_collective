param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

Add-Type -AssemblyName System.Drawing

function New-BrandIcon {
    param(
        [int]$Size,
        [string]$OutputPath,
        [switch]$Splash
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $background = [System.Drawing.ColorTranslator]::FromHtml('#0B0C0E')
    $foreground = [System.Drawing.ColorTranslator]::FromHtml('#E8E2D9')
    $brass = [System.Drawing.ColorTranslator]::FromHtml('#B79A65')
    $wine = [System.Drawing.ColorTranslator]::FromHtml('#B7465D')
    $dim = [System.Drawing.ColorTranslator]::FromHtml('#383439')
    $graphics.Clear($background)

    $scale = $Size / 1024.0
    $outerPen = [System.Drawing.Pen]::new($brass, [Math]::Max(2, 16 * $scale))
    $innerPen = [System.Drawing.Pen]::new($dim, [Math]::Max(1, 4 * $scale))
    $wineBrush = [System.Drawing.SolidBrush]::new($wine)
    $textBrush = [System.Drawing.SolidBrush]::new($foreground)
    $brassBrush = [System.Drawing.SolidBrush]::new($brass)

    $margin = 94 * $scale
    $graphics.DrawRectangle($outerPen, $margin, $margin, $Size - 2 * $margin, $Size - 2 * $margin)
    $innerMargin = 126 * $scale
    $graphics.DrawRectangle($innerPen, $innerMargin, $innerMargin, $Size - 2 * $innerMargin, $Size - 2 * $innerMargin)
    $graphics.FillRectangle($wineBrush, 110 * $scale, 126 * $scale, 24 * $scale, 772 * $scale)

    $fontSize = if ($Splash) { 280 * $scale } else { 300 * $scale }
    $font = [System.Drawing.Font]::new('Georgia', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $textSize = $graphics.MeasureString('CC', $font)
    $textX = ($Size - $textSize.Width) / 2
    $textY = ($Size - $textSize.Height) / 2 - 10 * $scale
    $graphics.DrawString('CC', $font, $textBrush, $textX, $textY)
    $graphics.FillRectangle($brassBrush, 350 * $scale, 690 * $scale, 324 * $scale, 12 * $scale)

    $directory = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $font.Dispose()
    $outerPen.Dispose()
    $innerPen.Dispose()
    $wineBrush.Dispose()
    $textBrush.Dispose()
    $brassBrush.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$brandingPath = Join-Path $ProjectRoot 'assets\branding\app_icon.png'
New-BrandIcon -Size 1024 -OutputPath $brandingPath

$densities = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}

foreach ($density in $densities.GetEnumerator()) {
    $resourcePath = Join-Path $ProjectRoot "android\app\src\main\res\$($density.Key)"
    New-BrandIcon -Size $density.Value -OutputPath (Join-Path $resourcePath 'ic_launcher.png')
    New-BrandIcon -Size $density.Value -OutputPath (Join-Path $resourcePath 'launch_image.png') -Splash
}

Write-Host "Generated Android brand assets from $brandingPath"
