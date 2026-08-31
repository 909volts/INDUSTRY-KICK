$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$ProjectRoot = "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
$BuildDir = Join-Path $ProjectRoot "build"
$ValidationDir = Join-Path $ProjectRoot "Stage72DValidation"
$BundleZip = Join-Path $ProjectRoot "Stage72DValidationBundle.zip"

$StatusFile = Join-Path $ValidationDir "RELEASE_STATUS.txt"
$RunnerLog = Join-Path $ValidationDir "RUNNER_TRANSCRIPT.txt"
$DspLog = Join-Path $ValidationDir "DspSmoke.log"
$SourceHashFile = Join-Path $ValidationDir "SOURCE_FREEZE_SHA256.txt"
$BinaryHashFile = Join-Path $ValidationDir "VST3_SHA256.txt"
$PluginvalLog = Join-Path $ValidationDir "pluginval.log"
$SteinbergLog = Join-Path $ValidationDir "steinberg_validator.log"

Set-Location $ProjectRoot

if (Test-Path $ValidationDir) {
    Remove-Item $ValidationDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $ValidationDir | Out-Null

$script:Status = [ordered]@{
    RUNNER_PARSE = "PASS"
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

$script:FailureClass = "NONE"
$script:FailedStep = "NONE"
$script:ExitCode = 0
$script:TranscriptStarted = $false

function Save-Status {
    $lines = @()
    foreach ($k in $script:Status.Keys) {
        $lines += "$k=$($script:Status[$k])"
    }
    $lines += "FAILURE_CLASS=$script:FailureClass"
    $lines += "FAILED_STEP=$script:FailedStep"
    $lines += "EXIT_CODE=$script:ExitCode"
    $lines += ""
    $lines += "RELEASE_NOTE=Final GUI still requires pluginval/DAW regression before release."
    Set-Content -Path $StatusFile -Value $lines -Encoding UTF8
}

function Set-Status([string]$Key, [string]$Value) {
    if (-not $script:Status.Contains($Key)) {
        throw "Unknown status key: $Key"
    }
    $script:Status[$Key] = $Value
    Save-Status
    Write-Host "$Key=$Value"
}

function Mark-Failure([string]$Class, [string]$Step, [int]$Code) {
    $script:FailureClass = $Class
    $script:FailedStep = $Step
    $script:ExitCode = $Code
    Save-Status
}

function Write-Daw-Checklist {
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
}

function Build-Bundle {
    Save-Status
    Write-Daw-Checklist

    if ($script:TranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        } catch {}
        $script:TranscriptStarted = $false
    }

    if (Test-Path $BundleZip) {
        Remove-Item $BundleZip -Force
    }

    Compress-Archive -Path (Join-Path $ValidationDir "*") -DestinationPath $BundleZip -Force
    Write-Host "VALIDATION_BUNDLE=$BundleZip"
}

Save-Status
Start-Transcript -Path $RunnerLog -Force | Out-Null
$script:TranscriptStarted = $true

Write-Host "INDUSTRY KICK — Stage 7.2D Robust DSP Freeze / Pre-GUI Gate"
Write-Host "runnerIdentity=7.2D"
Write-Host "runnerIdentity=7.2C"
Write-Host "DSP source changes: NONE"
Write-Host ""

try {
    # ---------------------------------------------------------------
    # 1. Exact Stage 7.1 approved source identity
    # ---------------------------------------------------------------
    $FaustSource = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp"
    $SmokeSource = Join-Path $ProjectRoot "Tests\DspSmoke.cpp"

    if (-not (Test-Path $FaustSource)) {
        throw "Required Faust source not found: $FaustSource"
    }
    if (-not (Test-Path $SmokeSource)) {
        throw "Required DspSmoke source not found: $SmokeSource"
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
            throw "Faust source identity marker missing: $m"
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
            throw "DspSmoke source identity marker missing: $m"
        }
    }

    Set-Status "SOURCE_IDENTITY" "PASS"

    # ---------------------------------------------------------------
    # 2. Recoverable approved-DSP checkpoint + hashes
    # ---------------------------------------------------------------
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $Checkpoint = Join-Path $ProjectRoot "Checkpoints\Stage7_1_DSP_APPROVED_$stamp"
    New-Item -ItemType Directory -Force -Path $Checkpoint | Out-Null

    foreach ($item in @("Faust","Source","Tests","CMakeLists.txt")) {
        $src = Join-Path $ProjectRoot $item
        if (Test-Path $src) {
            Copy-Item $src -Destination $Checkpoint -Recurse -Force
        }
    }

    foreach ($item in @("Assets","Resources","Presets")) {
        $src = Join-Path $ProjectRoot $item
        if (Test-Path $src) {
            Copy-Item $src -Destination $Checkpoint -Recurse -Force
        }
    }

    $checkpointFiles = @(Get-ChildItem $Checkpoint -Recurse -File)
    if ($checkpointFiles.Count -eq 0) {
        throw "Checkpoint contains no files"
    }

    $hashLines = @()
    $checkpointFiles | Sort-Object FullName | ForEach-Object {
        $rel = $_.FullName.Substring($Checkpoint.Length).TrimStart('\')
        $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        $hashLines += "$hash  $rel"
    }

    Set-Content -Path $SourceHashFile -Value $hashLines -Encoding UTF8
    Set-Content -Path (Join-Path $ValidationDir "CHECKPOINT_PATH.txt") -Value $Checkpoint -Encoding UTF8

    if (-not (Test-Path $SourceHashFile)) {
        throw "Source freeze hash file was not created"
    }

    Set-Status "CHECKPOINT" "PASS"

    # ---------------------------------------------------------------
    # 3. Configure + clean DspSmoke build
    # ---------------------------------------------------------------
    & cmake -S . -B build -G "Visual Studio 17 2022" -A x64
    if ($LASTEXITCODE -ne 0) {
        Mark-Failure "BUILD" "CMake configure" $LASTEXITCODE
        Set-Status "CLEAN_DSP_BUILD" "FAIL"
        throw "CMake configure failed with exit code $LASTEXITCODE"
    }

    & cmake --build build --config Release --target KICKCRAFTER_DspSmoke --clean-first
    if ($LASTEXITCODE -ne 0) {
        $code = $LASTEXITCODE
        Mark-Failure "BUILD" "Clean DspSmoke build" $code
        Set-Status "CLEAN_DSP_BUILD" "FAIL"
        throw "Clean DspSmoke build failed with exit code $code"
    }

    $SmokeExe = Join-Path $BuildDir "KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
    if (-not (Test-Path $SmokeExe)) {
        Mark-Failure "BUILD" "DspSmoke executable verification" 31
        Set-Status "CLEAN_DSP_BUILD" "FAIL"
        throw "DspSmoke executable missing after successful build"
    }

    Set-Status "CLEAN_DSP_BUILD" "PASS"

    # ---------------------------------------------------------------
    # 4. Full compiled Stage 7.1 DspSmoke gate
    # ---------------------------------------------------------------
    $runtimeOutput = @(& $SmokeExe 2>&1)
    $smokeExit = $LASTEXITCODE
    $runtimeOutput | Set-Content -Path $DspLog -Encoding UTF8
    $runtimeOutput | ForEach-Object { Write-Host $_ }
    $runtimeText = $runtimeOutput -join "`n"

    if ($runtimeText -notmatch "stageGate=7.1") {
        Mark-Failure "BUILD" "DspSmoke runtime identity" 32
        Set-Status "DSP_SMOKE" "FAIL"
        throw "Stale or unexpected DspSmoke binary"
    }

    if ($runtimeText -match "allFactoryPresetsTechnical=1") {
        Set-Status "FACTORY_50" "PASS"
    } elseif ($runtimeText -match "allFactoryPresetsTechnical=0") {
        Set-Status "FACTORY_50" "FAIL"
    } else {
        Set-Status "FACTORY_50" "NOT_REPORTED"
    }

    if ($runtimeText -match "randomizerTechnical=1") {
        Set-Status "RANDOMIZER" "PASS"
    } elseif ($runtimeText -match "randomizerTechnical=0") {
        Set-Status "RANDOMIZER" "FAIL"
    } else {
        Set-Status "RANDOMIZER" "NOT_REPORTED"
    }

    if ($runtimeText -match "stateRoundTrip=1") {
        Set-Status "STATE_ROUNDTRIP" "PASS"
    } elseif ($runtimeText -match "stateRoundTrip=0") {
        Set-Status "STATE_ROUNDTRIP" "FAIL"
    } else {
        Set-Status "STATE_ROUNDTRIP" "NOT_REPORTED"
    }

    $renderDir = Join-Path $ProjectRoot "Stage71TestRenders"
    if (Test-Path $renderDir) {
        $renderZip = Join-Path $ValidationDir "Stage71TestRenders.zip"
        Compress-Archive -Path (Join-Path $renderDir "*") -DestinationPath $renderZip -Force
    }

    if ($smokeExit -ne 0 -or $runtimeText -notmatch "result=PASS") {
        Mark-Failure "DSP_OR_VALIDATION" "DspSmoke execution" $smokeExit
        Set-Status "DSP_SMOKE" "FAIL"
        throw "DspSmoke did not report PASS"
    }

    Set-Status "DSP_SMOKE" "PASS"

    # ---------------------------------------------------------------
    # 5. VST3 Release build + exact binary SHA256
    # ---------------------------------------------------------------
    & cmake --build build --config Release --target KICKCRAFTER_VST3
    if ($LASTEXITCODE -ne 0) {
        $code = $LASTEXITCODE
        Mark-Failure "BUILD" "VST3 Release build" $code
        Set-Status "VST3_BUILD" "FAIL"
        throw "VST3 Release build failed with exit code $code"
    }

    $Vst3Bundle = Join-Path $BuildDir "KICKCRAFTER_artefacts\Release\VST3\INDUSTRY KICK.vst3"
    $Vst3Binary = Join-Path $Vst3Bundle "Contents\x86_64-win\INDUSTRY KICK.vst3"

    if (-not (Test-Path $Vst3Binary)) {
        Mark-Failure "BUILD" "VST3 binary verification" 33
        Set-Status "VST3_BUILD" "FAIL"
        throw "Expected VST3 binary not found"
    }

    $vstHash = (Get-FileHash $Vst3Binary -Algorithm SHA256).Hash
    Set-Content -Path $BinaryHashFile -Value "$vstHash  $Vst3Binary" -Encoding UTF8
    Set-Content -Path (Join-Path $ValidationDir "VST3_PATH.txt") -Value $Vst3Bundle -Encoding UTF8

    Set-Status "VST3_BUILD" "PASS"

    # ---------------------------------------------------------------
    # 6. Standalone if configured
    # ---------------------------------------------------------------
    $StandaloneProj = Join-Path $BuildDir "KICKCRAFTER_Standalone.vcxproj"
    if (Test-Path $StandaloneProj) {
        & cmake --build build --config Release --target KICKCRAFTER_Standalone
        if ($LASTEXITCODE -eq 0) {
            Set-Status "STANDALONE_BUILD" "PASS"
        } else {
            $code = $LASTEXITCODE
            Mark-Failure "BUILD" "Standalone Release build" $code
            Set-Status "STANDALONE_BUILD" "FAIL"
            throw "Standalone Release build failed with exit code $code"
        }
    } else {
        Set-Status "STANDALONE_BUILD" "NOT_CONFIGURED"
    }

    # ---------------------------------------------------------------
    # 7. pluginval if installed
    # ---------------------------------------------------------------
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
        $pvOut = @(& $Pluginval --strictness-level 10 $Vst3Bundle 2>&1)
        $pvExit = $LASTEXITCODE
        $pvOut | Set-Content -Path $PluginvalLog -Encoding UTF8
        $pvOut | ForEach-Object { Write-Host $_ }
        Set-Content -Path (Join-Path $ValidationDir "PLUGINVAL_PATH.txt") -Value $Pluginval -Encoding UTF8

        if ($pvExit -eq 0) {
            Set-Status "PLUGINVAL" "PASS"
        } else {
            Set-Status "PLUGINVAL" "FAIL"
        }
    } else {
        Set-Content -Path $PluginvalLog -Value "pluginval.exe not found. Test NOT_TESTED." -Encoding UTF8
        Set-Status "PLUGINVAL" "NOT_TESTED_NOT_FOUND"
    }

    # ---------------------------------------------------------------
    # 8. Steinberg validator if installed
    # ---------------------------------------------------------------
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
        $svOut = @(& $Validator --extensive $Vst3Bundle 2>&1)
        $svExit = $LASTEXITCODE
        $svOut | Set-Content -Path $SteinbergLog -Encoding UTF8
        $svOut | ForEach-Object { Write-Host $_ }
        Set-Content -Path (Join-Path $ValidationDir "STEINBERG_VALIDATOR_PATH.txt") -Value $Validator -Encoding UTF8

        if ($svExit -eq 0) {
            Set-Status "STEINBERG_VALIDATOR" "PASS"
        } else {
            Set-Status "STEINBERG_VALIDATOR" "FAIL"
        }
    } else {
        Set-Content -Path $SteinbergLog -Value "Steinberg validator not found. Test NOT_TESTED." -Encoding UTF8
        Set-Status "STEINBERG_VALIDATOR" "NOT_TESTED_NOT_FOUND"
    }

    # ---------------------------------------------------------------
    # 9. Pre-GUI hard gate
    # ---------------------------------------------------------------
    $standaloneOK = (
        ($script:Status["STANDALONE_BUILD"] -eq "PASS") -or
        ($script:Status["STANDALONE_BUILD"] -eq "NOT_CONFIGURED")
    )

    $hardChecks = @(
        ($script:Status["SOURCE_IDENTITY"] -eq "PASS"),
        ($script:Status["CHECKPOINT"] -eq "PASS"),
        ($script:Status["CLEAN_DSP_BUILD"] -eq "PASS"),
        ($script:Status["DSP_SMOKE"] -eq "PASS"),
        ($script:Status["FACTORY_50"] -eq "PASS"),
        ($script:Status["RANDOMIZER"] -eq "PASS"),
        ($script:Status["STATE_ROUNDTRIP"] -eq "PASS"),
        ($script:Status["VST3_BUILD"] -eq "PASS"),
        $standaloneOK
    )

    if ($hardChecks -contains $false) {
        Set-Status "PRE_GUI_DSP_GATE" "FAIL"
        Mark-Failure "VALIDATION" "Pre-GUI hard gate aggregation" 40
        throw "One or more mandatory pre-GUI checks did not pass"
    }

    Set-Status "PRE_GUI_DSP_GATE" "PASS"
    $script:ExitCode = 0
    Save-Status
}
catch {
    if ($script:FailureClass -eq "NONE") {
        $script:FailureClass = "RUNNER_OR_SOURCE"
        $script:FailedStep = $_.Exception.Message
        $script:ExitCode = 1
    }

    if ($script:Status["PRE_GUI_DSP_GATE"] -eq "NOT_TESTED") {
        $script:Status["PRE_GUI_DSP_GATE"] = "FAIL"
    }

    Save-Status

    Write-Host ""
    Write-Host "FAILURE_CLASS=$script:FailureClass"
    Write-Host "FAILED_STEP=$script:FailedStep"
    Write-Host "ERROR=$($_.Exception.Message)"
}
finally {
    # Never claim release readiness before the post-GUI validator + DAW pass.
    $script:Status["RELEASE_READY"] = "NO"
    Save-Status

    if ($script:TranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        } catch {}
        $script:TranscriptStarted = $false
    }

    Write-Daw-Checklist

    if (Test-Path $BundleZip) {
        Remove-Item $BundleZip -Force
    }
    Compress-Archive -Path (Join-Path $ValidationDir "*") -DestinationPath $BundleZip -Force

    Write-Host ""
    Write-Host "VALIDATION_BUNDLE=$BundleZip"
    $finalGateStatus = $script:Status['PRE_GUI_DSP_GATE']
    Write-Host "PRE_GUI_DSP_GATE=$finalGateStatus"
}

exit $script:ExitCode
