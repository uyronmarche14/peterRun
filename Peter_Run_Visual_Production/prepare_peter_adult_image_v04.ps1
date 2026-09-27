param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public sealed class PeterSpriteComponent
{
    public Rectangle Bounds { get; private set; }
    public Bitmap Image { get; private set; }

    public PeterSpriteComponent(Rectangle bounds, Bitmap image)
    {
        Bounds = bounds;
        Image = image;
    }
}

public static class PeterSpriteComponents
{
    public static PeterSpriteComponent[] Extract(Bitmap input, byte alphaThreshold)
    {
        using (var bitmap = input.Clone(
            new Rectangle(0, 0, input.Width, input.Height),
            PixelFormat.Format32bppArgb))
        {
            int width = bitmap.Width;
            int height = bitmap.Height;
            var rect = new Rectangle(0, 0, width, height);
            var data = bitmap.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            int stride = Math.Abs(data.Stride);
            var bytes = new byte[stride * height];
            Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
            bitmap.UnlockBits(data);

            var opaque = new bool[width * height];
            for (int y = 0; y < height; y++)
            {
                int row = y * stride;
                for (int x = 0; x < width; x++)
                    opaque[y * width + x] = bytes[row + x * 4 + 3] > alphaThreshold;
            }

            var visited = new bool[opaque.Length];
            var components = new List<PeterSpriteComponent>();
            var queue = new Queue<int>();
            for (int index = 0; index < opaque.Length; index++)
            {
                if (!opaque[index] || visited[index])
                    continue;
                visited[index] = true;
                queue.Enqueue(index);
                int count = 0;
                int minX = width, minY = height, maxX = 0, maxY = 0;
                var pixels = new List<int>();
                while (queue.Count > 0)
                {
                    int current = queue.Dequeue();
                    pixels.Add(current);
                    int cx = current % width;
                    int cy = current / width;
                    count++;
                    minX = Math.Min(minX, cx);
                    minY = Math.Min(minY, cy);
                    maxX = Math.Max(maxX, cx);
                    maxY = Math.Max(maxY, cy);
                    for (int ny = Math.Max(0, cy - 1); ny <= Math.Min(height - 1, cy + 1); ny++)
                    {
                        for (int nx = Math.Max(0, cx - 1); nx <= Math.Min(width - 1, cx + 1); nx++)
                        {
                            int neighbor = ny * width + nx;
                            if (opaque[neighbor] && !visited[neighbor])
                            {
                                visited[neighbor] = true;
                                queue.Enqueue(neighbor);
                            }
                        }
                    }
                }
                int componentWidth = maxX - minX + 1;
                int componentHeight = maxY - minY + 1;
                if (count > 500 && componentWidth > 40 && componentHeight > height / 4)
                {
                    var bounds = new Rectangle(minX, minY, componentWidth, componentHeight);
                    var componentImage = new Bitmap(componentWidth, componentHeight, PixelFormat.Format32bppArgb);
                    var outputData = componentImage.LockBits(
                        new Rectangle(0, 0, componentWidth, componentHeight),
                        ImageLockMode.WriteOnly,
                        PixelFormat.Format32bppArgb);
                    int outputStride = Math.Abs(outputData.Stride);
                    var outputBytes = new byte[outputStride * componentHeight];
                    foreach (int pixel in pixels)
                    {
                        int px = pixel % width;
                        int py = pixel / width;
                        int sourceOffset = py * stride + px * 4;
                        int outputOffset = (py - minY) * outputStride + (px - minX) * 4;
                        outputBytes[outputOffset] = bytes[sourceOffset];
                        outputBytes[outputOffset + 1] = bytes[sourceOffset + 1];
                        outputBytes[outputOffset + 2] = bytes[sourceOffset + 2];
                        outputBytes[outputOffset + 3] = bytes[sourceOffset + 3];
                    }
                    Marshal.Copy(outputBytes, 0, outputData.Scan0, outputBytes.Length);
                    componentImage.UnlockBits(outputData);
                    components.Add(new PeterSpriteComponent(bounds, componentImage));
                }
            }
            components.Sort((a, b) => a.Bounds.Left.CompareTo(b.Bounds.Left));
            return components.ToArray();
        }
    }
}
'@

