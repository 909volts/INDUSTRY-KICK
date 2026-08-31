# INDUSTRY KICK — Stage 10.3 Compiled Safety Fix

## CURRENT STATE

Stage 10.2 actually compiled successfully in Faust/MSVC, but DspSmoke failed.

Measured failure classification:
- BUILD: PASS
- CORE / Stage 7 anchor parity: PASS
- AccentBank mapping: PASS
- AccentBank state: PASS
- residual tails: PASS on all failed presets
- factory technical: FAIL
- randomizer: FAIL
- VST3/Standalone: not built because the DSP gate stopped first

All seven factory failures are HEAVY presets and all fail only because the
existing 0.10% emergency safety-clamp engagement limit is exceeded.

No validator threshold is changed.

Actual Stage 10.2 failed presets:
 index                     name family  bank  safety_hit_pct
    26   Sub Foundation / HEAVY  ROUND HEAVY        0.104167
    27     Warm Reactor / HEAVY  ROUND HEAVY        0.106250
    70     Clean Attack / HEAVY  PUNCH HEAVY        0.116667
    79   Concrete Punch / HEAVY  PUNCH HEAVY        0.127083
   226      Neon Tunnel / HEAVY   RAVE HEAVY        0.125000
   227      Acid Hammer / HEAVY   RAVE HEAVY        0.212500
   229 Belgian Basement / HEAVY   RAVE HEAVY        0.137500

## CHANGE

Only the Stage 10 added path is reduced for HEAVY. `stage10Dry` is untouched.

Measured-family trims:
- ROUND HEAVY: 0.70
- PUNCH HEAVY: 0.30
- HARD HEAVY: 0.85
- INDUSTRIAL HEAVY: 1.00
- RAVE HEAVY: 0.25

CORE/TIGHT/SUSTAIN/MUTANT are unchanged from Stage 10.2.

This specifically honors the sonic constraint that the original kick stays intact
and only the additional layer/reverb/FX path may be reduced.

A simple linear diagnostic from the real Stage 9.1 baseline and Stage 10.2 measured
clamp counts predicts the worst HEAVY value at:
0.096458%

This is only a diagnostic. The Windows DspSmoke run remains the required proof.

## STATIC VALIDATION
- Stage102 Windows build was PASS: PASS
- Stage102 failure was DspSmoke only: PASS
- 7 actual failures only: PASS
- all failures are HEAVY: PASS
- all failed residual tails pass: PASS
- no validator threshold change: PASS
- numerical silence threshold unchanged: PASS
- CORE anchor indices unchanged: PASS
- original dry expression unchanged: PASS
- only HEAVY bank gets safety trim: PASS
- family-specific measured trims present: PASS
- engine unchanged from Stage102: PASS
- processor unchanged from Stage102: PASS
- factory 250 remains Stage91: PASS
- GUI remains Stage81: PASS
- linear safety diagnostic has margin: PASS

## STATUS
Stage 10.3 Windows compile: NOT TESTED
Stage 10.3 full 250 preset gate: NOT TESTED
Listening: NOT REQUESTED
Release ready: NO
