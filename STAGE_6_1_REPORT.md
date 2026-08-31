# INDUSTRY KICK V2 — Stage 6.1 Build Gate

## CURRENT STATE
Gate 02 punch anchor: PASS (user)
Gate 04 family identity: PASS (user)
Gate 05 A anchors: PASS (user)
Faust source static API review: PASS
Faust local compile in this environment: NOT TESTED
JUCE Release build in this environment: NOT TESTED

## BLOCKERS OBSERVED IN THIS ENVIRONMENT
1. `faust` executable is not installed.
2. Outbound DNS/network is unavailable, so the original JUCE FetchContent path cannot fetch JUCE 8.0.6.

These are environment/dependency blockers, not DSP PASS results.

## CHANGES IN 6.1
- Added optional `INDUSTRY_KICK_JUCE_SOURCE_DIR` CMake cache path for deterministic/offline JUCE builds.
- Added Windows and Unix one-command build-gate scripts.
- Strengthened DspSmoke with:
  - DC mean check
  - block-size invariance (64/256/1024 at 48 kHz)
  - deterministic fresh-instance repeatability
  - existing 44.1/48/96 kHz anchor checks
  - sample-accurate onset
  - 50-preset technical scan
  - randomizer scan
  - state round-trip
  - anchor WAV export

## STATIC FAUST REVIEW
The R4 source uses currently documented Faust library APIs for:
- `os.hs_phasor(tablesize, freq, reset)`
- `en.are(attack, release, trigger)`
- `fi.peak_eq_cq(level, freq, Q)`
- `fi.high_shelf(level, freq)`
- `aa.tanh1`
- `aa.hardclip`
- `ba.selectn(N, index)`

Static review cannot prove code generation, runtime numerical stability, parity with approved offline anchors, or CPU cost.

## REQUIRED NEXT GATE
Run `Tools/RunStage6Gate.ps1` on the Windows build machine (or `.sh` on Unix).
The gate must produce:
- successful Faust-generated C++ header
- PASS smoke-test result
- `Stage6TestRenders/` WAVs + `anchor_metrics.csv`
- successful Release VST3 target

Only then should the GUI V2 implementation be unlocked.
