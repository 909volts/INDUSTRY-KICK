$ErrorActionPreference = "Stop"

function Fail-Step([string]$Kind, [string]$Step, [int]$Code) {
    Write-Host ""
    Write-Host "FAILURE_CLASS=$Kind"
    Write-Host "FAILED_STEP=$Step"
    Write-Host "EXIT_CODE=$Code"
    exit $Code
}

$ProjectRoot = "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
$BuildDir = Join-Path $ProjectRoot "build"
$FaustSource = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp"
$SmokeSource = Join-Path $ProjectRoot "Tests\DspSmoke.cpp"
$GeneratedHeader = Join-Path $BuildDir "generated\IndustryKickFaustDSP.h"
$RunLog = Join-Path $ProjectRoot "Stage71B_DspSmoke.log"

Set-Location $ProjectRoot

Write-Host "INDUSTRY KICK - Stage 7.1B Faust Compile Fix"
Write-Host "Sonic architecture / parameters / validation thresholds: UNCHANGED"
Write-Host ""

$requiredFaust = @(
    "Stage 7.1B compile fix",
    "stage7Round",
    "stage7Punch",
    "stage7Hard",
    "stage7Industrial",
    "stage7Rave",
    "co.compressor_mono(4,-9.5,0.030,0.030)",
    "stage7MasterHardClip",
    "0.800499021761",
    "0.069637106984"
)
foreach ($m in $requiredFaust) {
    if (-not (Select-String -Path $FaustSource -SimpleMatch $m -Quiet)) {
        Write-Host "SOURCE_MARKER_MISSING=$m"
        exit 2
    }
}

# Prohibit the exact unqualified construct that caused Stage 7.1 to fail.
$sourceText = Get-Content $FaustSource -Raw
if ($sourceText -match '(?<![\w\.])tanh\s*\(') {
    Write-Host "BARE_TANH_CALL_STILL_PRESENT"
    exit 2
}

$requiredSmoke = @(
    "stageGate=7.1",
    "approvedStage7Reference=30ms_release",
    "lowBandShapeParityPass",
    "crestParityPass"
)
foreach ($m in $requiredSmoke) {
    if (-not (Select-String -Path $SmokeSource -SimpleMatch $m -Quiet)) {
        Write-Host "DSP_SMOKE_SOURCE_MARKER_MISSING=$m"
        exit 2
    }
}

Write-Host "SOURCE IDENTITY: PASS"

(Get-Item $FaustSource).LastWriteTime = Get-Date
(Get-Item $SmokeSource).LastWriteTime = Get-Date

cmake -S . -B build -G "Visual Studio 17 2022" -A x64
if ($LASTEXITCODE -ne 0) {
    Fail-Step "BUILD" "CMake configure" $LASTEXITCODE
}

if (Test-Path $GeneratedHeader) {
    Remove-Item $GeneratedHeader -Force
    Write-Host "Removed stale generated Faust header."
}

Write-Host ""
Write-Host "STEP 1/3 - Faust generation only"
cmake --build build --config Release --target INDUSTRY_KICK_FaustDSP
if ($LASTEXITCODE -ne 0) {
    Fail-Step "BUILD" "Faust generation" $LASTEXITCODE
}

if (-not (Test-Path $GeneratedHeader)) {
    Write-Host "FAILURE_CLASS=BUILD"
    Write-Host "FAILED_STEP=Generated Faust header verification"
    exit 3
}
Write-Host "FAUST_GENERATION=PASS"

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
Write-Host "STEP 2/3 - DspSmoke compile + audio gate"
cmake --build build --config Release --target KICKCRAFTER_DspSmoke
if ($LASTEXITCODE -ne 0) {
    Fail-Step "BUILD" "DspSmoke build" $LASTEXITCODE
}

$exe = Join-Path $BuildDir "KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
if (-not (Test-Path $exe)) {
    Write-Host "FAILURE_CLASS=BUILD"
    Write-Host "FAILED_STEP=DspSmoke executable verification"
    exit 4
}

$runtimeOutput = @(& $exe 2>&1)
$smokeExit = $LASTEXITCODE
$runtimeOutput | Tee-Object -FilePath $RunLog | ForEach-Object { Write-Host $_ }
$runtimeText = $runtimeOutput -join "`n"

if ($runtimeText -notmatch "stageGate=7.1") {
    Write-Host "FAILURE_CLASS=BUILD"
    Write-Host "FAILED_STEP=Runtime binary identity"
    exit 5
}
if ($runtimeText -notmatch "approvedStage7Reference=30ms_release") {
    Write-Host "FAILURE_CLASS=BUILD"
    Write-Host "FAILED_STEP=Runtime reference identity"
    exit 5
}
if ($runtimeText -notmatch "Stage71TestRenders") {
    Write-Host "FAILURE_CLASS=BUILD"
    Write-Host "FAILED_STEP=Runtime render identity"
    exit 5
}

Write-Host ""
Write-Host "RUNTIME BINARY IDENTITY: PASS"

$renderDir = Join-Path $ProjectRoot "Stage71TestRenders"
$renderZip = Join-Path $ProjectRoot "Stage71TestRenders.zip"

if (Test-Path $renderDir) {
    if (Test-Path $renderZip) {
        Remove-Item $renderZip -Force
    }
    Compress-Archive -Path (Join-Path $renderDir "*") -DestinationPath $renderZip -Force
    Write-Host "RENDER_ZIP=$renderZip"
}

if ($smokeExit -ne 0) {
    Write-Host ""
    Write-Host "FAILURE_CLASS=DSP_OR_VALIDATION"
    Write-Host "FAILED_STEP=DspSmoke execution"
    Write-Host "RUN_LOG=$RunLog"
    if (Test-Path $renderZip) { Write-Host "RENDER_ZIP=$renderZip" }
    exit $smokeExit
}

Write-Host "DSP_GATE_RESULT=PASS"

Write-Host ""
Write-Host "STEP 3/3 - VST3 Release"
cmake --build build --config Release --target KICKCRAFTER_VST3
if ($LASTEXITCODE -ne 0) {
    Fail-Step "BUILD" "VST3 Release build" $LASTEXITCODE
}

Write-Host ""
Write-Host "STAGE_7_1B_BUILD_GATE_COMPLETE"
Write-Host "FAUST_GENERATION=PASS"
Write-Host "DSP_GATE_RESULT=PASS"
Write-Host "RUN_LOG=$RunLog"
Write-Host "RENDER_ZIP=$renderZip"
