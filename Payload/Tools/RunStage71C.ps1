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
$SmokeSource = Join-Path $ProjectRoot "Tests\DspSmoke.cpp"
$FaustSource = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp"
$GeneratedHeader = Join-Path $BuildDir "generated\IndustryKickFaustDSP.h"
$RunLog = Join-Path $ProjectRoot "Stage71C_DspSmoke.log"

Set-Location $ProjectRoot

Write-Host "INDUSTRY KICK - Stage 7.1C DspSmoke Compile Fix"
Write-Host "Faust DSP / sonic design / validator thresholds: UNCHANGED"
Write-Host ""

# Verify we are still on the compile-fixed Stage 7.1B Faust source.
if (-not (Select-String -Path $FaustSource -SimpleMatch "Stage 7.1B compile fix" -Quiet)) {
    Write-Host "FAILURE_CLASS=SOURCE"
    Write-Host "FAILED_STEP=Expected Stage 7.1B Faust source not found"
    exit 2
}

$requiredSmoke = @(
    'std::cout << "stageGate=7.1\n";',
    'std::cout << "approvedStage7Reference=30ms_release\n";',
    "lowBandShapeParityPass",
    "crestParityPass",
    "maxSafetyClampEngagementPercent = 0.10",
    "numericalSilenceRms = 1.0e-12"
)

foreach ($m in $requiredSmoke) {
    if (-not (Select-String -Path $SmokeSource -SimpleMatch $m -Quiet)) {
        Write-Host "FAILURE_CLASS=SOURCE"
        Write-Host "FAILED_STEP=DspSmoke source marker missing: $m"
        exit 2
    }
}

# Explicitly reject the exact malformed token from Stage 7.1B.
$raw = Get-Content $SmokeSource -Raw
if ($raw.Contains('";\n    std::cout')) {
    Write-Host "FAILURE_CLASS=SOURCE"
    Write-Host "FAILED_STEP=Literal backslash-n still outside C++ string"
    exit 2
}

Write-Host "SOURCE IDENTITY: PASS"

cmake -S . -B build -G "Visual Studio 17 2022" -A x64
if ($LASTEXITCODE -ne 0) {
    Fail-Step "BUILD" "CMake configure" $LASTEXITCODE
}

# Faust already generated successfully in Stage 7.1B.
# Do not regenerate it unless the generated header is actually missing.
if (-not (Test-Path $GeneratedHeader)) {
    Write-Host "Generated Faust header missing; rebuilding Faust target."
    cmake --build build --config Release --target INDUSTRY_KICK_FaustDSP
    if ($LASTEXITCODE -ne 0) {
        Fail-Step "BUILD" "Faust generation" $LASTEXITCODE
    }
}

# Force only DspSmoke build products stale.
(Get-Item $SmokeSource).LastWriteTime = Get-Date

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
Write-Host "STEP 1/2 - DspSmoke compile + compiled-audio gate"
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
    if (Test-Path $renderZip) {
        Write-Host "RENDER_ZIP=$renderZip"
    }
    exit $smokeExit
}

Write-Host "DSP_GATE_RESULT=PASS"

Write-Host ""
Write-Host "STEP 2/2 - VST3 Release"
cmake --build build --config Release --target KICKCRAFTER_VST3
if ($LASTEXITCODE -ne 0) {
    Fail-Step "BUILD" "VST3 Release build" $LASTEXITCODE
}

Write-Host ""
Write-Host "STAGE_7_1C_BUILD_GATE_COMPLETE"
Write-Host "DSP_GATE_RESULT=PASS"
Write-Host "RUN_LOG=$RunLog"
Write-Host "RENDER_ZIP=$renderZip"
