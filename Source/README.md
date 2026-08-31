# INDUSTRY KICK 0.7.0

INDUSTRY KICK by 909VOLTS is a Windows VST3 instrument for hard-techno and industrial kicks. It combines a phase-locked kick engine, protected low end, stereo convolution and an internal output stage.

## Highlights

- Five kick cores: Round, Punch, Hard, Industrial and Rave.
- 50 factory presets targeting approximately -7 dBFS peak.
- 20 stereo convolution spaces in four categories.
- Shape, Evolve, Destroy and four mix macros with safe ranges.
- Randomizer, preset stepping, output clipper, stereo meter and WAV drag-and-drop.

## Install

1. Close Ableton Live and any other VST host.
2. Run `INDUSTRY-KICK-Setup-Windows-x64.exe` as administrator.
3. Reopen the host and rescan VST3 plugins.

The installer uses `C:\Program Files\Common Files\VST3`. It replaces the earlier KICKCRAFTER bundle without deleting user presets.

## Build

Requirements: Visual Studio 2022 with **Desktop development with C++**, CMake 3.22+ and Git.

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release --target KICKCRAFTER_VST3
```

Output: `build/KICKCRAFTER_artefacts/Release/VST3/INDUSTRY KICK.vst3`

## Notes

- Windows 10/11 x64; 64-bit VST3 host required.
- Custom IR import and digital signing are not included yet.
- See `Documentation` for the English manual and `Legal` for the draft EULA.
