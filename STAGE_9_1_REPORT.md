# INDUSTRY KICK - Stage 9.1 Preset Diversity Revision

## CURRENT STATE FROM STAGE 9.0 COMPILED AUDIT

MEASURED:
- 250/250 factory presets passed the existing technical/residual gate.
- randomizer PASS.
- state round-trip PASS.
- VST3 Release PASS.
- Standalone Release PASS.
- Stage 7.1 family anchors still passed the frozen parity gates.

The candidate bank is technically valid, but internal diversity analysis found
several weak sub-bank separations. The lowest measured effect ratios were led by:

    family  bank_a  bank_b  centroid_distance  effect_ratio
INDUSTRIAL    CORE   HEAVY           0.273979      0.297129
INDUSTRIAL SUSTAIN  MUTANT           0.354408      0.370579
INDUSTRIAL    CORE  MUTANT           0.362845      0.376349
INDUSTRIAL    CORE SUSTAIN           0.390849      0.411303
      HARD    CORE   HEAVY           0.408907      0.506375
      RAVE    CORE   HEAVY           0.432118      0.549683
      HARD    CORE  MUTANT           0.464842      0.559756
      RAVE   TIGHT  MUTANT           0.491353      0.581362

This is not a listening claim. It is evidence that asking the user to audition all
250 now would be premature.

## IMPORTANT CSV ISSUE

Stage 9.0 `preset_metrics.csv` wrote literal `\n` text instead of physical newline
records. The 250 rows are recoverable and were repaired offline for this analysis,
but Stage 9.1 fixes the exporter itself.

The WAV renders and DspSmoke PASS/FAIL decisions were not dependent on pandas/CSV
parsing, so this formatting issue does not invalidate the Stage 9.0 technical pass.

## CHANGE

No Faust / PluginProcessor / FaustKickEngine / master-chain change.

ROUND:
- Stage 9.0 values preserved exactly.

PUNCH:
- Stage 9.0 values preserved exactly.

HARD:
- HEAVY becomes lower/slower/weightier while slightly REDUCING drive/clip.
- SUSTAIN uses more body/evolve/metal but lower sub and less clip.
- MUTANT increases shape/colour/metal/evolve with lower sub and LESS drive/clip.
- Goal: diversity without returning to excessive HARD saturation.

INDUSTRIAL:
- strongest revision because Stage 9.0 bank separation was weakest.
- TIGHT shortens and removes more low tail.
- HEAVY lowers tuning/drive/evolve instead of adding another crushed layer.
- SUSTAIN extends mechanical/harmonic behavior while reducing sub.
- MUTANT increases metal/shape/evolve while reducing sub/clip.
- Goal: avoid CORE/HEAVY/MUTANT collapsing into the same processed kick.

RAVE:
- TIGHT remains short and attack-led.
- HEAVY becomes lower/weightier.
- SUSTAIN extends body while controlling sub.
- MUTANT is no longer simply another short variant: more tune/colour/metal/evolve.

## PRESERVATION

- 250 unique names: PASS
- 250 unique active parameter vectors: PASS
- Stage 9.0 ROUND/PUNCH values preserved exactly: PASS
- all five CORE anchors preserved exactly: PASS
- Stage 7 safety threshold `0.10%`: preserved
- residual numerical-silence threshold `1e-12`: preserved
- approved anchor indices: 0 / 50 / 100 / 150 / 200
- GUI 8.1 source: unchanged
- DSP topology/master: unchanged

## VALIDATION STATUS

Internal source/static checks: PASS
Windows Stage 9.1 compile: NOT TESTED
250 compiled Stage 9.1 audit: NOT TESTED
Preset listening: NOT TESTED

Run:
`APPLY_AND_RUN_STAGE_9_1.bat`

If Stage 9.1 fails build or technical validation, the runner restores the validated
Stage 9.0 factory bank and DspSmoke automatically.
