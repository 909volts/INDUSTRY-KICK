# INDUSTRY KICK — Stage 7.1C DspSmoke Compile Fix

## FAILURE CLASS
BUILD

Faust generation in Stage 7.1B succeeded.
MSVC then failed in Tests/DspSmoke.cpp line 520.

## EXACT CAUSE
The generated source contained:

    std::cout << "stageGate=7.1\n";\n    std::cout << ...

The second `\n` was literal C++ source outside a quoted string.
MSVC therefore reported:
- C2017 illegal escape sequence
- C2065 `n` undeclared identifier
- C2143 missing semicolon

## CHANGE
DspSmoke.cpp only.

The line is now two legal C++ statements:

    std::cout << "stageGate=7.1\n";
    std::cout << "approvedStage7Reference=30ms_release\n";

No Faust source is included in this patch.
No DSP topology, preset, headroom value, compressor setting, clipper setting,
or validation threshold is changed.

## RUNNER
Stage 7.1C:
- reuses the successfully generated Faust header if present
- rebuilds only DspSmoke first
- verifies runtime identity
- exports Stage71TestRenders.zip on DSP/validation failure
- builds VST3 only after DspSmoke PASS

## STATUS
C++ source-line repair: PASS
Static search for same literal-escape bug: PASS
Faust DSP change: NONE
Windows DspSmoke compile: NOT TESTED
Compiled audio gate: NOT TESTED
VST3 Release: NOT TESTED
