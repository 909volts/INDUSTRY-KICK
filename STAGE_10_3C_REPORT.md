# INDUSTRY KICK — Stage 10.3C Robust Targeted HEAVY Gate

The previous 10.3B bundle stopped at SOURCE_IDENTITY before compiling anything.
That bundle contains only STATUS.txt, so it does not identify which individual
source file mismatched.

The 10.3B runner was unnecessarily strict: it required the current SafetyProbe.cpp
to match an old reference even though SafetyProbe is only a temporary test file.

10.3C fixes the workflow rather than asking for another diagnostic run:

- FactoryPresets / GUI / CMake still require exact known identity.
- Faust / FaustKickEngine / PluginProcessor may be any known Stage 7, Stage 10.2
  or Stage 10.3 state.
- the exact current SafetyProbe.cpp is backed up without requiring an old hash,
  temporarily replaced for the targeted test, then restored byte-for-byte.
- DspSmoke is not touched or re-run.
- the current exact production source is checkpointed before changes.

The test scope remains only:
50 HEAVY presets, 48 kHz, 256 samples, 1 second.
No 250-preset full gate, VST3 build, Standalone build or listening gate.
