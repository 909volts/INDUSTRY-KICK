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
    p.push_back(f(P::tune,"Tune",40,70,52,.1f,"Hz"));
    p.push_back(f(P::drop,"Pitch Drop",12,60,36,.1f,"st"));
    p.push_back(f(P::decay,"Length",120,700,320,1,"ms"));
    p.push_back(f(P::click,"Click",0,1,.26f));
    p.push_back(f(P::body,"Body",0,1,.62f));
    p.push_back(f(P::curve,"Pitch Curve",1,5,2.6f));
    p.push_back(f(P::punch,"Punch Freq",70,180,112,1,"Hz"));
    p.push_back(f(P::punchAmount,"Punch",0,1,.38f));
    p.push_back(f(P::punchLength,"Punch Length",8,45,22,1,"ms"));
    p.push_back(std::make_unique<juce::AudioParameterBool>(juce::ParameterID{P::phase,1},"Phase Reset",true));
    p.push_back(std::make_unique<juce::AudioParameterChoice>(juce::ParameterID{P::waveform,1},"Core Type",juce::StringArray{"ROUND","PUNCH","HARD","INDUSTRIAL","RAVE"},0));

    p.push_back(f(P::drive,"Drive",0,1,.08f));
    p.push_back(f(P::cabinet,"Colour",0,1,.16f));
    p.push_back(f(P::metal,"Metal",0,1,0));
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

    p.push_back(f(P::reverb,"Reverb",0,1,.34f));
    p.push_back(f(P::reverbSize,"Reverb Size",0,1,.55f));
    p.push_back(f(P::reverbDecay,"Reverb Decay",250,1800,760,1,"ms"));
    p.push_back(f(P::predelay,"Pre-delay",0,60,12,1,"ms"));
    p.push_back(f(P::damping,"Damping",0,1,.58f));
    p.push_back(f(P::reverbHP,"Reverb Low Cut",80,700,170,1,"Hz"));
    p.push_back(f(P::width,"Width",.5f,1.5f,1.1f));
    p.push_back(std::make_unique<juce::AudioParameterChoice>(juce::ParameterID{P::reverbMode,1},"Reverb Mode",juce::StringArray{"Algorithmic","Convolution"},1));

    p.push_back(f(P::sub,"SUB",0,1,.72f));
    p.push_back(f(P::kick,"BODY",0,1,.72f));
    p.push_back(f(P::tail,"SPACE",0,1,.42f));
    p.push_back(f(P::crunch,"GRIT",0,1,.22f));
    p.push_back(f(P::mono,"Mono Below",70,180,120,1,"Hz"));
    p.push_back(f(P::output,"Output",-18,6,0,.1f,"dB"));
    p.push_back(f(P::presetTrim,"Factory Calibration",-18,6,-6.2f,.1f,"dB"));
    p.push_back(f(P::clipper,"Clipper",0,1,.28f));
    p.push_back(f(P::shape,"Shape",0,1,.30f));
    p.push_back(f(P::evolve,"Evolve",0,1,0));
    p.push_back(f(P::destroy,"Destroy",0,1,0));
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
    reverbDelay.assign((size_t)(sr*.08),0.0f);
    reverbBuffer.setSize(2,preparedBlockSize,false,false,true);
    envelopeBuffer.setSize(2,preparedBlockSize,false,false,true);
    for(auto& c:convolutions) c=std::make_unique<juce::dsp::Convolution>();
    buildImpulseResponses();
    for(auto& c:convolutions) c->prepare({sr,(juce::uint32)preparedBlockSize,2});
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
    voice={}; reverbDelayPos=0; reverbAgeSeconds=0.0;
    std::fill(reverbDelay.begin(),reverbDelay.end(),0.0f);
    splitLow=cabinetLP=reverbHpX=reverbHpY=monoLowL=monoLowR=0.0f;
    dcXL=dcYL=dcXR=dcYR=0.0f;
    scopeCaptureIndex=0; scopeDecimationCounter=0; scopeAccumulator=0.0f;
    for(auto& sample:scope) sample.store(0.0f,std::memory_order_relaxed);
    outputPeakL.store(0.0f,std::memory_order_relaxed); outputPeakR.store(0.0f,std::memory_order_relaxed);
    for(auto& c:convolutions) if(c) c->reset();
}

