param(
    [string]$SearchRoot = "build/extension-windows"
)

$ErrorActionPreference = "Stop"

$dll = Get-ChildItem -Path $SearchRoot -Recurse -Filter "tcwa3_stats_tracker_x64.dll" |
    Select-Object -First 1

if (-not $dll) {
    Write-Error "tcwa3_stats_tracker_x64.dll was not found under $SearchRoot"
}

Write-Host "Inspecting $($dll.FullName)"
$dumpbinOutput = & dumpbin /dependents $dll.FullName
if ($LASTEXITCODE -ne 0) {
    Write-Error "dumpbin /dependents failed for $($dll.FullName)"
}

$dumpbinOutput | ForEach-Object { Write-Host $_ }

$forbidden = @(
    "libcurl.*\.dll",
    "curl.*\.dll",
    "libssl.*\.dll",
    "libcrypto.*\.dll",
    "zlib.*\.dll",
    "zstd.*\.dll",
    "brotli.*\.dll",
    "nghttp2.*\.dll",
    "idn2.*\.dll",
    "ssh2.*\.dll",
    "msvcp.*\.dll",
    "vcruntime.*\.dll",
    "concrt.*\.dll",
    "ucrtbased.*\.dll"
)

$matches = @()
foreach ($pattern in $forbidden) {
    $matches += $dumpbinOutput | Select-String -Pattern $pattern -CaseSensitive:$false
}

if ($matches.Count -gt 0) {
    Write-Error ("Windows extension depends on non-system runtime/library DLLs: " + (($matches | ForEach-Object { $_.Line.Trim() }) -join ", "))
}

Write-Host "Windows DLL dependency check passed: curl/TLS/compression/MSVC runtime dependencies are statically linked."
