#include "PluginEditor.h"
#include <BinaryData.h>
#include <cmath>

KickcrafterAudioProcessorEditor::IndustrialLook::IndustrialLook()
{
    const auto text = juce::Colour(0xfff0f0eb);
    const auto steel = juce::Colour(0xff737a82);
    setColour(juce::Slider::textBoxTextColourId, text);
    setColour(juce::Slider::textBoxBackgroundColourId, juce::Colour(0xff0b0d0f));
    setColour(juce::Slider::textBoxOutlineColourId, steel.darker(0.35f));
    setColour(juce::ComboBox::backgroundColourId, juce::Colour(0xff111418));
    setColour(juce::ComboBox::textColourId, text);
    setColour(juce::ComboBox::outlineColourId, steel);
    setColour(juce::PopupMenu::backgroundColourId, juce::Colour(0xff111418));
    setColour(juce::PopupMenu::textColourId, text);
    setColour(juce::PopupMenu::highlightedBackgroundColourId, juce::Colour(0xff7f0d1e));
    setColour(juce::PopupMenu::highlightedTextColourId, juce::Colours::white);
    setColour(juce::TextButton::textColourOffId, text);
    setColour(juce::TextButton::textColourOnId, juce::Colours::white);
}

void KickcrafterAudioProcessorEditor::IndustrialLook::drawRotarySlider(
    juce::Graphics& g, int x, int y, int w, int h, float pos,
    float a0, float a1, juce::Slider& s)
{
    const bool smart = s.getComponentID().startsWith("smart-");
    auto bounds = juce::Rectangle<float>((float)x, (float)y, (float)w, (float)h)
                      .reduced(smart ? 14.0f : 10.0f)
                      .withTrimmedBottom(smart ? 31.0f : 24.0f);

    const auto c = bounds.getCentre();
    const float radius = juce::jmin(bounds.getWidth(), bounds.getHeight()) * (smart ? 0.37f : 0.35f);
    const float angle = a0 + pos * (a1 - a0);
    const auto accent = juce::Colour(0xffef1838);
    const auto steel = juce::Colour(0xff777d84);

    // Mechanical shadow and fixed mounting ring.
    g.setColour(juce::Colour(0x85000000));
    g.fillEllipse(c.x - radius - 8.0f, c.y - radius - 3.0f,
                  (radius + 8.0f) * 2.0f, (radius + 8.0f) * 2.0f);

    juce::ColourGradient rim(juce::Colour(0xff858b92), c.x - radius, c.y - radius,
                             juce::Colour(0xff191d21), c.x + radius, c.y + radius, false);
    g.setGradientFill(rim);
    g.fillEllipse(c.x - radius - 4.0f, c.y - radius - 4.0f,
                  (radius + 4.0f) * 2.0f, (radius + 4.0f) * 2.0f);

    g.setColour(juce::Colour(0xff08090b));
    g.fillEllipse(c.x - radius, c.y - radius, radius * 2.0f, radius * 2.0f);

    juce::ColourGradient face(juce::Colour(0xff343a40), c.x - radius, c.y - radius,
                              juce::Colour(0xff0a0c0e), c.x + radius, c.y + radius, false);
    g.setGradientFill(face);
    g.fillEllipse(c.x - radius + 3.0f, c.y - radius + 3.0f,
                  (radius - 3.0f) * 2.0f, (radius - 3.0f) * 2.0f);

    // Calibrated engraved tick marks: intentional, not decorative scratches.
    const int tickCount = smart ? 13 : 11;
    for (int i = 0; i < tickCount; ++i)
    {
        const float t = (float)i / (float)(tickCount - 1);
        const float a = a0 + t * (a1 - a0);
        const float inner = radius + 8.5f;
        const float outer = radius + (i == 0 || i == tickCount - 1 ? 14.0f : 12.0f);
        const juce::Point<float> p1(c.x + std::sin(a) * inner, c.y - std::cos(a) * inner);
        const juce::Point<float> p2(c.x + std::sin(a) * outer, c.y - std::cos(a) * outer);
        g.setColour(steel.withAlpha(i == 0 || i == tickCount - 1 ? 0.85f : 0.55f));
        g.drawLine(juce::Line<float>(p1, p2), 1.0f);
    }

    juce::Path track;
    track.addCentredArc(c.x, c.y, radius + 8.0f, radius + 8.0f, 0.0f, a0, a1, true);
    g.setColour(juce::Colour(0xff353a40));
    g.strokePath(track, juce::PathStrokeType(smart ? 6.5f : 5.0f,
                                             juce::PathStrokeType::curved,
                                             juce::PathStrokeType::rounded));

    juce::Path valueArc;
    valueArc.addCentredArc(c.x, c.y, radius + 8.0f, radius + 8.0f, 0.0f, a0, angle, true);
    g.setColour(accent);
    g.strokePath(valueArc, juce::PathStrokeType(smart ? 4.5f : 3.2f,
                                                juce::PathStrokeType::curved,
                                                juce::PathStrokeType::rounded));

    // Pointer is a physical white/red insert rather than a glowing ornament.
    juce::Path pointer;
    pointer.addRoundedRectangle(-1.8f, -radius + 8.0f, 3.6f,
                                radius * (smart ? 0.64f : 0.54f), 1.8f);
    g.setColour(smart ? accent : juce::Colour(0xfff2f2ed));
    g.fillPath(pointer, juce::AffineTransform::rotation(angle).translated(c));

    g.setColour(juce::Colour(0xff060708));
    g.fillEllipse(c.x - 5.0f, c.y - 5.0f, 10.0f, 10.0f);
    g.setColour(steel);
    g.drawEllipse(c.x - 5.0f, c.y - 5.0f, 10.0f, 10.0f, 1.0f);

    g.setColour(smart ? accent : juce::Colour(0xffd7d9d5));
    g.setFont(juce::FontOptions("Bahnschrift SemiCondensed",
                                smart ? 17.0f : 12.5f, juce::Font::bold));
    g.drawFittedText(s.getName(), x, y + h - (smart ? 29 : 22),
                     w, smart ? 22 : 18, juce::Justification::centred, 1, 0.76f);
}

