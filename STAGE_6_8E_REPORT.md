# Stage 6.8E — Diagnostic Rebuild Fix

## Root cause
SafetyProbe.cpp compiled against the new PluginProcessor.h, so it emitted a reference to
KickcrafterAudioProcessor::resetSafetyDiagnostics().

The existing KICKCRAFTER_SharedCode.lib was reused without recompiling PluginProcessor.cpp.
Therefore the library did not yet contain the new implementation and MSVC failed with LNK2001.

## Evidence
The failing build log shows SafetyProbe.cpp compilation followed by link failure, with no
PluginProcessor.cpp recompilation in that target run.

## Change
No source/DSP/parameter/validator changes.

The runner now:
1. verifies declaration + implementation + SafetyProbe target;
2. configures CMake;
3. forces `KICKCRAFTER --clean-first`;
4. builds SafetyProbe against the freshly rebuilt SharedCode library;
5. runs the diagnostic;
6. verifies Stage68SafetyProbe.csv exists.

## Expected result
STAGE_6_8E_DIAGNOSTIC_COMPLETE
SEND_FILE=...Stage68SafetyProbe.csv