$sourceRoot = Join-Path $PSScriptRoot 'generated\peter_adult_image_v04\source_strips'
$runtimeRoot = Join-Path $ProjectRoot 'code\art\characters\peter_adult_image_v04'
$framesRoot = Join-Path $PSScriptRoot 'generated\peter_adult_image_v04\normalized_frames'
New-Item -ItemType Directory -Force -Path $runtimeRoot, $framesRoot | Out-Null

$displayScale = 0.36
$jumpLiftPixels = @(0, -8, -22, -36, -14, 0)
$slideVerticalScale = @(1.0, 0.96, 0.90, 0.88, 0.95, 1.0)

$clips = [ordered]@{
    idle_ready = @{ Source = 'idle_ready_source.png'; Frames = 6; Duration = 2.0; Loop = $true }
    walk_forward = @{ Source = 'walk_forward_source.png'; Frames = 6; Duration = 1.2; Loop = $true }
    move_left = @{ Source = 'move_left_source.png'; Frames = 6; Duration = 0.22; Loop = $false }
    move_right = @{ Source = 'move_right_source.png'; Frames = 6; Duration = 0.22; Loop = $false }
    jump_low = @{ Source = 'jump_low_source.png'; Frames = 6; Duration = 0.62; Loop = $false }
    slide_duck = @{ Source = 'slide_duck_source.png'; Frames = 6; Duration = 0.48; Loop = $false }
    rest = @{ Source = 'rest_source.png'; Frames = 6; Duration = 2.0; Loop = $true }
    success_settle = @{ Source = 'success_settle_source.png'; Frames = 4; Duration = 0.5; Loop = $false }
    neutral_clear = @{ Source = 'neutral_clear_source.png'; Frames = 4; Duration = 0.25; Loop = $false }
    paused = @{ Source = 'paused_source.png'; Frames = 1; Duration = (1.0 / 24.0); Loop = $false }
}

function New-TransparentBitmap([int]$width, [int]$height) {
    $bitmap = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.Clear([System.Drawing.Color]::Transparent)
    }
    finally {
        $graphics.Dispose()
    }
    return $bitmap
}

