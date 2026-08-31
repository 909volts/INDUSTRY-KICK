#include "PluginEditor.h"
#include <BinaryData.h>

KickcrafterAudioProcessorEditor::IndustrialLook::IndustrialLook()
{
    setColour(juce::Slider::textBoxTextColourId,juce::Colour(0xfffffff9));
    setColour(juce::Slider::textBoxBackgroundColourId,juce::Colour(0xff101316));
    setColour(juce::Slider::textBoxOutlineColourId,juce::Colour(0xff858b92));
    setColour(juce::ComboBox::backgroundColourId,juce::Colour(0xff1b1f23));
    setColour(juce::ComboBox::textColourId,juce::Colour(0xfffffff9));
    setColour(juce::ComboBox::outlineColourId,juce::Colour(0xff858b92));
    setColour(juce::PopupMenu::backgroundColourId,juce::Colour(0xff181c20));
    setColour(juce::PopupMenu::textColourId,juce::Colours::white);
}

void KickcrafterAudioProcessorEditor::IndustrialLook::drawRotarySlider(juce::Graphics& g,int x,int y,int w,int h,float pos,float a0,float a1,juce::Slider& s)
{
    const bool smart=s.getComponentID().startsWith("smart-");
    auto r=juce::Rectangle<float>((float)x,(float)y,(float)w,(float)h).reduced(smart?16.0f:12.0f).withTrimmedBottom(smart?28.0f:21.0f);
    const auto c=r.getCentre();
    const float radius=juce::jmin(r.getWidth(),r.getHeight())*(smart?.39f:.38f);
    const float angle=a0+pos*(a1-a0);
    juce::Colour accent(0xffff1635);

    g.setColour(juce::Colour(0x66000000)); g.fillEllipse(c.x-radius-7,c.y-radius-4,(radius+7)*2,(radius+7)*2);
    juce::ColourGradient rim(juce::Colour(0xff626870),c.x-radius,c.y-radius,juce::Colour(0xff101317),c.x+radius,c.y+radius,false);
    g.setGradientFill(rim); g.fillEllipse(c.x-radius-3,c.y-radius-3,(radius+3)*2,(radius+3)*2);
    juce::ColourGradient face(juce::Colour(0xff363b41),c.x-radius,c.y-radius,juce::Colour(0xff0a0c0f),c.x+radius,c.y+radius,false);
    g.setGradientFill(face); g.fillEllipse(c.x-radius,c.y-radius,radius*2,radius*2);
    g.setColour(juce::Colour(0xff08090a)); g.drawEllipse(c.x-radius,c.y-radius,radius*2,radius*2,2.0f);
    juce::Path track; track.addCentredArc(c.x,c.y,radius+7,radius+7,0,a0,a1,true);
    g.setColour(juce::Colour(0xff484d53)); g.strokePath(track,juce::PathStrokeType(smart?7.0f:5.0f));
    juce::Path arc; arc.addCentredArc(c.x,c.y,radius+7,radius+7,0,a0,angle,true);
    g.setColour(accent); g.strokePath(arc,juce::PathStrokeType(smart?5.0f:3.5f));
    juce::Path pointer; pointer.addRoundedRectangle(-1.6f,-radius+8,3.2f,radius*(smart?.59f:.49f),1.6f);
    g.setColour(smart?accent:juce::Colour(0xfffffff7)); g.fillPath(pointer,juce::AffineTransform::rotation(angle).translated(c));
    g.setColour(accent.withAlpha(.9f));
    g.setFont(juce::FontOptions("Bahnschrift SemiCondensed",smart?18.0f:12.5f,juce::Font::bold));
    g.drawFittedText(s.getName(),x,y+h-(smart?27:20),w,smart?23:18,juce::Justification::centred,1,.72f);
}

void KickcrafterAudioProcessorEditor::IndustrialLook::drawButtonBackground(juce::Graphics& g,juce::Button& b,const juce::Colour&,bool over,bool down)
{
    auto r=b.getLocalBounds().toFloat();
    juce::ColourGradient grad(down?juce::Colour(0xffb20d25):(over?juce::Colour(0xff50565d):juce::Colour(0xff343940)),0,0,juce::Colour(0xff0e1114),0,r.getBottom(),false);
    g.setGradientFill(grad); g.fillRoundedRectangle(r,2);
    const bool redAccent=b.getComponentID()=="trigger"||b.getComponentID()=="randomizer";
    g.setColour(redAccent?juce::Colour(0xffff1635):juce::Colour(0xff858b92));
    g.drawRoundedRectangle(r.reduced(.5f),2,1.3f);
}

