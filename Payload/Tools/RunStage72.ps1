$ErrorActionPreference = "Stop"

$ProjectRoot = "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
$BuildDir = Join-Path $ProjectRoot "build"
$ValidationDir = Join-Path $ProjectRoot "Stage72Validation"
$BundleZip = Join-Path $ProjectRoot "Stage72ValidationBundle.zip"
$StatusFile = Join-Path $ValidationDir "RELEASE_STATUS.txt"
$SourceHashFile = Join-Path $ValidationDir "SOURCE_FREEZE_SHA256.txt"
$BinaryHashFile = Join-Path $ValidationDir "VST3_SHA256.txt"
$DspLog = Join-Path $ValidationDir "DspSmoke.log"
$PluginvalLog = Join-Path $ValidationDir "pluginval.log"
$SteinbergLog = Join-Path $ValidationDir "steinberg_validator.log"

Set-Location $ProjectRoot

if (Test-Path $ValidationDir) {
    Remove-Item $ValidationDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $ValidationDir | Out-Null

$Status = [ordered]@{
    SOURCE_IDENTITY = "NOT_TESTED"
    CHECKPOINT = "NOT_TESTED"
    CLEAN_DSP_BUILD = "NOT_TESTED"
    DSP_SMOKE = "NOT_TESTED"
    FACTORY_50 = "NOT_TESTED"
    RANDOMIZER = "NOT_TESTED"
    STATE_ROUNDTRIP = "NOT_TESTED"
    VST3_BUILD = "NOT_TESTED"
    STANDALONE_BUILD = "NOT_TESTED"
    PLUGINVAL = "NOT_TESTED"
    STEINBERG_VALIDATOR = "NOT_TESTED"
    DAW_TEST = "NOT_TESTED"
    PRE_GUI_DSP_GATE = "NOT_TESTED"
    RELEASE_READY = "NO"
}

function Save-Status {
    $lines = @()
    foreach ($k in $Status.Keys) {
        $lines += "$k=$($Status[$k])"
    }
    $lines += ""
    $lines += "NOTE=GUI changes still require a final pluginval/DAW regression pass before release."
    Set-Content -Path $StatusFile -Value $lines -Encoding UTF8
}

function Make-Bundle {
    Save-Status

    $checklist = @'
INDUSTRY KICK — FINAL DAW REGRESSION CHECKLIST

Run after the final GUI is integrated.

[ ] DAW scans VST3 without error
[ ] Instantiate/remove repeatedly without crash
[ ] Audio output at 44.1 kHz
[ ] Audio output at 48 kHz
[ ] Audio output at 96 kHz
[ ] Small/medium/large buffer test
[ ] Preset change while stopped
[ ] Preset change while playing
[ ] Parameter automation
[ ] Save project / close / reopen / state recall
[ ] Bypass behavior
[ ] Silence input / extreme parameter values
[ ] Rapid parameter stress
[ ] Multiple plugin instances
[ ] Remove plugin while transport is running
[ ] CPU/memory sanity
[ ] No NaN/Inf, runaway tail or unexpected safety clipping
[ ] Final five approved-family anchor listening regression

Record each item only as PASS / FAIL / NOT TESTED.
'@
    Set-Content -Path (Join-Path $ValidationDir "DAW_TEST_CHECKLIST.txt") -Value $checklist -Encoding UTF8

    if (Test-Path $BundleZip) {
        Remove-Item $BundleZip -Force
    }
    Compress-Archive -Path (Join-Path $ValidationDir "*") -DestinationPath $BundleZip -Force
    Write-Host ""
    Write-Host "VALIDATION_BUNDLE=$BundleZip"
}

function Fail-And-Bundle([string]$Class, [string]$Step, [int]$Code) {
    Write-Host ""
    Write-Host "FAILURE_CLASS=$Class"
    Write-Host "FAILED_STEP=$Step"
    Write-Host "EXIT_CODE=$Code"
    Make-Bundle
    exit $Code
}

Write-Host "INDUSTRY KICK — Stage 7.2 DSP Freeze / Pre-GUI Gate"
Write-Host "DSP source changes: NONE"
Write-Host ""

# -------------------------------------------------------------------
# 1. Exact approved source identity
# -------------------------------------------------------------------
$FaustSource = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp"
$SmokeSource = Join-Path $ProjectRoot "Tests\DspSmoke.cpp"

if (-not (Test-Path $FaustSource) -or -not (Test-Path $SmokeSource)) {
    $Status.SOURCE_IDENTITY = "FAIL"
    Fail-And-Bundle "SOURCE" "Required Stage 7.1 source files missing" 2
}

$requiredFaust = @(
    "Stage 7.1B compile fix",
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
        $Status.SOURCE_IDENTITY = "FAIL"
        Fail-And-Bundle "SOURCE" "Faust marker missing: $m" 2
    }
}

