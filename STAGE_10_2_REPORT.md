# INDUSTRY KICK — Stage 10.2 Faust Accent/Bus Integration

## CURRENT STATE

This stage implements the approved architectural direction directly in Faust.

No new listening gate is generated.

The current Stage 9.1 250-preset bank and GUI 8.1 remain unchanged.

## USER CHANGE APPLIED

- Original kick path/level is NOT normalized and is NOT reprocessed.
- Only the added layer/reverb/parallel bus is reduced.
- SUSTAIN and MUTANT added layers are slightly lower again.
- SUSTAIN and MUTANT wet/bus feedback is slightly shorter.
- MUTANT remains less metallic: approximately 40% metal contribution in the
  layer blend, with reduced FM modulation depth and 4.8 kHz layer low-pass.

## DSP TOPOLOGY

`Stage 7 family DSP -> approved Stage 7 master -> stage10Dry`

Then, in parallel:

`AccentBank -> click / percussion / HP top-kick / reduced FM-metal -> HP 170 Hz`

`stage10Dry + accent send -> bank-specific parallel bus -> HP 190 Hz`

`accent + small bus send -> mono_freeverb -> HP 330 Hz -> LP 6 kHz`

Finally:

`stage10Dry + accent + low-level bus + low-level reverb`

JUCE's existing -0.70 dBFS safety ceiling remains the emergency protection.

CORE uses zero additional layer/bus/reverb, so the approved Stage 7 anchor path
remains exactly the old dry chain.

## INTERNAL BANK

No host parameter was added.

The 250 factory bank is still:
- 50 ROUND
- 50 PUNCH
- 50 HARD
- 50 INDUSTRIAL
- 50 RAVE

Within each family:
- 0-9 CORE -> AccentBank 0
- 10-19 TIGHT -> AccentBank 1
- 20-29 HEAVY -> AccentBank 2
- 30-39 SUSTAIN -> AccentBank 3
- 40-49 MUTANT -> AccentBank 4

`AccentBank` is stored as an internal ValueTree property and restored with plugin
state/user presets/A-B slots. It is not a new automatable public parameter.

## STATIC VALIDATION

- Faust Stage7 master preserved verbatim: PASS
- AccentBank control added: PASS
- CORE added path is zero: PASS
- Original dry master unchanged: PASS
- MUTANT metal share 40 percent: PASS
- SUSTAIN/MUTANT tail shortened: PASS
- No host parameter added: PASS
- Engine caches AccentBank: PASS
- Processor sends AccentBank: PASS
- Factory bank maps internal archetype: PASS
- Randomizer preserves archetype: PASS
- State restore syncs archetype: PASS
- Processor H balanced: PASS
- Processor CPP balanced: PASS
- Engine H balanced: PASS
- Engine CPP balanced: PASS
- DspSmoke balanced: PASS
- 250 bank unchanged: PASS
- GUI 8.1 unchanged: PASS
- Safety threshold untouched: PASS
- Residual threshold untouched: PASS
- Stage7 anchor indices untouched: PASS

## BUILD / AUDIO STATUS

Faust compile: NOT TESTED in this environment
Windows JUCE compile: NOT TESTED in this environment
250 compiled factory technical gate: NOT TESTED
Stage 7 CORE parity: NOT TESTED
AccentBank state round-trip: NOT TESTED
VST3 build: NOT TESTED
Standalone build: NOT TESTED
Listening gate: NOT REQUESTED
Release ready: NO

Run `APPLY_BUILD_VALIDATE_STAGE_10_2.bat`.

The runner rolls back the Stage 10.2 source automatically if compile or DspSmoke
fails. It does not modify validator thresholds.
