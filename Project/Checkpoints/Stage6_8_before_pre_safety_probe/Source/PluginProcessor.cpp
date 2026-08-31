#include "PluginProcessor.h"
#include "PluginEditor.h"
#include "FactoryPresets.h"
#include <BinaryData.h>

namespace P
{
constexpr auto tune="tune",drop="pitchDrop",decay="decay",click="click",body="body",curve="pitchCurve";
constexpr auto punch="punchFreq",punchAmount="punchAmount",punchLength="punchLength",phase="phaseReset";
constexpr auto waveform="waveform";
constexpr auto drive="drive",cabinet="cabinet",metal="metal",crush="crush",split="split",clipStages="clipStages";
constexpr auto rumble="rumble",size="rumbleSize",rdecay="rumbleDecay",duck="duck",lp="rumbleLP",feedback="rumbleFeedback",mode="rumbleMode",ir="irSelect";
constexpr auto reverb="reverbAmount",reverbSize="reverbSize",reverbDecay="reverbDecay",predelay="reverbPredelay",damping="reverbDamping",reverbHP="reverbHP",width="reverbWidth",reverbMode="reverbMode";
constexpr auto sub="sub",kick="kick",tail="tail",crunch="crunch",mono="monoBelow",output="output",presetTrim="presetTrim",clipper="clipper",shape="shapeAmount",evolve="evolveAmount",destroy="destroyAmount";
}

static std::unique_ptr<juce::RangedAudioParameter> f(const char* id,const char* name,float lo,float hi,float def,float step=.01f,const char* suffix="")
{
    return std::make_unique<juce::AudioParameterFloat>(juce::ParameterID{id,1},name,
        juce::NormalisableRange<float>(lo,hi,step),def,juce::AudioParameterFloatAttributes().withLabel(suffix));
}