function Save-Png([System.Drawing.Bitmap]$bitmap, [string]$path) {
    $parent = Split-Path -Parent $path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function New-FeedbackEffectAssets([string]$outputRoot) {
    $effectRoot = Join-Path $outputRoot 'effects'
    New-Item -ItemType Directory -Force -Path $effectRoot | Out-Null

    $effectSpecs = @(
        @{ Name = 'landing_ring.png'; Draw = {
            param($graphics)
            $haloBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 255, 222, 155))
            $creamPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(205, 255, 242, 205), 3.0)
            $mangoPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 239, 166, 66), 2.0)
            try {
                $graphics.FillEllipse($haloBrush, 18, 23, 92, 24)
                $graphics.DrawArc($creamPen, 19, 22, 90, 25, 190, 160)
                $graphics.DrawArc($mangoPen, 27, 27, 74, 17, 8, 164)
            }
            finally { $haloBrush.Dispose(); $creamPen.Dispose(); $mangoPen.Dispose() }
        }}
        @{ Name = 'landing_dust.png'; Draw = {
            param($graphics)
            $soft = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(105, 244, 222, 174))
            $warm = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(90, 218, 178, 111))
            $speck = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(150, 255, 237, 196))
            try {
                $graphics.FillEllipse($soft, 19, 30, 28, 13)
                $graphics.FillEllipse($soft, 81, 29, 30, 14)
                $graphics.FillEllipse($warm, 35, 36, 23, 8)
                $graphics.FillEllipse($warm, 70, 35, 22, 8)
                $graphics.FillEllipse($speck, 27, 24, 5, 5)
                $graphics.FillEllipse($speck, 98, 22, 4, 4)
                $graphics.FillEllipse($speck, 16, 28, 3, 3)
            }
            finally { $soft.Dispose(); $warm.Dispose(); $speck.Dispose() }
        }}
        @{ Name = 'lane_shift_trail.png'; Draw = {
            param($graphics)
            $creamPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(175, 247, 231, 192), 4.0)
            $tealPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(145, 89, 160, 153), 2.5)
            $mangoPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(125, 232, 157, 58), 1.8)
            try {
                foreach ($pen in @($creamPen, $tealPen, $mangoPen)) {
                    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
                    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
                }
                $graphics.DrawBezier($creamPen, 18, 38, 42, 35, 67, 42, 105, 34)
                $graphics.DrawBezier($tealPen, 9, 46, 36, 43, 66, 48, 94, 41)
                $graphics.DrawBezier($mangoPen, 35, 26, 58, 25, 75, 30, 112, 26)
            }
            finally { $creamPen.Dispose(); $tealPen.Dispose(); $mangoPen.Dispose() }
        }}
        @{ Name = 'slide_dust.png'; Draw = {
            param($graphics)
            $soft = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(125, 239, 217, 165))
            $warm = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(100, 202, 158, 92))
            $linePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(145, 255, 235, 190), 2.3)
            try {
                $linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
                $linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
                $graphics.FillEllipse($soft, 58, 31, 35, 14)
                $graphics.FillEllipse($soft, 30, 35, 37, 13)
                $graphics.FillEllipse($warm, 12, 39, 31, 10)
                $graphics.FillEllipse($warm, 79, 38, 27, 9)
                $graphics.DrawBezier($linePen, 12, 32, 34, 27, 47, 32, 67, 29)
                $graphics.DrawBezier($linePen, 26, 50, 51, 47, 74, 50, 103, 44)
            }
            finally { $soft.Dispose(); $warm.Dispose(); $linePen.Dispose() }
        }}
    )

    foreach ($effectSpec in $effectSpecs) {
        $bitmap = New-TransparentBitmap 128 64
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            & $effectSpec.Draw $graphics
        }
        finally { $graphics.Dispose() }
        Save-Png $bitmap (Join-Path $effectRoot $effectSpec.Name)
        $bitmap.Dispose()
    }
}

