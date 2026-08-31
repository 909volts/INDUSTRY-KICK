# INDUSTRY KICK V2 — Stage 6 Build Requirements

## Required
- CMake 3.22+
- C++17 toolchain
- Git (JUCE 8.0.6 is fetched by CMake)
- Faust compiler 2.80+ available on PATH
- Windows VST3 build: Visual Studio 2022 Desktop development with C++

Check Faust first:

```powershell
faust --version
```

## Configure / build (Windows)
From the `Project` directory:

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release --target KICKCRAFTER_VST3
cmake --build build --config Release --target KICKCRAFTER_DspSmoke
.\build\KICKCRAFTER_DspSmoke_artefacts\Release\INDUSTRY_KICK_DSP_Smoke.exe
```

Depending on the generator/JUCE artifact layout, the smoke-test executable directory may differ;
if so, locate the generated `INDUSTRY KICK DSP Smoke` executable inside `build`.

When the smoke test runs, it also creates `Stage6TestRenders` in its working directory with:
- five 48 kHz / 24-bit mono WAVs for the approved A anchors;
- `anchor_metrics.csv`.

Those files are the next parity gate: return the folder/ZIP for offline comparison against the approved anchors.

Expected VST3 artifact family:
`build/KICKCRAFTER_artefacts/Release/VST3/INDUSTRY KICK.vst3`

## Faust generation
CMake generates `IndustryKickFaustDSP.h` at build time using:
- double precision
- FTZ mode 2
- inline architecture output
- class name `IndustryKickFaustDSP`

The finished plugin does not require a Faust runtime library.

## Current environment status
CMake configure was executed here and correctly stopped with:
`Faust compiler not found`.

Therefore:
- CMake dependency check: FAIL
- Faust compile: NOT TESTED
- JUCE Release build: NOT TESTED
- DSP smoke runtime: NOT TESTED

Do not treat the static bridge compile as a substitute for the real Faust/JUCE build.