void KickcrafterAudioProcessorEditor::IndustrialLook::drawComboBox(juce::Graphics& g,int w,int h,bool,int,int,int,int,juce::ComboBox&)
{
    juce::ColourGradient grad(juce::Colour(0xff373c42),0,0,juce::Colour(0xff0e1114),0,(float)h,false);
    g.setGradientFill(grad); g.fillRect(0,0,w,h); g.setColour(juce::Colour(0xff858b92)); g.drawRect(0,0,w,h,1);
    juce::Path arrow; arrow.addTriangle((float)w-20,(float)h*.40f,(float)w-8,(float)h*.40f,(float)w-14,(float)h*.66f);
    g.setColour(juce::Colour(0xffefefeb)); g.fillPath(arrow);
}

void KickcrafterAudioProcessorEditor::ExportPad::paint(juce::Graphics& g)
{
    juce::ColourGradient grad(juce::Colour(0xff3a3f46),0,0,juce::Colour(0xff0c0f12),0,(float)getHeight(),false);
    g.setGradientFill(grad); g.fillRect(getLocalBounds()); g.setColour(juce::Colour(0xffff1635)); g.drawRect(getLocalBounds(),2);
    g.setColour(juce::Colours::white); g.setFont(juce::FontOptions("Bahnschrift SemiCondensed",13,juce::Font::bold));
    g.drawFittedText("DRAG  /  WAV",getLocalBounds(),juce::Justification::centred,1);
}
void KickcrafterAudioProcessorEditor::ExportPad::mouseDown(const juce::MouseEvent&){armed=true;}
void KickcrafterAudioProcessorEditor::ExportPad::mouseDrag(const juce::MouseEvent& e)
{
    if(!armed||e.getDistanceFromDragStart()<8)return; armed=false;
    auto file=juce::File::getSpecialLocation(juce::File::tempDirectory).getChildFile("INDUSTRY_KICK_export.wav");
    if(proc.exportWav(file)) juce::DragAndDropContainer::performExternalDragDropOfFiles({file.getFullPathName()},false,this);
}