function New-ContactSheetPackage(
    [string]$normalizedRoot,
    [string]$outputRoot,
    [System.Collections.IDictionary]$clipSpecs
) {
    New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
    $background = [System.Drawing.Color]::FromArgb(255, 242, 231, 202)
    $ink = [System.Drawing.Brushes]::DarkSlateGray
    $accentBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 40, 100, 98))
    $rowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 232, 216, 179))
    $titleFont = [System.Drawing.Font]::new([System.Drawing.FontFamily]::GenericSansSerif, 18, [System.Drawing.FontStyle]::Bold)
    $labelFont = [System.Drawing.Font]::new([System.Drawing.FontFamily]::GenericSansSerif, 11, [System.Drawing.FontStyle]::Regular)
    $smallFont = [System.Drawing.Font]::new([System.Drawing.FontFamily]::GenericSansSerif, 9, [System.Drawing.FontStyle]::Regular)
    $manifestClips = @()
    try {
        foreach ($clipName in $clipSpecs.Keys) {
            $spec = $clipSpecs[$clipName]
            $framePaths = @(Get-ChildItem -LiteralPath (Join-Path $normalizedRoot $clipName) -Filter '*.png' | Sort-Object Name | ForEach-Object FullName)
            $sheetWidth = [Math]::Max(320, 40 + ($framePaths.Count * 176))
            $sheetHeight = 292
            $sheet = [System.Drawing.Bitmap]::new($sheetWidth, $sheetHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [System.Drawing.Graphics]::FromImage($sheet)
            try {
                $graphics.Clear($background)
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.DrawString("PETER ADULT v04 - $clipName", $titleFont, $accentBrush, 20, 14)
                $graphics.DrawString(("{0} poses | {1:0.00}s | {2}" -f $framePaths.Count, [double]$spec.Duration, $(if ($spec.Loop) { 'loop' } else { 'one-shot' })), $labelFont, $ink, 22, 43)
                $graphics.DrawLine([System.Drawing.Pens]::DarkGray, 18, 246, $sheetWidth - 18, 246)
                for ($index = 0; $index -lt $framePaths.Count; $index++) {
                    $frame = [System.Drawing.Bitmap]::new($framePaths[$index])
                    try {
                        $destination = [System.Drawing.Rectangle]::new(24 + ($index * 176), 72, 160, 160)
                        $graphics.DrawImage($frame, $destination, [System.Drawing.Rectangle]::new(0, 0, 256, 256), [System.Drawing.GraphicsUnit]::Pixel)
                        $graphics.DrawString(("POSE {0:D2}" -f ($index + 1)), $smallFont, $ink, 68 + ($index * 176), 256)
                    }
                    finally { $frame.Dispose() }
                }
            }
            finally { $graphics.Dispose() }
            $sheetName = "${clipName}_contact_sheet.png"
            Save-Png $sheet (Join-Path $outputRoot $sheetName)
            $sheet.Dispose()
            $manifestClips += [ordered]@{
                id = $clipName
                sheet = $sheetName
                frames = $framePaths.Count
                duration_seconds = [double]$spec.Duration
                loop = [bool]$spec.Loop
            }
        }

        $overviewWidth = 1120
        $overviewHeight = 94 + ($clipSpecs.Count * 176)
        $overview = [System.Drawing.Bitmap]::new($overviewWidth, $overviewHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $overviewGraphics = [System.Drawing.Graphics]::FromImage($overview)
        try {
            $overviewGraphics.Clear($background)
            $overviewGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $overviewGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $overviewGraphics.DrawString('PETER ADULT IMAGE v04 - COMPLETE ANIMATION CONTACT SHEET', $titleFont, $accentBrush, 24, 18)
            $overviewGraphics.DrawString('Fixed 256x256 canvas | ground pivot (128, 216) | rear gameplay view', $labelFont, $ink, 26, 50)
            $row = 0
            foreach ($clipName in $clipSpecs.Keys) {
                $spec = $clipSpecs[$clipName]
                $rowTop = 86 + ($row * 176)
                if ($row % 2 -eq 1) { $overviewGraphics.FillRectangle($rowBrush, 12, $rowTop, $overviewWidth - 24, 168) }
                $overviewGraphics.DrawString($clipName, $labelFont, $accentBrush, 24, $rowTop + 18)
                $overviewGraphics.DrawString(("{0} poses / {1:0.00}s" -f [int]$spec.Frames, [double]$spec.Duration), $smallFont, $ink, 24, $rowTop + 44)
                $framePaths = @(Get-ChildItem -LiteralPath (Join-Path $normalizedRoot $clipName) -Filter '*.png' | Sort-Object Name | ForEach-Object FullName)
                for ($index = 0; $index -lt $framePaths.Count; $index++) {
                    $frame = [System.Drawing.Bitmap]::new($framePaths[$index])
                    try {
                        $destination = [System.Drawing.Rectangle]::new(190 + ($index * 148), $rowTop + 12, 144, 144)
                        $overviewGraphics.DrawImage($frame, $destination, [System.Drawing.Rectangle]::new(0, 0, 256, 256), [System.Drawing.GraphicsUnit]::Pixel)
                    }
                    finally { $frame.Dispose() }
                }
                $row++
            }
        }
        finally { $overviewGraphics.Dispose() }
        Save-Png $overview (Join-Path $outputRoot 'peter_adult_image_v04_contact_sheet.png')
        $overview.Dispose()

        $contactManifest = [ordered]@{
            schema_version = 1
            character_id = 'peter_adult_image_v04'
            design_reference = 'Peter_Run_Visual_Production/character_concepts/peter_character_v03/peter_character_turnaround_v03.png'
            canvas = @(256, 256)
            pivot = @(128, 216)
            overview = 'peter_adult_image_v04_contact_sheet.png'
            clips = $manifestClips
        }
        [System.IO.File]::WriteAllText(
            (Join-Path $outputRoot 'contact_sheet_manifest.json'),
            ($contactManifest | ConvertTo-Json -Depth 8),
            [System.Text.UTF8Encoding]::new($false)
        )
    }
    finally {
        $accentBrush.Dispose(); $rowBrush.Dispose(); $titleFont.Dispose(); $labelFont.Dispose(); $smallFont.Dispose()
    }
}

function Render-Component(
    [PeterSpriteComponent]$component,
    [int]$sourceHeight,
    [int]$targetSize
) {
    $frame = New-TransparentBitmap $targetSize $targetSize
    $graphics = [System.Drawing.Graphics]::FromImage($frame)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        # The existing player scene places the authored foot contact at y=216.
        # Preserve that contract instead of using the bottom of the 256px tile.
        $scale = [Math]::Min(240.0 / $component.Bounds.Width, 208.0 / $sourceHeight)
        $drawWidth = [Math]::Max(1, [int][Math]::Round($component.Bounds.Width * $scale))
        $drawHeight = [Math]::Max(1, [int][Math]::Round($component.Bounds.Height * $scale))
        $x = [int][Math]::Round(($targetSize - $drawWidth) / 2.0)
        $y = 8 + [int][Math]::Round($component.Bounds.Y * $scale)
        $destination = [System.Drawing.Rectangle]::new($x, $y, $drawWidth, $drawHeight)
        $sourceRect = [System.Drawing.Rectangle]::new(0, 0, $component.Image.Width, $component.Image.Height)
        $graphics.DrawImage($component.Image, $destination, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
    }
    finally {
        $graphics.Dispose()
    }
    return $frame
}

function Apply-ActionAdjustment(
    [System.Drawing.Bitmap]$frame,
    [string]$clipName,
    [int]$frameIndex
) {
    if ($clipName -ne 'jump_low' -and $clipName -ne 'slide_duck') {
        return $frame
    }

    $adjusted = New-TransparentBitmap 256 256
    $graphics = [System.Drawing.Graphics]::FromImage($adjusted)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        if ($clipName -eq 'jump_low') {
            $graphics.DrawImageUnscaled($frame, 0, [int]$jumpLiftPixels[$frameIndex])
        }
        else {
            $scaleY = [double]$slideVerticalScale[$frameIndex]
            $height = [int][Math]::Round(256 * $scaleY)
            # Scale around the established y=216 foot anchor so the slide
            # becomes visibly lower without moving its road contact point.
            $y = [int][Math]::Round(216 * (1.0 - $scaleY))
            $destination = [System.Drawing.Rectangle]::new(0, $y, 256, $height)
            $sourceRect = [System.Drawing.Rectangle]::new(0, 0, 256, 256)
            $graphics.DrawImage($frame, $destination, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
        }
    }
    finally {
        $graphics.Dispose()
    }
    return $adjusted
}

$animations = [ordered]@{}
foreach ($clipName in $clips.Keys) {
    $spec = $clips[$clipName]
    $sourcePath = Join-Path $sourceRoot $spec.Source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing generated source strip: $sourcePath"
    }
    $source = [System.Drawing.Bitmap]::new($sourcePath)
    try {
        $count = [int]$spec.Frames
        $components = [PeterSpriteComponents]::Extract($source, 24)
        if ($components.Count -ne $count) {
            $bounds = ($components | ForEach-Object { "[$($_.Bounds.X),$($_.Bounds.Y),$($_.Bounds.Width),$($_.Bounds.Height)]" }) -join ', '
            throw "$clipName expected $count connected figures but found $($components.Count): $bounds"
        }
        $atlas = New-TransparentBitmap ($count * 260) 260
        $atlasGraphics = [System.Drawing.Graphics]::FromImage($atlas)
        $atlasGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $regions = @()
        $timestamps = @()
        $frameDurations = @()
        $frameDirectory = Join-Path $framesRoot $clipName
        New-Item -ItemType Directory -Force -Path $frameDirectory | Out-Null

        try {
            for ($index = 0; $index -lt $count; $index++) {
                $component = $components[$index]
                $frame = Render-Component $component $source.Height 256
                $adjustedFrame = Apply-ActionAdjustment $frame $clipName $index
                if (-not [object]::ReferenceEquals($adjustedFrame, $frame)) {
                    $frame.Dispose()
                    $frame = $adjustedFrame
                }
                try {
                    Save-Png $frame (Join-Path $frameDirectory ('{0:D2}.png' -f $index))
                    $atlasGraphics.DrawImageUnscaled($frame, 2 + ($index * 260), 2)
                }
                finally {
                    $frame.Dispose()
                }
                $regions += ,@((2 + ($index * 260)), 2, 256, 256)
                $timestamps += ($index * [double]$spec.Duration / $count)
                $frameDurations += ([double]$spec.Duration / $count)
            }
        }
        finally {
            $atlasGraphics.Dispose()
        }

        $atlasName = "$clipName.png"
        Save-Png $atlas (Join-Path $runtimeRoot $atlasName)
        $atlas.Dispose()
        foreach ($component in $components) {
            $component.Image.Dispose()
        }
        $animations[$clipName] = [ordered]@{
            frames = $count
            fps = $count / [double]$spec.Duration
            duration_seconds = [double]$spec.Duration
            loop = [bool]$spec.Loop
            timestamps = $timestamps
            frame_durations = $frameDurations
            atlas = $atlasName
            regions = $regions
        }
    }
    finally {
        $source.Dispose()
    }
}