juce::AudioProcessorValueTreeState::ParameterLayout KickcrafterAudioProcessor::createLayout()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> p;
    p.push_back(f(P::tune,"Tune",40,70,48.509f,.1f,"Hz"));
    p.push_back(f(P::drop,"Pitch Drop",12,60,36,.1f,"st"));
    p.push_back(f(P::decay,"Length",120,700,414.83f,1,"ms"));
    p.push_back(f(P::click,"Click",0,1,.26f));
    p.push_back(f(P::body,"Body",0,1,.7150f));
    p.push_back(f(P::curve,"Pitch Curve",1,5,2.6f));
    p.push_back(f(P::punch,"Punch Freq",70,180,112,1,"Hz"));
    p.push_back(f(P::punchAmount,"Punch",0,1,.5330f));
    p.push_back(f(P::punchLength,"Punch Length",8,45,22,1,"ms"));
    p.push_back(std::make_unique<juce::AudioParameterBool>(juce::ParameterID{P::phase,1},"Phase Reset",true));
    p.push_back(std::make_unique<juce::AudioParameterChoice>(juce::ParameterID{P::waveform,1},"Core Type",juce::StringArray{"ROUND","PUNCH","HARD","INDUSTRIAL","RAVE"},0));

    p.push_back(f(P::drive,"Drive",0,1,.1746f));
    p.push_back(f(P::cabinet,"Colour",0,1,.1602f));
    p.push_back(f(P::metal,"Metal",0,1,.1054f));
    p.push_back(f(P::crush,"Crush",0,1,0));
    p.push_back(f(P::split,"Sub Protect",80,160,105,1,"Hz"));
    p.push_back(std::make_unique<juce::AudioParameterChoice>(juce::ParameterID{P::clipStages,1},"Clip Stages",juce::StringArray{"1","2","3"},1));

    p.push_back(f(P::rumble,"Rumble",0,1,.10f));
    p.push_back(f(P::size,"Rumble Space",28,100,52,1,"ms"));
    p.push_back(f(P::rdecay,"Rumble Length",150,1200,420,1,"ms"));
    p.push_back(f(P::duck,"Rumble Duck",0,1,.90f));
    p.push_back(f(P::lp,"Rumble Tone",180,1400,620,1,"Hz"));
    p.push_back(f(P::feedback,"Rumble Feedback",0,.6f,.22f));
    p.push_back(std::make_unique<juce::AudioParameterChoice>(juce::ParameterID{P::mode,1},"Rumble Mode",juce::StringArray{"Algorithmic","Convolution"},0));
    p.push_back(std::make_unique<juce::AudioParameterChoice>(juce::ParameterID{P::ir,1},"Chamber",juce::StringArray{
        "Airlock","Booth","Drum Cell","Concrete Box","Short Plate",
        "Studio","Concrete Room","Stone Chamber","Warehouse","Hangar",
        "Corridor","Tunnel","Sewer","Service Shaft","Underground",
        "Steel Plate","Oil Tank","Container","Reactor","Abyss"},0));

    p.push_back(f(P::reverb,"Reverb",0,1,0.0f));
    p.push_back(f(P::reverbSize,"Reverb Size",0,1,.55f));
    p.push_back(f(P::reverbDecay,"Reverb Decay",250,1800,760,1,"ms"));
    p.push_back(f(P::predelay,"Pre-delay",0,60,12,1,"ms"));
    p.push_back(f(P::damping,"Damping",0,1,.58f));
    p.push_back(f(P::reverbHP,"Reverb Low Cut",80,700,170,1,"Hz"));
    p.push_back(f(P::width,"Width",.5f,1.5f,1.1f));
    p.push_back(std::make_unique<juce::AudioParameterChoice>(juce::ParameterID{P::reverbMode,1},"Reverb Mode",juce::StringArray{"Algorithmic","Convolution"},1));

    p.push_back(f(P::sub,"SUB",0,1,.9492f));
    p.push_back(f(P::kick,"BODY",0,1,.6503f));
    p.push_back(f(P::tail,"SPACE",0,1,0.0f));
    p.push_back(f(P::crunch,"GRIT",0,1,.0913f));
    p.push_back(f(P::mono,"Mono Below",70,180,120,1,"Hz"));
    p.push_back(f(P::output,"Output",-18,6,0,.1f,"dB"));
    p.push_back(f(P::presetTrim,"Factory Calibration",-18,6,0.0f,.1f,"dB"));
    p.push_back(f(P::clipper,"Clipper",0,1,.0380f));
    p.push_back(f(P::shape,"Shape",0,1,.3853f));
    p.push_back(f(P::evolve,"Evolve",0,1,.0751f));
    p.push_back(f(P::destroy,"Destroy",0,1,.1814f));
    return {p.begin(),p.end()};
}

KickcrafterAudioProcessor::KickcrafterAudioProcessor()
 : AudioProcessor(BusesProperties().withOutput("Output",juce::AudioChannelSet::stereo(),true)),
   apvts(*this,&undo,"PARAMETERS",createLayout())
{
    startTimerHz(30);
}

bool KickcrafterAudioProcessor::isBusesLayoutSupported(const BusesLayout& l) const
{
    return l.getMainOutputChannelSet()==juce::AudioChannelSet::stereo()
        || l.getMainOutputChannelSet()==juce::AudioChannelSet::mono();
}

void KickcrafterAudioProcessor::prepareToPlay(double sr,int maximumBlockSize)
{
    sampleRate=sr;
    preparedBlockSize=juce::jmax(64,maximumBlockSize);
    const int scratchSize=juce::jmax(8192,preparedBlockSize);

    faustBuffer.setSize(2,scratchSize,false,false,true);
    reverbBuffer.setSize(2,scratchSize,false,false,true);
    envelopeBuffer.setSize(2,scratchSize,false,false,true);
    reverbDelay.assign((size_t)juce::jmax(1,(int)(sr*.08)),0.0f);

    faustKick.prepare(sr,scratchSize);
    jassert(faustKick.isReady());

    for(auto& c:convolutions) c=std::make_unique<juce::dsp::Convolution>();
    buildImpulseResponses();
    for(auto& c:convolutions) c->prepare({sr,(juce::uint32)scratchSize,2});
    resetDspState();
}

