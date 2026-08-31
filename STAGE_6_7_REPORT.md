# INDUSTRY KICK V2 — Stage 6.7 Compiled Diversity Integration

## CURRENT STATE
Stage 6.5 compiled DSP/build gate: PASS.
Stage 6.6 offline family-diversity gate: ROUND/PUNCH/RAVE approved.
Stage 6.6B: HARD and INDUSTRIAL approved after a modest saturation reduction.

## CHANGE
The approved direction is now encoded into Faust.

ROUND
- longer amplitude decay
- reduced transient over-emphasis
- softer asymmetric saturation

PUNCH
- shortest family decay
- narrower transient envelopes
- mild body saturation; stronger nonlinear emphasis is concentrated on the attack/noise path

HARD
- medium-short decay
- same serial clipping architecture
- lower drive/asymmetry and lower hard-clip gains than Stage 6.5

INDUSTRIAL
- longer amplitude/mechanical/harmonic decay
- same low-mid mechanical identity
- reduced soft/hard saturation gains versus Stage 6.5

RAVE
- medium body decay
- shorter bright harmonic/click envelopes
- less sustained full-event saturation

No factory parameter IDs, JUCE state schema, plugin identity, or preset values are changed.

## VALIDATION ADDED
DspSmoke now checks:
- technical safety at 44.1/48/96 kHz and 64/256/1024
- approved Stage 6.6/6.6B envelope targets
- persistent tail/DC safety
- block-size invariance
- deterministic repeatability
- sample-accurate onset
- all 50 factory presets
- randomizer safety
- APVTS state round-trip
- objective between-family envelope diversity (max smoothed-envelope correlation < 0.86)
- crest / near-peak density are printed for inspection
- five 48 kHz anchor WAVs are exported to Stage67TestRenders and automatically zipped

## CHECKPOINT
The one-click installer saves the current passing Stage 6.5 Faust/DspSmoke/runner before replacing anything.
ROLLBACK_TO_STAGE_6_5.bat restores that checkpoint.

## STATUS BEFORE WINDOWS TARGET RUN
Static patch verification: PASS
Faust compile: NOT TESTED
Compiled envelope parity: NOT TESTED
Compiled family diversity: NOT TESTED
50 factory presets: NOT TESTED
Randomizer: NOT TESTED
VST3 Release: NOT TESTED
Listening compiled Stage 6.7: NOT TESTED
