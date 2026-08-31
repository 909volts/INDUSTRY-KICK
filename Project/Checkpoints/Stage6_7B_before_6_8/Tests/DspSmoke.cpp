#include <JuceHeader.h>
#include "../Source/PluginProcessor.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
#include <fstream>
#include <set>
#include <vector>

struct RenderMetrics
{
    double peak = 0.0;
    double rms = 0.0;
    double lateRms = 0.0;
    double dc = 0.0;
    bool finite = true;
};

struct RenderResult
{
    RenderMetrics metrics;
    std::vector<float> mono;
};

static void setParameter(KickcrafterAudioProcessor& p, const char* id, float plain)
{
    if (auto* parameter = p.apvts.getParameter(id))
        parameter->setValueNotifyingHost(parameter->convertTo0to1(plain));
}

static RenderResult render(KickcrafterAudioProcessor& p,
                           double sampleRate,
                           int blockSize,
                           double seconds,
                           int triggerOffset = 0)
{
    const int total = static_cast<int>(std::ceil(sampleRate * seconds));
    RenderResult result;
    result.mono.reserve((size_t)total);

    double sum = 0.0;
    double late = 0.0;
    int count = 0;
    int lateCount = 0;

    for (int pos = 0; pos < total; pos += blockSize)
    {
        const int n = juce::jmin(blockSize, total - pos);
        juce::AudioBuffer<float> audio(2, n);
        juce::MidiBuffer midi;

        if (triggerOffset >= pos && triggerOffset < pos + n)
            midi.addEvent(juce::MidiMessage::noteOn(1, 60, (juce::uint8)127), triggerOffset - pos);

        p.processBlock(audio, midi);

        for (int i = 0; i < n; ++i)
        {
            const float l = audio.getSample(0, i);
            const float r = audio.getSample(1, i);
            result.metrics.finite = result.metrics.finite && std::isfinite(l) && std::isfinite(r);
            result.metrics.peak = juce::jmax(result.metrics.peak,
                                             (double)juce::jmax(std::abs(l), std::abs(r)));
            const double m = (l + r) * 0.5;
            result.mono.push_back((float)m);
            sum += m * m;
            ++count;

            const double t = (pos + i - triggerOffset) / sampleRate;
            if (t > 0.65 && t < 0.90)
            {
                late += m * m;
                ++lateCount;
            }
        }
    }

    result.metrics.rms = std::sqrt(sum / juce::jmax(1, count));
    result.metrics.lateRms = std::sqrt(late / juce::jmax(1, lateCount));
    if (!result.mono.empty())
    {
        double mean = 0.0;
        for (const auto s : result.mono) mean += s;
        result.metrics.dc = mean / (double)result.mono.size();
    }
    return result;
}

static double differenceRms(const RenderResult& a, const RenderResult& b)
{
    const auto n = std::min(a.mono.size(), b.mono.size());
    if (n == 0) return 0.0;

    double sum = 0.0;
    for (size_t i = 0; i < n; ++i)
    {
        const double d = a.mono[i] - b.mono[i];
        sum += d * d;
    }
    return std::sqrt(sum / (double)n);
}


static bool writeMonoWav(const juce::File& file,
                         const RenderResult& result,
                         double sampleRate)
{
    if (result.mono.empty())
        return false;

    juce::AudioBuffer<float> audio(1, (int)result.mono.size());
    audio.copyFrom(0, 0, result.mono.data(), (int)result.mono.size());

    auto stream = file.createOutputStream();
    if (!stream)
        return false;

    juce::WavAudioFormat wav;
    auto writer = std::unique_ptr<juce::AudioFormatWriter>(
        wav.createWriterFor(stream.release(), sampleRate, 1, 24, {}, 0));

    return writer != nullptr
        && writer->writeFromAudioSampleBuffer(audio, 0, audio.getNumSamples());
}

