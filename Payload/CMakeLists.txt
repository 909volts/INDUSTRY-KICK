cmake_minimum_required(VERSION 3.22)
project(KICKCRAFTER VERSION 2.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# -----------------------------------------------------------------------------
# INDUSTRY KICK V2 core DSP — Faust generated C++ header
# Faust is required only at build time. The generated header is self-contained
# (-i) so the finished VST3/Standalone has no Faust runtime dependency.
# -----------------------------------------------------------------------------
find_program(FAUST_EXECUTABLE NAMES faust)
if(NOT FAUST_EXECUTABLE)
    message(FATAL_ERROR
        "Faust compiler not found. Install Faust 2.80+ and ensure 'faust' is on PATH. "
        "INDUSTRY KICK V2 keeps the approved kick core in Faust by design.")
endif()

set(INDUSTRY_KICK_FAUST_DSP
    ${CMAKE_CURRENT_SOURCE_DIR}/Faust/IndustryKickV2_R4_Freeze.dsp)
set(INDUSTRY_KICK_FAUST_ARCH
    ${CMAKE_CURRENT_SOURCE_DIR}/Faust/faustMinimal.h)
set(INDUSTRY_KICK_FAUST_GENERATED_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/generated)
set(INDUSTRY_KICK_FAUST_HEADER
    ${INDUSTRY_KICK_FAUST_GENERATED_DIR}/IndustryKickFaustDSP.h)

file(MAKE_DIRECTORY ${INDUSTRY_KICK_FAUST_GENERATED_DIR})

# Faust -ftz 2 uses mask-based software denormal flushing. With Faust 2.85.9
# it can generate MSVC-invalid expressions such as taking the address of a
# negated temporary (&-fTempN). Use the fabs-based FTZ mode on MSVC; keep the
# faster mask mode on compilers where that codegen is valid.
if(MSVC)
    set(INDUSTRY_KICK_FAUST_FTZ_MODE 1)
else()
    set(INDUSTRY_KICK_FAUST_FTZ_MODE 2)
endif()
message(STATUS "INDUSTRY KICK Faust FTZ mode: ${INDUSTRY_KICK_FAUST_FTZ_MODE}")

add_custom_command(
    OUTPUT ${INDUSTRY_KICK_FAUST_HEADER}
    COMMAND ${FAUST_EXECUTABLE}
            -double
            -ftz ${INDUSTRY_KICK_FAUST_FTZ_MODE}
            -i
            -a ${INDUSTRY_KICK_FAUST_ARCH}
            -cn IndustryKickFaustDSP
            -o ${INDUSTRY_KICK_FAUST_HEADER}
            ${INDUSTRY_KICK_FAUST_DSP}
    DEPENDS
        ${INDUSTRY_KICK_FAUST_DSP}
        ${INDUSTRY_KICK_FAUST_ARCH}
    COMMENT "Generating INDUSTRY KICK V2 DSP from Faust"
    VERBATIM)

add_custom_target(INDUSTRY_KICK_FaustDSP
    DEPENDS ${INDUSTRY_KICK_FAUST_HEADER})


# JUCE can be supplied locally for deterministic/offline builds.
# Example:
#   cmake -S . -B build -DINDUSTRY_KICK_JUCE_SOURCE_DIR=C:/SDK/JUCE
set(INDUSTRY_KICK_JUCE_SOURCE_DIR "" CACHE PATH
    "Optional path to a local JUCE source tree. If empty, JUCE 8.0.6 is fetched.")

if(INDUSTRY_KICK_JUCE_SOURCE_DIR)
    if(NOT EXISTS "${INDUSTRY_KICK_JUCE_SOURCE_DIR}/CMakeLists.txt")
        message(FATAL_ERROR
            "INDUSTRY_KICK_JUCE_SOURCE_DIR does not point to a JUCE source tree: "
            "${INDUSTRY_KICK_JUCE_SOURCE_DIR}")
    endif()
    add_subdirectory("${INDUSTRY_KICK_JUCE_SOURCE_DIR}"
                     "${CMAKE_CURRENT_BINARY_DIR}/JUCE")
else()
    include(FetchContent)
    FetchContent_Declare(JUCE
        GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
        GIT_TAG 8.0.6)
    FetchContent_MakeAvailable(JUCE)
endif()

juce_add_plugin(KICKCRAFTER
    COMPANY_NAME "909VOLTS"
    BUNDLE_ID "audio.909volts.industrykick"
    PLUGIN_MANUFACTURER_CODE Gstn
    PLUGIN_CODE Kc01
    FORMATS VST3 Standalone
    PRODUCT_NAME "INDUSTRY KICK"
    IS_SYNTH TRUE
    NEEDS_MIDI_INPUT TRUE
    NEEDS_MIDI_OUTPUT FALSE
    IS_MIDI_EFFECT FALSE
    COPY_PLUGIN_AFTER_BUILD FALSE)

target_sources(KICKCRAFTER PRIVATE
    Source/PluginProcessor.cpp
    Source/PluginProcessor.h
    Source/FaustKickEngine.cpp
    Source/FaustKickEngine.h
    Source/FactoryPresets.h
    Source/PluginEditor.cpp
    Source/PluginEditor.h
    ${INDUSTRY_KICK_FAUST_HEADER})

set_source_files_properties(${INDUSTRY_KICK_FAUST_HEADER}
    PROPERTIES GENERATED TRUE)

add_dependencies(KICKCRAFTER INDUSTRY_KICK_FaustDSP)

target_include_directories(KICKCRAFTER PRIVATE
    ${INDUSTRY_KICK_FAUST_GENERATED_DIR})

juce_add_binary_data(KICKCRAFTERAssets
    HEADER_NAME BinaryData.h
    NAMESPACE BinaryData
    SOURCES
        Assets/reverb-chambers-v1.png
        Assets/plugin-background-brutalist-v1.png
        Assets/IR/tight_airlock.wav
        Assets/IR/tight_booth.wav
        Assets/IR/tight_drum_cell.wav
        Assets/IR/tight_concrete_box.wav
        Assets/IR/tight_short_plate.wav
        Assets/IR/room_studio.wav
        Assets/IR/room_concrete.wav
        Assets/IR/room_stone_chamber.wav
        Assets/IR/room_warehouse.wav
        Assets/IR/room_hangar.wav
        Assets/IR/passage_corridor.wav
        Assets/IR/passage_tunnel.wav
        Assets/IR/passage_sewer.wav
        Assets/IR/passage_service_shaft.wav
        Assets/IR/passage_underground.wav
        Assets/IR/metal_steel_plate.wav
        Assets/IR/metal_oil_tank.wav
        Assets/IR/metal_container.wav
        Assets/IR/metal_reactor.wav
        Assets/IR/metal_abyss.wav)

target_compile_definitions(KICKCRAFTER PUBLIC
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_VST3_CAN_REPLACE_VST2=0)

target_link_libraries(KICKCRAFTER PRIVATE
    KICKCRAFTERAssets
    juce::juce_audio_utils
    juce::juce_dsp
    PUBLIC juce::juce_recommended_config_flags
           juce::juce_recommended_lto_flags
           juce::juce_recommended_warning_flags)

option(KICKCRAFTER_ASAN "Enable AddressSanitizer for diagnostics" OFF)
if(KICKCRAFTER_ASAN AND MSVC)
    target_compile_options(KICKCRAFTER PRIVATE /fsanitize=address /Zi)
    target_compile_options(KICKCRAFTER_Standalone PRIVATE /fsanitize=address /Zi)
    target_compile_options(KICKCRAFTER_VST3 PRIVATE /fsanitize=address /Zi)
    target_link_options(KICKCRAFTER_Standalone PRIVATE /DEBUG)
    target_link_options(KICKCRAFTER_VST3 PRIVATE /DEBUG)
endif()

juce_generate_juce_header(KICKCRAFTER)

option(KICKCRAFTER_BUILD_TESTS "Build the non-GUI DSP smoke test" ON)
if(KICKCRAFTER_BUILD_TESTS)
    juce_add_console_app(KICKCRAFTER_DspSmoke PRODUCT_NAME "INDUSTRY KICK DSP Smoke")
    target_sources(KICKCRAFTER_DspSmoke PRIVATE Tests/DspSmoke.cpp)
    target_include_directories(KICKCRAFTER_DspSmoke PRIVATE
        ${INDUSTRY_KICK_FAUST_GENERATED_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}/KICKCRAFTER_artefacts/JuceLibraryCode
        ${CMAKE_CURRENT_BINARY_DIR}/juce_binarydata_KICKCRAFTERAssets/JuceLibraryCode)

    # DspSmoke includes PluginProcessor.h -> FaustKickEngine.h -> the generated
    # Faust header. KICKCRAFTER's generated include directory is PRIVATE, so
    # expose it explicitly to the smoke-test target and order generation first.
    add_dependencies(KICKCRAFTER_DspSmoke INDUSTRY_KICK_FaustDSP)
    target_link_libraries(KICKCRAFTER_DspSmoke PRIVATE KICKCRAFTER juce::juce_audio_utils juce::juce_dsp)
endif()


# -----------------------------------------------------------------------------
# Stage 6.8D exact pre-safety diagnostic. This does not alter DSP/audio output.
# -----------------------------------------------------------------------------
if(KICKCRAFTER_BUILD_TESTS)
    juce_add_console_app(KICKCRAFTER_SafetyProbe
        PRODUCT_NAME "INDUSTRY KICK Safety Probe")
    target_sources(KICKCRAFTER_SafetyProbe PRIVATE Tests/SafetyProbe.cpp)
    target_include_directories(KICKCRAFTER_SafetyProbe PRIVATE
        ${INDUSTRY_KICK_FAUST_GENERATED_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}/KICKCRAFTER_artefacts/JuceLibraryCode
        ${CMAKE_CURRENT_BINARY_DIR}/juce_binarydata_KICKCRAFTERAssets/JuceLibraryCode)
    add_dependencies(KICKCRAFTER_SafetyProbe INDUSTRY_KICK_FaustDSP)
    target_link_libraries(KICKCRAFTER_SafetyProbe PRIVATE
        KICKCRAFTER
        juce::juce_audio_utils
        juce::juce_dsp)
endif()
