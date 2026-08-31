cmake_minimum_required(VERSION 3.22)
project(KICKCRAFTER VERSION 0.7.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(JUCE
    GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
    GIT_TAG 8.0.6)
FetchContent_MakeAvailable(JUCE)

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
    Source/FactoryPresets.h
    Source/PluginEditor.cpp
    Source/PluginEditor.h)

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
        ${CMAKE_CURRENT_BINARY_DIR}/KICKCRAFTER_artefacts/JuceLibraryCode
        ${CMAKE_CURRENT_BINARY_DIR}/juce_binarydata_KICKCRAFTERAssets/JuceLibraryCode)
    target_link_libraries(KICKCRAFTER_DspSmoke PRIVATE KICKCRAFTER juce::juce_audio_utils juce::juce_dsp)
endif()
