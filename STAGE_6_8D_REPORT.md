# INDUSTRY KICK V2 — Stage 6.8D Pre-Safety Diagnostic

## WHY THIS EXISTS
Stage 6.8 proved that guessing family output multipliers is not acceptable.
The post-JUCE WAV cannot reveal the true peak because jlimit has already destroyed
the overshoot information.

## AUDIO CHANGE
NONE.

PluginProcessor receives a disabled-by-default measurement probe that records:
- true peak immediately before jlimit
- number/percentage of frames actually exceeding the safety ceiling

The probe is enabled only by the SafetyProbe console test.

## MEASUREMENTS
SafetyProbe renders:
- all 50 factory presets
- 50 local-randomizer states
- 48 kHz / 256 samples / 1 second

It writes Stage68SafetyProbe.csv containing exact pre-safety peaks and diagnostic
trim calculations. The 0.86 / 0.82 target columns are REPORTING references only;
they do not alter the plugin and are not validation thresholds.

## NEXT DSP CHANGE
After this CSV:
1. set real factory/randomizer headroom from measured pre-safety peaks instead of guessing;
2. change RAVE topology to a separate rising body envelope plus short bright attack;
3. keep the existing fixed validation thresholds;
4. rebuild once and compare compiled WAVs with the approved 6.6/6.6B references.

## STATUS
Sound path modification: NONE
Static diagnostic checks: PASS
Windows diagnostic build: NOT TESTED
Pre-safety measurements: NOT TESTED
