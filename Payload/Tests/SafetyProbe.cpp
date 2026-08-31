#include <JuceHeader.h>
#include "../Source/PluginProcessor.h"

#include <array>
#include <cmath>
#include <fstream>
#include <iomanip>
#include <iostream>

struct Metrics
{
    double peak = 0.0;
    double rms = 0.0;
    double safetyHitPercent = 0.0;
    bool finite = true;
};

static Metrics renderOne(KickcrafterAudioProcessor& p,
                         double sampleRate = 48000.0,
                         int blockSize = 256,
                         double seconds = 1.0)
{
    p.prepareToPlay(sampleRate, blockSize);

    constexpr double safetyCeiling = 0.9225714;
    const int total = static_cast<int>(std::ceil(sampleRate * seconds));

    double sum = 0.0;
    int count = 0;
    int hitCount = 0;
    Metrics m;

    for (int pos = 0; pos < total; pos += blockSize)
    {
        const int n = juce::jmin(blockSize, total - pos);
        juce::AudioBuffer<float> audio(2, n);
        juce::MidiBuffer midi;

        if (pos == 0)
            midi.addEvent(juce::MidiMessage::noteOn(1, 60, (juce::uint8)127), 0);

        p.processBlock(audio, midi);

        for (int i = 0; i < n; ++i)
        {
            const float l = audio.getSample(0, i);
            const float r = audio.getSample(1, i);

            m.finite = m.finite && std::isfinite(l) && std::isfinite(r);
            m.peak = juce::jmax(m.peak,
                               (double)juce::jmax(std::abs(l), std::abs(r)));

            const double mono = 0.5 * ((double)l + (double)r);
            sum += mono * mono;
            ++count;

            if (std::abs((double)l) >= safetyCeiling - 1.0e-6
                || std::abs((double)r) >= safetyCeiling - 1.0e-6)
                ++hitCount;
        }
    }

    m.rms = std::sqrt(sum / (double)juce::jmax(1, count));
    m.safetyHitPercent = 100.0 * (double)hitCount / (double)juce::jmax(1, count);
    return m;
}

static bool technicalPass(const Metrics& m)
{
    constexpr double maxPeak = 0.9230;
    constexpr double maxSafetyClampEngagementPercent = 0.10;

    return m.finite
        && std::isfinite(m.peak)
        && std::isfinite(m.rms)
        && std::isfinite(m.safetyHitPercent)
        && m.peak > 1.0e-4
        && m.peak <= maxPeak
        && m.rms > 1.0e-7
        && m.safetyHitPercent <= maxSafetyClampEngagementPercent;
}

int main()
{
    juce::ScopedJuceInitialiser_GUI juce;

    constexpr std::array<int, 7> previousFailures {
        26, 27, 70, 79, 226, 227, 229
    };

    const auto csvFile = juce::File::getCurrentWorkingDirectory()
        .getChildFile("Stage103HeavySafety.csv");

    std::ofstream csv(csvFile.getFullPathName().toStdString(),
                      std::ios::out | std::ios::trunc);
    if (!csv)
        return 2;

    csv << "index,name,family,heavy_slot,accent_bank,previous_failure,"
           "technical,peak,rms,safety_hit_pct\n";

    KickcrafterAudioProcessor namesProcessor;
    const auto names = namesProcessor.factoryPresetNames();

    bool allPass = names.size() == 250;
    double worstSafety = 0.0;
    int worstIndex = -1;
    int tested = 0;

    std::cout << std::fixed << std::setprecision(7);
    std::cout << "targetedGate=Stage10.3_HEAVY_ONLY\n";
    std::cout << "factoryCount=" << names.size() << "\n";
    std::cout << "validatorSafetyLimitPct=0.1000000\n";

    for (int family = 0; family < 5; ++family)
    {
        for (int slot = 0; slot < 10; ++slot)
        {
            const int index = family * 50 + 20 + slot;

            KickcrafterAudioProcessor p;
            p.loadFactoryPreset(index);

            const bool bankCorrect = p.getAccentBank() == 2;
            const auto m = renderOne(p);
            const bool pass = bankCorrect && technicalPass(m);

            bool wasFailure = false;
            for (const auto oldIndex : previousFailures)
                wasFailure = wasFailure || oldIndex == index;

            if (m.safetyHitPercent > worstSafety)
            {
                worstSafety = m.safetyHitPercent;
                worstIndex = index;
            }

            allPass = allPass && pass;
            ++tested;

            csv << index << ","
                << '"' << names[index].toStdString() << '"' << ","
                << family << ","
                << slot << ","
                << p.getAccentBank() << ","
                << (wasFailure ? 1 : 0) << ","
                << (pass ? 1 : 0) << ","
                << m.peak << ","
                << m.rms << ","
                << m.safetyHitPercent << "\n";

            std::cout << "heavy index=" << index
                      << " previousFailure=" << (wasFailure ? 1 : 0)
                      << " bank=" << p.getAccentBank()
                      << " technical=" << (pass ? 1 : 0)
                      << " peak=" << m.peak
                      << " safetyHitPct=" << m.safetyHitPercent
                      << "\n";
        }
    }

    csv.flush();

    std::cout << "heavyTested=" << tested << "\n";
    std::cout << "worstSafetyHitPct=" << worstSafety
              << " worstIndex=" << worstIndex << "\n";
    std::cout << "HEAVY_SAFETY_GATE=" << (allPass ? "PASS" : "FAIL") << "\n";
    std::cout << "result=" << (allPass ? "PASS" : "FAIL") << "\n";
    return allPass ? 0 : 1;
}