KickcrafterAudioProcessorEditor::KickcrafterAudioProcessorEditor(KickcrafterAudioProcessor& p)
 : AudioProcessorEditor(&p),exportPad(p),proc(p)
{
    setLookAndFeel(&look); setOpaque(true);
    chamberAtlas=juce::ImageCache::getFromMemory(BinaryData::reverbchambersv1_png,BinaryData::reverbchambersv1_pngSize);
    backgroundImage=juce::ImageCache::getFromMemory(BinaryData::pluginbackgroundbrutalistv1_png,BinaryData::pluginbackgroundbrutalistv1_pngSize);
    title.setText("INDUSTRY KICK",juce::dontSendNotification); title.setFont(juce::FontOptions("Impact",38,juce::Font::plain)); title.setColour(juce::Label::textColourId,juce::Colour(0xfffffff7));
    maker.setText("BY 909VOLTS",juce::dontSendNotification); maker.setFont(juce::FontOptions("Consolas",13,juce::Font::bold)); maker.setColour(juce::Label::textColourId,juce::Colour(0xffd6d8d4));
    tagline.setText("READY-TO-HIT / PHASE-LOCKED SYSTEM",juce::dontSendNotification); tagline.setFont(juce::FontOptions("Consolas",10,juce::Font::bold)); tagline.setColour(juce::Label::textColourId,juce::Colour(0xff9da2a8));
    for(auto* label:{&maker,&tagline}) addAndMakeVisible(label);

    addKnob("tune","TUNE",Unit::hz);
    addKnob("body","BODY",Unit::percent);
    addKnob("punchAmount","PUNCH",Unit::percent);
    addKnob("decay","LENGTH",Unit::ms);
    addKnob("drive","DRIVE",Unit::percent);
    addKnob("cabinet","COLOUR",Unit::percent);
    addKnob("metal","METAL",Unit::percent);
    addKnob("reverbAmount","REVERB",Unit::percent);
    addKnob("reverbDecay","DECAY",Unit::ms);
    addKnob("reverbWidth","WIDTH",Unit::percent);
    addKnob("sub","SUB",Unit::percent);
    addKnob("kick","IMPACT",Unit::percent);
    addKnob("tail","SPACE",Unit::percent);
    addKnob("crunch","GRIT",Unit::percent);
    addKnob("shapeAmount","SHAPE",Unit::percent,"smart-shape");
    addKnob("evolveAmount","EVOLVE",Unit::percent,"smart-evolve");
    addKnob("destroyAmount","DESTROY",Unit::percent,"smart-destroy");
    addKnob("output","OUTPUT",Unit::db);
    addKnob("clipper","CLIPPER",Unit::percent);

    waveformSelect.addItemList({"ROUND / SINE","PUNCH / TRIANGLE","HARD / CLIPPED","INDUSTRIAL / HYBRID","RAVE / SAW"},1);
    addAndMakeVisible(waveformSelect); waveformAttachment=std::make_unique<CA>(proc.apvts,"waveform",waveformSelect);
    waveformSelect.onChange=[this]{repaint(waveformArea);};
    int chamberId=1;
    chamberSelect.addSectionHeading("TIGHT / SHORT");
    for(const auto& name:{"AIRLOCK","BOOTH","DRUM CELL","CONCRETE BOX","SHORT PLATE"}) chamberSelect.addItem(name,chamberId++);
    chamberSelect.addSectionHeading("ROOMS");
    for(const auto& name:{"STUDIO","CONCRETE ROOM","STONE CHAMBER","WAREHOUSE","HANGAR"}) chamberSelect.addItem(name,chamberId++);
    chamberSelect.addSectionHeading("PASSAGES");
    for(const auto& name:{"CORRIDOR","TUNNEL","SEWER","SERVICE SHAFT","UNDERGROUND"}) chamberSelect.addItem(name,chamberId++);
    chamberSelect.addSectionHeading("METAL / EXTREME");
    for(const auto& name:{"STEEL PLATE","OIL TANK","CONTAINER","REACTOR","ABYSS"}) chamberSelect.addItem(name,chamberId++);
    addAndMakeVisible(chamberSelect); chamberAttachment=std::make_unique<CA>(proc.apvts,"irSelect",chamberSelect);
    chamberSelect.onChange=[this]{repaint(chamberArea);};
    addAndMakeVisible(presetBox); addAndMakeVisible(exportPad);
    preview.setComponentID("trigger"); randomizeBtn.setComponentID("randomizer");
    for(auto* button:{&preview,&randomizeBtn,&presetPrevBtn,&presetNextBtn,&saveBtn,&undoBtn,&redoBtn}) addAndMakeVisible(button);
    preview.onClick=[this]{proc.triggerPreview();};
    randomizeBtn.onClick=[this]{proc.randomizeParameters();repaint();};
    presetPrevBtn.onClick=[this]{stepPreset(-1);};
    presetNextBtn.onClick=[this]{stepPreset(1);};
    saveBtn.onClick=[this]{proc.savePreset("User "+juce::Time::getCurrentTime().formatted("%Y%m%d-%H%M%S"));refreshPresets();};
    presetBox.onChange=[this]
    {
        const int id=presetBox.getSelectedId();
        if(id>=1&&id<=50) proc.loadFactoryPreset(id-1);
        else if(id>=1001)
        {
            const auto files=proc.presets(); const int index=id-1001;
            if(juce::isPositiveAndBelow(index,files.size())) proc.loadPreset(files[index]);
        }
    };
    undoBtn.onClick=[this]{proc.undo.undo();}; redoBtn.onClick=[this]{proc.undo.redo();};
    refreshPresets();
    setResizable(true,true); getConstrainer()->setFixedAspectRatio(baseW/baseH); setResizeLimits(900,575,1600,1022); setSize(1152,736); startTimerHz(12);
}

KickcrafterAudioProcessorEditor::~KickcrafterAudioProcessorEditor(){setLookAndFeel(nullptr);}

