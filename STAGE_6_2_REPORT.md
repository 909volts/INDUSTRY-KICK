# INDUSTRY KICK V2 — Stage 6.2 Build Fix

## Evidence from Windows build
The Stage 6.1 gate reached:
- Faust 2.85.9: PASS
- JUCE configure/fetch: PASS
- MSVC toolchain: PASS
- Faust DSP generation: PASS
- C++ compilation: FAIL

Two independent compile blockers were identified.

### BLOCKER A — Faust FTZ mask codegen on MSVC
The generated header contained expressions such as:

`reinterpret_cast<int64_t*>(&-fTemp17)`

MSVC rejects this because unary `-fTemp17` is a temporary/rvalue and its
address cannot be taken.

Stage 6.1 explicitly requested Faust `-ftz 2`, the mask-based FTZ mode.
Stage 6.2 changes only MSVC builds to `-ftz 1` (fabs-based software FTZ).
Other compilers keep `-ftz 2`.

This does not redesign the kick DSP. The difference is restricted to handling
subnormal recursive values close to numerical zero.

JUCE's processor path also uses `juce::ScopedNoDenormals`.

### BLOCKER B — MapUI compatibility
The bridge used `ui->getMap()`. The MapUI available with the user's Faust
installation does not expose that API in the compiled variant.

Stage 6.2 enumerates controls using:
- `getParamsCount()`
- `getParamAddress(index)`
- `getParamZone(index)`

Zone pointers are still cached during prepare; there are no path lookups on
the realtime audio thread.

## Stage 6.2 validation status
- Root cause identification: PASS
- Source patch applied: PASS
- 44 parameter IDs preserved: PASS (no parameter-layout edit in this patch)
- DSP architecture changed: NO
- Faust compile on target Windows machine: NOT TESTED
- DspSmoke: NOT TESTED
- Five anchor renders: NOT TESTED
- VST3 Release: NOT TESTED

## Run
From the Project directory:

`powershell -ExecutionPolicy Bypass -File ".\Tools\RunStage6Gate.ps1"`

The script deletes the stale generated Faust header first, then re-runs
Faust generation, CMake, DspSmoke and VST3 build.
