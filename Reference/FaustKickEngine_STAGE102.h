#pragma once

#include <JuceHeader.h>
#include "IndustryKickFaustDSP.h"

// Thin realtime-safe bridge around the generated Faust DSP.
// MapUI is used only during prepare() to discover zones. Audio-thread updates
// write directly to cached FAUSTFLOAT pointers, avoiding string/map lookups.
class FaustKickEngine
{
public:
    struct Parameters
    {
        int family = 0;
        int accentBank = 0;
        float tune = 52.0f;
        float body = 0.75f;
        float punch = 0.75f;
        float lengthMs = 320.0f;
        float drive = 0.35f;
        float colour = 0.35f;
        float metal = 0.15f;
        float sub = 0.85f;
        float impact = 0.80f;
        float grit = 0.25f;
        float shape = 0.25f;
        float evolve = 0.20f;
        float destroy = 0.20f;
        float clipper = 0.25f;
    };

    void prepare(double sampleRate, int maximumBlockSize);
    void reset() noexcept;
    void setParameters(const Parameters&) noexcept;
    void trigger(float velocity) noexcept;
    void render(float* left, float* right, int numSamples) noexcept;

    bool isReady() const noexcept { return ready; }

private:
    struct Zones
    {
        FAUSTFLOAT* family = nullptr;
        FAUSTFLOAT* accentBank = nullptr;
        FAUSTFLOAT* trigger = nullptr;
        FAUSTFLOAT* tune = nullptr;
        FAUSTFLOAT* body = nullptr;
        FAUSTFLOAT* punch = nullptr;
        FAUSTFLOAT* length = nullptr;
        FAUSTFLOAT* drive = nullptr;
        FAUSTFLOAT* colour = nullptr;
        FAUSTFLOAT* metal = nullptr;
        FAUSTFLOAT* sub = nullptr;
        FAUSTFLOAT* impact = nullptr;
        FAUSTFLOAT* grit = nullptr;
        FAUSTFLOAT* shape = nullptr;
        FAUSTFLOAT* evolve = nullptr;
        FAUSTFLOAT* destroy = nullptr;
        FAUSTFLOAT* clipper = nullptr;
        FAUSTFLOAT* output = nullptr;
    };

    std::unique_ptr<IndustryKickFaustDSP> dsp;
    std::unique_ptr<MapUI> ui;
    Zones zones;
    Parameters parameters;
    bool ready = false;
    int gateSamplesRemaining = 0;
    int gateHoldSamples = 24;
    float currentVelocity = 1.0f;
    std::vector<FAUSTFLOAT> renderL, renderR;

    void cacheZones();
    void applyParameters() noexcept;
    static bool pathEndsWith(const std::string&, const char*) noexcept;
    static void setZone(FAUSTFLOAT* zone, float value) noexcept
    {
        if (zone != nullptr)
            *zone = static_cast<FAUSTFLOAT>(value);
    }
};
