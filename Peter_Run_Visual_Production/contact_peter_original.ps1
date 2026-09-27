$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$project = Split-Path $PSScriptRoot -Parent
$source = Join-Path $PSScriptRoot 'generated/peter_original_v01'
$manifest = Get-Content (Join-Path $project 'code/art/characters/peter_original_v01/animation_manifest.json') -Raw | ConvertFrom-Json
$target = Join-Path $project 'test_evidence/peter_original_v01'
$sheet = [Drawing.Bitmap]::new(1152, 10 * 158 + 54)
$g = [Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(229,231,217))
$font = [Drawing.Font]::new('Segoe UI',12)
$ink = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(30,68,67))
$g.DrawString('PETER / original skeletal animation / eight samples per clip', $font,$ink,16,12)
$row = 0
foreach ($property in $manifest.animations.PSObject.Properties) {
    $clip = $property.Name
    $spec = $property.Value
    $y = 54 + $row * 158
    $g.DrawString(($clip + ' / ' + $spec.duration_seconds + ' s'),$font,$ink,10,$y)
    for ($column=0; $column -lt 8; $column++) {
        $index = [int][Math]::Floor($column * ($spec.frames-1) / 7)
        $path = Join-Path $source ('{0}/{0}_{1:000}.png' -f $clip,$index)
        $im = [Drawing.Image]::FromFile($path)
        $g.DrawImage($im,[Drawing.Rectangle]::new($column*144,$y+22,128,128))
        $im.Dispose()
    }
    $row++
}
$sheet.Save((Join-Path $target 'animation_contact_sheet.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $sheet.Dispose()
$sheet = [Drawing.Bitmap]::new(1024,330)
$g = [Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(229,231,217))
$column=0
foreach ($view in @('front','side','rear','gameplay')) {
    $g.DrawString($view,$font,$ink,$column*256+16,12)
    $im=[Drawing.Image]::FromFile((Join-Path $source ('preview_'+$view+'.png')))
    $g.DrawImage($im,[Drawing.Rectangle]::new($column*256,40,256,256))
    $im.Dispose(); $column++
}
$sheet.Save((Join-Path $target 'design_turnaround.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $sheet.Dispose(); $font.Dispose(); $ink.Dispose()
Write-Output 'PETER CONTACT SHEETS PASS'