static double rmsDbWindow(const RenderResult& r,
                          double sampleRate,
                          double startSeconds,
                          double endSeconds)
{
    if (r.mono.empty() || sampleRate <= 0.0)
        return -300.0;

    const auto a = juce::jlimit<size_t>(0, r.mono.size(),
        static_cast<size_t>(std::floor(startSeconds * sampleRate)));
    const auto b = juce::jlimit<size_t>(a, r.mono.size(),
        static_cast<size_t>(std::floor(endSeconds * sampleRate)));
    if (b <= a)
        return -300.0;

    double sum = 0.0;
    for (size_t i = a; i < b; ++i)
        sum += static_cast<double>(r.mono[i]) * static_cast<double>(r.mono[i]);

    const double rms = std::sqrt(sum / static_cast<double>(b - a));
    return 20.0 * std::log10(juce::jmax(1.0e-15, rms));
}

static double meanWindow(const RenderResult& r,
                         double sampleRate,
                         double startSeconds,
                         double endSeconds)
{
    if (r.mono.empty() || sampleRate <= 0.0)
        return 0.0;

    const auto a = juce::jlimit<size_t>(0, r.mono.size(),
        static_cast<size_t>(std::floor(startSeconds * sampleRate)));
    const auto b = juce::jlimit<size_t>(a, r.mono.size(),
        static_cast<size_t>(std::floor(endSeconds * sampleRate)));
    if (b <= a)
        return 0.0;

    double sum = 0.0;
    for (size_t i = a; i < b; ++i)
        sum += static_cast<double>(r.mono[i]);

    return sum / static_cast<double>(b - a);
}

static double residualDecayDropDb(const RenderResult& r, double sampleRate)
{
    const double earlier = rmsDbWindow(r, sampleRate, 3.0, 3.5);
    const double finalDb = rmsDbWindow(r, sampleRate, 6.5, 7.0);
    return earlier - finalDb;
}

static bool residualSafetyPass(const RenderResult& r, double sampleRate)
{
    // Stage 6.7B:
    // Long ROUND/INDUSTRIAL envelopes are intentional. A fixed -50 dBFS check
    // at 3.5-4.0 s incorrectly classifies a legitimate decaying kick as a
    // runaway. Test persistent residue only after the longest designed tau
    // has had enough time to decay, and also require the tail to keep falling.
    const double finalTailRmsDb = rmsDbWindow(r, sampleRate, 6.5, 7.0);
    const double finalTailMean  = meanWindow(r, sampleRate, 6.5, 7.0);
    const double decayDropDb    = residualDecayDropDb(r, sampleRate);

    return std::isfinite(finalTailRmsDb)
        && std::isfinite(finalTailMean)
        && std::isfinite(decayDropDb)
        && finalTailRmsDb < -55.0
        && std::abs(finalTailMean) < 1.0e-4
        && decayDropDb > 12.0;
}

static bool envelopeParityPass(const RenderResult& r,
                               double sampleRate,
                               const std::array<double, 5>& targetDb)
{
    const std::array<std::pair<double,double>,5> windows {{
        {0.000,0.030}, {0.030,0.080}, {0.080,0.180}, {0.180,0.400}, {0.650,0.750}
    }};
    const std::array<double,5> tolerances {{ 2.5, 2.5, 3.0, 3.5, 4.5 }};

    for (size_t i = 0; i < windows.size(); ++i)
    {
        const auto measured = rmsDbWindow(r, sampleRate,
                                          windows[i].first, windows[i].second);
        if (std::abs(measured - targetDb[i]) > tolerances[i])
            return false;
    }
    return true;
}