void KickcrafterAudioProcessor::buildImpulseResponses()
{
    const void* data[]={
        BinaryData::tight_airlock_wav,BinaryData::tight_booth_wav,BinaryData::tight_drum_cell_wav,
        BinaryData::tight_concrete_box_wav,BinaryData::tight_short_plate_wav,
        BinaryData::room_studio_wav,BinaryData::room_concrete_wav,BinaryData::room_stone_chamber_wav,
        BinaryData::room_warehouse_wav,BinaryData::room_hangar_wav,
        BinaryData::passage_corridor_wav,BinaryData::passage_tunnel_wav,BinaryData::passage_sewer_wav,
        BinaryData::passage_service_shaft_wav,BinaryData::passage_underground_wav,
        BinaryData::metal_steel_plate_wav,BinaryData::metal_oil_tank_wav,BinaryData::metal_container_wav,
        BinaryData::metal_reactor_wav,BinaryData::metal_abyss_wav};
    const int sizes[]={
        BinaryData::tight_airlock_wavSize,BinaryData::tight_booth_wavSize,BinaryData::tight_drum_cell_wavSize,
        BinaryData::tight_concrete_box_wavSize,BinaryData::tight_short_plate_wavSize,
        BinaryData::room_studio_wavSize,BinaryData::room_concrete_wavSize,BinaryData::room_stone_chamber_wavSize,
        BinaryData::room_warehouse_wavSize,BinaryData::room_hangar_wavSize,
        BinaryData::passage_corridor_wavSize,BinaryData::passage_tunnel_wavSize,BinaryData::passage_sewer_wavSize,
        BinaryData::passage_service_shaft_wavSize,BinaryData::passage_underground_wavSize,
        BinaryData::metal_steel_plate_wavSize,BinaryData::metal_oil_tank_wavSize,BinaryData::metal_container_wavSize,
        BinaryData::metal_reactor_wavSize,BinaryData::metal_abyss_wavSize};
    for(size_t i=0;i<convolutions.size();++i)
        convolutions[i]->loadImpulseResponse(data[i],sizes[i],juce::dsp::Convolution::Stereo::yes,
            juce::dsp::Convolution::Trim::no,0,juce::dsp::Convolution::Normalise::yes);
}

void KickcrafterAudioProcessor::resetDspState()
{
    faustKick.reset();
    reverbDelayPos=0; reverbAgeSeconds=0.0;
    std::fill(reverbDelay.begin(),reverbDelay.end(),0.0f);
    reverbHpX=reverbHpY=monoLowL=monoLowR=0.0f;
    dryEnvelope=0.0f;
    dcXL=dcYL=dcXR=dcYR=0.0f;
    scopeCaptureIndex=0; scopeDecimationCounter=0; scopeAccumulator=0.0f;
    for(auto& sample:scope) sample.store(0.0f,std::memory_order_relaxed);
    outputPeakL.store(0.0f,std::memory_order_relaxed); outputPeakR.store(0.0f,std::memory_order_relaxed);
    for(auto& c:convolutions) if(c) c->reset();
}

void KickcrafterAudioProcessor::noteOn(float velocity)
{
    faustKick.trigger(velocity);
    reverbAgeSeconds=0.0;
    scopeCaptureIndex=0; scopeDecimationCounter=0; scopeAccumulator=0.0f;
    for(auto& sample:scope) sample.store(0.0f,std::memory_order_relaxed);
}

