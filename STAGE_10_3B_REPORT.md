# INDUSTRY KICK — Stage 10.3B Targeted HEAVY Gate

This replaces the previously supplied full Stage 10.3 validation runner.

Do NOT run the old Stage 10.3 full gate.

The only unresolved Stage 10.2 failure was safety-clamp engagement in HEAVY.
Therefore this runner tests exactly the affected scope:

- 50 HEAVY factory presets total
- 48 kHz
- 256-sample blocks
- 1 second per preset
- same 0.10% safety-clamp limit as DspSmoke
- same 0.923 output-peak limit
- finite / non-silent checks

It explicitly re-checks the seven Stage 10.2 failures:
26, 27, 70, 79, 226, 227, 229.

It does NOT run:
- all 250 presets
- full residual suite
- family anchor matrix
- randomizer
- state round-trip
- VST3 build
- Standalone build
- listening gate

Why those are skipped:
- Stage 10.2 already compiled the new AccentBank/processor/engine code successfully.
- mapping/state already passed.
- failed presets had residual PASS.
- Stage 10.3 changes only the HEAVY added-path gain.
- CORE/TIGHT/SUSTAIN/MUTANT are source-identical to Stage 10.2.
- the full 250 + VST3/Standalone gate is deferred until the next actual milestone.

On PASS:
- Stage 10.3 production source remains applied.
- the temporary SafetyProbe source is restored to the original project file.

On FAIL:
- production source is rolled back to Stage 9.1.
