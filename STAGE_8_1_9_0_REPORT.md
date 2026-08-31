# INDUSTRY KICK - Stage 8.1 + Stage 9.0

## CURRENT STATE
Stage 7.1 DSP/master chain is treated as frozen.

This package changes:
- `Source/PluginEditor.cpp`
- `Source/FactoryPresets.h`
- `Tests/DspSmoke.cpp`

It does NOT change:
- Faust DSP
- PluginProcessor
- FaustKickEngine
- parameter IDs/ranges
- master saturation/compressor/hard clipper settings
- approved parity thresholds

## STAGE 8.1 - GUI
The previous Stage 8 GUI compiled, but visually remained too close to the old skin.

Stage 8.1 intentionally removes the full-background-skin look and uses a fabricated
machine chassis drawn in JUCE:
- thick structural rails
- bolted inset modules
- raised identification plates
- twelve-sided knob retaining bezels
- mounting lugs and engraved calibration marks
- inspection-window framing for scope/IR chamber
- hydraulic manifold treatment for MUTANT
- localized hazard marking on MASTER only
- hardware blocks for SAT / GLUE 4:1 / HARD CLIP

No random scratch/glitch filler is introduced.

Expected PluginEditor.cpp SHA256:
`d4020b8c1741a8069d61b835a6908fb12a04393153d539cf2237f5a0cda2ad28`

## STAGE 9.0 - CURRENT 50 PRESET AUDIT

Static parameter-space observations only; these are NOT listening claims.

Closest current family centroids:
- INDUSTRIAL vs RAVE: 0.162
- HARD vs INDUSTRIAL: 0.184
- HARD vs RAVE: 0.191

This objectively supports investigating the user-reported HARD / INDUSTRIAL / RAVE
similarity first.

The current 50 bank also has relatively close within-family parameter pairs,
especially ROUND and PUNCH. Parameter proximity does not prove perceptual duplication,
so compiled audio metrics are required before removal/replacement decisions.

## STAGE 9.0 - 250 CANDIDATE BANK

250 = 50 per family.

Each family contains:
- 10 CORE
- 10 TIGHT
- 10 HEAVY
- 10 SUSTAIN
- 10 MUTANT

The 50 CORE values are preserved exactly from the existing factory bank.
The approved family anchors therefore remain:
- 0 Clean Weight
- 50 Clean Attack
- 100 Hard Clean
- 150 Industrial Clean
- 200 Rave Foundation

Design intent:
- TIGHT shortens decay and controls sub persistence while increasing impact.
- HEAVY adds body/weight with lower tuning.
- SUSTAIN extends body but deliberately REDUCES sub level so "long" does not simply
  mean a larger low-frequency tail.
- MUTANT increases family-specific character. HARD/INDUSTRIAL/RAVE use separate
  saturation/clip guard rails so they are not all pushed toward the same clipped sound.

Reverb and SPACE remain neutral in all 250 candidates.

Candidate FactoryPresets.h SHA256:
`45b12455d7bfc67914513016c14b89b427d92675d1510777e3ec1678905abbe1`

## INTERNAL STATIC VALIDATION

- Stage 8.1 C++ delimiter/string balance: PASS
- Stage 9 DspSmoke delimiter/string balance: PASS
- 250 unique preset names: PASS
- 250 unique active parameter vectors: PASS
- 50 CORE preset values preserved exactly: PASS
- Existing Stage 7 technical thresholds retained: PASS
- Approved anchor targets retained: PASS
- Frozen DSP source included in patch: NONE

Windows JUCE build: NOT TESTED
Compiled 250-preset technical audit: NOT TESTED
Preset listening quality: NOT TESTED

## WINDOWS RUN

`APPLY_AND_RUN_STAGE_8_1_9_0.bat`

Workflow:
1. verifies frozen Stage 7.1 engine
2. checkpoints current Stage 8 GUI + approved preset/test sources
3. applies GUI 8.1
4. compiles GUI 8.1 while the approved 50-preset bank is still active
5. applies 250 candidate bank + audit-only DspSmoke extension
6. renders/tests all 250 through the real compiled processor
7. exports objective metrics + 25 representative WAVs
8. builds VST3 + Standalone if the 250 technical gate passes

If the 250 candidate bank/test fails, the runner automatically restores the
approved 50-preset bank and original DspSmoke while keeping the already-validated
GUI 8.1 source.

The candidate bank must NOT be considered sonically approved until the compiled
audit bundle is analyzed and the later listening gate passes.