void KickcrafterAudioProcessor::processBlock(juce::AudioBuffer<float>& b,juce::MidiBuffer& midi)
{
    juce::ScopedNoDenormals no;
    const int n=b.getNumSamples();
    if(n<=0) return;

    // Scratch buffers are allocated in prepareToPlay; never resize on the audio thread.
    if(n>faustBuffer.getNumSamples() || n>reverbBuffer.getNumSamples() || n>envelopeBuffer.getNumSamples())
    {
        jassertfalse;
        b.clear();
        return;
    }

    b.clear();
    faustBuffer.clear();
    reverbBuffer.clear();
    envelopeBuffer.clear();

    FaustKickEngine::Parameters fp;
    fp.family   = juce::jlimit(0,4,(int)apvts.getRawParameterValue(P::waveform)->load());
    fp.tune     = apvts.getRawParameterValue(P::tune)->load();
    fp.body     = apvts.getRawParameterValue(P::body)->load();
    fp.punch    = apvts.getRawParameterValue(P::punchAmount)->load();
    fp.lengthMs = apvts.getRawParameterValue(P::decay)->load();
    fp.drive    = apvts.getRawParameterValue(P::drive)->load();
    fp.colour   = apvts.getRawParameterValue(P::cabinet)->load();
    fp.metal    = apvts.getRawParameterValue(P::metal)->load();
    fp.sub      = apvts.getRawParameterValue(P::sub)->load();
    fp.impact   = apvts.getRawParameterValue(P::kick)->load();
    fp.grit     = apvts.getRawParameterValue(P::crunch)->load();
    fp.shape    = apvts.getRawParameterValue(P::shape)->load();
    fp.evolve   = apvts.getRawParameterValue(P::evolve)->load();
    fp.destroy  = apvts.getRawParameterValue(P::destroy)->load();
    fp.clipper  = apvts.getRawParameterValue(P::clipper)->load();
    faustKick.setParameters(fp);

    auto* dryL=faustBuffer.getWritePointer(0);
    auto* dryR=faustBuffer.getWritePointer(1);

    int rendered=0;
    if(previewPending.exchange(false))
        noteOn(1.0f);

    for(const auto metadata:midi)
    {
        const int eventPosition=juce::jlimit(0,n,metadata.samplePosition);
        if(eventPosition>rendered)
        {
            faustKick.render(dryL+rendered,dryR+rendered,eventPosition-rendered);
            rendered=eventPosition;
        }

        const auto message=metadata.getMessage();
        if(message.isNoteOn())
            noteOn(message.getFloatVelocity());
    }

    if(rendered<n)
        faustKick.render(dryL+rendered,dryR+rendered,n-rendered);

    auto* revL=reverbBuffer.getWritePointer(0);
    auto* revR=reverbBuffer.getWritePointer(1);
    auto* envOut=envelopeBuffer.getWritePointer(0);
    auto* ageOut=envelopeBuffer.getWritePointer(1);

    const float tailGain=std::pow(apvts.getRawParameterValue(P::tail)->load(),1.2f)*1.25f;
    const float reverbAmount=std::pow(apvts.getRawParameterValue(P::reverb)->load(),1.1f)*.70f;
    const float hpA=std::exp(-juce::MathConstants<float>::twoPi*apvts.getRawParameterValue(P::reverbHP)->load()/(float)sampleRate);
    const int preSamples=juce::jlimit(0,(int)reverbDelay.size()-1,
        (int)(apvts.getRawParameterValue(P::predelay)->load()*.001f*sampleRate));
    const float envRelease=std::exp(-1.0f/((float)sampleRate*.055f));

    for(int i=0;i<n;++i)
    {
        const float dry=(dryL[i]+dryR[i])*.5f;
        dryEnvelope=juce::jmax(std::abs(dry),dryEnvelope*envRelease);
        envOut[i]=juce::jlimit(0.0f,1.0f,dryEnvelope*1.35f);
        ageOut[i]=(float)reverbAgeSeconds;
        reverbAgeSeconds+=1.0/sampleRate;

        const float send=dry*.72f;
        const float highPassed=hpA*(reverbHpY+send-reverbHpX);
        reverbHpX=send; reverbHpY=highPassed;
        reverbDelay[reverbDelayPos]=highPassed;
        const size_t preRead=(reverbDelayPos+reverbDelay.size()-(size_t)preSamples)%reverbDelay.size();
        revL[i]=revR[i]=reverbDelay[preRead]*reverbAmount;
        reverbDelayPos=(reverbDelayPos+1)%reverbDelay.size();
    }

    const int selected=juce::jlimit(0,19,(int)apvts.getRawParameterValue(P::ir)->load());
    if(reverbAmount>0.00001f)
    {
        juce::dsp::AudioBlock<float> block(reverbBuffer);
        auto activeBlock=block.getSubBlock(0,(size_t)n);
        juce::dsp::ProcessContextReplacing<float> context(activeBlock);
        convolutions[(size_t)selected]->process(context);
    }

    auto* left=b.getWritePointer(0);
    auto* right=b.getNumChannels()>1?b.getWritePointer(1):nullptr;
    const float width=apvts.getRawParameterValue(P::width)->load();
    const float reverbT60=apvts.getRawParameterValue(P::reverbDecay)->load()*.001f;
    const float outputGain=juce::Decibels::decibelsToGain(apvts.getRawParameterValue(P::output)->load());
    const float presetGain=juce::Decibels::decibelsToGain(apvts.getRawParameterValue(P::presetTrim)->load());
    const float monoA=1.0f-std::exp(-juce::MathConstants<float>::twoPi*apvts.getRawParameterValue(P::mono)->load()/(float)sampleRate);
    constexpr float ceiling=0.9225714f; // -0.70 dBFS safety ceiling; character clipping lives in Faust.
    const float dcR=std::exp(-juce::MathConstants<float>::twoPi*7.0f/(float)sampleRate);
    float blockPeakL=0.0f,blockPeakR=0.0f;

    for(int i=0;i<n;++i)
    {
        float l=dryL[i];
        float r=dryR[i];

        if(reverbAmount>0.00001f)
        {
            const float wetBoost=selected<5?24.0f:(selected<10?20.0f:(selected<15?26.0f:9.0f));
            const float decayGain=std::pow(10.0f,-3.0f*ageOut[i]/juce::jmax(.12f,reverbT60));
            const float mid=(revL[i]+revR[i])*.5f*wetBoost*decayGain;
            const float side=(revL[i]-revR[i])*.5f*width*wetBoost*decayGain;
            const float reverbDuck=1.0f-envOut[i]*.68f;
            l+=(mid+side)*tailGain*reverbDuck;
            r+=(mid-side)*tailGain*reverbDuck;
        }

        monoLowL+=monoA*(l-monoLowL); monoLowR+=monoA*(r-monoLowR);
        const float monoLow=(monoLowL+monoLowR)*.5f;
        l=l-monoLowL+monoLow; r=r-monoLowR+monoLow;

        const float dcl=l-dcXL+dcR*dcYL; dcXL=l; dcYL=dcl;
        const float dcr=r-dcXR+dcR*dcYR; dcXR=r; dcYR=dcr;

        l=juce::jlimit(-ceiling,ceiling,dcl*presetGain*outputGain);
        r=juce::jlimit(-ceiling,ceiling,dcr*presetGain*outputGain);

        left[i]=l;
        if(right!=nullptr) right[i]=r;

        blockPeakL=juce::jmax(blockPeakL,std::abs(l));
        blockPeakR=juce::jmax(blockPeakR,std::abs(right!=nullptr?r:l));

        if(scopeCaptureIndex<(int)scope.size())
        {
            scopeAccumulator+=(l+(right!=nullptr?r:l))*.5f;
            if(++scopeDecimationCounter>=24)
            {
                scope[(size_t)scopeCaptureIndex++].store(scopeAccumulator/24.0f,std::memory_order_relaxed);
                scopeDecimationCounter=0; scopeAccumulator=0.0f;
            }
        }
    }

    auto updatePeak=[](std::atomic<float>& destination,float value)
    {
        float previous=destination.load(std::memory_order_relaxed);
        while(previous<value&&!destination.compare_exchange_weak(previous,value,std::memory_order_relaxed)) {}
    };
    updatePeak(outputPeakL,blockPeakL);
    updatePeak(outputPeakR,blockPeakR);
}

