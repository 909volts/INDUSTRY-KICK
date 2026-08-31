# INDUSTRY KICK V2 — Stage 6.9

## CURRENT STATE
The pre-safety diagnostic completed successfully. The wrapper failed only because the
probe wrote its CSV one directory above `Project`; the numerical measurement itself is valid.

Worst measured pre-jlimit peaks:
- ROUND: 1.0620029
- PUNCH: 1.0488460
- HARD: 1.0279590
- INDUSTRIAL: 1.3201032
- RAVE: 0.8761228

## HEADROOM CHANGE
No more guessed attenuation.

Formula:
`newScale = Stage6.8Scale * 0.78 / max(factoryWorstPrePeak, randomWorstPrePeak)`

Derived Faust family scales:
- ROUND: 0.646326
- PUNCH: 0.654434
- HARD: 0.682907
- INDUSTRIAL: 0.484508
- RAVE: 0.801258

For unchanged topology this predicts a worst pre-safety peak of exactly 0.78.
The JUCE safety ceiling remains unchanged.

## RAVE CHANGE
RAVE no longer uses an instant-full-level exponential core.
It now uses:
- linear percussion AR body (`en.ar`)
- body attack ~50-73 ms according to Body
- release linked to Length (~0.82 s for Rave Foundation)
- coherent same-core transient around 18-24 ms
- existing brief bright harmonic/click paths remain separate

For the Rave Foundation anchor, the simplified offline envelope model gives:
 window  approved_shape_db  offline_ar_core_model_db  error_db
   0-30            -1.1653                 -2.372254 -1.206954
  30-80            -0.2191                 -0.406911 -0.187811
 80-180             0.0000                  0.000000  0.000000
180-400            -2.0733                 -2.057662  0.015638
650-750           -12.1998                -12.152022  0.047778

This is only an offline envelope model, NOT compiled-audio proof.

## PUNCH
Only the body decay is extended modestly (0.75 -> 0.82 length multiplier) because Stage 6.8
missed the approved 30-80 ms shape by only about 0.03 dB beyond the fixed tolerance.

## VALIDATOR
UNCHANGED:
- safety-clamp engagement <= 0.10%
- family max envelope correlation < 0.82
- shape tolerances = [1.50, 1.50, 0.01, 2.00, 3.00] dB
- 7 s residual/DC test
- block invariance, repeatability, onset
- 50 presets, randomizer, state round-trip

## STATUS
Pre-safety measurement: PASS
Headroom derivation: PASS
Offline RAVE envelope model: PASS as design calculation
Static source checks: PASS
Faust compile: NOT TESTED
Compiled sonic parity: NOT TESTED
VST3 build: NOT TESTED
Listening: NOT TESTED