void KickcrafterAudioProcessor::noteOn(float velocity)
{
    if(apvts.getRawParameterValue(P::phase)->load()>.5f)
    {
        voice.phase=0.0;
        voice.punchPhase=0.0;
    }
    voice.age=0.0;
    voice.velocity=juce::jlimit(0.0f,1.0f,velocity);
    voice.active=true;
    reverbAgeSeconds=0.0;
    scopeCaptureIndex=0; scopeDecimationCounter=0; scopeAccumulator=0.0f;
    for(auto& sample:scope) sample.store(0.0f,std::memory_order_relaxed);
}

KickcrafterAudioProcessor::Layers KickcrafterAudioProcessor::renderLayers(Voice& v)
{
    Layers o;
    if(!v.active) return o;

    const float tune=apvts.getRawParameterValue(P::tune)->load();
    const float drop=apvts.getRawParameterValue(P::drop)->load();
    const float decay=apvts.getRawParameterValue(P::decay)->load()*.001f;
    const float curve=apvts.getRawParameterValue(P::curve)->load();
    const float weight=apvts.getRawParameterValue(P::body)->load();
    const float shape=apvts.getRawParameterValue(P::shape)->load();
    const float evolve=apvts.getRawParameterValue(P::evolve)->load();
    const float destroy=apvts.getRawParameterValue(P::destroy)->load();
    const double t=v.age;
    const double pitchEnvelope=std::exp(-t*(14.0+curve*8.0));
    const double hz=tune*std::pow(2.0,(drop*pitchEnvelope)/12.0);
    v.phase+=juce::MathConstants<double>::twoPi*hz/sampleRate;
    v.punchPhase+=juce::MathConstants<double>::twoPi*apvts.getRawParameterValue(P::punch)->load()/sampleRate;

    const float attack=1.0f-std::exp((float)(-t*1900.0));
    const float t60=juce::jmax(.10f,decay*(1.0f-shape*.10f));
    const float envelope=attack*std::exp((float)(-t/(t60/6.9f)));
    const float fundamental=std::sin((float)v.phase);
    const int wave=(int)apvts.getRawParameterValue(P::waveform)->load();
    o.envelope=envelope;
    const float coreSubScale=wave==3?1.15f:1.0f;
    o.sub=fundamental*envelope*.77f*coreSubScale*v.velocity;

    const float harmonic2=std::sin((float)v.phase*2.0f);
    const float harmonic3=std::sin((float)v.phase*3.0f);
    const float harmonic5=std::sin((float)v.phase*5.0f);
    const float triangle=(2.0f/juce::MathConstants<float>::pi)*std::asin(fundamental);
    const float clipped=std::tanh(fundamental*3.4f)/std::tanh(3.4f);
    const float industrial=juce::jlimit(-1.0f,1.0f,fundamental*.94f+harmonic2*.07f+harmonic3*.17f+harmonic5*.045f);
    const float raveSaw=juce::jlimit(-1.0f,1.0f,(fundamental+harmonic2*.50f+harmonic3*.33f
        +std::sin((float)v.phase*4.0f)*.25f+harmonic5*.20f)*.64f);
    const float selectedWave=wave==1?triangle:(wave==2?clipped:(wave==3?industrial:(wave==4?raveSaw:fundamental)));
    const float harmonicBody=selectedWave-fundamental*(wave==3?.90f:.72f);
    const float evolvingColour=harmonic2*evolve*.12f+harmonic3*evolve*.10f+harmonic5*evolve*.07f;
    o.kick=(fundamental*(.08f+weight*.18f)+harmonicBody*(.12f+weight*1.08f)+evolvingColour)
        *envelope*(.48f+weight*.58f)*v.velocity;

    const float punchLength=apvts.getRawParameterValue(P::punchLength)->load()*.001f;
    const float punchEnvelope=std::exp((float)(-t/punchLength));
    const float punchTone=std::sin((float)v.punchPhase)*punchEnvelope
        *apvts.getRawParameterValue(P::punchAmount)->load()*(.62f+shape*.52f);
    const float clickEnvelope=std::exp((float)(-t*(520.0+shape*300.0)));
    const float clickTone=(std::sin((float)(t*juce::MathConstants<double>::twoPi*4300.0))
        +std::sin((float)(t*juce::MathConstants<double>::twoPi*7100.0))*.38f)
        *clickEnvelope*apvts.getRawParameterValue(P::click)->load()*.24f;
    o.punch=(punchTone+clickTone)*v.velocity;

    const float split=apvts.getRawParameterValue(P::split)->load();
    const float splitA=1.0f-std::exp(-juce::MathConstants<float>::twoPi*split/(float)sampleRate);
    const float distortionInput=o.kick+o.punch*.55f;
    splitLow+=splitA*(distortionInput-splitLow);
    const float protectedHigh=distortionInput-splitLow;
    const float drive=apvts.getRawParameterValue(P::drive)->load();
    const float gain=1.0f+drive*8.0f+destroy*10.0f;
    const float saturated=std::tanh(protectedHigh*gain)/std::tanh(gain);
    const float blend=juce::jlimit(0.0f,1.0f,.08f+drive*.92f+destroy*.52f);
    float processed=protectedHigh+(saturated-protectedHigh)*blend;
    if(drive+destroy>.42f) processed=juce::jlimit(-.76f,.76f,processed*1.22f);
    if(drive+destroy>1.05f) processed=juce::jlimit(-.62f,.62f,processed*1.35f);

    const float metal=apvts.getRawParameterValue(P::metal)->load();
    const float metallic=std::sin((float)v.phase*(13.0f+evolve*6.0f)+std::sin((float)v.phase*1.73f)*2.4f)
        *envelope*metal*(.60f+destroy*.18f);
    processed+=metallic;
    const float crush=apvts.getRawParameterValue(P::crush)->load();
    const float steps=juce::jmap(crush,320.0f,18.0f);
    processed=processed+(std::round(processed*steps)/steps-processed)*crush;
    const float cabinet=apvts.getRawParameterValue(P::cabinet)->load();
    const float cabinetHz=juce::jmap(cabinet,12500.0f,2600.0f);
    const float cabinetA=1.0f-std::exp(-juce::MathConstants<float>::twoPi*cabinetHz/(float)sampleRate);
    cabinetLP+=cabinetA*(processed-cabinetLP);
    const float cabinetDrive=1.8f+cabinet*4.2f;
    const float cabinetTone=std::tanh((cabinetLP+protectedHigh*cabinet*.42f)*cabinetDrive)/std::tanh(cabinetDrive);
    const float asymmetric=std::tanh((cabinetTone+cabinet*.09f)*2.3f)-std::tanh(cabinet*.09f*2.3f);
    o.texture=processed+(asymmetric-processed)*juce::jlimit(0.0f,1.0f,cabinet*.88f);

    v.age+=1.0/sampleRate;
    if(envelope<.00002f && t>t60*1.15f) v.active=false;
    return o;
}