void KickcrafterAudioProcessor::triggerPreview(){previewPending=true;}
void KickcrafterAudioProcessor::set(const char* id,double value){if(auto* p=apvts.getParameter(id))p->setValueNotifyingHost(p->convertTo0to1((float)value));}
void KickcrafterAudioProcessor::shape(){set(P::shape,juce::jlimit(0.0f,1.0f,apvts.getRawParameterValue(P::shape)->load()+.15f));}
void KickcrafterAudioProcessor::evolve(){set(P::evolve,juce::Random::getSystemRandom().nextFloat());}
void KickcrafterAudioProcessor::destroy(){set(P::destroy,juce::jlimit(0.0f,1.0f,apvts.getRawParameterValue(P::destroy)->load()+.18f));}

juce::File KickcrafterAudioProcessor::presetDir() const
{
    auto d=juce::File::getSpecialLocation(juce::File::userDocumentsDirectory).getChildFile("909VOLTS").getChildFile("INDUSTRY KICK Presets");
    d.createDirectory(); return d;
}
void KickcrafterAudioProcessor::savePreset(const juce::String& n){apvts.copyState().createXml()->writeTo(presetDir().getChildFile(juce::File::createLegalFileName(n)+".xml"));}
void KickcrafterAudioProcessor::loadPreset(const juce::File& file){if(auto x=juce::XmlDocument::parse(file))apvts.replaceState(juce::ValueTree::fromXml(*x));}
juce::Array<juce::File> KickcrafterAudioProcessor::presets() const{return presetDir().findChildFiles(juce::File::findFiles,false,"*.xml");}
juce::StringArray KickcrafterAudioProcessor::factoryPresetNames() const
{
    juce::StringArray names; for(const auto& preset:factoryPresets) names.add(preset.name); return names;
}
void KickcrafterAudioProcessor::loadFactoryPreset(int index)
{
    if(!juce::isPositiveAndBelow(index,(int)factoryPresets.size())) return;
    undo.beginNewTransaction("Load Factory Preset");
    const auto& p=factoryPresets[(size_t)index];
    set(P::waveform,(float)p.wave); set(P::ir,(float)p.ir); set(P::tune,p.tune); set(P::body,p.body);
    set(P::punchAmount,p.punch); set(P::decay,p.length); set(P::drive,p.drive); set(P::cabinet,p.colour);
    set(P::metal,p.metal); set(P::reverb,p.reverb); set(P::reverbDecay,p.reverbDecay); set(P::width,p.width);
    set(P::sub,p.sub); set(P::kick,p.impact); set(P::tail,p.space); set(P::crunch,p.grit);
    set(P::shape,p.shape); set(P::evolve,p.evolve); set(P::destroy,p.destroy); set(P::clipper,p.clipper);
    set(P::presetTrim,p.calibration+5.0); set(P::output,0.0); set(P::crush,juce::jlimit(0.0,1.0,p.grit*.34+p.destroy*.28));
}

