#pragma once
#include <JuceHeader.h>
#include "FaustKickEngine.h"

class KickcrafterAudioProcessor final : public juce::AudioProcessor, private juce::Timer
{
public:
    KickcrafterAudioProcessor();
    ~KickcrafterAudioProcessor() override = default;
    void prepareToPlay(double, int) override;
    void releaseResources() override {}
    bool isBusesLayoutSupported(const BusesLayout&) const override;
    void processBlock(juce::AudioBuffer<float>&, juce::MidiBuffer&) override;
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override { return true; }
    const juce::String getName() const override { return JucePlugin_Name; }
    bool acceptsMidi() const override { return true; }
    bool producesMidi() const override { return false; }
    bool isMidiEffect() const override { return false; }
    double getTailLengthSeconds() const override { return 3.0; }
    int getNumPrograms() override { return 1; }
    int getCurrentProgram() override { return 0; }
    void setCurrentProgram(int) override {}
    const juce::String getProgramName(int) override { return {}; }
    void changeProgramName(int, const juce::String&) override {}
    void getStateInformation(juce::MemoryBlock&) override;
    void setStateInformation(const void*, int) override;

    static juce::AudioProcessorValueTreeState::ParameterLayout createLayout();
    juce::AudioProcessorValueTreeState apvts;
    juce::UndoManager undo;
    void triggerPreview();
    void shape(); void evolve(); void destroy();
    void savePreset(const juce::String&);
    void loadPreset(const juce::File&);
    juce::Array<juce::File> presets() const;
    juce::StringArray factoryPresetNames() const;
    void loadFactoryPreset(int);
    void randomizeParameters();
    void copyToSlot(char); void recallSlot(char);
    bool exportWav(const juce::File&);
    std::array<float,1024> getScope() const;
    float getOutputPeakL() { return outputPeakL.exchange(0.0f,std::memory_order_relaxed); }
    float getOutputPeakR() { return outputPeakR.exchange(0.0f,std::memory_order_relaxed); }

private:
    FaustKickEngine faustKick;


    double sampleRate=44100.0;
    int preparedBlockSize=512;
    float reverbHpX=0,reverbHpY=0,dryEnvelope=0;
    float monoLowL=0,monoLowR=0,dcXL=0,dcYL=0,dcXR=0,dcYR=0;
    std::vector<float> reverbDelay;
    size_t reverbDelayPos=0;
    double reverbAgeSeconds=0.0;
    juce::AudioBuffer<float> faustBuffer,reverbBuffer,envelopeBuffer;
    std::array<std::unique_ptr<juce::dsp::Convolution>,20> convolutions;
    std::array<std::atomic<float>,1024> scope {};
    int scopeCaptureIndex=0,scopeDecimationCounter=0;
    float scopeAccumulator=0.0f;
    std::atomic<float> outputPeakL {0.0f},outputPeakR {0.0f};
    juce::ValueTree slotA,slotB;
    std::atomic<bool> previewPending {false};

    void noteOn(float); void resetDspState(); void buildImpulseResponses();
    void timerCallback() override {}
    juce::File presetDir() const;
    void set(const char*,double);
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(KickcrafterAudioProcessor)
};