static double waveformCorrelation(const RenderResult& a, const RenderResult& b)
{
    const auto n = std::min(a.mono.size(), b.mono.size());
    if (n < 2) return 1.0;

    double ma = 0.0, mb = 0.0;
    for (size_t i = 0; i < n; ++i) { ma += a.mono[i]; mb += b.mono[i]; }
    ma /= static_cast<double>(n);
    mb /= static_cast<double>(n);

    double num = 0.0, da = 0.0, db = 0.0;
    for (size_t i = 0; i < n; ++i)
    {
        const double xa = static_cast<double>(a.mono[i]) - ma;
        const double xb = static_cast<double>(b.mono[i]) - mb;
        num += xa * xb;
        da += xa * xa;
        db += xb * xb;
    }

    return num / std::sqrt(juce::jmax(1.0e-30, da * db));
}

static std::vector<double> smoothedAbsEnvelope(const RenderResult& r, double sampleRate)
{
    std::vector<double> env;
    env.resize(r.mono.size());
    if (r.mono.empty() || sampleRate <= 0.0)
        return env;

    const double a = std::exp(-1.0 / (0.005 * sampleRate)); // 5 ms detector
    double state = 0.0;
    for (size_t i = 0; i < r.mono.size(); ++i)
    {
        state = a * state + (1.0 - a) * std::abs(static_cast<double>(r.mono[i]));
        env[i] = state;
    }
    return env;
}

static double vectorCorrelation(const std::vector<double>& a,
                                const std::vector<double>& b)
{
    const auto n = std::min(a.size(), b.size());
    if (n < 2) return 1.0;

    double ma = 0.0, mb = 0.0;
    for (size_t i = 0; i < n; ++i) { ma += a[i]; mb += b[i]; }
    ma /= static_cast<double>(n);
    mb /= static_cast<double>(n);

    double num = 0.0, da = 0.0, db = 0.0;
    for (size_t i = 0; i < n; ++i)
    {
        const double xa = a[i] - ma;
        const double xb = b[i] - mb;
        num += xa * xb;
        da += xa * xa;
        db += xb * xb;
    }
    return num / std::sqrt(juce::jmax(1.0e-30, da * db));
}

static double crestDb(const RenderResult& r)
{
    if (r.metrics.peak <= 0.0 || r.metrics.rms <= 0.0)
        return 0.0;
    return 20.0 * std::log10(r.metrics.peak / r.metrics.rms);
}

static double nearPeakPercent(const RenderResult& r, double fraction)
{
    if (r.mono.empty() || r.metrics.peak <= 0.0)
        return 0.0;
    const double threshold = r.metrics.peak * fraction;
    size_t count = 0;
    for (const auto s : r.mono)
        if (std::abs(static_cast<double>(s)) >= threshold)
            ++count;
    return 100.0 * static_cast<double>(count) / static_cast<double>(r.mono.size());
}

static bool technicalPass(const RenderResult& r)
{
    constexpr double ceiling = 0.9230; // V2 safety ceiling is -0.70 dBFS.
    return r.metrics.finite
        && r.metrics.peak > 1.0e-4
        && r.metrics.peak <= ceiling
        && std::isfinite(r.metrics.rms)
        && r.metrics.rms > 1.0e-7;
}

