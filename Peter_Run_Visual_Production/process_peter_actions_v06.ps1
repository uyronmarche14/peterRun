param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$sourceRoot = Join-Path $PSScriptRoot 'generated\peter_adult_image_v06\source_strips'
$runtimeRoot = Join-Path $ProjectRoot 'code\art\characters\peter_adult_image_v04'
$frameSize = 256
$stride = 260
$padding = 2

function New-Atlas([int]$count) {
    $atlas = [System.Drawing.Bitmap]::new($count * $stride + $padding, $frameSize + 2 * $padding, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($atlas)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    return @{ Image = $atlas; Graphics = $graphics }
}

function Copy-KeyPose($graphics, $source, [int]$sourceIndex, [int]$targetIndex) {
    $sourceRect = [System.Drawing.Rectangle]::new($padding + $sourceIndex * $stride, $padding, $frameSize, $frameSize)
    $targetRect = [System.Drawing.Rectangle]::new($padding + $targetIndex * $stride, $padding, $frameSize, $frameSize)
    $graphics.DrawImage($source, $targetRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-Inbetween($graphics, $source, [int[]]$bounds, [int]$targetIndex, [int]$targetHeight, [int]$bottom) {
    # The generated strips have independently inspected, non-touching cutouts.
    # Two pixels of padding preserve their antialiased alpha fringes.
    $x = [Math]::Max(0, $bounds[0] - 2)
    $y = [Math]::Max(0, $bounds[1] - 2)
    $width = [Math]::Min($source.Width - $x, $bounds[2] + 4)
    $height = [Math]::Min($source.Height - $y, $bounds[3] + 4)
    $targetWidth = [int][Math]::Round($width / $height * $targetHeight)
    if ($targetWidth -gt $frameSize - 8) { throw "In-between pose is too wide for a fixed 256-pixel frame." }
    $targetX = $padding + $targetIndex * $stride + [int][Math]::Round(($frameSize - $targetWidth) / 2.0)
    $targetY = $padding + $bottom - $targetHeight
    if ($targetY -lt $padding -or $bottom -gt $frameSize) { throw "In-between pose leaves its frame." }
    $sourceRect = [System.Drawing.Rectangle]::new($x, $y, $width, $height)
    $targetRect = [System.Drawing.Rectangle]::new($targetX, $targetY, $targetWidth, $targetHeight)
    $graphics.DrawImage($source, $targetRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
}

function Save-Atlas($bundle, [string]$filename) {
    $bundle.Graphics.Dispose()
    $path = Join-Path $runtimeRoot $filename
    $bundle.Image.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bundle.Image.Dispose()
    Write-Output "Created $path"
}

$oldJump = [System.Drawing.Bitmap]::new((Join-Path $runtimeRoot 'jump_high_v05.png'))
$jumpUp = [System.Drawing.Bitmap]::new((Join-Path $sourceRoot 'jump_inbetweens_ascent_v06.png'))
$jumpDown = [System.Drawing.Bitmap]::new((Join-Path $sourceRoot 'jump_inbetweens_descent_v06.png'))
$oldSlide = [System.Drawing.Bitmap]::new((Join-Path $runtimeRoot 'slide_duck.png'))
$slideMid = [System.Drawing.Bitmap]::new((Join-Path $sourceRoot 'slide_inbetweens_v06.png'))

try {
    foreach ($source in @($jumpUp, $jumpDown, $slideMid)) {
        if ($source.GetPixel(0, 0).A -ne 0) { throw 'The new source strip is not transparent.' }
    }

    $jump = New-Atlas 15
    $jumpUpBounds = @(
        @(36, 296, 289, 355),
        @(370, 208, 315, 443),
        @(700, 130, 299, 473),
        @(1868, 201, 264, 455)
    )
    $jumpDownBounds = @(
        @(358, 44, 407, 553),
        @(893, 59, 397, 582),
        @(1454, 154, 423, 521)
    )
    for ($index = 0; $index -lt 8; $index++) {
        Copy-KeyPose $jump.Graphics $oldJump $index ($index * 2)
    }
    # Four ascent/recovery cutouts and three apex/descent cutouts alternate
    # with the eight preserved, previously approved Jump key poses.
    $jumpNew = @(
        @{ Source = $jumpUp; Bounds = $jumpUpBounds[0]; Frame = 1; Bottom = 210 },
        @{ Source = $jumpUp; Bounds = $jumpUpBounds[1]; Frame = 3; Bottom = 196 },
        @{ Source = $jumpUp; Bounds = $jumpUpBounds[2]; Frame = 5; Bottom = 179 },
        @{ Source = $jumpDown; Bounds = $jumpDownBounds[0]; Frame = 7; Bottom = 165 },
        @{ Source = $jumpDown; Bounds = $jumpDownBounds[1]; Frame = 9; Bottom = 170 },
        @{ Source = $jumpDown; Bounds = $jumpDownBounds[2]; Frame = 11; Bottom = 198 },
        @{ Source = $jumpUp; Bounds = $jumpUpBounds[3]; Frame = 13; Bottom = 216 }
    )
    foreach ($pose in $jumpNew) {
        Draw-Inbetween $jump.Graphics $pose.Source $pose.Bounds $pose.Frame 152 $pose.Bottom
    }
    Save-Atlas $jump 'jump_smooth_v06.png'

    $slide = New-Atlas 11
    for ($index = 0; $index -lt 6; $index++) {
        Copy-KeyPose $slide.Graphics $oldSlide $index ($index * 2)
    }
    $slideBounds = @(
        @(39, 57, 390, 640),
        @(470, 129, 415, 558),
        @(901, 216, 409, 461),
        @(1348, 155, 412, 531),
        @(1806, 86, 351, 605)
    )
    $slideHeights = @(167, 134, 108, 124, 163)
    $slideBottoms = @(201, 195, 191, 195, 200)
    for ($index = 0; $index -lt 5; $index++) {
        Draw-Inbetween $slide.Graphics $slideMid $slideBounds[$index] ($index * 2 + 1) $slideHeights[$index] $slideBottoms[$index]
    }
    Save-Atlas $slide 'slide_smooth_v06.png'
}
finally {
    $oldJump.Dispose()
    $jumpUp.Dispose()
    $jumpDown.Dispose()
    $oldSlide.Dispose()
    $slideMid.Dispose()
}
