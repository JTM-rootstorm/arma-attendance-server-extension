param(
    [string]$DllPath = "build/extension-windows/Release/tcwa3_stats_tracker_x64.dll"
)

$ErrorActionPreference = "Stop"

function Get-DumpbinPath {
    $fromPath = Get-Command dumpbin -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }

    $searchRoots = @()
    if (${env:ProgramFiles(x86)}) {
        $searchRoots += Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio"
    }
    if ($env:ProgramFiles) {
        $searchRoots += Join-Path $env:ProgramFiles "Microsoft Visual Studio"
    }

    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) {
            continue
        }

        $candidate = Get-ChildItem `
            -Path $root `
            -Recurse `
            -Filter dumpbin.exe `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "\\VC\\Tools\\MSVC\\[^\\]+\\bin\\Hostx64\\x64\\dumpbin\.exe$" } |
            Sort-Object FullName -Descending |
            Select-Object -First 1

        if ($candidate) {
            return $candidate.FullName
        }
    }

    Write-Error "dumpbin.exe was not found on PATH or under the Visual Studio installation."
}

$dll = Get-Item -LiteralPath $DllPath -ErrorAction Stop
if ($dll.FullName -match "\\Debug\\") { Write-Error "Debug DLL is not a valid release artifact: $($dll.FullName)" }

Write-Host "Inspecting $($dll.FullName)"
$dumpbin = Get-DumpbinPath
Write-Host "Using dumpbin at $dumpbin"
$dumpbinOutput = & $dumpbin /dependents $dll.FullName
if ($LASTEXITCODE -ne 0) {
    Write-Error "dumpbin /dependents failed for $($dll.FullName)"
}

$dumpbinOutput | ForEach-Object { Write-Host $_ }
$headers = & $dumpbin /headers $dll.FullName
if ($headers -notmatch "8664 machine \(x64\)") { Write-Error "DLL is not AMD64." }
$exports = & $dumpbin /exports $dll.FullName
foreach ($name in @("RVExtension", "RVExtensionArgs", "RVExtensionVersion")) {
    if ($exports -notmatch "\s$name\s*$") { Write-Error "Missing undecorated export: $name" }
}

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
    $dependencies = $matches |
        ForEach-Object { $_.Line.Trim() } |
        Sort-Object -Unique
    Write-Error ("Windows extension depends on non-system runtime/library DLLs: " + ($dependencies -join ", "))
}

Write-Host "Windows DLL dependency check passed: curl/TLS/compression/MSVC runtime dependencies are statically linked."