void KickcrafterAudioProcessor::randomizeParameters()
{
    undo.beginNewTransaction("Randomizer");
    auto& rng=juce::Random::getSystemRandom();
    const auto clamp01=[](float v){return juce::jlimit(0.0f,1.0f,v);};
    const auto jitter=[&](float base,float amount){return base+(rng.nextFloat()*2.0f-1.0f)*amount;};

    // V2 randomization is deliberately local: choose a validated factory point,
    // then make a modest mutation. This avoids independent random ranges that
    // can combine individually-valid values into a bad kick.
    const auto& p=factoryPresets[(size_t)rng.nextInt((int)factoryPresets.size())];

    set(P::waveform,(float)p.wave);
    set(P::tune,juce::jlimit(42.0f,70.0f,jitter((float)p.tune,1.25f)));
    set(P::body,clamp01(jitter((float)p.body,.045f)));
    set(P::punchAmount,clamp01(jitter((float)p.punch,.050f)));
    set(P::decay,juce::jlimit(120.0f,600.0f,jitter((float)p.length,(float)p.length*.055f)));
    set(P::drive,clamp01(jitter((float)p.drive,.050f)));
    set(P::cabinet,clamp01(jitter((float)p.colour,.050f)));
    set(P::metal,clamp01(jitter((float)p.metal,.045f)));
    set(P::sub,clamp01(jitter((float)p.sub,.035f)));
    set(P::kick,clamp01(jitter((float)p.impact,.040f)));
    set(P::crunch,clamp01(jitter((float)p.grit,.045f)));
    set(P::shape,clamp01(jitter((float)p.shape,.040f)));
    set(P::evolve,clamp01(jitter((float)p.evolve,.045f)));
    set(P::destroy,clamp01(jitter((float)p.destroy,.045f)));
    set(P::clipper,clamp01(jitter((float)p.clipper,.040f)));

    // Space is intentionally neutral until the dedicated space/rumble gate.
    set(P::reverb,0.0f);
    set(P::tail,0.0f);
    set(P::presetTrim,0.0f);
    set(P::output,0.0f);

    // Legacy compatibility parameters remain at stable neutral defaults.
    set(P::drop,36.0f);
    set(P::click,.26f);
    set(P::curve,2.6f);
    set(P::punch,112.0f);
    set(P::punchLength,22.0f);
    set(P::phase,1.0f);
    set(P::crush,0.0f);
    set(P::split,105.0f);
    set(P::clipStages,1.0f);
}
void KickcrafterAudioProcessor::copyToSlot(char s){(s=='A'?slotA:slotB)=apvts.copyState();}
void KickcrafterAudioProcessor::recallSlot(char s){auto v=s=='A'?slotA:slotB;if(v.isValid())apvts.replaceState(v.createCopy());}