void KickcrafterAudioProcessorEditor::IndustrialLook::drawButtonBackground(
    juce::Graphics& g, juce::Button& b, const juce::Colour&, bool over, bool down)
{
    auto r = b.getLocalBounds().toFloat().reduced(0.5f);
    const bool critical = b.getComponentID() == "trigger" || b.getComponentID() == "randomizer";

    juce::Colour top = down ? juce::Colour(0xff761020)
                            : (over ? juce::Colour(0xff444a50) : juce::Colour(0xff2c3136));
    juce::Colour bottom = juce::Colour(0xff0a0c0e);
    juce::ColourGradient grad(top, 0.0f, 0.0f, bottom, 0.0f, r.getBottom(), false);
    g.setGradientFill(grad);
    g.fillRoundedRectangle(r, 2.0f);

    g.setColour(critical ? juce::Colour(0xffef1838) : juce::Colour(0xff6f767d));
    g.drawRoundedRectangle(r, 2.0f, critical ? 1.5f : 1.0f);

    g.setColour(juce::Colour(0x35ffffff));
    g.drawLine(r.getX() + 4.0f, r.getY() + 3.0f, r.getRight() - 4.0f, r.getY() + 3.0f, 0.8f);

    if (critical)
    {
        g.setColour(juce::Colour(0xffef1838));
        g.fillRect(r.getX() + 4.0f, r.getBottom() - 4.0f, r.getWidth() - 8.0f, 2.0f);
    }
}

void KickcrafterAudioProcessorEditor::IndustrialLook::drawComboBox(
    juce::Graphics& g, int w, int h, bool, int, int, int, int, juce::ComboBox&)
{
    auto r = juce::Rectangle<float>(0.0f, 0.0f, (float)w, (float)h);
    juce::ColourGradient grad(juce::Colour(0xff292e33), 0.0f, 0.0f,
                              juce::Colour(0xff0b0d10), 0.0f, (float)h, false);
    g.setGradientFill(grad);
    g.fillRect(r);

    g.setColour(juce::Colour(0xff747b82));
    g.drawRect(r, 1.0f);
    g.setColour(juce::Colour(0x30ffffff));
    g.drawLine(4.0f, 3.0f, (float)w - 4.0f, 3.0f, 0.8f);

    juce::Path arrow;
    arrow.addTriangle((float)w - 22.0f, (float)h * 0.42f,
                      (float)w - 8.0f, (float)h * 0.42f,
                      (float)w - 15.0f, (float)h * 0.65f);
    g.setColour(juce::Colour(0xffe8e9e5));
    g.fillPath(arrow);
}

