#include <JuceHeader.h>
#include "../Source/PluginProcessor.h"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <string>
#include <vector>

struct ProbeResult
{
    double prePeak = 0.0;
    double postPeak = 0.0;
    double preOverPct = 0.0;
};

static ProbeResult probeRender(KickcrafterAudioProcessor& p,
                               double sampleRate = 48000.0,
                               int blockSize = 256,
                               double seconds = 1.0)
{
    p.prepareToPlay(sampleRate, blockSize);
    p.resetSafetyDiagnostics();
    p.setSafetyDiagnosticsEnabled(true);

    const int total = (int)std::ceil(sampleRate * seconds);
    double postPeak = 0.0;

    for(int pos=0; pos<total; pos+=blockSize)
    {
        const int n = juce::jmin(blockSize,total-pos);
        juce::AudioBuffer<float> audio(2,n);
        juce::MidiBuffer midi;

        if(pos==0)
            midi.addEvent(juce::MidiMessage::noteOn(1,60,(juce::uint8)127),0);

        p.processBlock(audio,midi);

        for(int i=0;i<n;++i)
            postPeak=juce::jmax(postPeak,
                (double)juce::jmax(std::abs(audio.getSample(0,i)),
                                   std::abs(audio.getSample(1,i))));
    }

    p.setSafetyDiagnosticsEnabled(false);

    const auto over = p.getPreSafetyOverCount();
    const auto frames = p.getPreSafetyFrameCount();

    ProbeResult r;
    r.prePeak = p.getPreSafetyPeak();
    r.postPeak = postPeak;
    r.preOverPct = 100.0 * (double)over / (double)juce::jmax<uint64_t>(1,frames);
    return r;
}

static double trimDbForTarget(double prePeak,double targetPeak)
{
    if(!(prePeak>0.0) || prePeak<=targetPeak)
        return 0.0;
    return 20.0*std::log10(targetPeak/prePeak);
}

int main()
{
    constexpr double targetFactoryPeak = 0.86; // diagnostic reference only
    constexpr double targetRandomPeak  = 0.82; // extra mutation margin

    KickcrafterAudioProcessor namesProcessor;
    const auto names = namesProcessor.factoryPresetNames();

    const auto csvFile = juce::File::getCurrentWorkingDirectory()
        .getChildFile("Stage68SafetyProbe.csv");

    std::ofstream csv(csvFile.getFullPathName().toStdString(),
                      std::ios::out|std::ios::trunc);

    if(!csv)
    {
        std::cerr << "Could not create " << csvFile.getFullPathName() << "\n";
        return 2;
    }

    csv << "kind,index,family,name,pre_safety_peak,post_peak,pre_over_pct,"
           "trim_db_to_0p86,trim_db_to_0p82\n";

    std::array<double,5> familyWorstPeak {0,0,0,0,0};
    std::array<double,5> familyWorstOver {0,0,0,0,0};

    std::cout << std::fixed << std::setprecision(7);

    for(int i=0;i<names.size();++i)
    {
        KickcrafterAudioProcessor p;
        p.loadFactoryPreset(i);
        const auto r=probeRender(p);
        const int family=i/10;

        familyWorstPeak[(size_t)family]=
            juce::jmax(familyWorstPeak[(size_t)family],r.prePeak);
        familyWorstOver[(size_t)family]=
            juce::jmax(familyWorstOver[(size_t)family],r.preOverPct);

        const auto t86=trimDbForTarget(r.prePeak,targetFactoryPeak);
        const auto t82=trimDbForTarget(r.prePeak,targetRandomPeak);

        csv << "factory," << i << "," << family << ","
            << '"' << names[i].toStdString() << '"' << ","
            << r.prePeak << "," << r.postPeak << "," << r.preOverPct << ","
            << t86 << "," << t82 << "\n";

        std::cout << "factory index=" << i
                  << " family=" << family
                  << " name=" << names[i]
                  << " prePeak=" << r.prePeak
                  << " postPeak=" << r.postPeak
                  << " preOverPct=" << r.preOverPct
                  << " trim86Db=" << t86 << "\n";
    }

    std::array<double,5> randomWorstPeak {0,0,0,0,0};
    std::array<double,5> randomWorstOver {0,0,0,0,0};

    for(int i=0;i<50;++i)
    {
        KickcrafterAudioProcessor p;
        p.randomizeParameters();
        const int family=juce::jlimit(0,4,
            (int)p.apvts.getRawParameterValue("waveform")->load());

        const auto r=probeRender(p);
        randomWorstPeak[(size_t)family]=
            juce::jmax(randomWorstPeak[(size_t)family],r.prePeak);
        randomWorstOver[(size_t)family]=
            juce::jmax(randomWorstOver[(size_t)family],r.preOverPct);

        csv << "random," << i << "," << family << ",\"random\","
            << r.prePeak << "," << r.postPeak << "," << r.preOverPct << ","
            << trimDbForTarget(r.prePeak,targetFactoryPeak) << ","
            << trimDbForTarget(r.prePeak,targetRandomPeak) << "\n";
    }

    csv.flush();

    std::cout << "\nFAMILY_WORST_FACTORY\n";
    for(int f=0;f<5;++f)
    {
        std::cout << "family=" << f
                  << " prePeak=" << familyWorstPeak[(size_t)f]
                  << " preOverPct=" << familyWorstOver[(size_t)f]
                  << " trim86Db="
                  << trimDbForTarget(familyWorstPeak[(size_t)f],targetFactoryPeak)
                  << "\n";
    }

    std::cout << "\nFAMILY_WORST_RANDOM_50\n";
    for(int f=0;f<5;++f)
    {
        std::cout << "family=" << f
                  << " prePeak=" << randomWorstPeak[(size_t)f]
                  << " preOverPct=" << randomWorstOver[(size_t)f]
                  << " trim82Db="
                  << trimDbForTarget(randomWorstPeak[(size_t)f],targetRandomPeak)
                  << "\n";
    }

    std::cout << "\nSAFETY_PROBE_CSV="
              << csvFile.getFullPathName() << "\n";
    std::cout << "SAFETY_PROBE_COMPLETE\n";
    return 0;
}
