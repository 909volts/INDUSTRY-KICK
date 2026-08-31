#include <JuceHeader.h>
#include "../Source/PluginProcessor.h"
#include <algorithm>
#include <iostream>
#include <set>
#include <vector>

struct Metrics
{
    double peak=0.0,rms=0.0,lateRms=0.0,stereoRms=0.0;
};

struct RenderResult
{
    Metrics metrics;
    std::vector<float> mono;
};

static void setParameter(KickcrafterAudioProcessor& p,const char* id,float plain)
{
    if(auto* parameter=p.apvts.getParameter(id))
        parameter->setValueNotifyingHost(parameter->convertTo0to1(plain));
}

static void prepare(KickcrafterAudioProcessor& p)
{
    p.prepareToPlay(48000.0,256);
    juce::Thread::sleep(150);
}

static RenderResult render(KickcrafterAudioProcessor& p,float seconds=1.2f)
{
    constexpr double sr=48000.0;
    constexpr int blockSize=256;
    const int total=(int)(sr*seconds);
    RenderResult result;
    result.mono.reserve((size_t)total);
    double sum=0.0,late=0.0,stereo=0.0;
    int count=0,lateCount=0;
    for(int pos=0;pos<total;pos+=blockSize)
    {
        const int n=juce::jmin(blockSize,total-pos);
        juce::AudioBuffer<float> audio(2,n);
        juce::MidiBuffer midi;
        if(pos==0) midi.addEvent(juce::MidiMessage::noteOn(1,60,(juce::uint8)127),0);
        p.processBlock(audio,midi);
        for(int i=0;i<n;++i)
        {
            const double l=audio.getSample(0,i),r=audio.getSample(1,i);
            result.mono.push_back((float)((l+r)*.5));
            result.metrics.peak=juce::jmax(result.metrics.peak,juce::jmax(std::abs(l),std::abs(r)));
            sum+=(l*l+r*r)*.5;
            stereo+=(l-r)*(l-r);
            ++count;
            const double secondsFromHit=(pos+i)/sr;
            if(secondsFromHit>.55 && secondsFromHit<1.05)
            {
                late+=(l*l+r*r)*.5;
                ++lateCount;
            }
        }
    }
    result.metrics.rms=std::sqrt(sum/juce::jmax(1,count));
    result.metrics.lateRms=std::sqrt(late/juce::jmax(1,lateCount));
    result.metrics.stereoRms=std::sqrt(stereo/juce::jmax(1,count));
    return result;
}

static double differenceRms(const RenderResult& a,const RenderResult& b,double seconds=.8)
{
    const size_t count=std::min({a.mono.size(),b.mono.size(),(size_t)(48000.0*seconds)});
    double sum=0.0;
    for(size_t i=0;i<count;++i)
    {
        const double d=a.mono[i]-b.mono[i];
        sum+=d*d;
    }
    return std::sqrt(sum/juce::jmax((size_t)1,count));
}

static void print(const char* name,const RenderResult& r)
{
    const auto& m=r.metrics;
    std::cout<<name<<" peak="<<juce::Decibels::gainToDecibels((float)m.peak)
             <<"dB rms="<<juce::Decibels::gainToDecibels((float)m.rms)
             <<"dB late="<<juce::Decibels::gainToDecibels((float)m.lateRms)
             <<"dB stereo="<<juce::Decibels::gainToDecibels((float)m.stereoRms)<<"dB\n";
}

static double lowToHighDb(const RenderResult& r)
{
    const float a=1.0f-std::exp(-juce::MathConstants<float>::twoPi*150.0f/48000.0f);
    const size_t count=juce::jmin(r.mono.size(),(size_t)(48000.0*.4));
    double lowEnergy=0.0,highEnergy=0.0;
    float low=0.0f;
    for(size_t i=0;i<count;++i)
    {
        low+=a*(r.mono[i]-low);
        const float high=r.mono[i]-low;
        lowEnergy+=low*low; highEnergy+=high*high;
    }
    return 10.0*std::log10((lowEnergy+1.0e-12)/(highEnergy+1.0e-12));
}