void KickcrafterAudioProcessorEditor::addKnob(const char* id,const char* label,Unit unit,const char* style)
{
    auto slider=std::make_unique<juce::Slider>(juce::Slider::RotaryHorizontalVerticalDrag,juce::Slider::TextBoxBelow);
    slider->setName(label); slider->setComponentID(style); slider->setTextBoxStyle(juce::Slider::TextBoxBelow,false,92,21);
    if(unit==Unit::percent)
    {
        slider->textFromValueFunction=[](double v){return juce::String(juce::roundToInt(v*100.0))+" %";};
        slider->valueFromTextFunction=[](const juce::String& t){return t.retainCharacters("0123456789.-").getDoubleValue()/100.0;};
    }
    else if(unit==Unit::hz){slider->setTextValueSuffix(" Hz");slider->setNumDecimalPlacesToDisplay(1);}
    else if(unit==Unit::ms){slider->setTextValueSuffix(" ms");slider->setNumDecimalPlacesToDisplay(0);}
    else if(unit==Unit::db){slider->setTextValueSuffix(" dB");slider->setNumDecimalPlacesToDisplay(1);}
    addAndMakeVisible(*slider);
    sliderAttachments.push_back(std::make_unique<SA>(proc.apvts,id,*slider)); knobs.push_back(std::move(slider));
}

void KickcrafterAudioProcessorEditor::refreshPresets()
{
    presetBox.clear();
    const auto factory=proc.factoryPresetNames();
    const char* categories[]={"ROUND / SUB","PUNCH","HARD / CLIPPED","INDUSTRIAL","RAVE / SAW"};
    for(int i=0;i<factory.size();++i)
    {
        if(i%10==0) presetBox.addSectionHeading(categories[i/10]);
        presetBox.addItem(factory[i],i+1);
    }
    const auto user=proc.presets();
    if(!user.isEmpty())
    {
        presetBox.addSeparator(); presetBox.addSectionHeading("USER PRESETS");
        for(int i=0;i<user.size();++i) presetBox.addItem(user[i].getFileNameWithoutExtension(),1001+i);
    }
    presetBox.setTextWhenNothingSelected("PRESETS / BANK");
}

void KickcrafterAudioProcessorEditor::stepPreset(int direction)
{
    const int factoryCount=proc.factoryPresetNames().size();
    const int userCount=proc.presets().size();
    const int total=factoryCount+userCount;
    if(total<=0) return;

    const int selected=presetBox.getSelectedId();
    int position=0;
    if(selected>=1&&selected<=factoryCount) position=selected-1;
    else if(selected>=1001&&selected<1001+userCount) position=factoryCount+(selected-1001);
    else position=direction<0?0:-1;

    position=(position+direction+total)%total;
    const int targetId=position<factoryCount?position+1:1001+(position-factoryCount);
    presetBox.setSelectedId(targetId,juce::sendNotificationSync);
}

void KickcrafterAudioProcessorEditor::timerCallback()
{
    meterL=juce::jmax(proc.getOutputPeakL(),meterL*.78f);
    meterR=juce::jmax(proc.getOutputPeakR(),meterR*.78f);
    repaint(scopeArea); repaint(meterArea);
}

juce::Rectangle<int> KickcrafterAudioProcessorEditor::R(float x,float y,float w,float h) const
{
    const float sx=getWidth()/baseW,sy=getHeight()/baseH;
    return {juce::roundToInt(x*sx),juce::roundToInt(y*sy),juce::roundToInt(w*sx),juce::roundToInt(h*sy)};
}

