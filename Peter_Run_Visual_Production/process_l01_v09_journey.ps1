# Deterministic export of the reviewed five-stage daylight keyframes.
# Source artwork remains in imagegen_sources; only 960x540 PNGs enter Godot.
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $PSScriptRoot 'imagegen_sources\l01_journey_keyframes_v02_time_moods'
$outputDir = Join-Path $projectRoot 'code\art\backgrounds\l01_barangay_v09_journey'
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$exports = @(
    @('l01_stage_01_home_street_dawn.png', 'l01_v09_home_dawn.png'),
    @('l01_stage_02_waiting_shed_early_morning.png', 'l01_v09_waiting_early_morning.png'),
    @('l01_stage_03_sari_sari_late_morning.png', 'l01_v09_sari_sari_late_morning.png'),
    @('l01_stage_04_palengke_early_afternoon.png', 'l01_v09_palengke_early_afternoon.png'),
    @('l01_stage_05_hall_plaza_golden_afternoon.png', 'l01_v09_plaza_golden_afternoon.png')
)

foreach ($export in $exports) {
    $sourcePath = Join-Path $sourceDir $export[0]
    $outputPath = Join-Path $outputDir $export[1]
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing reviewed scenery source: $sourcePath"
    }
    $source = [System.Drawing.Bitmap]::FromFile($sourcePath)
    try {
        if ($source.Width -ne 1672 -or $source.Height -ne 941) {
            throw "Unexpected source canvas: $sourcePath ($($source.Width)x$($source.Height))"
        }
        $output = [System.Drawing.Bitmap]::new(960, 540, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($output)
            try {
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                # Center-crop a quarter source pixel vertically for an exact 16:9 export.
                $sourceRect = [System.Drawing.RectangleF]::new(0.0, 0.25, 1672.0, 940.5)
                $outputRect = [System.Drawing.RectangleF]::new(0.0, 0.0, 960.0, 540.0)
                $graphics.DrawImage($source, $outputRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
            }
            finally {
                $graphics.Dispose()
            }
            $output.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $output.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
    Write-Output $outputPath
}
