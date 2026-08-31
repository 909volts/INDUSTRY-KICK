$ErrorActionPreference = "Stop"

# Always run from the Project root, regardless of where PowerShell was opened.
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

Write-Host "INDUSTRY KICK V2 - Stage 6.5 Validation Build Gate"
Write-Host "Project root: $ProjectRoot"

function Assert-NativeSuccess([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE"
    }
}

$faust = Get-Command faust -ErrorAction SilentlyContinue
if (-not $faust) {
    throw "FAUST_NOT_FOUND: install Faust and ensure faust.exe is on PATH."
}

faust -v
Assert-NativeSuccess "Faust version check"

# Force Faust regeneration so the build cannot reuse an older generated header.
$generatedHeader = Join-Path $ProjectRoot "build\generated\IndustryKickFaustDSP.h"
if (Test-Path $generatedHeader) {
    Remove-Item $generatedHeader -Force
    Write-Host "Removed stale generated Faust header."
}

$juceArgs = @()
if ($env:JUCE_SOURCE_DIR) {
    $juceArgs += "-DINDUSTRY_KICK_JUCE_SOURCE_DIR=$env:JUCE_SOURCE_DIR"
    Write-Host "Using local JUCE: $env:JUCE_SOURCE_DIR"
} else {
    Write-Host "JUCE_SOURCE_DIR not set; CMake will use/fetch JUCE 8.0.6."
}

cmake -S . -B build -G "Visual Studio 17 2022" -A x64 @juceArgs
Assert-NativeSuccess "CMake configure"

cmake --build build --config Release --target KICKCRAFTER_DspSmoke
Assert-NativeSuccess "DspSmoke build"

$smokeCandidates = @(
    (Join-Path $ProjectRoot "build\KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"),
    (Join-Path $ProjectRoot "build\KICKCRAFTER_DspSmoke_artefacts\Release\INDUSTRY KICK DSP Smoke.exe")
)
$smokeExe = $smokeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $smokeExe) {
    throw "DSP_SMOKE_EXE_NOT_FOUND: checked $($smokeCandidates -join '; ')"
}
Write-Host "Running DspSmoke: $smokeExe"

& $smokeExe
Assert-NativeSuccess "DspSmoke execution"

cmake --build build --config Release --target KICKCRAFTER_VST3
Assert-NativeSuccess "VST3 Release build"

Write-Host ""
Write-Host "STAGE_6_5_BUILD_GATE_COMPLETE"
Write-Host "If DspSmoke exported anchor WAVs, zip Stage6TestRenders and send it with this log."