void KickcrafterAudioProcessorEditor::ExportPad::paint(juce::Graphics& g)
{
    auto r = getLocalBounds().toFloat().reduced(0.5f);
    juce::ColourGradient grad(juce::Colour(0xff2b3036), 0.0f, 0.0f,
                              juce::Colour(0xff080a0c), 0.0f, r.getBottom(), false);
    g.setGradientFill(grad);
    g.fillRoundedRectangle(r, 2.0f);

    g.setColour(juce::Colour(0xff6e757c));
    g.drawRoundedRectangle(r, 2.0f, 1.0f);
    g.setColour(juce::Colour(0xffef1838));
    g.fillRect(r.getX() + 5.0f, r.getBottom() - 4.0f, r.getWidth() - 10.0f, 2.0f);

    g.setColour(juce::Colour(0xffedede8));
    g.setFont(juce::FontOptions("Bahnschrift SemiCondensed", 13.0f, juce::Font::bold));
    g.drawFittedText("DRAG WAV", getLocalBounds(), juce::Justification::centred, 1);
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
    tagline.setText("FAMILY ENGINE / MASTER GLUE SYSTEM",juce::dontSendNotification); tagline.setFont(juce::FontOptions("Consolas",10,juce::Font::bold)); tagline.setColour(juce::Label::textColourId,juce::Colour(0xff9da2a8));
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
    addKnob("kick","KICK",Unit::percent);
    addKnob("tail","TAIL",Unit::percent);
    addKnob("crunch","CRUNCH",Unit::percent);
    addKnob("shapeAmount","SHAPE",Unit::percent,"smart-shape");
    addKnob("evolveAmount","EVOLVE",Unit::percent,"smart-evolve");
    addKnob("destroyAmount","DESTROY",Unit::percent,"smart-destroy");
    addKnob("output","OUTPUT",Unit::db);
    addKnob("clipper","CLIP",Unit::percent);

    waveformSelect.addItemList({"ROUND / SINE","PUNCH / TRIANGLE","HARD / CLIPPED","INDUSTRIAL / HYBRID","RAVE / SAW"},1);
    addAndMakeVisible(waveformSelect); waveformAttachment=std::make_unique<CA>(proc.apvts,"waveform",waveformSelect);
    waveformSelect.onChange=[this]{repaint();};
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
    chamberSelect.onChange=[this]{repaint();};
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
    const float sx = getWidth() / baseW;
    const float sy = getHeight() / baseH;
    g.addTransform(juce::AffineTransform::scale(sx, sy));

    if (backgroundImage.isValid())
    {
        const int sideCrop = juce::roundToInt(backgroundImage.getWidth() * 0.091f);
        g.drawImage(backgroundImage, 0, 0, (int)baseW, (int)baseH,
                    sideCrop, 0, backgroundImage.getWidth() - sideCrop * 2,
                    backgroundImage.getHeight(), false);
    }
    else
    {
        juce::ColourGradient base(juce::Colour(0xff171a1d), 0, 0,
                                  juce::Colour(0xff050607), baseW, baseH, true);
        g.setGradientFill(base);
        g.fillRect(0.0f, 0.0f, baseW, baseH);
    }

    // Header rail: clean mechanical identity, no random glitch/scratch filler.
    g.setColour(juce::Colour(0xe80a0c0f));
    g.fillRect(0.0f, 0.0f, baseW, 78.0f);
    g.setColour(juce::Colour(0xffef1838));
    g.fillRect(0.0f, 75.0f, baseW, 3.0f);

    g.setColour(juce::Colour(0xaa2a2e32));
    g.fillRect(0.0f, 0.0f, 14.0f, baseH);
    g.fillRect(baseW - 14.0f, 0.0f, 14.0f, baseH);

    // Side fasteners are mechanically regular.
    for (int y = 18; y < 900; y += 44)
    {
        for (float x : { 7.0f, baseW - 7.0f })
        {
            g.setColour(juce::Colour(0xff050607));
            g.fillEllipse(x - 3.0f, (float)y - 3.0f, 6.0f, 6.0f);
            g.setColour(juce::Colour(0xff61676d));
            g.drawEllipse(x - 3.0f, (float)y - 3.0f, 6.0f, 6.0f, 0.8f);
        }
    }

    g.setColour(juce::Colour(0xfff3f3ee));
    g.setFont(juce::FontOptions("Impact", 38.0f, juce::Font::plain));
    g.drawText("INDUSTRY KICK", 30, 16, 288, 46, juce::Justification::centredLeft);

    g.setColour(juce::Colour(0xffef1838));
    g.fillRect(30.0f, 62.0f, 104.0f, 3.0f);
    g.setColour(juce::Colour(0xff858b91));
    g.fillRect(140.0f, 62.0f, 146.0f, 1.0f);

    auto drawBolt = [&](juce::Point<float> p)
    {
        g.setColour(juce::Colour(0xff050607));
        g.fillEllipse(p.x - 3.5f, p.y - 3.5f, 7.0f, 7.0f);
        g.setColour(juce::Colour(0xff656b71));
        g.drawEllipse(p.x - 3.5f, p.y - 3.5f, 7.0f, 7.0f, 1.0f);
        g.drawLine(p.x - 2.0f, p.y, p.x + 2.0f, p.y, 0.8f);
    };

    auto panel = [&](float x, float y, float w, float h,
                     const juce::String& titleText, const juce::String& subtitle)
    {
        juce::Rectangle<float> r(x, y, w, h);

        g.setColour(juce::Colour(0x94101418));
        g.fillRoundedRectangle(r, 4.0f);

        // Bevel and structural seam.
        g.setColour(juce::Colour(0xc9787e84));
        g.drawRoundedRectangle(r, 4.0f, 1.1f);
        g.setColour(juce::Colour(0x48000000));
        g.drawRoundedRectangle(r.reduced(4.0f), 3.0f, 1.0f);

        g.setColour(juce::Colour(0xd80b0d10));
        g.fillRect(x + 8.0f, y + 7.0f, w - 16.0f, 34.0f);

        g.setColour(juce::Colour(0xffef1838));
        g.fillRect(x + 13.0f, y + 13.0f, 4.0f, 21.0f);

        g.setColour(juce::Colour(0xfff1f1ec));
        g.setFont(juce::FontOptions("Bahnschrift SemiCondensed", 15.0f, juce::Font::bold));
        g.drawText(titleText, juce::Rectangle<float>(x + 25.0f, y + 10.0f, w - 180.0f, 25.0f),
                   juce::Justification::centredLeft);

        g.setColour(juce::Colour(0xff7e858b));
        g.setFont(juce::FontOptions("Consolas", 8.5f, juce::Font::bold));
        g.drawText(subtitle, juce::Rectangle<float>(x + w - 178.0f, y + 11.0f, 158.0f, 22.0f),
                   juce::Justification::centredRight);

        drawBolt({ x + 12.0f, y + 12.0f });
        drawBolt({ x + w - 12.0f, y + 12.0f });
        drawBolt({ x + 12.0f, y + h - 12.0f });
        drawBolt({ x + w - 12.0f, y + h - 12.0f });
    };

    panel(20, 92, 700, 246, "01 / CORE", "PITCH / BODY / TRANSIENT");
    panel(735, 92, 685, 246, "02 / MATERIAL", "SATURATION / HARMONICS");
    panel(20, 354, 900, 280, "03 / SPACE", "IR CHAMBER / TAIL");
    panel(935, 354, 485, 280, "04 / BODY MIX", "SUB / KICK / TAIL / CRUNCH");
    panel(20, 650, 1050, 250, "05 / MUTANT", "SHAPE / EVOLVE / DESTROY");
    panel(1085, 650, 335, 250, "06 / MASTER", "FIXED GLUE CHAIN");

    // CORE family selector and compact family waveform.
    g.setColour(juce::Colour(0xff7f858b));
    g.setFont(juce::FontOptions("Consolas", 9.0f, juce::Font::bold));
    g.drawText("FAMILY", 38, 298, 98, 20, juce::Justification::centredLeft);

    juce::Rectangle<float> waveBox(455, 296, 235, 29);
    g.setColour(juce::Colour(0xff07090b));
    g.fillRect(waveBox);
    g.setColour(juce::Colour(0xff454b51));
    g.drawRect(waveBox, 1.0f);

    for (int i = 1; i < 4; ++i)
    {
        const float gx = waveBox.getX() + waveBox.getWidth() * (float)i / 4.0f;
        g.setColour(juce::Colour(0x244f555b));
        g.drawVerticalLine(juce::roundToInt(gx), waveBox.getY() + 4.0f, waveBox.getBottom() - 4.0f);
    }
    g.setColour(juce::Colour(0x304f555b));
    g.drawHorizontalLine(juce::roundToInt(waveBox.getCentreY()),
                         waveBox.getX() + 4.0f, waveBox.getRight() - 4.0f);

    juce::Path wavePreview;
    const int waveType = juce::jlimit(0, 4, waveformSelect.getSelectedItemIndex());
    for (int i = 0; i <= 120; ++i)
    {
        const float phase = (float)i / 120.0f * juce::MathConstants<float>::twoPi * 2.0f;
        const float sine = std::sin(phase);
        float value = sine;
        if (waveType == 1)
            value = (2.0f / juce::MathConstants<float>::pi) * std::asin(sine);
        else if (waveType == 2)
            value = std::tanh(sine * 3.4f) / std::tanh(3.4f);
        else if (waveType == 3)
            value = juce::jlimit(-1.0f, 1.0f,
                                 sine * 0.94f + std::sin(phase * 2.0f) * 0.07f
                                 + std::sin(phase * 3.0f) * 0.17f
                                 + std::sin(phase * 5.0f) * 0.045f);
        else if (waveType == 4)
            value = juce::jlimit(-1.0f, 1.0f,
                                 (sine + std::sin(phase * 2.0f) * 0.5f
                                 + std::sin(phase * 3.0f) * 0.33f
                                 + std::sin(phase * 4.0f) * 0.25f
                                 + std::sin(phase * 5.0f) * 0.2f) * 0.64f);

        const float px = waveBox.getX() + 5.0f
                       + (float)i / 120.0f * (waveBox.getWidth() - 10.0f);
        const float py = waveBox.getCentreY() - value * 9.5f;
        if (i == 0) wavePreview.startNewSubPath(px, py);
        else wavePreview.lineTo(px, py);
    }

    g.setColour(juce::Colour(0xffef1838));
    g.strokePath(wavePreview, juce::PathStrokeType(1.7f));

    // MATERIAL scope: family identity and transient/body relationship.
    juce::Rectangle<float> scope(1212.0f, 139.0f, 184.0f, 122.0f);
    g.setColour(juce::Colour(0xee06080a));
    g.fillRect(scope);
    g.setColour(juce::Colour(0xff454b51));
    g.drawRect(scope, 1.0f);

    for (int i = 1; i < 4; ++i)
    {
        g.setColour(juce::Colour(0x284d5359));
        const float y = scope.getY() + scope.getHeight() * (float)i / 4.0f;
        g.drawHorizontalLine(juce::roundToInt(y), scope.getX() + 4.0f, scope.getRight() - 4.0f);
    }

    const auto data = proc.getScope();
    juce::Path scopeWave;
    scopeWave.startNewSubPath(scope.getX() + 5.0f, scope.getCentreY());
    for (size_t i = 0; i < data.size(); ++i)
    {
        const float px = scope.getX() + 5.0f
                       + (float)i / (float)(data.size() - 1) * (scope.getWidth() - 10.0f);
        const float py = scope.getCentreY() - data[i] * (scope.getHeight() * 0.39f);
        scopeWave.lineTo(px, py);
    }
    g.setColour(juce::Colour(0xffef1838));
    g.strokePath(scopeWave, juce::PathStrokeType(1.5f));

    g.setColour(juce::Colour(0xff8a9096));
    g.setFont(juce::FontOptions("Consolas", 8.0f, juce::Font::bold));
    g.drawText(waveformSelect.getText(), juce::Rectangle<float>(
                   scope.getX() + 6.0f, scope.getY() + 5.0f, scope.getWidth() - 12.0f, 14.0f),
               juce::Justification::centredRight);

    // SPACE chamber display.
    juce::Rectangle<float> chamber(500, 402, 394, 164);
    g.setColour(juce::Colour(0xff050607));
    g.fillRect(chamber);
    if (chamberAtlas.isValid())
    {
        const int irIndex = juce::jlimit(0, 19, chamberSelect.getSelectedItemIndex());
        const int selected = irIndex < 10 ? 0 : (irIndex < 15 ? 1 : 2);
        const float sourceW = (float)chamberAtlas.getWidth() / 3.0f;
        const auto destination = chamber.reduced(4.0f).toNearestInt();
        g.drawImage(chamberAtlas,
                    destination.getX(), destination.getY(),
                    destination.getWidth(), destination.getHeight(),
                    juce::roundToInt(selected * sourceW), 0,
                    juce::roundToInt(sourceW), chamberAtlas.getHeight(), false);
    }
    g.setColour(juce::Colour(0xff727980));
    g.drawRect(chamber, 1.0f);
    g.setColour(juce::Colour(0xffef1838));
    g.fillRect(chamber.getX(), chamber.getY(), 4.0f, chamber.getHeight());

    const int irIndex = juce::jlimit(0, 19, chamberSelect.getSelectedItemIndex());
    const juce::String category = irIndex < 5 ? "TIGHT"
                               : (irIndex < 10 ? "ROOM"
                               : (irIndex < 15 ? "PASSAGE" : "METAL"));
    g.setColour(juce::Colour(0xc9050709));
    g.fillRect(chamber.getX() + 4.0f, chamber.getBottom() - 26.0f,
               chamber.getWidth() - 4.0f, 26.0f);
    g.setColour(juce::Colour(0xffeeeee9));
    g.setFont(juce::FontOptions("Bahnschrift SemiCondensed", 12.0f, juce::Font::bold));
    g.drawText(category + " / TRUE IR",
               juce::Rectangle<float>(chamber.getX() + 14.0f, chamber.getBottom() - 24.0f,
                                      chamber.getWidth() - 28.0f, 20.0f),
               juce::Justification::centredLeft);

    // MASTER meter and fixed processing topology.
    juce::Rectangle<float> meter(1288.0f, 713.0f, 30.0f, 126.0f);
    g.setColour(juce::Colour(0xe9050709));
    g.fillRect(meter);
    g.setColour(juce::Colour(0xff565d63));
    g.drawRect(meter, 1.0f);

    const auto meterHeight = [&](float gain)
    {
        const float db = juce::Decibels::gainToDecibels(juce::jmax(gain, 0.001f), -60.0f);
        return juce::jmap(db, -60.0f, 0.0f, 0.0f, meter.getHeight() - 18.0f);
    };
    const auto meterColour = [](float gain)
    {
        const float db = juce::Decibels::gainToDecibels(juce::jmax(gain, 0.001f), -60.0f);
        return db > -3.0f ? juce::Colour(0xffef1838)
             : db > -12.0f ? juce::Colour(0xffffb21a)
                           : juce::Colour(0xffe8e9e4);
    };

    const float hL = meterHeight(meterL);
    const float hR = meterHeight(meterR);
    g.setColour(meterColour(meterL));
    g.fillRect(meter.getX() + 5.0f, meter.getBottom() - 5.0f - hL, 7.0f, hL);
    g.setColour(meterColour(meterR));
    g.fillRect(meter.getX() + 18.0f, meter.getBottom() - 5.0f - hR, 7.0f, hR);

    g.setColour(juce::Colour(0xffef1838));
    g.fillRect(meter.getX() + 3.0f, meter.getY() + 9.0f, meter.getWidth() - 6.0f, 1.0f);

    g.setColour(juce::Colour(0xff7f858b));
    g.setFont(juce::FontOptions("Consolas", 7.5f, juce::Font::bold));
    g.drawText("L  R", juce::Rectangle<float>(meter.getX(), meter.getY() + 1.0f,
                                               meter.getWidth(), 10.0f),
               juce::Justification::centred);

    // Localized vent and hazard marking only in the master/output assembly.
    for (int x = 1098; x < 1400; x += 16)
    {
        g.setColour(juce::Colour(0xff343a40));
        g.fillRoundedRectangle((float)x, 674.0f, 8.0f, 24.0f, 2.0f);
    }

    g.setColour(juce::Colour(0xff8d9399));
    g.setFont(juce::FontOptions("Consolas", 8.2f, juce::Font::bold));
    g.drawText("LIGHT SAT  >  GLUE 4:1  >  HARD CLIP",
               1098, 842, 304, 18, juce::Justification::centred);

    for (int x = 1098; x < 1404; x += 28)
    {
        g.setColour(juce::Colour(0xffffb21a));
        juce::Path stripe;
        stripe.addQuadrilateral((float)x + 7.0f, 872.0f,
                                (float)x + 18.0f, 872.0f,
                                (float)x + 12.0f, 882.0f,
                                (float)x + 1.0f, 882.0f);
        g.fillPath(stripe);
    }

    // Architecture strip reinforces the sound-first structure without fake controls.
    g.setColour(juce::Colour(0xb707090b));
    g.fillRect(36.0f, 866.0f, 1012.0f, 22.0f);
    g.setColour(juce::Colour(0xff7e858b));
    g.setFont(juce::FontOptions("Consolas", 8.8f, juce::Font::bold));
    g.drawText("FAMILY DSP  >  BODY / SUB CONTROL  >  MASTER GLUE",
               48, 868, 988, 18, juce::Justification::centred);
}

