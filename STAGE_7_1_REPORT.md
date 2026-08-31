# INDUSTRY KICK — Stage 7.1 Faust Integration

## CURRENT STATE
The user approved the Stage 7 offline candidate with the 30 ms compressor release.
Those five WAVs are now frozen under `Reference/Stage7_Approved_30ms`.

## CHANGE
The five Stage 6.10 generators remain intact.

A second family-specific stage is added after each generator:
- ROUND: controlled long sub + mild body saturation
- PUNCH: shortest sub + brief upper transient + minimal saturation
- HARD: sub bypasses the local clipped-body path
- INDUSTRIAL: short sub + asymmetric 180-1800 Hz mechanical path
- RAVE: short/medium sub + 1.5 kHz body + brief bright transient

Then every family passes through exactly one shared master:
1. light saturation
2. Faust standard-library mono compressor
   - ratio 4:1
   - threshold -9.5 dBFS
   - attack 30 ms
   - release 30 ms
3. ADAA hard clipper
   - +2 dB drive
   - -0.8 dBFS output ceiling

JUCE's -0.70 dBFS clamp remains emergency safety only.

## VALIDATION CHANGE
The approved Stage 7 WAVs define the sonic regression target.

Hard sonic checks at 48 kHz / 256:
- five-window envelope shape
- low-band (<~105 Hz validator meter) tail shape
- 0-750 ms crest factor

Technical gates remain:
- finite / non-silent
- JUCE safety-clamp engagement <= 0.10%
- residual/DC safety
- 44.1/48/96 kHz
- 64/256/1024 blocks
- block invariance
- repeatability
- sample-accurate onset
- all 50 factory presets
- randomizer
- state round-trip

Pairwise correlation remains diagnostic only.

## BUILD HYGIENE
The runner forces:
- current Faust source timestamp
- deletion of stale generated Faust header
- deletion of stale DspSmoke object/exe/PDB
- clean DspSmoke rebuild
- runtime stage marker verification

Even if the sonic gate FAILS, Stage71TestRenders.zip is created before exit so the
compiled WAVs can be analyzed without another user-side run.

## STATUS
Stage 7 offline listening direction: USER APPROVED
Reference extraction/measurement: PASS
Static Faust architecture checks: PASS
Static DspSmoke checks: PASS
Windows Faust compile: NOT TESTED
Compiled Stage 7.1 parity: NOT TESTED
VST3 Release: NOT TESTED
GUI: intentionally unchanged
