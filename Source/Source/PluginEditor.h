#pragma once
#include <JuceHeader.h>
#include "PluginProcessor.h"

class KickcrafterAudioProcessorEditor final : public juce::AudioProcessorEditor, private juce::Timer
{
public:
    explicit KickcrafterAudioProcessorEditor(KickcrafterAudioProcessor&);
    ~KickcrafterAudioProcessorEditor() override;
    void paint(juce::Graphics&) override;
    void resized() override;
private:
    enum class Unit { percent,hz,ms,db };
    struct IndustrialLook final : juce::LookAndFeel_V4
    {
        IndustrialLook();
        void drawRotarySlider(juce::Graphics&,int,int,int,int,float,float,float,juce::Slider&) override;
        void drawButtonBackground(juce::Graphics&,juce::Button&,const juce::Colour&,bool,bool) override;
        void drawComboBox(juce::Graphics&,int,int,bool,int,int,int,int,juce::ComboBox&) override;
    } look;
    struct ExportPad final : juce::Component
    {
        explicit ExportPad(KickcrafterAudioProcessor& p):proc(p){}
        void paint(juce::Graphics&) override;
        void mouseDown(const juce::MouseEvent&) override;
        void mouseDrag(const juce::MouseEvent&) override;
        KickcrafterAudioProcessor& proc; bool armed=false;
    } exportPad;
    using SA=juce::AudioProcessorValueTreeState::SliderAttachment;
    using CA=juce::AudioProcessorValueTreeState::ComboBoxAttachment;
    KickcrafterAudioProcessor& proc;
    std::vector<std::unique_ptr<juce::Slider>> knobs;
    std::vector<std::unique_ptr<SA>> sliderAttachments;
    juce::ComboBox waveformSelect,chamberSelect,presetBox;
    std::unique_ptr<CA> waveformAttachment,chamberAttachment;
    juce::TextButton preview{"TRIGGER"},randomizeBtn{"RANDOMIZER"},presetPrevBtn{"-"},presetNextBtn{"+"},saveBtn{"SAVE"},undoBtn{"UNDO"},redoBtn{"REDO"};
    juce::Label title,maker,tagline;
    juce::Image chamberAtlas,backgroundImage;
    juce::Rectangle<int> scopeArea,chamberArea,waveformArea,meterArea;
    float meterL=0.0f,meterR=0.0f;
    static constexpr float baseW=1440.0f,baseH=920.0f;
    void addKnob(const char*,const char*,Unit,const char* style="");
    void refreshPresets();
    void stepPreset(int);
    void timerCallback() override;
    juce::Rectangle<int> R(float,float,float,float) const;
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(KickcrafterAudioProcessorEditor)
};