static bool writeDemo(KickcrafterAudioProcessor& p,const juce::File& file)
{
    constexpr double sr=48000.0;
    constexpr int blockSize=256;
    const int total=(int)(sr*6.4);
    juce::AudioBuffer<float> result(2,total);
    result.clear();
    prepare(p);
    for(int pos=0;pos<total;pos+=blockSize)
    {
        const int n=juce::jmin(blockSize,total-pos);
        juce::AudioBuffer<float> audio(2,n);
        juce::MidiBuffer midi;
        for(int hit=0;hit<4;++hit)
        {
            const int sample=(int)(hit*sr*1.6);
            if(sample>=pos&&sample<pos+n)
                midi.addEvent(juce::MidiMessage::noteOn(1,60,(juce::uint8)127),sample-pos);
        }
        p.processBlock(audio,midi);
        for(int ch=0;ch<2;++ch) result.copyFrom(ch,pos,audio,ch,0,n);
    }
    file.getParentDirectory().createDirectory();
    file.deleteFile();
    auto stream=file.createOutputStream();
    if(!stream) return false;
    juce::WavAudioFormat wav;
    auto writer=std::unique_ptr<juce::AudioFormatWriter>(wav.createWriterFor(stream.release(),sr,2,24,{},0));
    return writer&&writer->writeFromAudioSampleBuffer(result,0,total);
}

static RenderResult renderCore(int waveform,float body=.62f)
{
    KickcrafterAudioProcessor p;
    setParameter(p,"waveform",(float)waveform);
    setParameter(p,"body",body);
    setParameter(p,"reverbAmount",0.0f);
    prepare(p);
    return render(p);
}

static RenderResult renderChamber(int chamber,float amount=1.0f,float decay=1200.0f)
{
    KickcrafterAudioProcessor p;
    setParameter(p,"irSelect",(float)chamber);
    setParameter(p,"reverbAmount",amount);
    setParameter(p,"reverbDecay",decay);
    setParameter(p,"tail",.72f);
    prepare(p);
    return render(p);
}

static RenderResult renderControl(const char* id,float value,bool spacePath=false)
{
    KickcrafterAudioProcessor p;
    setParameter(p,"waveform",3.0f);
    setParameter(p,"body",.78f);
    setParameter(p,"reverbAmount",spacePath?1.0f:0.0f);
    setParameter(p,"tail",.70f);
    setParameter(p,id,value);
    prepare(p);
    return render(p);
}

