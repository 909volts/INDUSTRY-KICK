# INDUSTRY KICK — Stage 7.2B PowerShell Parser Fix

## CURRENT STATE
Stage 7.2 did not execute. Windows PowerShell failed while parsing RunStage72.ps1
before any checkpoint, build, DspSmoke test or validator could run.

## FAILURE CLASS
RUNNER / BUILD INFRASTRUCTURE

## ROOT CAUSE
The Stage 7.2 runner used a multiline boolean expression whose continuation
lines began with `-and`. Windows PowerShell 5.1 rejected that form here.

## CHANGE
Runner only.

The hard-gate condition is now represented as an array of parenthesized boolean
expressions and reduced with:

    $hardPass = -not ($hardChecks -contains $false)

No Faust source, JUCE source, DspSmoke logic, thresholds, presets or sonic
behavior is changed.

## PREVENTION
The .bat wrapper now asks Windows PowerShell's own parser to parse
RunStage72B.ps1 before executing it.

If syntax errors exist:
- the runner is not executed
- FAILURE_CLASS=RUNNER_PARSER
- no validation result is claimed

## STATUS
DSP change: NONE
Validator change: NONE
Stage 7.2 original run: NOT TESTED (parser stopped execution)
Stage 7.2B Windows parse preflight: NOT TESTED until user runs it
Pre-GUI DSP gate: NOT TESTED