void KickcrafterAudioProcessorEditor::resized()
{
    maker.setBounds(R(322, 28, 112, 21));
    tagline.setBounds(R(458, 29, 258, 18));

    randomizeBtn.setBounds(R(720, 21, 115, 35));
    presetPrevBtn.setBounds(R(843, 21, 38, 35));
    presetNextBtn.setBounds(R(889, 21, 38, 35));
    presetBox.setBounds(R(935, 21, 210, 35));
    saveBtn.setBounds(R(1155, 21, 65, 35));
    undoBtn.setBounds(R(1228, 21, 74, 35));
    redoBtn.setBounds(R(1310, 21, 74, 35));

    // CORE
    for (int i = 0; i < 4; ++i)
        knobs[(size_t)i]->setBounds(R(48.0f + (float)i * 165.0f, 132, 145, 160));
    waveformSelect.setBounds(R(145, 296, 290, 29));
    waveformArea = R(455, 296, 235, 29);

    // MATERIAL
    for (int i = 0; i < 3; ++i)
        knobs[(size_t)(4 + i)]->setBounds(R(765.0f + (float)i * 150.0f, 132, 135, 160));
    scopeArea = R(1212, 139, 184, 122);

    // SPACE
    for (int i = 0; i < 3; ++i)
        knobs[(size_t)(7 + i)]->setBounds(R(52.0f + (float)i * 150.0f, 400, 135, 160));
    chamberArea = R(500, 402, 394, 164);
    chamberSelect.setBounds(R(500, 576, 394, 36));

    // BODY MIX
    knobs[10]->setBounds(R(960, 400, 205, 112));
    knobs[11]->setBounds(R(1175, 400, 205, 112));
    knobs[12]->setBounds(R(960, 508, 205, 112));
    knobs[13]->setBounds(R(1175, 508, 205, 112));

    // MUTANT
    for (int i = 0; i < 3; ++i)
        knobs[(size_t)(14 + i)]->setBounds(R(110.0f + (float)i * 320.0f, 684, 260, 170));

    // MASTER
    preview.setBounds(R(1098, 720, 84, 108));
    knobs[17]->setBounds(R(1183, 708, 104, 135));
    knobs[18]->setBounds(R(1320, 708, 84, 135));
    meterArea = R(1288, 713, 30, 126);
    exportPad.setBounds(R(1098, 850, 306, 38));
}
