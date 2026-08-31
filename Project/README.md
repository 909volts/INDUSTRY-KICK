# INDUSTRY KICK V2 — Stage 6 Development Build

INDUSTRY KICK V2 replaces the legacy kick core with the user-approved R4 family architecture in Faust,
while preserving the existing JUCE VST3/Standalone wrapper, public parameter IDs, state serialization,
assets and host identity.

## Approved sonic anchors

Five family centres are currently frozen from Listening Gate 05:

- ROUND / DARK — Clean Weight
- PUNCH / ATTACK — Clean Attack
- HARD / CLIPPED — Hard Clean
- INDUSTRIAL / SUSTAINED — Industrial Clean
- RAVE / BRIGHT — Rave Foundation

The factory bank contains 50 A-biased presets, 10 per family.

## Core architecture

Faust owns the creative kick generation and nonlinear topology:
pitched core, transient/body envelopes, family-specific harmonic construction, EQ, saturation and clipping.

JUCE owns:
VST3/Standalone integration, APVTS parameters/state, MIDI, factory/user presets, convolution/space,
meters/scope, WAV export and host integration.

Creative clipping is not duplicated in the JUCE final stage. JUCE retains only a -0.70 dBFS safety ceiling.

## Build status

See `BUILD_STAGE6.md` and `../Analysis/STAGE_6_VALIDATION_MATRIX.csv`.

The Faust compiler is not installed in the current development environment, so the actual Faust
generation, JUCE Release build and audio parity tests remain NOT TESTED. The project intentionally
fails CMake configuration early when Faust is missing rather than silently substituting another DSP.

## GUI status

The current GUI is transitional/legacy. The PRESS/MUTANT-style V2 GUI is intentionally deferred until
the compiled Faust output is verified against the approved sonic anchors.