void KickcrafterAudioProcessorEditor::paint(juce::Graphics& g)
{
    const float sx=getWidth()/baseW,sy=getHeight()/baseH;
    g.addTransform(juce::AffineTransform::scale(sx,sy));
    if(backgroundImage.isValid())
    {
        const int sideCrop=juce::roundToInt(backgroundImage.getWidth()*.091f);
        g.drawImage(backgroundImage,0,0,(int)baseW,(int)baseH,sideCrop,0,backgroundImage.getWidth()-sideCrop*2,backgroundImage.getHeight(),false);
    }
    else { juce::ColourGradient base(juce::Colour(0xff1a1d20),0,0,juce::Colour(0xff060708),baseW,baseH,true); g.setGradientFill(base); g.fillRect(0.0f,0.0f,baseW,baseH); }
    g.setColour(juce::Colour(0x12000000)); g.fillRect(0.0f,0.0f,baseW,baseH);
    g.setColour(juce::Colour(0xe50d1013)); g.fillRect(0.0f,0.0f,baseW,78.0f);
    g.setColour(juce::Colour(0xffff1635)); g.fillRect(0.0f,75.0f,baseW,3.0f);
    g.setColour(juce::Colour(0x88282b2f)); g.fillRect(0.0f,0.0f,14.0f,baseH); g.fillRect(baseW-14.0f,0.0f,14.0f,baseH);
    for(int y=18;y<900;y+=38){g.setColour(juce::Colour(0xff050607));g.fillEllipse(4.0f,(float)y,6.0f,6.0f);g.fillEllipse(baseW-10.0f,(float)y,6.0f,6.0f);}

    juce::GlyphArrangement titleGlyphs;
    titleGlyphs.addLineOfText(juce::Font(juce::FontOptions("Impact",38.0f,juce::Font::plain)),"INDUSTRY KICK",30.0f,56.0f);
    juce::Path titlePath; titleGlyphs.createPath(titlePath);
    g.setColour(juce::Colour(0xfffffff7)); g.fillPath(titlePath);
    g.saveState(); g.reduceClipRegion(titlePath,juce::AffineTransform());
    juce::Random titleWear(0x39303956);
    for(int i=0;i<42;++i)
    {
        const float x=30.0f+titleWear.nextFloat()*282.0f,y=20.0f+titleWear.nextFloat()*35.0f;
        g.setColour(juce::Colour(i%3==0?0xaa050607:0x66050607));
        g.drawLine(x,y,x+4.0f+titleWear.nextFloat()*22.0f,y+titleWear.nextFloat()*1.8f,1.1f+titleWear.nextFloat()*1.2f);
    }
    g.restoreState();

    auto panel=[&](float x,float y,float w,float h,const juce::String& titleText)
    {
        juce::Rectangle<float> r(x,y,w,h);
        g.setColour(juce::Colour(0x74151a1f)); g.fillRoundedRectangle(r,4); g.setColour(juce::Colour(0xcc858b92)); g.drawRoundedRectangle(r,4,1.2f);
        juce::Random wear(juce::roundToInt(x*31.0f+y*17.0f+w*7.0f+h));
        const int scratchCount=juce::roundToInt(w*h/5400.0f);
        for(int i=0;i<scratchCount;++i)
        {
            const float sx=x+10.0f+wear.nextFloat()*(w-20.0f);
            const float sy=y+9.0f+wear.nextFloat()*(h-18.0f);
            const float length=8.0f+wear.nextFloat()*74.0f;
            g.setColour(i%7==0?juce::Colour(0x20ff1635):juce::Colour(0x20d8dcdf));
            g.drawLine(sx,sy,juce::jmin(x+w-8.0f,sx+length),sy+(wear.nextFloat()-.5f)*2.2f,.45f+wear.nextFloat()*.65f);
        }
        for(int i=0;i<scratchCount/2;++i)
        {
            const float sx=x+8.0f+wear.nextFloat()*(w-16.0f),sy=y+8.0f+wear.nextFloat()*(h-16.0f);
            const float size=.6f+wear.nextFloat()*2.0f;
            g.setColour(juce::Colour(0x2a020304)); g.fillEllipse(sx,sy,size*2.4f,size);
        }
        g.setColour(juce::Colour(0xffff1635)); g.fillRect(x,y,6.0f,h);
        g.setColour(juce::Colour(0xfffffff7)); g.setFont(juce::FontOptions("Bahnschrift SemiCondensed",15,juce::Font::bold));
        g.drawText(titleText,juce::Rectangle<float>(x+18,y+10,w-36,22),juce::Justification::centredLeft);
        g.setColour(juce::Colour(0xffff1635)); g.fillRect(x+18,y+34,54.0f,2.0f);
        for(auto p:{juce::Point<float>(x+12,y+12),juce::Point<float>(x+w-12,y+12),juce::Point<float>(x+12,y+h-12),juce::Point<float>(x+w-12,y+h-12)}){g.setColour(juce::Colour(0xff050607));g.fillEllipse(p.x-3,p.y-3,6,6);g.setColour(juce::Colour(0xff62666b));g.drawEllipse(p.x-3,p.y-3,6,6,1);}
    };
    panel(20,92,700,246,"01  /  CORE"); panel(735,92,685,246,"02  /  CHARACTER");
    panel(20,354,900,280,"03  /  SPACE"); panel(935,354,485,280,"04  /  MIX CONTROL");
    panel(20,650,1050,250,"05  /  KICK LAB"); panel(1085,650,335,250,"06  /  OUTPUT");

    g.setColour(juce::Colour(0xff85898e));g.setFont(juce::FontOptions("Consolas",9.5f,juce::Font::bold));
    g.drawText("CORE TYPE",38,301,105,22,juce::Justification::centredLeft);
    juce::Rectangle<float> waveBox(455,296,235,29);g.setColour(juce::Colour(0xff070809));g.fillRect(waveBox);g.setColour(juce::Colour(0xff4b4f54));g.drawRect(waveBox,1.0f);
    juce::Path wavePreview;const int waveType=juce::jlimit(0,4,waveformSelect.getSelectedItemIndex());
    for(int i=0;i<=120;++i){const float phase=(float)i/120.0f*juce::MathConstants<float>::twoPi*2.0f;const float sine=std::sin(phase);float value=sine;if(waveType==1)value=(2.0f/juce::MathConstants<float>::pi)*std::asin(sine);else if(waveType==2)value=std::tanh(sine*3.4f)/std::tanh(3.4f);else if(waveType==3)value=juce::jlimit(-1.0f,1.0f,sine*.94f+std::sin(phase*2)*.07f+std::sin(phase*3)*.17f+std::sin(phase*5)*.045f);else if(waveType==4)value=juce::jlimit(-1.0f,1.0f,(sine+std::sin(phase*2)*.5f+std::sin(phase*3)*.33f+std::sin(phase*4)*.25f+std::sin(phase*5)*.2f)*.64f);const float px=waveBox.getX()+5+(float)i/120.0f*(waveBox.getWidth()-10);const float py=waveBox.getCentreY()-value*10.0f;if(i==0)wavePreview.startNewSubPath(px,py);else wavePreview.lineTo(px,py);}
    g.setColour(juce::Colour(0xffff1635));g.strokePath(wavePreview,juce::PathStrokeType(1.8f));

    g.setColour(juce::Colour(0xff090a0b)); g.fillRect(1218.0f,142.0f,178.0f,116.0f);
    g.setColour(juce::Colour(0xff373b40)); g.drawRect(1218.0f,142.0f,178.0f,116.0f,1.0f);
    auto data=proc.getScope(); juce::Path wave; wave.startNewSubPath(1223.0f,200.0f);
    for(size_t i=0;i<data.size();++i) wave.lineTo(1223.0f+(float)i/(data.size()-1)*168.0f,200.0f-data[i]*47.0f);
    g.setColour(juce::Colour(0xffff1635)); g.strokePath(wave,juce::PathStrokeType(1.6f));
    g.setColour(juce::Colour(0xff7e8287)); g.setFont(juce::FontOptions("Consolas",8.5f,juce::Font::bold)); g.drawText("512 ms / IMPACT HOLD",1224,146,166,15,juce::Justification::centredRight);

    juce::Rectangle<float> chamber(500,402,394,164);
    g.setColour(juce::Colour(0xff050607)); g.fillRect(chamber);
    if(chamberAtlas.isValid())
    {
        const int irIndex=juce::jlimit(0,19,chamberSelect.getSelectedItemIndex());
        const int selected=irIndex<10?0:(irIndex<15?1:2);
        const float sourceW=(float)chamberAtlas.getWidth()/3.0f;
        const auto destination=chamber.reduced(4).toNearestInt();
        g.drawImage(chamberAtlas,destination.getX(),destination.getY(),destination.getWidth(),destination.getHeight(),
            juce::roundToInt(selected*sourceW),0,juce::roundToInt(sourceW),chamberAtlas.getHeight(),false);
    }
    g.setColour(juce::Colour(0xffff1635)); g.drawRect(chamber,2.0f);
    g.setColour(juce::Colour(0xaa050607)); g.fillRect(chamber.getX()+4,chamber.getBottom()-28,chamber.getWidth()-8,24.0f);
    g.setColour(juce::Colour(0xfffffff7)); g.setFont(juce::FontOptions("Bahnschrift SemiCondensed",13,juce::Font::bold));
    const int irIndex=juce::jlimit(0,19,chamberSelect.getSelectedItemIndex());
    const juce::String category=irIndex<5?"TIGHT":(irIndex<10?"ROOMS":(irIndex<15?"PASSAGES":"METAL / EXTREME"));
    g.drawText(category+"  /  EMBEDDED TRUE IR",juce::Rectangle<float>(chamber.getX()+12,chamber.getBottom()-27,chamber.getWidth()-24,22),juce::Justification::centredLeft);

    juce::Rectangle<float> meter(1292,710,20,128);
    g.setColour(juce::Colour(0xdd050607));g.fillRect(meter);g.setColour(juce::Colour(0xff666a70));g.drawRect(meter,1.0f);
    const auto meterHeight=[&](float gain){const float db=juce::Decibels::gainToDecibels(juce::jmax(gain,.001f),-60.0f);return juce::jmap(db,-60.0f,0.0f,0.0f,meter.getHeight()-18.0f);};
    const float hL=meterHeight(meterL),hR=meterHeight(meterR);
    auto meterColour=[](float gain){const float db=juce::Decibels::gainToDecibels(juce::jmax(gain,.001f),-60.0f);return db>-3.0f?juce::Colour(0xffff1635):(db>-12.0f?juce::Colour(0xffffb018):juce::Colour(0xfffffff7));};
    g.setColour(meterColour(meterL));g.fillRect(meter.getX()+4,meter.getBottom()-5-hL,6.0f,hL);
    g.setColour(meterColour(meterR));g.fillRect(meter.getX()+13,meter.getBottom()-5-hR,6.0f,hR);
    g.setColour(juce::Colour(0xffb8bab7));g.setFont(juce::FontOptions("Consolas",7.5f,juce::Font::bold));g.drawText("dB",juce::Rectangle<float>(meter.getX(),meter.getY()+2,meter.getWidth(),12),juce::Justification::centred);

    // Keep the decorative output grille clear of the section title.
    for(int x=1210;x<1402;x+=14){g.setColour(juce::Colour(0xff343940));g.fillRoundedRectangle((float)x,670,7,37,2);}
    for(int x=1095;x<1405;x+=26){g.setColour(juce::Colour(0xffffb018));juce::Path stripe;stripe.addQuadrilateral((float)x+6,872,(float)x+18,872,(float)x+12,882,(float)x,882);g.fillPath(stripe);}
    g.setColour(juce::Colour(0xff85898e));g.setFont(juce::FontOptions("Consolas",9,juce::Font::bold));
    g.drawText("SAFE MACRO RANGES / SUB PROTECTED",38,872,1020,16,juce::Justification::centred);
}

