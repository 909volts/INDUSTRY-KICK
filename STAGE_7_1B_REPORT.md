# INDUSTRY KICK — Stage 7.1B Faust Compile Fix

## CURRENT STATE
Stage 7.1 did not reach DSP validation. Faust generation failed first.

## FAILURE CLASS
BUILD

Compiler evidence:
`BoxIdent[tanh] is defined here : maths.lib:782`

## PROBLEM
Stage 7.1 introduced three unqualified `tanh(...)` invocations in normalization
helpers. The Faust maths library exposes tanh as a signal processor, and this
compiler/library combination rejects the unqualified call form used there.

## CHANGE
No sonic architecture or approved parameter is changed.

All Stage 7 saturation drives are fixed constants, so the intended normalization
constants are precalculated:
- 1.10 -> 0.800499021761
- 1.08 -> 0.793199097084
- 1.65 -> 0.928857621455
- 1.55 -> 0.913785490118
- 1.14 -> 0.814414093766
- 1.55 * 0.045 -> 0.069637106984

`aa.tanh1`, `aa.hardclip`, the 4:1 30/30 compressor, family topology,
master chain and all DspSmoke sonic thresholds remain unchanged.

## RUNNER FIX
The runner now separates:
1. Faust generation
2. DspSmoke build + execution
3. VST3 Release build

A compile failure is reported as BUILD and no nonexistent render ZIP is requested.

## STATUS
Static source check: PASS
Bare unqualified tanh calls removed: PASS
ADAA nonlinearities preserved: PASS
DspSmoke source unchanged: PASS
Windows Faust generation: NOT TESTED
Compiled audio validation: NOT TESTED
VST3 Release: NOT TESTED