$requiredSmoke = @(
    "stageGate=7.1",
    "approvedStage7Reference=30ms_release",
    "lowBandShapeParityPass",
    "crestParityPass",
    "maxSafetyClampEngagementPercent = 0.10",
    "numericalSilenceRms = 1.0e-12"
)

foreach ($m in $requiredSmoke) {
    if (-not (Select-String -Path $SmokeSource -SimpleMatch $m -Quiet)) {
        $Status.SOURCE_IDENTITY = "FAIL"
        Fail-And-Bundle "SOURCE" "DspSmoke marker missing: $m" 2
    }
}

$Status.SOURCE_IDENTITY = "PASS"
Write-Host "SOURCE_IDENTITY=PASS"

# -------------------------------------------------------------------
# 2. Recoverable checkpoint + SHA256 source freeze
# -------------------------------------------------------------------
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Checkpoint = Join-Path $ProjectRoot "Checkpoints\Stage7_1_DSP_APPROVED_$stamp"
New-Item -ItemType Directory -Force -Path $Checkpoint | Out-Null

$freezeItems = @(
    "Faust",
    "Source",
    "Tests",
    "CMakeLists.txt"
)

foreach ($item in $freezeItems) {
    $src = Join-Path $ProjectRoot $item
    if (Test-Path $src) {
        Copy-Item $src -Destination $Checkpoint -Recurse -Force
    }
}

foreach ($optional in @("Assets","Resources","Presets")) {
    $src = Join-Path $ProjectRoot $optional
    if (Test-Path $src) {
        Copy-Item $src -Destination $Checkpoint -Recurse -Force
    }
}

$hashLines = @()
Get-ChildItem $Checkpoint -Recurse -File | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($Checkpoint.Length).TrimStart('\')
    $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    $hashLines += "$h  $rel"
}
Set-Content -Path $SourceHashFile -Value $hashLines -Encoding UTF8
Set-Content -Path (Join-Path $ValidationDir "CHECKPOINT_PATH.txt") -Value $Checkpoint -Encoding UTF8
$Status.CHECKPOINT = "PASS"
Write-Host "CHECKPOINT=PASS"
Write-Host "CHECKPOINT_PATH=$Checkpoint"

# -------------------------------------------------------------------
# 3. Configure + CLEAN DspSmoke build from frozen source
# -------------------------------------------------------------------
cmake -S . -B build -G "Visual Studio 17 2022" -A x64
if ($LASTEXITCODE -ne 0) {
    $Status.CLEAN_DSP_BUILD = "FAIL"
    Fail-And-Bundle "BUILD" "CMake configure" $LASTEXITCODE
}

Write-Host ""
Write-Host "Clean rebuilding DspSmoke..."
cmake --build build --config Release --target KICKCRAFTER_DspSmoke --clean-first
if ($LASTEXITCODE -ne 0) {
    $Status.CLEAN_DSP_BUILD = "FAIL"
    Fail-And-Bundle "BUILD" "Clean DspSmoke build" $LASTEXITCODE
}
$Status.CLEAN_DSP_BUILD = "PASS"

$SmokeExe = Join-Path $BuildDir "KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
if (-not (Test-Path $SmokeExe)) {
    $Status.CLEAN_DSP_BUILD = "FAIL"
    Fail-And-Bundle "BUILD" "DspSmoke executable missing" 3
}

# -------------------------------------------------------------------
# 4. Full compiled-audio technical/sonic gate
# -------------------------------------------------------------------
$runtimeOutput = @(& $SmokeExe 2>&1)
$smokeExit = $LASTEXITCODE
$runtimeOutput | Tee-Object -FilePath $DspLog | ForEach-Object { Write-Host $_ }
$runtimeText = $runtimeOutput -join "`n"

if ($runtimeText -notmatch "stageGate=7.1") {
    $Status.DSP_SMOKE = "FAIL"
    Fail-And-Bundle "BUILD" "Stale DspSmoke runtime identity" 4
}

