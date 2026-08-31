$ErrorActionPreference = "Stop"

function Assert-NativeSuccess([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE"
    }
}

$ProjectRoot = "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
$BuildDir = Join-Path $ProjectRoot "build"
Set-Location $ProjectRoot

Write-Host "INDUSTRY KICK V2 - Stage 6.9B Numerical-Silence Validation"
Write-Host "Faust DSP / presets / headroom / sonic thresholds: UNCHANGED"
Write-Host ""

$faustSource = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp"
if (-not (Test-Path $faustSource)) {
    throw "FAUST_SOURCE_NOT_FOUND"
}
if (-not (Select-String -Path $faustSource -SimpleMatch "Stage 6.9: measured family headroom" -Quiet)) {
    throw "EXPECTED_STAGE_6_9_DSP_NOT_FOUND"
}

cmake -S . -B build -G "Visual Studio 17 2022" -A x64
Assert-NativeSuccess "CMake configure"

# Only DspSmoke changed. Reuse the Stage 6.9 generated DSP that already ran.
cmake --build build --config Release --target KICKCRAFTER_DspSmoke
Assert-NativeSuccess "DspSmoke build"

$smokeCandidates = @(
    (Join-Path $ProjectRoot "build\KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"),
    (Join-Path $ProjectRoot "build\KICKCRAFTER_DspSmoke_artefacts\Release\INDUSTRY KICK DSP Smoke.exe")
)
$smokeExe = $smokeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $smokeExe) {
    throw "DSP_SMOKE_EXE_NOT_FOUND"
}

& $smokeExe
Assert-NativeSuccess "DspSmoke execution"

cmake --build build --config Release --target KICKCRAFTER_VST3
Assert-NativeSuccess "VST3 Release build"

$renderDir = Join-Path $ProjectRoot "Stage69BTestRenders"
$renderZip = Join-Path $ProjectRoot "Stage69BTestRenders.zip"
if (Test-Path $renderDir) {
    if (Test-Path $renderZip) { Remove-Item $renderZip -Force }
    Compress-Archive -Path (Join-Path $renderDir "*") -DestinationPath $renderZip -Force
}

Write-Host ""
Write-Host "STAGE_6_9B_BUILD_GATE_COMPLETE"
Write-Host "STAGE_6_9B_RENDER_ZIP=$renderZip"
