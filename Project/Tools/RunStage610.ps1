$ErrorActionPreference = "Stop"

function Assert-NativeSuccess([string]$Step, [int]$Code) {
    if ($Code -ne 0) {
        throw "$Step failed with exit code $Code"
    }
}

$ProjectRoot = "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
$BuildDir = Join-Path $ProjectRoot "build"
$FaustSource = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp"
$SmokeSource = Join-Path $ProjectRoot "Tests\DspSmoke.cpp"
$GeneratedHeader = Join-Path $BuildDir "generated\IndustryKickFaustDSP.h"
$RunLog = Join-Path $ProjectRoot "Stage610_DspSmoke.log"

Set-Location $ProjectRoot

Write-Host "INDUSTRY KICK V2 - Stage 6.10 RAVE Tail + Gate Fix"
Write-Host "Correlation is diagnostic only; technical/shape thresholds are unchanged."
Write-Host ""

if (-not (Select-String -Path $FaustSource -SimpleMatch "Stage 6.10: final RAVE decay contour" -Quiet)) {
    throw "STAGE610_FAUST_MARKER_MISSING"
}
if (-not (Select-String -Path $SmokeSource -SimpleMatch 'stageGate=6.10' -Quiet)) {
    throw "STAGE610_DSP_SMOKE_MARKER_MISSING"
}
if (-not (Select-String -Path $SmokeSource -SimpleMatch "familyEnvelopeCorrelationDiagnostic" -Quiet)) {
    throw "STAGE610_CORRELATION_DIAGNOSTIC_MARKER_MISSING"
}
if (-not (Select-String -Path $SmokeSource -SimpleMatch "maxSafetyClampEngagementPercent = 0.10" -Quiet)) {
    throw "SAFETY_THRESHOLD_CHANGED"
}

Write-Host "SOURCE IDENTITY: PASS"

# Make both edited sources definitely newer than incremental build products.
(Get-Item $FaustSource).LastWriteTime = Get-Date
(Get-Item $SmokeSource).LastWriteTime = Get-Date

cmake -S . -B build -G "Visual Studio 17 2022" -A x64
Assert-NativeSuccess "CMake configure" $LASTEXITCODE

# Force new Faust generation.
if (Test-Path $GeneratedHeader) {
    Remove-Item $GeneratedHeader -Force
    Write-Host "Removed stale generated Faust header."
}

# Force only DspSmoke's direct products out as an additional stale-build guard.
Get-ChildItem $BuildDir -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -eq "DspSmoke.obj" -or
        $_.Name -eq "KICKCRAFTER_DspSmoke.exe" -or
        $_.Name -eq "KICKCRAFTER_DspSmoke.pdb"
    } |
    ForEach-Object {
        Write-Host "Removing stale: $($_.FullName)"
        Remove-Item $_.FullName -Force
    }

Write-Host ""
Write-Host "Clean rebuilding DspSmoke + Faust dependency..."
cmake --build build --config Release --target KICKCRAFTER_DspSmoke --clean-first
Assert-NativeSuccess "DspSmoke clean rebuild" $LASTEXITCODE

$exe = Join-Path $BuildDir "KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
if (-not (Test-Path $exe)) {
    throw "DSP_SMOKE_EXE_NOT_FOUND: $exe"
}

$runtimeOutput = @(& $exe 2>&1)
$smokeExit = $LASTEXITCODE
$runtimeOutput | Tee-Object -FilePath $RunLog | ForEach-Object { Write-Host $_ }
$runtimeText = $runtimeOutput -join "`n"

if ($runtimeText -notmatch "stageGate=6.10") {
    throw "STALE_DSP_SMOKE_BINARY: stageGate 6.10 missing"
}
if ($runtimeText -notmatch "Stage610TestRenders") {
    throw "STALE_DSP_SMOKE_BINARY: Stage610TestRenders marker missing"
}
if ($runtimeText -notmatch "familyEnvelopeCorrelationDiagnostic") {
    throw "STALE_DSP_SMOKE_BINARY: correlation diagnostic marker missing"
}

Write-Host ""
Write-Host "RUNTIME BINARY IDENTITY: PASS"
Assert-NativeSuccess "DspSmoke execution" $smokeExit

cmake --build build --config Release --target KICKCRAFTER_VST3
Assert-NativeSuccess "VST3 Release build" $LASTEXITCODE

$renderDir = Join-Path $ProjectRoot "Stage610TestRenders"
$renderZip = Join-Path $ProjectRoot "Stage610TestRenders.zip"
if (-not (Test-Path $renderDir)) {
    throw "STAGE610_RENDER_DIR_NOT_FOUND"
}
if (Test-Path $renderZip) {
    Remove-Item $renderZip -Force
}
Compress-Archive -Path (Join-Path $renderDir "*") -DestinationPath $renderZip -Force

Write-Host ""
Write-Host "STAGE_6_10_BUILD_GATE_COMPLETE"
Write-Host "RUN_LOG=$RunLog"
Write-Host "RENDER_ZIP=$renderZip"