$shadow = New-TransparentBitmap 256 256
$shadowGraphics = [System.Drawing.Graphics]::FromImage($shadow)
try {
    $shadowGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $shadowGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(72, 16, 46, 50))
    try {
        $shadowGraphics.FillEllipse($brush, 76, 207, 104, 18)
    }
    finally {
        $brush.Dispose()
    }
}
finally {
    $shadowGraphics.Dispose()
}
Save-Png $shadow (Join-Path $runtimeRoot 'ground_shadow.png')
$shadow.Dispose()
New-FeedbackEffectAssets $runtimeRoot

$manifest = [ordered]@{
    schema_version = 2
    asset_origin = 'image-generated action sprites derived from the approved original Peter concept'
    source_type = 'transparent illustrated sprite strips'
    design_reference = 'Peter_Run_Visual_Production/character_concepts/peter_character_v03/peter_character_turnaround_v03.png'
    source_directory = 'Peter_Run_Visual_Production/generated/peter_adult_image_v04/source_strips'
    generation_method = 'OpenAI built-in image generation with identity-preserving reference prompts'
    canvas = @(256, 256)
    pivot = @(128, 216)
    visual_adjustments = [ordered]@{
        display_scale = $displayScale
        jump_lift_pixels = $jumpLiftPixels
        slide_vertical_scale = $slideVerticalScale
    }
    playback_contract = 'Existing Godot controller remains the sole owner of lane position, timing, repetition, and pause.'
    jump_displacement = 'baked_into_frames'
    shadow = 'ground_shadow.png'
    feedback_effects = [ordered]@{
        landing_ring = 'effects/landing_ring.png'
        landing_dust = 'effects/landing_dust.png'
        lane_shift_trail = 'effects/lane_shift_trail.png'
        slide_dust = 'effects/slide_dust.png'
        character_compatibility = 'Shared ground-anchored effects; no dependency on adult body pixels.'
        reduced_motion = 'All optional effect layers are suppressed when reduced motion is enabled.'
    }
    contact_sheet_package = 'Peter_Run_Visual_Production/generated/peter_adult_image_v04/contact_sheets'
    animations = $animations
}
$manifestJson = $manifest | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText(
    (Join-Path $runtimeRoot 'animation_manifest.json'),
    $manifestJson,
    [System.Text.UTF8Encoding]::new($false)
)
New-ContactSheetPackage $framesRoot (Join-Path $PSScriptRoot 'generated\peter_adult_image_v04\contact_sheets') $clips
Write-Output "PETER_ADULT_IMAGE_V04_PREPARED $runtimeRoot"
