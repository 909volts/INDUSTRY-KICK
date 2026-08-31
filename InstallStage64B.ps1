param(
    [string]$ProjectRoot = "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
)

$ErrorActionPreference = "Stop"

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Payload = Join-Path $PackageRoot "Payload"

$targets = @(
    @{ Src = Join-Path $Payload "Faust\IndustryKickV2_R4_Freeze.dsp"; Dst = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp" },
    @{ Src = Join-Path $Payload "Tests\DspSmoke.cpp";                Dst = Join-Path $ProjectRoot "Tests\DspSmoke.cpp" },
    @{ Src = Join-Path $Payload "Tools\RunStage6Gate.ps1";          Dst = Join-Path $ProjectRoot "Tools\RunStage6Gate.ps1" }
)

foreach ($item in $targets) {
    if (-not (Test-Path $item.Src)) { throw "Missing payload: $($item.Src)" }
    if (-not (Test-Path (Split-Path -Parent $item.Dst))) { throw "Missing target directory: $(Split-Path -Parent $item.Dst)" }
    Copy-Item $item.Src $item.Dst -Force
    Write-Host "COPIED: $($item.Dst)"
}

$faustFile = Join-Path $ProjectRoot "Faust\IndustryKickV2_R4_Freeze.dsp"
$smokeFile = Join-Path $ProjectRoot "Tests\DspSmoke.cpp"
$runnerFile = Join-Path $ProjectRoot "Tools\RunStage6Gate.ps1"

$faustOk = Select-String -Path $faustFile -Pattern "tau \* 6.91" -Quiet
$smokeOk = Select-String -Path $smokeFile -Pattern "approvedEnvelopeTargets" -Quiet
$runnerOk = Select-String -Path $runnerFile -Pattern "Stage 6.4 Parity Build Gate" -Quiet

Write-Host ""
Write-Host "VERIFY Faust tau*6.91: $faustOk"
Write-Host "VERIFY DspSmoke parity targets: $smokeOk"
Write-Host "VERIFY Runner 6.4: $runnerOk"

if (-not ($faustOk -and $smokeOk -and $runnerOk)) {
    throw "STAGE_6_4B_INSTALL_VERIFY_FAILED"
}

Write-Host ""
Write-Host "STAGE_6_4B_INSTALL_PASS"
Write-Host "Now run:"
Write-Host "powershell -ExecutionPolicy Bypass -File `"$runnerFile`""
