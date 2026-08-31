$ErrorActionPreference = "Stop"

function Assert-NativeSuccess([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE"
    }
}

$ProjectRoot = "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
$BuildDir = Join-Path $ProjectRoot "build"

Write-Host "INDUSTRY KICK V2 - Stage 6.8E Diagnostic Rebuild Fix"
Write-Host "Project: $ProjectRoot"
Write-Host "DSP / presets / validation thresholds: UNCHANGED"
Write-Host ""

$processorCpp = Join-Path $ProjectRoot "Source\PluginProcessor.cpp"
$processorH   = Join-Path $ProjectRoot "Source\PluginProcessor.h"
$safetyProbe  = Join-Path $ProjectRoot "Tests\SafetyProbe.cpp"
$cmakeFile    = Join-Path $ProjectRoot "CMakeLists.txt"

foreach ($f in @($processorCpp,$processorH,$safetyProbe,$cmakeFile)) {
    if (-not (Test-Path $f)) {
        throw "Required diagnostic file missing: $f"
    }
}

if (-not (Select-String -Path $processorCpp -SimpleMatch "KickcrafterAudioProcessor::resetSafetyDiagnostics()" -Quiet)) {
    throw "PluginProcessor.cpp does not contain resetSafetyDiagnostics implementation."
}
if (-not (Select-String -Path $processorH -SimpleMatch "void resetSafetyDiagnostics() noexcept;" -Quiet)) {
    throw "PluginProcessor.h does not contain resetSafetyDiagnostics declaration."
}
if (-not (Select-String -Path $cmakeFile -SimpleMatch "KICKCRAFTER_SafetyProbe" -Quiet)) {
    throw "CMakeLists.txt does not contain KICKCRAFTER_SafetyProbe target."
}

Write-Host "SOURCE VERIFY: PASS"
Write-Host ""

# Configure first so the target graph is current.
cmake -S $ProjectRoot -B $BuildDir -DCMAKE_BUILD_TYPE=Release
Assert-NativeSuccess "CMake configure"

# Critical fix:
# The previous runner allowed an old KICKCRAFTER_SharedCode.lib to survive.
# Force a clean rebuild of the shared-code target so PluginProcessor.cpp is
# definitely recompiled with the diagnostic implementation.
Write-Host ""
Write-Host "Forcing CLEAN rebuild of KICKCRAFTER SharedCode..."
cmake --build $BuildDir --config Release --target KICKCRAFTER --clean-first
Assert-NativeSuccess "KICKCRAFTER clean rebuild"

Write-Host ""
Write-Host "Building SafetyProbe against freshly rebuilt SharedCode..."
cmake --build $BuildDir --config Release --target KICKCRAFTER_SafetyProbe
Assert-NativeSuccess "SafetyProbe build"

$candidates = @(
    (Join-Path $BuildDir "KICKCRAFTER_SafetyProbe_artefacts\Release\KICKCRAFTER_SafetyProbe.exe"),
    (Join-Path $BuildDir "KICKCRAFTER_SafetyProbe_artefacts\Release\INDUSTRY KICK Safety Probe.exe")
)

$exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $exe) {
    $exe = Get-ChildItem $BuildDir -Filter "*SafetyProbe*.exe" -Recurse |
           Select-Object -First 1 -ExpandProperty FullName
}

if (-not $exe) {
    throw "SAFETY_PROBE_EXE_NOT_FOUND"
}

Write-Host ""
Write-Host "Running diagnostic: $exe"
& $exe
Assert-NativeSuccess "SafetyProbe execution"

$csv = Join-Path $ProjectRoot "Stage68SafetyProbe.csv"
if (-not (Test-Path $csv)) {
    throw "SAFETY_PROBE_CSV_NOT_FOUND"
}

Write-Host ""
Write-Host "STAGE_6_8E_DIAGNOSTIC_COMPLETE"
Write-Host "SEND_FILE=$csv"
