param([Parameter(Mandatory=$true)][string]$OutputPath,[Parameter(Mandatory=$true)][long]$WindowHandle)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class PeterCaptureWindow {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X,Y; }
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string cls,string name);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hwnd,out RECT rect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hwnd,ref POINT point);
}
'@
$handle=[IntPtr]::new($WindowHandle)
if ($handle -eq [IntPtr]::Zero) { throw 'Verification window not found' }
$rect=[PeterCaptureWindow+RECT]::new()
$point=[PeterCaptureWindow+POINT]::new()
[void][PeterCaptureWindow]::GetClientRect($handle,[ref]$rect)
[void][PeterCaptureWindow]::ClientToScreen($handle,[ref]$point)
$bitmap=[Drawing.Bitmap]::new($rect.Right,$rect.Bottom)
$graphics=[Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($point.X,$point.Y,0,0,$bitmap.Size)
$bitmap.Save($OutputPath,[Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $bitmap.Dispose()
