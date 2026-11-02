$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
$svg = [IO.File]::ReadAllText((Join-Path $root 'assets/icons/app_logo.svg'))
$match = [regex]::Match($svg, 'data:image/jpeg;base64,([^"''\s]+)')
if (-not $match.Success) {
    throw 'No embedded JPEG found in app_logo.svg.'
}

$bytes = [Convert]::FromBase64String($match.Groups[1].Value)
$stream = [IO.MemoryStream]::new($bytes)
$source = [Drawing.Image]::FromStream($stream)

function Write-LauncherIcon([string]$path, [int]$size) {
    $bitmap = [Drawing.Bitmap]::new($size, $size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([Drawing.Color]::White)
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $maxSide = $size * 0.84
        $scale = [Math]::Min($maxSide / $source.Width, $maxSide / $source.Height)
        $width = [single]($source.Width * $scale)
        $height = [single]($source.Height * $scale)
        $graphics.DrawImage($source, [Drawing.RectangleF]::new(($size - $width) / 2, ($size - $height) / 2, $width, $height))
        $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

try {
    $androidSizes = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
    foreach ($density in $androidSizes.Keys) {
        $path = Join-Path $root "android/app/src/main/res/mipmap-$density/ic_launcher.png"
        Write-LauncherIcon $path $androidSizes[$density]
    }

    $iconDir = Join-Path $root 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    $contents = Get-Content (Join-Path $iconDir 'Contents.json') -Raw | ConvertFrom-Json
    foreach ($entry in $contents.images) {
        $points = [double]($entry.size.Split('x')[0])
        $scale = [double]($entry.scale.TrimEnd('x'))
        $pixels = [int][Math]::Round($points * $scale)
        Write-LauncherIcon (Join-Path $iconDir $entry.filename) $pixels
    }
} finally {
    $source.Dispose()
    $stream.Dispose()
}
