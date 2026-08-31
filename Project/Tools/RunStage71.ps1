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
$RunLog = Join-Path $ProjectRoot "Stage71_DspSmoke.log"

Set-Location $ProjectRoot

Write-Host "INDUSTRY KICK - Stage 7.1 Faust Family + Master Integration"
Write-Host "Reference: user-approved Stage 7 / 30 ms release"
Write-Host ""

$requiredFaust = @(
    "Stage 7.1",
    "stage7Round",
    "stage7Punch",
    "stage7Hard",
    "stage7Industrial",
    "stage7Rave",
    "co.compressor_mono(4,-9.5,0.030,0.030)",
    "stage7MasterHardClip"
)
foreach ($m in $requiredFaust) {
    if (-not (Select-String -Path $FaustSource -SimpleMatch $m -Quiet)) {
        throw "FAUST_SOURCE_MARKER_MISSING: $m"
    }
}

$requiredSmoke = @(
    "stageGate=7.1",
    "approvedStage7Reference=30ms_release",
    "lowBandShapeParityPass",
    "crestParityPass",
    "familyEnvelopeCorrelationDiagnostic"
)
foreach ($m in $requiredSmoke) {
    if (-not (Select-String -Path $SmokeSource -SimpleMatch $m -Quiet)) {
        throw "DSP_SMOKE_SOURCE_MARKER_MISSING: $m"
    }
}

Write-Host "SOURCE IDENTITY: PASS"

(Get-Item $FaustSource).LastWriteTime = Get-Date
(Get-Item $SmokeSource).LastWriteTime = Get-Date

cmake -S . -B build -G "Visual Studio 17 2022" -A x64
Assert-NativeSuccess "CMake configure" $LASTEXITCODE

if (Test-Path $GeneratedHeader) {
    Remove-Item $GeneratedHeader -Force
    Write-Host "Removed stale generated Faust header."
}

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
Write-Host "Clean rebuilding Faust dependency + DspSmoke..."
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

if ($runtimeText -notmatch "stageGate=7.1") {
    throw "STALE_DSP_SMOKE_BINARY: stageGate 7.1 missing"
}
if ($runtimeText -notmatch "approvedStage7Reference=30ms_release") {
    throw "STALE_DSP_SMOKE_BINARY: Stage7 reference marker missing"
}
if ($runtimeText -notmatch "Stage71TestRenders") {
    throw "STALE_DSP_SMOKE_BINARY: Stage71TestRenders marker missing"
}

Write-Host ""
Write-Host "RUNTIME BINARY IDENTITY: PASS"

# Export/zip happens BEFORE we turn a sonic FAIL into a PowerShell exception.
$renderDir = Join-Path $ProjectRoot "Stage71TestRenders"
$renderZip = Join-Path $ProjectRoot "Stage71TestRenders.zip"
if (Test-Path $renderDir) {
    if (Test-Path $renderZip) {
        Remove-Item $renderZip -Force
    }
    Compress-Archive -Path (Join-Path $renderDir "*") -DestinationPath $renderZip -Force
    Write-Host "RENDER_ZIP=$renderZip"
} else {
    Write-Host "RENDER_ZIP_NOT_CREATED"
}

if ($smokeExit -ne 0) {
    Write-Host ""
    Write-Host "DSP_GATE_RESULT=FAIL"
    Write-Host "Upload Stage71TestRenders.zip and Stage71_DspSmoke.log."
    exit $smokeExit
}

Write-Host "DSP_GATE_RESULT=PASS"

# Build the actual VST3 only after the complete compiled-audio gate passes.
cmake --build build --config Release --target KICKCRAFTER_VST3
Assert-NativeSuccess "VST3 Release build" $LASTEXITCODE

Write-Host ""
Write-Host "STAGE_7_1_BUILD_GATE_COMPLETE"
Write-Host "RUN_LOG=$RunLog"
Write-Host "RENDER_ZIP=$renderZip"