bool KickcrafterAudioProcessor::exportWav(const juce::File& file)
{
    suspendProcessing(true);
    const int total=(int)(sampleRate*3.0);
    juce::AudioBuffer<float> out(2,total); out.clear(); resetDspState();
    const int chunk=juce::jmax(64,preparedBlockSize);
    for(int pos=0;pos<total;pos+=chunk)
    {
        const int count=juce::jmin(chunk,total-pos);
        juce::AudioBuffer<float> temp(2,count); juce::MidiBuffer notes;
        if(pos==0) notes.addEvent(juce::MidiMessage::noteOn(1,60,(juce::uint8)127),0);
        processBlock(temp,notes);
        for(int ch=0;ch<2;++ch) out.copyFrom(ch,pos,temp,ch,0,count);
    }
    resetDspState();
    auto stream=file.createOutputStream();
    if(!stream){suspendProcessing(false);return false;}
    juce::WavAudioFormat wav;
    auto writer=std::unique_ptr<juce::AudioFormatWriter>(wav.createWriterFor(stream.release(),sampleRate,2,24,{},0));
    const bool ok=writer&&writer->writeFromAudioSampleBuffer(out,0,total);
    writer.reset(); suspendProcessing(false); return ok;
}

std::array<float,1024> KickcrafterAudioProcessor::getScope() const
{
    std::array<float,1024> copy{};
    for(size_t i=0;i<copy.size();++i) copy[i]=scope[i].load(std::memory_order_relaxed);
    return copy;
}
void KickcrafterAudioProcessor::getStateInformation(juce::MemoryBlock& b){if(auto x=apvts.copyState().createXml())copyXmlToBinary(*x,b);}
void KickcrafterAudioProcessor::setStateInformation(const void* d,int n){if(auto x=getXmlFromBinary(d,n))apvts.replaceState(juce::ValueTree::fromXml(*x));}
juce::AudioProcessorEditor* KickcrafterAudioProcessor::createEditor(){return new KickcrafterAudioProcessorEditor(*this);}
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter(){return new KickcrafterAudioProcessor();}