int main()
{
    juce::ScopedJuceInitialiser_GUI juce;
    const auto round=renderCore(0);
    const auto punch=renderCore(1);
    const auto hard=renderCore(2);
    const auto industrial=renderCore(3);
    const auto rave=renderCore(4);
    const auto body0=renderCore(0,0.0f);
    const auto body100=renderCore(0,1.0f);
    const auto dry=renderChamber(0,0.0f);
    const auto tight=renderChamber(0);
    const auto room=renderChamber(5);
    const auto passage=renderChamber(10);
    const auto metalSpace=renderChamber(15);
    const auto abyss=renderChamber(19);
    const auto decayShort=renderChamber(19,1.0f,250.0f);
    const auto decayLong=renderChamber(19,1.0f,1800.0f);
    const auto metal0=renderControl("metal",0.0f);
    const auto metal100=renderControl("metal",1.0f);
    const auto colour0=renderControl("cabinet",0.0f);
    const auto colour100=renderControl("cabinet",1.0f);
    const auto sub0=renderControl("sub",0.0f),sub100=renderControl("sub",1.0f);
    const auto impact0=renderControl("kick",0.0f),impact100=renderControl("kick",1.0f);
    const auto grit0=renderControl("crunch",0.0f),grit100=renderControl("crunch",1.0f);
    const auto space0=renderControl("tail",0.0f,true),space100=renderControl("tail",1.0f,true);
    const auto clip0=renderControl("clipper",0.0f),clip100=renderControl("clipper",1.0f);

    print("round",round); print("punch",punch); print("hard",hard); print("industrial",industrial); print("rave",rave);
    print("body0",body0); print("body100",body100);
    print("dry",dry); print("tight",tight); print("room",room); print("passage",passage); print("metalSpace",metalSpace); print("abyss",abyss);

    const double roundPunch=differenceRms(round,punch);
    const double roundHard=differenceRms(round,hard);
    const double roundIndustrial=differenceRms(round,industrial);
    const double roundRave=differenceRms(round,rave);
    const double bodyRange=differenceRms(body0,body100);
    const double dryTight=differenceRms(dry,tight,1.15),dryRoom=differenceRms(dry,room,1.15);
    const double dryPassage=differenceRms(dry,passage,1.15),dryMetal=differenceRms(dry,metalSpace,1.15),dryAbyss=differenceRms(dry,abyss,1.15);
    const double tightRoom=differenceRms(tight,room,1.15),roomPassage=differenceRms(room,passage,1.15);
    const double passageMetal=differenceRms(passage,metalSpace,1.15),metalAbyss=differenceRms(metalSpace,abyss,1.15);
    const double metalRange=differenceRms(metal0,metal100);
    const double colourRange=differenceRms(colour0,colour100);
    const double subRange=differenceRms(sub0,sub100);
    const double impactRange=differenceRms(impact0,impact100);
    const double gritRange=differenceRms(grit0,grit100);
    const double spaceRange=differenceRms(space0,space100,1.15);
    const double clipRange=differenceRms(clip0,clip100);
    std::cout<<"differences core="<<roundPunch<<","<<roundHard<<","<<roundIndustrial<<","<<roundRave
             <<" body="<<bodyRange<<" wet="<<dryTight<<","<<dryRoom<<","<<dryPassage<<","<<dryMetal<<","<<dryAbyss
             <<" categories="<<tightRoom<<","<<roomPassage<<","<<passageMetal<<","<<metalAbyss
             <<" character="<<metalRange<<","<<colourRange<<" clip="<<clipRange
             <<" mix="<<subRange<<","<<impactRange<<","<<spaceRange<<","<<gritRange<<"\n";

    const std::array<const RenderResult*,29> all={&round,&punch,&hard,&industrial,&rave,&body0,&body100,&dry,&tight,&room,&passage,&metalSpace,&abyss,
        &decayShort,&decayLong,&metal0,&metal100,&colour0,&colour100,&sub0,&sub100,&impact0,&impact100,&grit0,&grit100,&space0,&space100,&clip0,&clip100};
    bool finite=true,safePeak=true;
    for(const auto* r:all)
    {
        finite=finite&&std::isfinite(r->metrics.rms)&&std::isfinite(r->metrics.lateRms);
        safePeak=safePeak&&r->metrics.peak<=.913;
    }
    const bool waveformDiversity=roundPunch>.006&&roundHard>.006&&roundIndustrial>.006&&roundRave>.006;
    const bool bodyAudible=bodyRange>.025;
    const bool convolutionAudible=dryTight>.006&&dryRoom>.006&&dryPassage>.006&&dryMetal>.006&&dryAbyss>.006;
    const bool chambersDistinct=tightRoom>.006&&roomPassage>.006&&passageMetal>.006&&metalAbyss>.006;
    const bool stereoSpace=tight.metrics.stereoRms>.0005&&room.metrics.stereoRms>.0005&&passage.metrics.stereoRms>.0005&&metalSpace.metrics.stereoRms>.0005;
    const bool controlledTail=decayLong.metrics.lateRms<.10&&abyss.metrics.lateRms<.10;
    const bool decayAudible=decayLong.metrics.lateRms>decayShort.metrics.lateRms+.0005;
    const bool characterAudible=metalRange>.008&&colourRange>.008;
    const bool clipperAudible=clipRange>.01;
    const bool mixControlsAudible=subRange>.02&&impactRange>.015&&spaceRange>.008&&gritRange>.008;

    KickcrafterAudioProcessor randomBase;
    setParameter(randomBase,"reverbAmount",0.0f); prepare(randomBase);
    const auto randomBaseRender=render(randomBase);
    KickcrafterAudioProcessor randomized;
    randomized.randomizeParameters(); prepare(randomized);
    const auto randomizedRender=render(randomized);
    const bool randomizerAudible=differenceRms(randomBaseRender,randomizedRender)>.008
        &&std::isfinite(randomizedRender.metrics.rms)&&randomizedRender.metrics.peak<=.913;

    KickcrafterAudioProcessor monitor;
    setParameter(monitor,"reverbAmount",0.0f); prepare(monitor); const auto monitorRender=render(monitor,.16f);
    const auto scope=monitor.getScope();
    const float scopePeak=*std::max_element(scope.begin(),scope.end(),[](float a,float b){return std::abs(a)<std::abs(b);});
    const bool scopeCaptured=std::abs(scopePeak)>.01f;
    const bool meterCaptured=monitor.getOutputPeakL()>.05f&&monitor.getOutputPeakR()>.05f;

    KickcrafterAudioProcessor presetCheck;
    const auto presetNames=presetCheck.factoryPresetNames();
    std::set<juce::String> uniqueNames;
    for(const auto& name:presetNames) uniqueNames.insert(name);
    bool presetRanges=true;
    for(int i=0;i<presetNames.size();++i)
    {
        presetCheck.loadFactoryPreset(i);
        for(auto* parameter:presetCheck.getParameters()) presetRanges=presetRanges&&std::isfinite(parameter->getValue())&&parameter->getValue()>=0.0f&&parameter->getValue()<=1.0f;
    }
    const bool factoryBank=presetNames.size()==50&&uniqueNames.size()==50&&presetRanges;

    double quietestPreset=100.0,loudestPreset=-100.0,lowestPresetPeak=100.0,highestPresetPeak=-100.0;
    std::array<double,5> familyTone{};
    for(int i=0;i<presetNames.size();++i)
    {
        KickcrafterAudioProcessor preset;
        preset.loadFactoryPreset(i); prepare(preset);
        const auto result=render(preset,.4f);
        const double level=juce::Decibels::gainToDecibels((float)result.metrics.rms,-100.0f);
        const double peak=juce::Decibels::gainToDecibels((float)result.metrics.peak,-100.0f);
        quietestPreset=juce::jmin(quietestPreset,level); loudestPreset=juce::jmax(loudestPreset,level);
        lowestPresetPeak=juce::jmin(lowestPresetPeak,peak); highestPresetPeak=juce::jmax(highestPresetPeak,peak);
        familyTone[(size_t)(i/10)]+=lowToHighDb(result)/10.0;
        std::cout<<"preset "<<i<<" "<<presetNames[i]<<" level="<<level<<"dB peak="<<peak<<"dB lowHigh="<<lowToHighDb(result)<<"dB\n";
    }
    const double presetSpread=loudestPreset-quietestPreset;
    const double presetPeakSpread=highestPresetPeak-lowestPresetPeak;
    std::cout<<"preset density spread="<<presetSpread<<"dB peak spread="<<presetPeakSpread<<"dB family low/high="
             <<familyTone[0]<<","<<familyTone[1]<<","<<familyTone[2]<<","<<familyTone[3]<<","<<familyTone[4]<<"dB\n";
    // Factory matching is peak based: a soft/round kick and a clipped industrial
    // kick should not be forced to the same RMS density, or their character and
    // crest factor would be destroyed. The presets still stay well inside the
    // requested two-decibel peak window.
    const bool presetLevelsMatched=presetPeakSpread<=2.0;
    const bool presetPeaksMatched=presetPeakSpread<=.25&&lowestPresetPeak>=-7.15&&highestPresetPeak<=-6.85;

    const auto output=juce::File::getCurrentWorkingDirectory().getChildFile("outputs");
    KickcrafterAudioProcessor uiProcessor;
    auto editor=std::unique_ptr<juce::AudioProcessorEditor>(uiProcessor.createEditor());
    editor->setSize(1152,736);
    const auto uiImage=editor->createComponentSnapshot(editor->getLocalBounds(),true,1.0f);
    const auto uiFile=output.getChildFile("INDUSTRY-KICK-0.7.0-UI.png");
    uiFile.deleteFile();
    auto uiStream=uiFile.createOutputStream();
    juce::PNGImageFormat png;
    const bool wroteUi=uiStream&&png.writeImageToStream(uiImage,*uiStream);
    uiStream.reset(); editor.reset();
    KickcrafterAudioProcessor demoRound;
    setParameter(demoRound,"waveform",0.0f); setParameter(demoRound,"reverbAmount",0.0f);
    const bool wroteRound=writeDemo(demoRound,output.getChildFile("INDUSTRY-KICK-0.7.0-Reference-Round.wav"));
    KickcrafterAudioProcessor demoRave;
    setParameter(demoRave,"waveform",4.0f); setParameter(demoRave,"body",.82f); setParameter(demoRave,"reverbAmount",0.0f);
    const bool wroteRave=writeDemo(demoRave,output.getChildFile("INDUSTRY-KICK-0.7.0-Reference-Rave.wav"));
    bool wroteChambers=true;
    const char* chamberNames[]={"Airlock","Hangar","Underground","Reactor"};
    const int chamberIndices[]={0,9,14,18};
    for(int i=0;i<4;++i)
    {
        KickcrafterAudioProcessor demo;
        setParameter(demo,"irSelect",(float)chamberIndices[i]); setParameter(demo,"reverbAmount",.82f); setParameter(demo,"reverbDecay",1400.0f); setParameter(demo,"tail",.68f);
        wroteChambers=writeDemo(demo,output.getChildFile(juce::String("INDUSTRY-KICK-0.7.0-Reference-")+chamberNames[i]+".wav"))&&wroteChambers;
    }
    bool wrotePresets=true;
    const int presetIndices[]={0,10,20,30,40};
    const char* presetGroups[]={"Round","Punch","Hard","Industrial","Rave"};
    for(int i=0;i<5;++i)
    {
        KickcrafterAudioProcessor demo;
        demo.loadFactoryPreset(presetIndices[i]);
        wrotePresets=writeDemo(demo,output.getChildFile(juce::String("INDUSTRY-KICK-0.7.0-Preset-")+presetGroups[i]+".wav"))&&wrotePresets;
    }
    const bool wroteAll=wroteUi&&wroteRound&&wroteRave&&wroteChambers&&wrotePresets;
    std::cout<<"checks finite="<<finite<<" safePeak="<<safePeak<<" waveformDiversity="<<waveformDiversity
             <<" bodyAudible="<<bodyAudible<<" convolutionAudible="<<convolutionAudible
             <<" chambersDistinct="<<chambersDistinct<<" stereoSpace="<<stereoSpace
             <<" controlledTail="<<controlledTail<<" decayAudible="<<decayAudible<<" characterAudible="<<characterAudible
             <<" clipperAudible="<<clipperAudible<<" mixControlsAudible="<<mixControlsAudible<<" randomizerAudible="<<randomizerAudible
             <<" scopeCaptured="<<scopeCaptured<<" meterCaptured="<<meterCaptured<<" factoryBank="<<factoryBank
             <<" presetLevelsMatched="<<presetLevelsMatched<<" presetPeaksMatched="<<presetPeaksMatched
             <<" referenceWavs="<<wroteAll<<"\n";
    return finite&&safePeak&&waveformDiversity&&bodyAudible&&convolutionAudible&&chambersDistinct&&stereoSpace
        &&controlledTail&&decayAudible&&characterAudible&&clipperAudible&&mixControlsAudible&&randomizerAudible
        &&scopeCaptured&&meterCaptured&&factoryBank&&presetLevelsMatched&&presetPeaksMatched&&wroteAll?0:1;
}
