# INDUSTRY KICK V2 — Stage 6.9B Numerical-Silence Validation Fix

## PROBLEM
Stage 6.9 failures show `basic=1`, `tailRmsDb=-300`, `tailMean=0`,
`decayDropDb=0`. Both residual-analysis windows are already at numerical silence.

The old validator floors both windows to -300 dB and then computes:
`-300 - (-300) = 0 dB`.
It therefore rejects a fully decayed zero tail because there is no further measurable
12 dB slope left.

## CHANGE
DspSmoke only. No Faust DSP or product behavior changes.

Normal residual rule remains:
- final tail < -55 dBFS
- abs(final mean) < 1e-4
- decay drop > 12 dB

Only when BOTH exact linear RMS windows are <= 1e-12 (-240 dBFS) is the slope rule
considered inapplicable and the already-silent tail accepted.

This does not accept persistent or rising non-zero tails.

## INTERNAL TESTS
PASS:
- normal decaying tail
- exact zero -> zero
- numerical-floor -> numerical-floor

Correctly FAIL:
- persistent tail
- rising tail
- zero -> later non-zero signal

## UNCHANGED
Faust DSP
factory presets
randomizer
measured headroom
JUCE safety ceiling
safety-clamp engagement <= 0.10%
family envelope correlation < 0.82
approved shape tolerances
7-second residual render

## STATUS
Static patch: PASS
Synthetic edge-case validation: PASS
Windows DspSmoke: NOT TESTED
VST3 Release: NOT TESTED
