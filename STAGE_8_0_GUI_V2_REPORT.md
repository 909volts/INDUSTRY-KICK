# INDUSTRY KICK — Stage 8.0 GUI V2

## CURRENT STATE
The uploaded project's active `Project/` source is byte-identical to
`Checkpoints/Stage7_1_DSP_APPROVED_FINAL_72E` for the Faust DSP, JUCE processor,
Faust bridge, factory presets, DspSmoke and CMakeLists.

The active GUI is also identical to the approved checkpoint's previous editor.

## GUI AUDIT
Existing graphical assets:
- `plugin-background-brutalist-v1.png`: 1586 x 992, RGB
- `reverb-chambers-v1.png`: 1774 x 887, RGB
- no baked control knobs/buttons were detected in these assets; they are chassis /
  chamber imagery and can safely remain behind interactive JUCE components.

Current editor:
- 1440 x 920 design grid, resizable
- 19 slider attachments
- waveform family selector
- 20 IR chamber selector
- factory/user preset browser
- trigger, randomize, save, undo, redo
- scope, output meter, drag-to-WAV
- all of those functions are preserved.

## PROBLEM
The previous editor overlaid random scratch/wear generators and had less explicit
separation between family processing, body mix and the fixed master chain.

The GUI should communicate the approved sound architecture without pretending that
decorative elements are controls.

## CHANGE
`PluginEditor.cpp` only.

Visual direction:
- restrained dark mechanically plausible chassis
- regular fasteners and panel seams
- engraved control tick marks instead of random scratches
- localized red accents
- localized hazard marking in the master/output assembly only
- panels: CORE / MATERIAL / SPACE / BODY MIX / MUTANT / MASTER
- fixed master chain shown as informational text:
  `LIGHT SAT > GLUE 4:1 > HARD CLIP`

Control behavior:
- all 19 APVTS slider IDs preserved exactly
- waveform attachment preserved
- chamber attachment preserved
- factory/user preset behavior preserved
- trigger/randomizer/save/undo/redo preserved
- scope/meter/drag-WAV preserved

GUI-only label changes:
- IMPACT -> KICK
- SPACE macro -> TAIL
- GRIT -> CRUNCH
- CLIPPER -> CLIP

These are display labels only. Parameter IDs are unchanged.

## DSP FREEZE
The installer compares all non-GUI approved source files against:
`Checkpoints\Stage7_1_DSP_APPROVED_FINAL_72E`

It refuses to patch if any frozen DSP/build-test source differs.

After applying the editor it repeats the byte-level comparison, then runs the full
compiled DspSmoke regression before building VST3/Standalone.

## INTERNAL VALIDATION
Static C++ delimiter/quote structure: PASS
19/19 slider attachment IDs preserved: PASS
Waveform/chamber attachments preserved: PASS
Callbacks preserved: PASS
Random scratch generator removed: PASS
DSP file payload in patch: NONE
GUI V2 source SHA256:
`ed65d1d199cc69962696b01dd500046c5e259458e938f972af0c56bff6f47604`

Windows JUCE compile: NOT TESTED
Compiled DspSmoke after GUI patch: NOT TESTED
VST3/Standalone after GUI patch: NOT TESTED
DAW visual/interaction test: NOT TESTED
