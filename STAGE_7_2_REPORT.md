# INDUSTRY KICK — Stage 7.2 DSP Freeze / Pre-GUI Gate

## PURPOSE
Freeze the user-approved compiled Stage 7.1 sound and validate the exact project
before GUI work. This stage changes no DSP source.

## ACTIONS
1. Verifies Stage 7.1 Faust/DspSmoke identity.
2. Creates a recoverable checkpoint of Faust, Source, Tests, CMakeLists and
   optional Assets/Resources/Presets.
3. Writes SHA256 hashes of the frozen source.
4. Performs a clean Release DspSmoke build.
5. Runs the complete Stage 7.1 compiled-audio gate.
6. Requires:
   - DspSmoke result PASS
   - all 50 factory presets PASS
   - randomizer PASS
   - state round-trip PASS
7. Builds VST3 Release.
8. Builds Standalone if that target is configured.
9. Runs pluginval at strictness 10 if pluginval.exe is installed.
10. Runs Steinberg VST3 Validator with extensive tests if installed.
11. Produces Stage72ValidationBundle.zip regardless of later validation status.

## INTERPRETATION
`PRE_GUI_DSP_GATE=PASS` means the approved DSP source/build/regression checks passed
and GUI work may proceed without changing the sound.

`RELEASE_READY=NO` remains intentional. A final release still requires:
- final-GUI pluginval regression
- DAW scan / instantiate / remove
- state recall
- automation
- supported sample-rate and buffer-size checks in a real host
- final listening regression

Unavailable external validators are reported as NOT_TESTED, never PASS.

## EXTERNAL VALIDATOR POLICY
pluginval strictness 10 is used when available.
Steinberg Validator is run with its extensive-test option when available.