int main()
{
    juce::ScopedJuceInitialiser_GUI juce;

    bool ok = true;

    // ---------------------------------------------------------------------
    // Stable public identity / factory bank
    // ---------------------------------------------------------------------
    KickcrafterAudioProcessor bankCheck;
    const auto names = bankCheck.factoryPresetNames();
    std::set<juce::String> uniqueNames;
    for (const auto& name : names) uniqueNames.insert(name);

    const bool bankShape = names.size() == 50 && uniqueNames.size() == 50;
    ok = ok && bankShape;
    std::cout << "factoryBank=" << bankShape << " count=" << names.size() << "\n";

    // ---------------------------------------------------------------------
    // Approved A anchors are the first preset of each 10-preset family.
    // Technical checks are performed at several rates and buffer sizes.
    // ---------------------------------------------------------------------
    constexpr std::array<int, 5> anchorIndices { 0, 10, 20, 30, 40 };
    // User-approved Stage 6.6/6.6B offline family targets:
    // RMS dB in [0-30, 30-80, 80-180, 180-400, 650-750] ms.
    constexpr std::array<std::array<double,5>,5> approvedEnvelopeTargets {{
        {{ -4.0573, -4.7207, -5.0395,  -5.7670,  -9.1321 }},  // ROUND
        {{ -3.9196, -5.1023, -8.8398, -16.7307, -45.3546 }},  // PUNCH
        {{ -3.5766, -4.1659, -5.2209,  -6.4106,  -9.7924 }},  // HARD less-sat
        {{ -3.8594, -4.2853, -4.7432,  -5.9012,  -7.8399 }},  // INDUSTRIAL less-sat
        {{ -6.3548, -5.4087, -5.1895,  -7.2628, -17.3893 }}   // RAVE
    }};
    constexpr std::array<double, 3> sampleRates { 44100.0, 48000.0, 96000.0 };
    constexpr std::array<int, 3> blockSizes { 64, 256, 1024 };

    for (const auto sr : sampleRates)
    {
        for (const auto block : blockSizes)
        {
            for (const auto presetIndex : anchorIndices)
            {
                KickcrafterAudioProcessor p;
                p.loadFactoryPreset(presetIndex);
                p.prepareToPlay(sr, block);
                const auto r = render(p, sr, block, 1.0, 0);
                const bool pass = technicalPass(r);
                ok = ok && pass;

                const auto it = std::find(anchorIndices.begin(), anchorIndices.end(), presetIndex);
                const auto familySlot = static_cast<size_t>(std::distance(anchorIndices.begin(), it));
                const bool parity = envelopeParityPass(r, sr, approvedEnvelopeTargets[familySlot]);
                if (sr == 48000.0 && block == 256)
                    ok = ok && parity;

                std::cout << "anchor preset=" << presetIndex
                          << " sr=" << sr
                          << " block=" << block
                          << " technical=" << pass
                          << " parity=" << parity
                          << " peak=" << r.metrics.peak
                          << " rms=" << r.metrics.rms
                          << " dc=" << r.metrics.dc
                          << " late=" << r.metrics.lateRms
                          << " w0_30=" << rmsDbWindow(r,sr,0.000,0.030)
                          << " w30_80=" << rmsDbWindow(r,sr,0.030,0.080)
                          << " w80_180=" << rmsDbWindow(r,sr,0.080,0.180)
                          << " w180_400=" << rmsDbWindow(r,sr,0.180,0.400)
                          << " w650_750=" << rmsDbWindow(r,sr,0.650,0.750)
                          << "\n";
            }
        }
    }

    // ---------------------------------------------------------------------
    // Persistent DC / runaway-tail safety after the musical event decays.
    // ---------------------------------------------------------------------
    bool anchorResidualSafe = true;
    for (const auto presetIndex : anchorIndices)
    {
        KickcrafterAudioProcessor p;
        p.loadFactoryPreset(presetIndex);
        p.prepareToPlay(48000.0, 256);
        const auto r = render(p, 48000.0, 256, 7.0, 0);
        const bool pass = residualSafetyPass(r, 48000.0);
        anchorResidualSafe = anchorResidualSafe && pass;

        std::cout << "anchorResidual preset=" << presetIndex
                  << " pass=" << pass
                  << " tailRmsDb=" << rmsDbWindow(r,48000.0,6.5,7.0)
                  << " tailMean=" << meanWindow(r,48000.0,6.5,7.0)
                  << " decayDropDb=" << residualDecayDropDb(r,48000.0)
                  << "\n";
    }
    ok = ok && anchorResidualSafe;

    // ---------------------------------------------------------------------
    // Block-size invariance at 48 kHz. A synth kick should not materially
    // change merely because the host buffer changes.
    // ---------------------------------------------------------------------
    {
        bool blockInvariant = true;
        constexpr std::array<int, 3> parityBlocks { 64, 256, 1024 };
        for (const auto presetIndex : anchorIndices)
        {
            std::array<RenderResult, 3> renders {};
            for (size_t i = 0; i < parityBlocks.size(); ++i)
            {
                KickcrafterAudioProcessor p;
                p.loadFactoryPreset(presetIndex);
                p.prepareToPlay(48000.0, parityBlocks[i]);
                renders[i] = render(p, 48000.0, parityBlocks[i], 0.80, 0);
            }

            const auto d01 = differenceRms(renders[0], renders[1]);
            const auto d12 = differenceRms(renders[1], renders[2]);
            const bool pass = d01 < 2.0e-5 && d12 < 2.0e-5;
            blockInvariant = blockInvariant && pass;
            std::cout << "blockInvariant preset=" << presetIndex
                      << " pass=" << pass
                      << " d64_256=" << d01
                      << " d256_1024=" << d12 << "\\n";
        }
        ok = ok && blockInvariant;
    }

    // ---------------------------------------------------------------------
    // Reset repeatability. Resetting/preparing a fresh processor with the
    // same preset must reproduce the same deterministic kick.
    // ---------------------------------------------------------------------
    {
        bool repeatable = true;
        for (const auto presetIndex : anchorIndices)
        {
            KickcrafterAudioProcessor a;
            a.loadFactoryPreset(presetIndex);
            a.prepareToPlay(48000.0, 256);
            const auto ra = render(a, 48000.0, 256, 0.80, 0);

            KickcrafterAudioProcessor b;
            b.loadFactoryPreset(presetIndex);
            b.prepareToPlay(48000.0, 256);
            const auto rb = render(b, 48000.0, 256, 0.80, 0);

            const auto diff = differenceRms(ra, rb);
            const bool pass = diff < 1.0e-7;
            repeatable = repeatable && pass;
            std::cout << "repeatability preset=" << presetIndex
                      << " pass=" << pass << " diff=" << diff << "\\n";
        }
        ok = ok && repeatable;
    }

    // ---------------------------------------------------------------------
    // Sample-accurate MIDI onset: no output should precede a note-on.
    // ---------------------------------------------------------------------
    {
        KickcrafterAudioProcessor p;
        p.loadFactoryPreset(0);
        p.prepareToPlay(48000.0, 256);
        constexpr int onset = 91;
        const auto r = render(p, 48000.0, 256, 0.20, onset);
        double prePeak = 0.0;
        for (int i = 0; i < onset && i < (int)r.mono.size(); ++i)
            prePeak = juce::jmax(prePeak, (double)std::abs(r.mono[(size_t)i]));
        const bool pass = prePeak < 1.0e-7;
        ok = ok && pass;
        std::cout << "sampleAccurateOnset=" << pass << " prePeak=" << prePeak << "\n";
    }

    // ---------------------------------------------------------------------
    // Family separation: routing plus objective envelope diversity.
    // This is still not a perceptual-quality claim; it catches families
    // collapsing back toward the same temporal identity.
    // ---------------------------------------------------------------------
    {
        std::array<RenderResult, 5> family {};
        std::array<std::vector<double>, 5> envelopes {};
        for (int i = 0; i < 5; ++i)
        {
            KickcrafterAudioProcessor p;
            p.loadFactoryPreset(anchorIndices[(size_t)i]);
            p.prepareToPlay(48000.0, 256);
            family[(size_t)i] = render(p, 48000.0, 256, 0.80, 0);
            envelopes[(size_t)i] = smoothedAbsEnvelope(family[(size_t)i], 48000.0);
        }

        bool routed = true;
        double maxEnvCorr = 0.0;
        double maxAbsWaveCorr = 0.0;
        for (int i = 0; i < 5; ++i)
        {
            std::cout << "familyAnchor index=" << i
                      << " crestDb=" << crestDb(family[(size_t)i])
                      << " nearPeak90=" << nearPeakPercent(family[(size_t)i], 0.90)
                      << "\n";

            for (int j = i + 1; j < 5; ++j)
            {
                routed = routed && differenceRms(family[(size_t)i], family[(size_t)j]) > 1.0e-4;
                const double ec = vectorCorrelation(envelopes[(size_t)i], envelopes[(size_t)j]);
                const double wc = std::abs(waveformCorrelation(family[(size_t)i], family[(size_t)j]));
                maxEnvCorr = juce::jmax(maxEnvCorr, ec);
                maxAbsWaveCorr = juce::jmax(maxAbsWaveCorr, wc);
                std::cout << "familyPair " << i << "-" << j
                          << " envCorr=" << ec
                          << " absWaveCorr=" << wc << "\n";
            }
        }

        const bool diversity = maxEnvCorr < 0.86;
        ok = ok && routed && diversity;
        std::cout << "familyRoutingSeparated=" << routed << "\n";
        std::cout << "familyEnvelopeDiversity=" << diversity
                  << " maxEnvCorr=" << maxEnvCorr
                  << " maxAbsWaveCorr=" << maxAbsWaveCorr << "\n";
    }

    // ---------------------------------------------------------------------
    // All 50 A-biased factory presets: finite, non-silent, under ceiling.
    // ---------------------------------------------------------------------
    {
        bool allPresets = true;
        for (int i = 0; i < names.size(); ++i)
        {
            KickcrafterAudioProcessor p;
            p.loadFactoryPreset(i);
            p.prepareToPlay(48000.0, 256);
            const auto r = render(p, 48000.0, 256, 7.0, 0);
            const bool basicTechnical = technicalPass(r);
            const bool residualSafe = residualSafetyPass(r, 48000.0);
            const bool presetTechnical = basicTechnical && residualSafe;
            allPresets = allPresets && presetTechnical;
            if (!presetTechnical)
                std::cout << "factoryFail index=" << i
                          << " name=" << names[i]
                          << " basic=" << basicTechnical
                          << " residual=" << residualSafe
                          << " peak=" << r.metrics.peak
                          << " rms=" << r.metrics.rms
                          << " eventMean=" << r.metrics.dc
                          << " tailRmsDb=" << rmsDbWindow(r,48000.0,6.5,7.0)
                          << " tailMean=" << meanWindow(r,48000.0,6.5,7.0)
                          << " decayDropDb=" << residualDecayDropDb(r,48000.0)
                          << "\n";

            for (auto* parameter : p.getParameters())
                allPresets = allPresets
                    && std::isfinite(parameter->getValue())
                    && parameter->getValue() >= 0.0f
                    && parameter->getValue() <= 1.0f;
        }
        ok = ok && allPresets;
        std::cout << "allFactoryPresetsTechnical=" << allPresets << "\n";
    }

    // ---------------------------------------------------------------------
    // Randomizer: local mutations around validated presets must remain safe.
    // ---------------------------------------------------------------------
    {
        bool randomSafe = true;
        for (int i = 0; i < 25; ++i)
        {
            KickcrafterAudioProcessor p;
            p.randomizeParameters();
            p.prepareToPlay(48000.0, 256);
            const auto r = render(p, 48000.0, 256, 7.0, 0);
            const bool basicTechnical = technicalPass(r);
            const bool residualSafe = residualSafetyPass(r, 48000.0);
            const bool pass = basicTechnical && residualSafe;
            randomSafe = randomSafe && pass;
            if (!pass)
                std::cout << "randomizerFail iteration=" << i
                          << " basic=" << basicTechnical
                          << " residual=" << residualSafe
                          << " peak=" << r.metrics.peak
                          << " rms=" << r.metrics.rms
                          << " eventMean=" << r.metrics.dc
                          << " tailRmsDb=" << rmsDbWindow(r,48000.0,6.5,7.0)
                          << " tailMean=" << meanWindow(r,48000.0,6.5,7.0)
                          << " decayDropDb=" << residualDecayDropDb(r,48000.0)
                          << "\n";
        }
        ok = ok && randomSafe;
        std::cout << "randomizerTechnical=" << randomSafe << "\n";
    }

    // ---------------------------------------------------------------------
    // APVTS state round-trip on V2-driving parameters.
    // ---------------------------------------------------------------------
    {
        KickcrafterAudioProcessor source;
        source.loadFactoryPreset(23);
        setParameter(source, "output", -2.0f);
        juce::MemoryBlock state;
        source.getStateInformation(state);

        KickcrafterAudioProcessor restored;
        restored.setStateInformation(state.getData(), (int)state.getSize());

        constexpr const char* ids[] {
            "waveform", "tune", "body", "punchAmount", "decay", "drive",
            "cabinet", "metal", "sub", "kick", "crunch", "shapeAmount",
            "evolveAmount", "destroyAmount", "clipper", "output"
        };

        bool same = true;
        for (const auto* id : ids)
        {
            const auto a = source.apvts.getRawParameterValue(id)->load();
            const auto b = restored.apvts.getRawParameterValue(id)->load();
            same = same && std::abs(a - b) < 1.0e-6f;
        }

        ok = ok && same;
        std::cout << "stateRoundTrip=" << same << "\n";
    }


    // ---------------------------------------------------------------------
    // Reproducible Stage 6.7 anchor renders for external diversity/parity analysis.
    // This is intentionally a non-realtime test-app operation.
    // ---------------------------------------------------------------------
    {
        const auto renderDir = juce::File::getCurrentWorkingDirectory()
                                   .getChildFile("Stage67TestRenders");
        const bool dirOk = renderDir.createDirectory().wasOk();
        bool renderExportOk = dirOk;

        const std::array<const char*, 5> fileNames {
            "01_ROUND_Clean_Weight.wav",
            "02_PUNCH_Clean_Attack.wav",
            "03_HARD_Hard_Clean.wav",
            "04_INDUSTRIAL_Industrial_Clean.wav",
            "05_RAVE_Rave_Foundation.wav"
        };

        std::ofstream csv(renderDir.getChildFile("anchor_metrics.csv")
                              .getFullPathName().toStdString());
        if (!csv)
            renderExportOk = false;
        else
            csv << "family,preset_index,peak,rms,late_rms,dc,finite,w0_30_db,w30_80_db,w80_180_db,w180_400_db,w650_750_db\n";

        for (size_t i = 0; i < anchorIndices.size(); ++i)
        {
            KickcrafterAudioProcessor p;
            p.loadFactoryPreset(anchorIndices[i]);
            p.prepareToPlay(48000.0, 256);
            const auto r = render(p, 48000.0, 256, 1.0, 0);

            const bool wavOk = writeMonoWav(renderDir.getChildFile(fileNames[i]), r, 48000.0);
            renderExportOk = renderExportOk && wavOk;

            if (csv)
                csv << i << ","
                    << anchorIndices[i] << ","
                    << r.metrics.peak << ","
                    << r.metrics.rms << ","
                    << r.metrics.lateRms << ","
                    << r.metrics.dc << ","
                    << (r.metrics.finite ? 1 : 0) << ","
                    << rmsDbWindow(r,48000.0,0.000,0.030) << ","
                    << rmsDbWindow(r,48000.0,0.030,0.080) << ","
                    << rmsDbWindow(r,48000.0,0.080,0.180) << ","
                    << rmsDbWindow(r,48000.0,0.180,0.400) << ","
                    << rmsDbWindow(r,48000.0,0.650,0.750) << "\n";
        }

        ok = ok && renderExportOk;
        std::cout << "anchorRenderExport=" << renderExportOk
                  << " path=" << renderDir.getFullPathName() << "\n";
    }

    // Space/IR sonic quality is intentionally NOT tested in Stage 6.
    std::cout << "spaceSonicValidation=NOT_TESTED\n";
    std::cout << "result=" << (ok ? "PASS" : "FAIL") << "\n";
    return ok ? 0 : 1;
}
