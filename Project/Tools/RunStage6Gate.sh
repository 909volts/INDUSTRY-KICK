#!/usr/bin/env bash
set -euo pipefail
echo "INDUSTRY KICK V2 - Stage 6.1 Build Gate"
command -v faust >/dev/null || { echo "FAUST_NOT_FOUND"; exit 2; }
faust -v
JUCE_ARGS=()
if [[ -n "${JUCE_SOURCE_DIR:-}" ]]; then
  JUCE_ARGS+=("-DINDUSTRY_KICK_JUCE_SOURCE_DIR=${JUCE_SOURCE_DIR}")
  echo "Using local JUCE: ${JUCE_SOURCE_DIR}"
else
  echo "JUCE_SOURCE_DIR not set; CMake will fetch JUCE 8.0.6."
fi
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release "${JUCE_ARGS[@]}"
cmake --build build --target KICKCRAFTER_DspSmoke
( cd build && ./KICKCRAFTER_DspSmoke_artefacts/Release/"INDUSTRY KICK DSP Smoke" )
cmake --build build --target KICKCRAFTER_VST3
echo "STAGE_6_1_BUILD_GATE_COMPLETE"
