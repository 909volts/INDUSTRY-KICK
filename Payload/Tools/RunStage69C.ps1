$ErrorActionPreference = "Stop"

function Assert-NativeSuccess([string]$Step, [int]$Code) {
    if ($Code -ne 0) {
        throw "$Step failed with exit code $Code"
    }
}

$ProjectRoot = "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
$BuildDir = Join-Path $ProjectRoot "build"
$SmokeSource = Join-Path $ProjectRoot "Tests\DspSmoke.cpp"
$RunLog = Join-Path $ProjectRoot "Stage69C_DspSmoke.log"

Set-Location $ProjectRoot

Write-Host "INDUSTRY KICK V2 - Stage 6.9C Force DspSmoke Rebuild"
Write-Host "DSP / presets / validator logic / thresholds: UNCHANGED"
Write-Host ""

$requiredSourceMarkers = @(
    "residualNumericallySilent",
    "numericalSilenceRms = 1.0e-12",
    "Stage69BTestRenders",
    "maxSafetyClampEngagementPercent = 0.10",
    "maxEnvCorr < 0.82"
)

foreach ($m in $requiredSourceMarkers) {
    if (-not (Select-String -Path $SmokeSource -SimpleMatch $m -Quiet)) {
        throw "SOURCE_MARKER_MISSING: $m"
    }
}

$faustSource = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp"
if (-not (Select-String -Path $faustSource -SimpleMatch "Stage 6.9: measured family headroom" -Quiet)) {
    throw "EXPECTED_STAGE_6_9_DSP_NOT_FOUND"
}

Write-Host "SOURCE IDENTITY: PASS"

# Make source unambiguously newer than prior incremental-build products.
(Get-Item $SmokeSource).LastWriteTime = Get-Date

cmake -S . -B build -G "Visual Studio 17 2022" -A x64
Assert-NativeSuccess "CMake configure" $LASTEXITCODE

# Delete only the DspSmoke compilation/link products.
$stale = Get-ChildItem $BuildDir -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -eq "DspSmoke.obj" -or
        $_.Name -eq "KICKCRAFTER_DspSmoke.exe" -or
        $_.Name -eq "KICKCRAFTER_DspSmoke.pdb"
    }

foreach ($f in $stale) {
    Write-Host "Removing stale: $($f.FullName)"
    Remove-Item $f.FullName -Force
}

Write-Host ""
Write-Host "Building verified Stage 6.9B DspSmoke..."
cmake --build build --config Release --target KICKCRAFTER_DspSmoke
Assert-NativeSuccess "DspSmoke rebuild" $LASTEXITCODE

$exe = Get-ChildItem $BuildDir -Filter "KICKCRAFTER_DspSmoke.exe" -Recurse -File |
       Select-Object -First 1 -ExpandProperty FullName

if (-not $exe) {
    throw "DSP_SMOKE_EXE_NOT_FOUND_AFTER_REBUILD"
}

Write-Host "Running: $exe"

$runtimeOutput = @(& $exe 2>&1)
$smokeExit = $LASTEXITCODE
$runtimeOutput | Tee-Object -FilePath $RunLog | ForEach-Object { Write-Host $_ }
$runtimeText = $runtimeOutput -join "`n"

# Prove the runtime binary is the patched validator, not an old executable.
if ($runtimeText -notmatch "numericalSilence=") {
    throw "STALE_DSP_SMOKE_BINARY: runtime output lacks numericalSilence marker"
}
if ($runtimeText -notmatch "Stage69BTestRenders") {
    throw "STALE_DSP_SMOKE_BINARY: runtime output lacks Stage69BTestRenders marker"
}

Write-Host ""
Write-Host "RUNTIME BINARY IDENTITY: PASS"

Assert-NativeSuccess "DspSmoke execution" $smokeExit

# Build VST3 only after the verified DspSmoke passes.
cmake --build build --config Release --target KICKCRAFTER_VST3
Assert-NativeSuccess "VST3 Release build" $LASTEXITCODE

$renderDir = Join-Path $ProjectRoot "Stage69BTestRenders"
$renderZip = Join-Path $ProjectRoot "Stage69BTestRenders.zip"

if (-not (Test-Path $renderDir)) {
    throw "STAGE69B_RENDER_DIR_NOT_FOUND"
}

if (Test-Path $renderZip) {
    Remove-Item $renderZip -Force
}
Compress-Archive -Path (Join-Path $renderDir "*") -DestinationPath $renderZip -Force

Write-Host ""
Write-Host "STAGE_6_9C_BUILD_GATE_COMPLETE"
Write-Host "RUN_LOG=$RunLog"
Write-Host "RENDER_ZIP=$renderZip"
