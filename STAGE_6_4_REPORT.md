# INDUSTRY KICK V2 — Stage 6.4 Faust Parity Fix

## CURRENT STATE
Stage 6.3 build infrastructure: PASS
Compiled Faust execution: PASS
Compiled Faust vs approved Gate-05 A parity: FAIL

## MEASURED
At the same safety peak (~-0.70 dBFS), compiled Faust RMS vs approved A:
ROUND -15.94 vs -7.67 dBFS
PUNCH -18.28 vs -10.53 dBFS
HARD -13.89 vs -5.72 dBFS
INDUSTRIAL -14.52 vs -6.71 dBFS
RAVE -18.22 vs -8.82 dBFS

The first 0-30 ms is already close. The body is not:
ROUND 80-180 ms -16.18 vs -4.93 dBFS
PUNCH 80-180 ms -33.17 vs -7.11 dBFS
HARD 80-180 ms -11.86 vs -3.40 dBFS
INDUSTRIAL 80-180 ms -12.41 vs -4.13 dBFS
RAVE 80-180 ms -27.23 vs -5.14 dBFS

## ROOT CAUSE
The offline prototype used tau as an exponential time constant.
The Faust freeze passed tau directly to en.are().
Faust documents ARE on a scale corresponding to approximately 6.91*tau.
This made amplitude, pitch and transient envelopes decay much too quickly.

## CHANGE
- Convert prototype tau to Faust ARE time with tau*6.91.
- Apply to amp, fast-pitch, body-pitch, transient and Industrial mechanical envelopes.
- No family topology changes.
- No preset-value changes.
- No parameter-ID changes.
- Keep current technical DC guardrail for this run.
- Add approved-A envelope parity test.
- Print exact failed factory/randomizer cases.
- Auto-detect the actual DspSmoke executable.

## VALIDATION
Static patch checks: PASS
Compiled Stage 6.4 Faust: NOT TESTED
Envelope parity: NOT TESTED
Factory preset technical: NOT TESTED
Randomizer technical: NOT TESTED
VST3 Release: NOT TESTED

No user listening gate until compiled parity passes.
