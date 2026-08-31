# INDUSTRY KICK - Stage 7.2E CMD-only Freeze Gate

## WHY THIS EXISTS
Stages 7.2 through 7.2D became blocked by PowerShell runner/parser/reporting failures.
Those failures occurred before reliable DSP validation and are not evidence of a DSP failure.

Stage 7.2E removes the complex PowerShell runner entirely.

## IMPLEMENTATION
The gate is plain Windows CMD/batch and ASCII-only.

It uses:
- findstr for source/runtime markers
- robocopy for the recoverable checkpoint
- certutil for SHA256 evidence
- cmake for clean DspSmoke / VST3 / optional Standalone builds
- the DspSmoke executable for the actual compiled-audio gate
- pluginval if installed
- Steinberg validator if installed
- tar.exe for the final ZIP
- a single one-line Compress-Archive fallback only if tar.exe is unavailable

## MANDATORY PRE-GUI PASS
- Stage 7.1 source identity
- recoverable checkpoint
- clean DspSmoke build
- DspSmoke result=PASS
- all 50 factory presets
- randomizer
- state round-trip
- VST3 Release
- Standalone PASS or NOT_CONFIGURED

External validators are reported independently:
- PASS
- FAIL
- NOT_TESTED_NOT_FOUND

They are never silently promoted to PASS.

## VALIDATOR CLI
pluginval:
    pluginval --strictness-level 10 <path_to_plugin>

Steinberg validator:
    validator -e <path_to_plugin>

## RELEASE STATUS
Even if PRE_GUI_DSP_GATE=PASS:
    RELEASE_READY=NO

Final release still requires the post-GUI pluginval/DAW regression pass.
