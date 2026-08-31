$ErrorActionPreference = "Stop"

function Assert-NativeSuccess([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE"
    }
}

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

Write-Host "INDUSTRY KICK V2 - Stage 6.8D Pre-Safety Diagnostic"
Write-Host "Project root: $ProjectRoot"
Write-Host "AUDIO DSP IS NOT CHANGED BY THIS PROBE."

cmake -S $ProjectRoot -B (Join-Path $ProjectRoot "build") -DCMAKE_BUILD_TYPE=Release
Assert-NativeSuccess "CMake configure"

cmake --build (Join-Path $ProjectRoot "build") --config Release --target KICKCRAFTER_SafetyProbe
Assert-NativeSuccess "SafetyProbe build"

$candidates = @(
    (Join-Path $ProjectRoot "build\KICKCRAFTER_SafetyProbe_artefacts\Release\KICKCRAFTER_SafetyProbe.exe"),
    (Join-Path $ProjectRoot "build\KICKCRAFTER_SafetyProbe_artefacts\Release\INDUSTRY KICK Safety Probe.exe")
)

$exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) {
    $exe = Get-ChildItem (Join-Path $ProjectRoot "build") -Filter "*SafetyProbe*.exe" -Recurse |
           Select-Object -First 1 -ExpandProperty FullName
}
if (-not $exe) {
    throw "SAFETY_PROBE_EXE_NOT_FOUND"
}

Write-Host "Running: $exe"
& $exe
Assert-NativeSuccess "SafetyProbe execution"

$csv = Join-Path $ProjectRoot "Stage68SafetyProbe.csv"
if (-not (Test-Path $csv)) {
    throw "SAFETY_PROBE_CSV_NOT_FOUND"
}

Write-Host ""
Write-Host "STAGE_6_8D_DIAGNOSTIC_COMPLETE"
Write-Host "SEND_FILE=$csv"
