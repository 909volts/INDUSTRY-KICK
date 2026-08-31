#include "FaustKickEngine.h"

#include <algorithm>
#include <cstring>

bool FaustKickEngine::pathEndsWith(const std::string& path, const char* suffix) noexcept
{
    if (suffix == nullptr)
        return false;
    const auto suffixLength = std::strlen(suffix);
    return path.size() >= suffixLength
        && path.compare(path.size() - suffixLength, suffixLength, suffix) == 0;
}

void FaustKickEngine::prepare(double sampleRate, int maximumBlockSize)
{
    ready = false;
    gateSamplesRemaining = 0;
    gateHoldSamples = juce::jmax(4, static_cast<int>(std::round(sampleRate * 0.0005)));
    currentVelocity = 1.0f;
    zones = {};
    const auto renderSize = static_cast<size_t>(juce::jmax(64, maximumBlockSize));
    renderL.assign(renderSize, FAUSTFLOAT(0));
    renderR.assign(renderSize, FAUSTFLOAT(0));

    dsp = std::make_unique<IndustryKickFaustDSP>();
    ui = std::make_unique<MapUI>();

    dsp->init(static_cast<int>(std::round(sampleRate)));
    dsp->buildUserInterface(ui.get());
    cacheZones();

    ready = zones.family != nullptr
         && zones.trigger != nullptr
         && zones.tune != nullptr
         && zones.body != nullptr
         && zones.punch != nullptr
         && zones.length != nullptr
         && zones.drive != nullptr
         && zones.colour != nullptr
         && zones.metal != nullptr
         && zones.sub != nullptr
         && zones.impact != nullptr
         && zones.grit != nullptr
         && zones.shape != nullptr
         && zones.evolve != nullptr
         && zones.destroy != nullptr
         && zones.clipper != nullptr
         && zones.output != nullptr;

    if (ready)
    {
        setZone(zones.trigger, 0.0f);
        // The JUCE layer owns final output gain. Keep Faust's internal output
        // at unity so public output/state semantics remain stable.
        setZone(zones.output, 0.0f);
        applyParameters();
    }
}

void FaustKickEngine::cacheZones()
{
    if (ui == nullptr)
        return;

    // Use MapUI's public enumeration API. Do not depend on getMap(), which is
    // not part of every Faust MapUI variant/version shipped on Windows.
    const int count = ui->getParamsCount();
    for (int i = 0; i < count; ++i)
    {
        const auto path = ui->getParamAddress(i);
        auto* zone = ui->getParamZone(i);
        if (zone == nullptr)
            continue;

        if      (pathEndsWith(path, "/Family"))  zones.family = zone;
        else if (pathEndsWith(path, "/Trigger")) zones.trigger = zone;
        else if (pathEndsWith(path, "/Tune"))    zones.tune = zone;
        else if (pathEndsWith(path, "/Body"))    zones.body = zone;
        else if (pathEndsWith(path, "/Punch"))   zones.punch = zone;
        else if (pathEndsWith(path, "/Length"))  zones.length = zone;
        else if (pathEndsWith(path, "/Drive"))   zones.drive = zone;
        else if (pathEndsWith(path, "/Colour"))  zones.colour = zone;
        else if (pathEndsWith(path, "/Metal"))   zones.metal = zone;
        else if (pathEndsWith(path, "/Sub"))     zones.sub = zone;
        else if (pathEndsWith(path, "/Impact"))  zones.impact = zone;
        else if (pathEndsWith(path, "/Grit"))    zones.grit = zone;
        else if (pathEndsWith(path, "/Shape"))   zones.shape = zone;
        else if (pathEndsWith(path, "/Evolve"))  zones.evolve = zone;
        else if (pathEndsWith(path, "/Destroy")) zones.destroy = zone;
        else if (pathEndsWith(path, "/Clipper")) zones.clipper = zone;
        else if (pathEndsWith(path, "/Output"))  zones.output = zone;
    }
}

void FaustKickEngine::reset() noexcept
{
    gateSamplesRemaining = 0;
    currentVelocity = 1.0f;

    if (dsp != nullptr)
        dsp->instanceClear();

    if (ready)
    {
        setZone(zones.trigger, 0.0f);
        setZone(zones.output, 0.0f);
        applyParameters();
    }
}

void FaustKickEngine::setParameters(const Parameters& newParameters) noexcept
{
    parameters = newParameters;
    if (ready)
        applyParameters();
}

void FaustKickEngine::applyParameters() noexcept
{
    setZone(zones.family,  static_cast<float>(juce::jlimit(0, 4, parameters.family)));
    setZone(zones.tune,    juce::jlimit(42.0f, 70.0f, parameters.tune));
    setZone(zones.body,    juce::jlimit(0.0f, 1.0f, parameters.body));
    setZone(zones.punch,   juce::jlimit(0.0f, 1.0f, parameters.punch));
    setZone(zones.length,  juce::jlimit(120.0f, 600.0f, parameters.lengthMs));
    setZone(zones.drive,   juce::jlimit(0.0f, 1.0f, parameters.drive));
    setZone(zones.colour,  juce::jlimit(0.0f, 1.0f, parameters.colour));
    setZone(zones.metal,   juce::jlimit(0.0f, 1.0f, parameters.metal));
    setZone(zones.sub,     juce::jlimit(0.0f, 1.0f, parameters.sub));
    setZone(zones.impact,  juce::jlimit(0.0f, 1.0f, parameters.impact));
    setZone(zones.grit,    juce::jlimit(0.0f, 1.0f, parameters.grit));
    setZone(zones.shape,   juce::jlimit(0.0f, 1.0f, parameters.shape));
    setZone(zones.evolve,  juce::jlimit(0.0f, 1.0f, parameters.evolve));
    setZone(zones.destroy, juce::jlimit(0.0f, 1.0f, parameters.destroy));
    setZone(zones.clipper, juce::jlimit(0.0f, 1.0f, parameters.clipper));
}

void FaustKickEngine::trigger(float velocity) noexcept
{
    currentVelocity = juce::jlimit(0.0f, 1.0f, velocity);
    gateSamplesRemaining = gateHoldSamples;
}

void FaustKickEngine::render(float* left, float* right, int numSamples) noexcept
{
    if (!ready || dsp == nullptr || left == nullptr || right == nullptr || numSamples <= 0)
        return;

    if (static_cast<size_t>(numSamples) > renderL.size()
        || static_cast<size_t>(numSamples) > renderR.size())
    {
        jassertfalse;
        std::fill(left, left + numSamples, 0.0f);
        std::fill(right, right + numSamples, 0.0f);
        return;
    }

    int outputOffset = 0;
    while (outputOffset < numSamples)
    {
        const int remaining = numSamples - outputOffset;
        const bool gateHigh = gateSamplesRemaining > 0;
        const int chunk = gateHigh ? juce::jmin(remaining, gateSamplesRemaining) : remaining;

        setZone(zones.trigger, gateHigh ? 1.0f : 0.0f);

        FAUSTFLOAT* outputs[2] { renderL.data(), renderR.data() };
        dsp->compute(chunk, nullptr, outputs);

        for (int j = 0; j < chunk; ++j)
        {
            left[outputOffset + j] = static_cast<float>(renderL[(size_t)j]) * currentVelocity;
            right[outputOffset + j] = static_cast<float>(renderR[(size_t)j]) * currentVelocity;
        }

        outputOffset += chunk;
        if (gateHigh)
        {
            gateSamplesRemaining -= chunk;
            if (gateSamplesRemaining <= 0)
                setZone(zones.trigger, 0.0f);
        }
    }
}
