# INDUSTRY KICK V2 — Stage 6.3 Patch

## Evidence from Stage 6.2 target build

PASS:
- Faust 2.85.9 invoked
- JUCE configured
- Faust header generated with the MSVC-safe FTZ mode
- Previous C2102 blocker removed
- Previous MapUI/getMap blocker removed
- KICKCRAFTER SharedCode built successfully

FAIL:
- DspSmoke compilation could not find `IndustryKickFaustDSP.h`.

## Root cause
`KICKCRAFTER` had `${INDUSTRY_KICK_FAUST_GENERATED_DIR}` as a PRIVATE include
directory. `KICKCRAFTER_DspSmoke` includes `PluginProcessor.h`, which includes
`FaustKickEngine.h`, which includes the generated Faust header. PRIVATE include
paths do not propagate to the smoke-test target.

## Fix
- Add `${INDUSTRY_KICK_FAUST_GENERATED_DIR}` to DspSmoke includes.
- Add explicit DspSmoke dependency on `INDUSTRY_KICK_FaustDSP`.
- Make the PowerShell gate automatically switch to the Project directory.
- Stop immediately when Faust/CMake/MSBuild/DspSmoke returns a non-zero exit
  code; Windows PowerShell 5.1 does not make `$ErrorActionPreference` sufficient
  for native executable failures.

DSP design changed: NO.
Factory presets changed: NO.
Parameter IDs changed: NO.

Next required evidence:
DspSmoke PASS -> five real Faust anchor WAVs -> VST3 Release build.
