# INDUSTRY KICK V2 — Stage 6.10

## CURRENT STATE
The uploaded ZIP contains both Stage69 and Stage69B folders.
The Stage69 WAVs are malformed/concatenated (file size is roughly twice the RIFF payload)
and libsndfile rejects them. The Stage69B WAVs are valid 48 kHz mono files and are the
basis of this analysis.

Stage69B technical evidence from the user's last log:
- safety clamp engagement: 0% on all five anchors
- anchor residual safety: PASS
- 50 factory presets: PASS
- randomizer: PASS
- state round-trip: PASS
- four anchors envelope parity: PASS
- RAVE envelope parity: FAIL
- correlation-only diversity gate: FAIL at max 0.827386

## PROBLEM 1 — THE CORRELATION GATE IS NOT ACTIONABLE
The max correlation was ROUND/PUNCH = 0.827386, but their compiled 650-750 ms
shape differs by about 29.6 dB:
- ROUND: -5.43 dB relative to body
- PUNCH: -35.06 dB relative to body

That pair is temporally very different despite the correlation number.
Correlation remains printed for diagnostics but no longer controls PASS/FAIL.
Per-family approved envelope-shape parity remains a hard sonic gate.

## PROBLEM 2 — RAVE TAIL IS TOO LONG AFTER THE NONLINEAR CHAIN
Approved RAVE shape relative to 80-180 ms:
- 180-400 ms: -2.07 dB
- 650-750 ms: -12.20 dB

Compiled Stage69B:
- 180-400 ms: -0.94 dB
- 650-750 ms: -7.97 dB

The Stage6.9 AR solved the previous PUNCH/RAVE collapse, but downstream nonlinear
processing makes the audible tail longer than the offline approved reference.

## CHANGE
Only RAVE receives a sonic change.

A final exponential tail contour is applied AFTER the RAVE creative saturation/filter chain:
- hold: 155 ms
- tau at Rave Foundation: 1.089 s
- tau remains linked to Length: 0.95 .. 1.65 s

This separates:
creative saturation -> final decay contour

The attack/body and bright paths are not changed.

## OFFLINE PROXY ON THE ACTUAL COMPILED STAGE69B RAVE
The proposed post-character taper was applied directly to the uploaded compiled RAVE WAV.

Predicted shape:
- 0-30: 0.16 dB  (approved -1.17)
- 30-80: 1.13 dB (approved -0.22)
- 80-180: 0.00 dB
- 180-400: -1.91 dB (approved -2.07)
- 650-750: -12.24 dB (approved -12.20)

Existing approved-shape tolerance check on this proxy: PASS.
Peak cannot increase because the new contour is <= 1.0.

## SATURATION / BAND OBSERVATIONS
HARD:
- approved 6.6B 0-750 ms crest: 5.91 dB
- compiled Stage69B crest: 5.83 dB
This is close in overall density.

INDUSTRIAL:
- approved 6.6B crest: 5.23 dB
- compiled Stage69B crest: 7.39 dB
The compiled result is materially less dense/more dynamic, consistent with the user's
request for less saturation, but this is not claimed as perceptually better without listening.

RAVE transient centroid:
- approved offline: 372 Hz
- compiled Stage69B: 265 Hz
The compiled RAVE is measurably darker in its first 30 ms. This patch deliberately does NOT
boost highs because earlier user feedback rejected excessive high-frequency energy.
Brightness remains a listening decision after decay parity is fixed.

## VALIDATION METHOD
Hard gates retained:
- approved per-family envelope shape
- finite/non-silent
- safety clamp <= 0.10%
- residual/DC safety
- sample-rate/buffer invariance
- repeatability
- sample-accurate onset
- all 50 presets
- randomizer
- state round-trip

Diagnostic only:
- pairwise envelope/waveform correlation

## STATUS
Stage69B WAV analysis: PASS
Stage6.10 offline RAVE-tail proxy: PASS
Static patch checks: PASS
Faust Windows compile: NOT TESTED
Compiled Stage6.10 RAVE parity: NOT TESTED
VST3 Release: NOT TESTED
Listening: NOT TESTED