if ($runtimeText -match "allFactoryPresetsTechnical=1") {
    $Status.FACTORY_50 = "PASS"
} elseif ($runtimeText -match "allFactoryPresetsTechnical=0") {
    $Status.FACTORY_50 = "FAIL"
}

if ($runtimeText -match "randomizerTechnical=1") {
    $Status.RANDOMIZER = "PASS"
} elseif ($runtimeText -match "randomizerTechnical=0") {
    $Status.RANDOMIZER = "FAIL"
}

if ($runtimeText -match "stateRoundTrip=1") {
    $Status.STATE_ROUNDTRIP = "PASS"
} elseif ($runtimeText -match "stateRoundTrip=0") {
    $Status.STATE_ROUNDTRIP = "FAIL"
}

$renderDir = Join-Path $ProjectRoot "Stage71TestRenders"
$renderZip = Join-Path $ValidationDir "Stage71TestRenders.zip"
if (Test-Path $renderDir) {
    Compress-Archive -Path (Join-Path $renderDir "*") -DestinationPath $renderZip -Force
}

if ($smokeExit -ne 0 -or $runtimeText -notmatch "result=PASS") {
    $Status.DSP_SMOKE = "FAIL"
    $Status.PRE_GUI_DSP_GATE = "FAIL"
    Fail-And-Bundle "DSP_OR_VALIDATION" "DspSmoke execution" $smokeExit
}

$Status.DSP_SMOKE = "PASS"
Write-Host "DSP_SMOKE=PASS"

# -------------------------------------------------------------------
# 5. VST3 Release
# -------------------------------------------------------------------
Write-Host ""
Write-Host "Building VST3 Release..."
cmake --build build --config Release --target KICKCRAFTER_VST3
if ($LASTEXITCODE -ne 0) {
    $Status.VST3_BUILD = "FAIL"
    $Status.PRE_GUI_DSP_GATE = "FAIL"
    Fail-And-Bundle "BUILD" "VST3 Release build" $LASTEXITCODE
}

$Vst3Bundle = Join-Path $BuildDir "KICKCRAFTER_artefacts\Release\VST3\INDUSTRY KICK.vst3"
$Vst3Binary = Join-Path $Vst3Bundle "Contents\x86_64-win\INDUSTRY KICK.vst3"

if (-not (Test-Path $Vst3Binary)) {
    $Status.VST3_BUILD = "FAIL"
    $Status.PRE_GUI_DSP_GATE = "FAIL"
    Fail-And-Bundle "BUILD" "Built VST3 binary not found" 5
}

$Status.VST3_BUILD = "PASS"
$VstHash = (Get-FileHash $Vst3Binary -Algorithm SHA256).Hash
Set-Content -Path $BinaryHashFile -Value "$VstHash  $Vst3Binary" -Encoding UTF8
Set-Content -Path (Join-Path $ValidationDir "VST3_PATH.txt") -Value $Vst3Bundle -Encoding UTF8
Write-Host "VST3_BUILD=PASS"

# -------------------------------------------------------------------
# 6. Standalone — only if this project actually configures the target
# -------------------------------------------------------------------
$StandaloneProj = Join-Path $BuildDir "KICKCRAFTER_Standalone.vcxproj"
if (Test-Path $StandaloneProj) {
    Write-Host ""
    Write-Host "Building Standalone Release..."
    cmake --build build --config Release --target KICKCRAFTER_Standalone
    if ($LASTEXITCODE -eq 0) {
        $Status.STANDALONE_BUILD = "PASS"
    } else {
        $Status.STANDALONE_BUILD = "FAIL"
        $Status.PRE_GUI_DSP_GATE = "FAIL"
        Fail-And-Bundle "BUILD" "Standalone Release build" $LASTEXITCODE
    }
} else {
    $Status.STANDALONE_BUILD = "NOT_CONFIGURED"
}

# -------------------------------------------------------------------
# 7. pluginval strictness 10 if installed
# -------------------------------------------------------------------
$pluginvalCandidates = @()

$cmd = Get-Command pluginval.exe -ErrorAction SilentlyContinue
if ($cmd) { $pluginvalCandidates += $cmd.Source }

$pluginvalCandidates += @(
    (Join-Path $ProjectRoot "Tools\pluginval.exe"),
    "C:\Program Files\pluginval\pluginval.exe",
    "C:\Program Files (x86)\pluginval\pluginval.exe",
    (Join-Path $env:LOCALAPPDATA "Programs\pluginval\pluginval.exe")
)

