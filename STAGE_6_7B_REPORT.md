# INDUSTRY KICK V2 — Stage 6.7B Residual Validation Fix

## CURRENT STATE
Stage 6.7 compiled and executed far enough to expose the real issue:
randomizer failures are `basic=1 residual=0`.
The reported failing tails at 3.5-4.0 s are approximately -36 to -49 dBFS.

## PROBLEM
Stage 6.7 intentionally lengthened ROUND/INDUSTRIAL family decays.
The longest designed amplitude time constant is 0.90 s.
Therefore the old Stage-6.5 rule `tail RMS < -50 dBFS at 3.5-4.0 s`
is no longer a valid runaway-tail criterion.

For a simple exponential at the worst designed tau=0.90 s:
- ideal level around 6.5 s is approximately -62.7 dB relative to start;
- expected decay from ~3.0 s to ~6.5 s is roughly 33.8 dB.

## CHANGE
VALIDATION ONLY. Faust DSP, presets and randomizer are unchanged.

Persistent residual now requires:
- render through 7.0 s;
- RMS at 6.5-7.0 s < -55 dBFS;
- abs(mean) at 6.5-7.0 s < 1e-4;
- at least 12 dB further decay from the 3.0-3.5 s window to the final window.

This rejects a sustained/runaway/DC tail while allowing the intentionally longer
Stage-6.7 family envelopes to decay naturally.

## VALIDATION
Static patch checks: PASS
Windows DspSmoke: NOT TESTED
Factory bank residual safety: NOT TESTED
Randomizer residual safety: NOT TESTED
VST3 Release: NOT TESTED
