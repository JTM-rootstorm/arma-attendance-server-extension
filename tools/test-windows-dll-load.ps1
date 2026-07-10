param(
    [Parameter(Mandatory = $true)]
    [string]$DllPath
)
$ErrorActionPreference = "Stop"
$expected = [IO.Path]::GetFullPath($DllPath)
if (-not (Test-Path -LiteralPath $expected -PathType Leaf)) { throw "Release DLL not found: $expected" }
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeDllTest {
  [DllImport("kernel32", SetLastError=true, CharSet=CharSet.Unicode)] public static extern IntPtr LoadLibraryW(string path);
  [DllImport("kernel32", SetLastError=true)] public static extern IntPtr GetProcAddress(IntPtr module, string name);
  [DllImport("kernel32", SetLastError=true)] public static extern bool FreeLibrary(IntPtr module);
}
"@
$module = [NativeDllTest]::LoadLibraryW($expected)
if ($module -eq [IntPtr]::Zero) { throw "LoadLibraryW failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())" }
try {
  foreach ($name in @("RVExtension", "RVExtensionArgs", "RVExtensionVersion")) {
    if ([NativeDllTest]::GetProcAddress($module, $name) -eq [IntPtr]::Zero) { throw "Missing undecorated export: $name" }
  }
} finally { [void][NativeDllTest]::FreeLibrary($module) }
Write-Host "[PASS] Loaded exact Release DLL and resolved Arma exports: $expected"
