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

$displayScale = 0.32
$jumpLiftPixels = @(0, -4, -12, -18, -7, 0)
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
    animations = $animations
}
$manifestJson = $manifest | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText(
    (Join-Path $runtimeRoot 'animation_manifest.json'),
    $manifestJson,
    [System.Text.UTF8Encoding]::new($false)
)
Write-Output "PETER_ADULT_IMAGE_V04_PREPARED $runtimeRoot"