void KickcrafterAudioProcessor::processBlock(juce::AudioBuffer<float>& b,juce::MidiBuffer& midi)
{
    juce::ScopedNoDenormals no;
    b.clear();
    const int n=b.getNumSamples();
    if(reverbBuffer.getNumSamples()<n)
    {
        reverbBuffer.setSize(2,n,false,false,true);
        envelopeBuffer.setSize(2,n,false,false,true);
    }
    reverbBuffer.clear(); envelopeBuffer.clear();
    auto* left=b.getWritePointer(0);
    auto* right=b.getNumChannels()>1?b.getWritePointer(1):left;
    auto* revL=reverbBuffer.getWritePointer(0);
    auto* revR=reverbBuffer.getWritePointer(1);
    auto* envOut=envelopeBuffer.getWritePointer(0);
    auto* ageOut=envelopeBuffer.getWritePointer(1);
    auto event=midi.cbegin(); const auto end=midi.cend();
    if(previewPending.exchange(false)) noteOn(1.0f);

    const float subGain=std::pow(apvts.getRawParameterValue(P::sub)->load(),1.08f)*1.68f;
    const float kickGain=std::pow(apvts.getRawParameterValue(P::kick)->load(),1.15f)*1.35f;
    const float tailGain=std::pow(apvts.getRawParameterValue(P::tail)->load(),1.2f)*1.25f;
    const float gritGain=std::pow(apvts.getRawParameterValue(P::crunch)->load(),1.1f)*1.30f;
    const float shape=apvts.getRawParameterValue(P::shape)->load();
    const float destroy=apvts.getRawParameterValue(P::destroy)->load();
    const float reverbAmount=std::pow(apvts.getRawParameterValue(P::reverb)->load(),1.1f)*.70f;
    const float hpA=std::exp(-juce::MathConstants<float>::twoPi*apvts.getRawParameterValue(P::reverbHP)->load()/(float)sampleRate);
    const int preSamples=juce::jlimit(0,(int)reverbDelay.size()-1,
        (int)(apvts.getRawParameterValue(P::predelay)->load()*.001f*sampleRate));

    for(int i=0;i<n;++i)
    {
        while(event!=end && (*event).samplePosition<=i)
        {
            const auto message=(*event).getMessage();
            if(message.isNoteOn()) noteOn(message.getFloatVelocity());
            ++event;
        }
        const auto x=renderLayers(voice);
        float dry=x.sub*subGain+(x.kick+x.punch)*kickGain+x.texture*gritGain;
        dry*=1.0f+shape*.10f+destroy*.18f;
        dry=juce::jlimit(-.96f,.96f,dry);
        left[i]=dry;
        right[i]=dry;
        envOut[i]=x.envelope;
        ageOut[i]=(float)reverbAgeSeconds;
        reverbAgeSeconds+=1.0/sampleRate;

        const float send=x.kick*.72f+x.punch*.46f+x.texture*.22f;
        const float highPassed=hpA*(reverbHpY+send-reverbHpX);
        reverbHpX=send; reverbHpY=highPassed;
        reverbDelay[reverbDelayPos]=highPassed;
        const size_t preRead=(reverbDelayPos+reverbDelay.size()-(size_t)preSamples)%reverbDelay.size();
        revL[i]=revR[i]=reverbDelay[preRead]*reverbAmount;
        reverbDelayPos=(reverbDelayPos+1)%reverbDelay.size();
    }

    const int selected=juce::jlimit(0,19,(int)apvts.getRawParameterValue(P::ir)->load());
    juce::dsp::AudioBlock<float> block(reverbBuffer);
    juce::dsp::ProcessContextReplacing<float> context(block);
    convolutions[(size_t)selected]->process(context);

    const float width=apvts.getRawParameterValue(P::width)->load();
    const float reverbT60=apvts.getRawParameterValue(P::reverbDecay)->load()*.001f;
    const float outputGain=juce::Decibels::decibelsToGain(apvts.getRawParameterValue(P::output)->load());
    const float presetGain=juce::Decibels::decibelsToGain(apvts.getRawParameterValue(P::presetTrim)->load());
    const float clipAmount=apvts.getRawParameterValue(P::clipper)->load();
    const float clipThreshold=juce::jmap(clipAmount,.92f,.48f);
    const float clipDrive=1.0f+clipAmount*2.8f;
    const float monoA=1.0f-std::exp(-juce::MathConstants<float>::twoPi*apvts.getRawParameterValue(P::mono)->load()/(float)sampleRate);
    constexpr float ceiling=.9120108f;
    constexpr float factoryPeak=.4466836f;
    const float dcR=std::exp(-juce::MathConstants<float>::twoPi*7.0f/(float)sampleRate);
    float blockPeakL=0.0f,blockPeakR=0.0f;
    for(int i=0;i<n;++i)
    {
        const float wetBoost=selected<5?24.0f:(selected<10?20.0f:(selected<15?26.0f:9.0f));
        const float decayGain=std::pow(10.0f,-3.0f*ageOut[i]/juce::jmax(.12f,reverbT60));
        const float mid=(revL[i]+revR[i])*.5f*wetBoost*decayGain;
        const float side=(revL[i]-revR[i])*.5f*width*wetBoost*decayGain;
        const float reverbDuck=1.0f-envOut[i]*.68f;
        float l=left[i]+(mid+side)*tailGain*reverbDuck;
        float r=right[i]+(mid-side)*tailGain*reverbDuck;
        monoLowL+=monoA*(l-monoLowL); monoLowR+=monoA*(r-monoLowR);
        const float monoLow=(monoLowL+monoLowR)*.5f;
        l=l-monoLowL+monoLow; r=r-monoLowR+monoLow;
        const float dcl=l-dcXL+dcR*dcYL; dcXL=l; dcYL=dcl;
        const float dcr=r-dcXR+dcR*dcYR; dcXR=r; dcYR=dcr;
        const float hardL=juce::jlimit(-clipThreshold,clipThreshold,dcl*clipDrive)/clipThreshold*ceiling;
        const float hardR=juce::jlimit(-clipThreshold,clipThreshold,dcr*clipDrive)/clipThreshold*ceiling;
        const float shapedL=juce::jlimit(-ceiling,ceiling,dcl+(hardL-dcl)*clipAmount);
        const float shapedR=juce::jlimit(-ceiling,ceiling,dcr+(hardR-dcr)*clipAmount);
        const float factoryL=juce::jlimit(-factoryPeak,factoryPeak,shapedL*presetGain);
        const float factoryR=juce::jlimit(-factoryPeak,factoryPeak,shapedR*presetGain);
        left[i]=juce::jlimit(-ceiling,ceiling,factoryL*outputGain);
        right[i]=juce::jlimit(-ceiling,ceiling,factoryR*outputGain);
        blockPeakL=juce::jmax(blockPeakL,std::abs(left[i])); blockPeakR=juce::jmax(blockPeakR,std::abs(right[i]));
        if(scopeCaptureIndex<(int)scope.size())
        {
            scopeAccumulator+=(left[i]+right[i])*.5f;
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
    updatePeak(outputPeakL,blockPeakL); updatePeak(outputPeakR,blockPeakR);
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
    const auto between=[&](float low,float high){return low+(high-low)*rng.nextFloat();};
    static constexpr float musicalRoots[]={46.25f,49.00f,51.91f,55.00f,58.27f};

    const int wave=rng.nextInt(5);
    set(P::waveform,wave);
    set(P::tune,musicalRoots[rng.nextInt((int)std::size(musicalRoots))]);
    set(P::drop,between(24.0f,48.0f));
    set(P::curve,between(1.8f,4.2f));
    set(P::decay,between(230.0f,560.0f));
    set(P::click,between(.12f,.48f));
    set(P::body,between(.48f,.94f));
    set(P::punch,between(88.0f,145.0f));
    set(P::punchAmount,between(.24f,.82f));
    set(P::punchLength,between(14.0f,34.0f));
    set(P::phase,1.0);

    set(P::drive,between(.05f,.78f));
    set(P::cabinet,between(.08f,.82f));
    set(P::metal,wave>=3?between(.12f,.64f):between(0.0f,.38f));
    set(P::crush,between(0.0f,.38f));
    set(P::split,between(96.0f,124.0f));
    set(P::clipStages,rng.nextInt(3));

    set(P::ir,rng.nextInt(20));
    set(P::reverb,between(.08f,.55f));
    set(P::reverbDecay,between(360.0f,1380.0f));
    set(P::predelay,between(4.0f,26.0f));
    set(P::damping,between(.38f,.78f));
    set(P::reverbHP,between(135.0f,320.0f));
    set(P::width,between(.82f,1.46f));
    set(P::reverbMode,1.0);

    set(P::sub,between(.68f,.96f));
    set(P::kick,between(.58f,.94f));
    set(P::tail,between(.18f,.68f));
    set(P::crunch,between(.12f,.76f));
    set(P::mono,120.0f);
    set(P::shape,between(.08f,.72f));
    set(P::evolve,between(0.0f,.58f));
    set(P::destroy,between(0.0f,.56f));
    set(P::clipper,between(.22f,.68f));
    set(P::presetTrim,0.0f);
    set(P::output,0.0f);
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
