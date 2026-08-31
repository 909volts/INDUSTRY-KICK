# INDUSTRY KICK V2 — Stage 6.8 Audio Parity

## CURRENT STATE
Stage 6.7B residual/DC safety, 50 factory presets and randomizer safety are valid.
The uploaded compiled Stage67 WAVs expose two actual audio problems.

## MEASURED PROBLEM 1 — SAFETY CLAMP USED AS CREATIVE CLIPPING
Exact first-second samples at the JUCE -0.70 dBFS ceiling:
ROUND 5.10%
PUNCH 2.81%
HARD 6.34%
INDUSTRIAL 10.95%
RAVE 0.004%

A safety ceiling must not flatten 3-11% of a kick.

## MEASURED PROBLEM 2 — RAVE COLLAPSES TOWARD PUNCH
Relative to its own 80-180 ms body, compiled RAVE is:
0-30 ms: +4.14 dB too strong
30-80 ms: +2.57 dB too strong

Compiled PUNCH-RAVE smoothed-envelope correlation is 0.899.

## CHANGE
- Family-specific LINEAR headroom after Faust creative processing.
- HARD/INDUSTRIAL decay and creative saturation topology left unchanged.
  First remove the unintended post-Faust clipping.
- ROUND transient multiplier reduced slightly.
- PUNCH transient multiplier reduced; decay lengthened ~4%.
- RAVE core transient multiplier strongly reduced; its separate bright paths remain.

## VALIDATION — FIXED BEFORE TARGET RUN
- JUCE safety clamp engagement <= 0.10% during first second.
  If it fails, change DSP/headroom, not the threshold.
- Envelope parity uses gain-independent shape relative to 80-180 ms.
- Shape targets are derived from the user-approved Stage 6.6/6.6B WAVs.
- Between-family smoothed-envelope correlation < 0.82.
- 7-second residual/DC, sample rates, buffers, block invariance, repeatability,
  onset, all 50 presets, randomizer and state round-trip remain active.

## STATUS
Uploaded Stage67 diagnosis: PASS
Static patch checks: PASS
Faust compile: NOT TESTED
Compiled Stage 6.8 parity: NOT TESTED
Safety clamp inactivity: NOT TESTED
Family diversity: NOT TESTED
50 presets: NOT TESTED
Randomizer: NOT TESTED
VST3 Release: NOT TESTED