void KickcrafterAudioProcessorEditor::resized()
{
    maker.setBounds(R(322,28,112,21)); tagline.setBounds(R(458,29,262,18));
    randomizeBtn.setBounds(R(720,21,115,35)); presetPrevBtn.setBounds(R(843,21,38,35)); presetNextBtn.setBounds(R(889,21,38,35));
    presetBox.setBounds(R(935,21,210,35)); saveBtn.setBounds(R(1155,21,65,35)); undoBtn.setBounds(R(1228,21,74,35)); redoBtn.setBounds(R(1310,21,74,35));
    for(int i=0;i<4;++i) knobs[(size_t)i]->setBounds(R(48.0f+(float)i*165.0f,132,145,160));
    waveformSelect.setBounds(R(145,296,290,29));waveformArea=R(455,296,235,29);
    for(int i=0;i<3;++i) knobs[(size_t)(4+i)]->setBounds(R(765.0f+(float)i*150.0f,132,135,160));
    scopeArea=R(1218,142,178,116);
    for(int i=0;i<3;++i) knobs[(size_t)(7+i)]->setBounds(R(52.0f+(float)i*150.0f,400,135,160));
    chamberArea=R(500,402,394,164); chamberSelect.setBounds(R(500,576,394,36));
    knobs[10]->setBounds(R(960,400,205,112)); knobs[11]->setBounds(R(1175,400,205,112));
    knobs[12]->setBounds(R(960,508,205,112)); knobs[13]->setBounds(R(1175,508,205,112));
    for(int i=0;i<3;++i) knobs[(size_t)(14+i)]->setBounds(R(110.0f+(float)i*320.0f,684,260,170));
    preview.setBounds(R(1098,720,88,108)); knobs[17]->setBounds(R(1186,708,104,135)); knobs[18]->setBounds(R(1314,708,90,135));
    meterArea=R(1292,710,20,128); exportPad.setBounds(R(1098,850,306,38));
}