$Pluginval = $pluginvalCandidates |
    Where-Object { $_ -and (Test-Path $_) } |
    Select-Object -First 1

if ($Pluginval) {
    Write-Host ""
    Write-Host "Running pluginval strictness 10..."
    $pvOut = @(& $Pluginval --strictness-level 10 $Vst3Bundle 2>&1)
    $pvExit = $LASTEXITCODE
    $pvOut | Tee-Object -FilePath $PluginvalLog | ForEach-Object { Write-Host $_ }

    Set-Content -Path (Join-Path $ValidationDir "PLUGINVAL_PATH.txt") -Value $Pluginval -Encoding UTF8
    if ($pvExit -eq 0) {
        $Status.PLUGINVAL = "PASS"
    } else {
        $Status.PLUGINVAL = "FAIL"
    }
} else {
    $Status.PLUGINVAL = "NOT_TESTED_NOT_FOUND"
    Set-Content -Path $PluginvalLog -Value "pluginval.exe not found. Test NOT TESTED." -Encoding UTF8
}

# -------------------------------------------------------------------
# 8. Steinberg VST3 Validator if installed
# -------------------------------------------------------------------
$validatorCandidates = @()

foreach ($name in @("validator.exe","vstvalidator.exe")) {
    $vcmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($vcmd) { $validatorCandidates += $vcmd.Source }
}

$validatorCandidates += @(
    (Join-Path $ProjectRoot "Tools\validator.exe"),
    (Join-Path $ProjectRoot "Tools\vstvalidator.exe"),
    "C:\VST3_SDK\build\bin\Release\validator.exe",
    "C:\VST_SDK\vst3sdk\build\bin\Release\validator.exe"
)

$Validator = $validatorCandidates |
    Where-Object { $_ -and (Test-Path $_) } |
    Select-Object -First 1

if ($Validator) {
    Write-Host ""
    Write-Host "Running Steinberg VST3 Validator extensive tests..."
    $svOut = @(& $Validator --extensive $Vst3Bundle 2>&1)
    $svExit = $LASTEXITCODE
    $svOut | Tee-Object -FilePath $SteinbergLog | ForEach-Object { Write-Host $_ }

    Set-Content -Path (Join-Path $ValidationDir "STEINBERG_VALIDATOR_PATH.txt") -Value $Validator -Encoding UTF8
    if ($svExit -eq 0) {
        $Status.STEINBERG_VALIDATOR = "PASS"
    } else {
        $Status.STEINBERG_VALIDATOR = "FAIL"
    }
} else {
    $Status.STEINBERG_VALIDATOR = "NOT_TESTED_NOT_FOUND"
    Set-Content -Path $SteinbergLog -Value "Steinberg validator not found. Test NOT TESTED." -Encoding UTF8
}

# -------------------------------------------------------------------
# 9. Gate interpretation
# -------------------------------------------------------------------
$hardPass = (
       $Status.SOURCE_IDENTITY -eq "PASS"
    -and $Status.CHECKPOINT -eq "PASS"
    -and $Status.CLEAN_DSP_BUILD -eq "PASS"
    -and $Status.DSP_SMOKE -eq "PASS"
    -and $Status.FACTORY_50 -eq "PASS"
    -and $Status.RANDOMIZER -eq "PASS"
    -and $Status.STATE_ROUNDTRIP -eq "PASS"
    -and $Status.VST3_BUILD -eq "PASS"
    -and ($Status.STANDALONE_BUILD -eq "PASS" -or $Status.STANDALONE_BUILD -eq "NOT_CONFIGURED")
)

if ($hardPass) {
    $Status.PRE_GUI_DSP_GATE = "PASS"
} else {
    $Status.PRE_GUI_DSP_GATE = "FAIL"
}

# Final release cannot be claimed before final GUI regression + DAW.
# pluginval/Steinberg are reported independently and never silently promoted.
$Status.RELEASE_READY = "NO"

# -------------------------------------------------------------------
# 10. Final bundle
# -------------------------------------------------------------------
Make-Bundle

Write-Host ""
Write-Host "=== STAGE 7.2 STATUS ==="
foreach ($k in $Status.Keys) {
    Write-Host "$k=$($Status[$k])"
}

if ($Status.PRE_GUI_DSP_GATE -eq "PASS") {
    Write-Host ""
    Write-Host "PRE_GUI_DSP_GATE_COMPLETE"
    exit 0
}

exit 1
