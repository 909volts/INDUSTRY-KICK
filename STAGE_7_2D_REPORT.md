# INDUSTRY KICK — Stage 7.2D PowerShell Quote Fix

## FAILURE CLASS
RUNNER_PARSER

## EXACT ROOT CAUSE
Stage 7.2C ended with this invalid Windows PowerShell expression:

    Write-Host "PRE_GUI_DSP_GATE=$($script:Status["PRE_GUI_DSP_GATE"])"

The inner double quotes terminate the outer interpolated string.

The parser preflight correctly stopped execution before checkpoint/build/test work.

## CHANGE
Runner only.

The final status output is now:

    $finalGateStatus = $script:Status['PRE_GUI_DSP_GATE']
    Write-Host "PRE_GUI_DSP_GATE=$finalGateStatus"

This avoids nested quoted dictionary indexing entirely.

No Faust source, JUCE source, DspSmoke source, thresholds, presets, DSP settings,
master-chain settings or validation criteria are changed.

## PREVENTION
The package generation includes a static guard against the specific unsafe pattern:
interpolated PowerShell strings containing dictionary keys quoted with `"`.

The Windows PowerShell parser preflight remains mandatory before execution.

## STATUS
Stage 7.2C execution: NOT TESTED — parser blocked it
DSP change: NONE
Validator change: NONE
Stage 7.2D parser on target Windows machine: NOT TESTED
Pre-GUI DSP gate: NOT TESTED
