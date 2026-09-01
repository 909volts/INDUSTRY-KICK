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
                      .reduced(smart ? 10.0f : 8.0f)
                      .withTrimmedBottom(smart ? 31.0f : 23.0f);

    const auto c = bounds.getCentre();
    const float radius = juce::jmin(bounds.getWidth(), bounds.getHeight()) * (smart ? 0.345f : 0.335f);
    const float angle = a0 + pos * (a1 - a0);

    const auto accent = juce::Colour(0xffe51735);
    const auto warmSteel = juce::Colour(0xff8a8d88);
    const auto coldSteel = juce::Colour(0xff4d5358);

    g.setColour(juce::Colour(0x99000000));
    g.fillEllipse(c.x - radius - 13.0f, c.y - radius - 8.0f,
                  (radius + 13.0f) * 2.0f, (radius + 13.0f) * 2.0f);

    juce::Path bezel;
    constexpr int sides = 12;
    for (int i = 0; i < sides; ++i)
    {
        const float a = juce::MathConstants<float>::twoPi * (float)i / (float)sides
                      + juce::MathConstants<float>::pi / 12.0f;
        const juce::Point<float> p(c.x + std::cos(a) * (radius + 11.0f),
                                   c.y + std::sin(a) * (radius + 11.0f));
        if (i == 0) bezel.startNewSubPath(p); else bezel.lineTo(p);
    }
    bezel.closeSubPath();

        juce::ColourGradient bezelGrad(juce::Colour(0xff5d5a52),
                                    c.x - radius, c.y - radius,
                                    juce::Colour(0xff14100c),
                                    c.x + radius, c.y + radius, false);
    g.setGradientFill(bezelGrad);
    g.fillPath(bezel);
        g.setColour(juce::Colour(0xff050607));
    g.strokePath(bezel, juce::PathStrokeType(2.2f));
    g.setColour(juce::Colour(0x7a5a3016));
    g.strokePath(bezel, juce::PathStrokeType(1.0f));

    for (const float lugAngle : { 0.0f,
                                  juce::MathConstants<float>::halfPi,
                                  juce::MathConstants<float>::pi,
                                  juce::MathConstants<float>::pi + juce::MathConstants<float>::halfPi })
    {
        const juce::Point<float> p(c.x + std::cos(lugAngle) * (radius + 8.0f),
                                   c.y + std::sin(lugAngle) * (radius + 8.0f));
        g.setColour(juce::Colour(0xff111417));
        g.fillEllipse(p.x - 4.0f, p.y - 4.0f, 8.0f, 8.0f);
        g.setColour(coldSteel);
        g.drawEllipse(p.x - 4.0f, p.y - 4.0f, 8.0f, 8.0f, 1.0f);
    }

    g.setColour(juce::Colour(0xff050607));
    g.fillEllipse(c.x - radius - 2.0f, c.y - radius - 2.0f,
                  (radius + 2.0f) * 2.0f, (radius + 2.0f) * 2.0f);

        juce::ColourGradient face(juce::Colour(0xff33302b),
                              c.x - radius * 0.55f, c.y - radius * 0.75f,
                              juce::Colour(0xff0a0c0e),
                              c.x + radius * 0.65f, c.y + radius * 0.70f, false);
    g.setGradientFill(face);
    g.fillEllipse(c.x - radius + 3.0f, c.y - radius + 3.0f,
                  (radius - 3.0f) * 2.0f, (radius - 3.0f) * 2.0f);

    const int tickCount = smart ? 15 : 13;
    for (int i = 0; i < tickCount; ++i)
    {
        const float t = (float)i / (float)(tickCount - 1);
        const float a = a0 + t * (a1 - a0);
        const bool major = (i == 0 || i == tickCount - 1 || i == tickCount / 2);
        const float r1 = radius + 14.0f;
        const float r2 = radius + (major ? 22.0f : 19.0f);
        const juce::Point<float> p1(c.x + std::sin(a) * r1, c.y - std::cos(a) * r1);
        const juce::Point<float> p2(c.x + std::sin(a) * r2, c.y - std::cos(a) * r2);
        g.setColour((major ? warmSteel : coldSteel).withAlpha(major ? 0.95f : 0.72f));
        g.drawLine(juce::Line<float>(p1, p2), major ? 1.7f : 1.0f);
    }

    juce::Path track;
    track.addCentredArc(c.x, c.y, radius + 10.0f, radius + 10.0f, 0.0f, a0, a1, true);
    g.setColour(juce::Colour(0xff292e32));
    g.strokePath(track, juce::PathStrokeType(smart ? 7.0f : 5.5f,
                                             juce::PathStrokeType::curved,
                                             juce::PathStrokeType::rounded));

    juce::Path valueArc;
    valueArc.addCentredArc(c.x, c.y, radius + 10.0f, radius + 10.0f, 0.0f, a0, angle, true);
    g.setColour(accent);
    g.strokePath(valueArc, juce::PathStrokeType(smart ? 5.0f : 3.8f,
                                                juce::PathStrokeType::curved,
                                                juce::PathStrokeType::rounded));

    juce::Path pointer;
    pointer.addRoundedRectangle(-2.4f, -radius + 8.0f, 4.8f,
                                radius * (smart ? 0.70f : 0.60f), 2.0f);
    g.setColour(smart ? accent : juce::Colour(0xffe7e6df));
    g.fillPath(pointer, juce::AffineTransform::rotation(angle).translated(c));

    g.setColour(juce::Colour(0xff060708));
    g.fillEllipse(c.x - 7.0f, c.y - 7.0f, 14.0f, 14.0f);
    g.setColour(warmSteel);
    g.drawEllipse(c.x - 7.0f, c.y - 7.0f, 14.0f, 14.0f, 1.2f);
    g.drawLine(c.x - 3.0f, c.y, c.x + 3.0f, c.y, 1.2f);

    g.setColour(smart ? accent : juce::Colour(0xffdedfd9));
    g.setFont(juce::FontOptions("Bahnschrift SemiCondensed",
                                smart ? 17.0f : 12.5f, juce::Font::bold));
    g.drawFittedText(s.getName(), x, y + h - (smart ? 29 : 21),
                     w, smart ? 23 : 18, juce::Justification::centred, 1, 0.78f);
}

void KickcrafterAudioProcessorEditor::IndustrialLook::drawButtonBackground(
    juce::Graphics& g, juce::Button& b, const juce::Colour&, bool over, bool down)
{
    const auto r = b.getLocalBounds().toFloat().reduced(0.75f);
    const bool critical = b.getComponentID() == "trigger" || b.getComponentID() == "randomizer";
    const float cut = juce::jmin(6.0f, r.getHeight() * 0.22f);

    juce::Path plate;
    plate.startNewSubPath(r.getX() + cut, r.getY());
    plate.lineTo(r.getRight() - cut, r.getY());
    plate.lineTo(r.getRight(), r.getY() + cut);
    plate.lineTo(r.getRight(), r.getBottom() - cut);
    plate.lineTo(r.getRight() - cut, r.getBottom());
    plate.lineTo(r.getX() + cut, r.getBottom());
    plate.lineTo(r.getX(), r.getBottom() - cut);
    plate.lineTo(r.getX(), r.getY() + cut);
    plate.closeSubPath();

    juce::Colour top = down ? juce::Colour(0xff6d0b1a)
                            : (over ? juce::Colour(0xff4c5155) : juce::Colour(0xff303438));
    juce::ColourGradient grad(top, r.getX(), r.getY(),
                              juce::Colour(0xff090b0d), r.getX(), r.getBottom(), false);
    g.setGradientFill(grad);
    g.fillPath(plate);

    g.setColour(critical ? juce::Colour(0xffe51735) : juce::Colour(0xff6f7579));
    g.strokePath(plate, juce::PathStrokeType(critical ? 1.7f : 1.1f));

    g.setColour(juce::Colour(0x38ffffff));
    g.drawLine(r.getX() + cut + 2.0f, r.getY() + 3.0f,
               r.getRight() - cut - 2.0f, r.getY() + 3.0f, 0.9f);

    if (critical)
    {
        g.setColour(juce::Colour(0xffe51735));
        g.fillRect(r.getX() + 6.0f, r.getBottom() - 4.0f, r.getWidth() - 12.0f, 2.0f);
    }
}

void KickcrafterAudioProcessorEditor::IndustrialLook::drawComboBox(
    juce::Graphics& g, int w, int h, bool, int, int, int, int, juce::ComboBox&)
{
    auto r = juce::Rectangle<float>(0.0f, 0.0f, (float)w, (float)h).reduced(0.5f);

    g.setColour(juce::Colour(0xff07090b));
    g.fillRect(r);

    juce::ColourGradient cartridge(juce::Colour(0xff32373b), r.getX(), r.getY(),
                                   juce::Colour(0xff111417), r.getX(), r.getBottom(), false);
    g.setGradientFill(cartridge);
    g.fillRect(r.reduced(2.0f));

    g.setColour(juce::Colour(0xff747a7e));
    g.drawRect(r, 1.0f);
    g.setColour(juce::Colour(0xff0a0c0e));
    g.drawRect(r.reduced(4.0f), 1.0f);

    g.setColour(juce::Colour(0x42ffffff));
    g.drawLine(r.getX() + 5.0f, r.getY() + 4.0f,
               r.getRight() - 29.0f, r.getY() + 4.0f, 0.8f);

    juce::Path arrow;
    arrow.addTriangle((float)w - 23.0f, (float)h * 0.40f,
                      (float)w - 9.0f, (float)h * 0.40f,
                      (float)w - 16.0f, (float)h * 0.66f);
    g.setColour(juce::Colour(0xffe7e6df));
    g.fillPath(arrow);

    g.setColour(juce::Colour(0xffe51735));
    g.fillRect((float)w - 29.0f, 5.0f, 2.0f, (float)h - 10.0f);
}

void KickcrafterAudioProcessorEditor::ExportPad::paint(juce::Graphics& g)
{
    auto r = getLocalBounds().toFloat().reduced(0.75f);
    const float cut = 6.0f;

    juce::Path plate;
    plate.startNewSubPath(r.getX() + cut, r.getY());
    plate.lineTo(r.getRight() - cut, r.getY());
    plate.lineTo(r.getRight(), r.getY() + cut);
    plate.lineTo(r.getRight(), r.getBottom() - cut);
    plate.lineTo(r.getRight() - cut, r.getBottom());
    plate.lineTo(r.getX() + cut, r.getBottom());
    plate.lineTo(r.getX(), r.getBottom() - cut);
    plate.lineTo(r.getX(), r.getY() + cut);
    plate.closeSubPath();

    juce::ColourGradient grad(juce::Colour(0xff2d3236), r.getX(), r.getY(),
                              juce::Colour(0xff080a0c), r.getX(), r.getBottom(), false);
    g.setGradientFill(grad);
    g.fillPath(plate);
    g.setColour(juce::Colour(0xff6f7579));
    g.strokePath(plate, juce::PathStrokeType(1.1f));

    g.setColour(juce::Colour(0xffe51735));
    g.fillRect(r.getX() + 7.0f, r.getBottom() - 4.0f, r.getWidth() - 14.0f, 2.0f);

    g.setColour(juce::Colour(0xffedede6));
    g.setFont(juce::FontOptions("Bahnschrift SemiCondensed", 13.0f, juce::Font::bold));
    g.drawFittedText("DRAG WAV  /  EXPORT", getLocalBounds(), juce::Justification::centred, 1);
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
    tagline.setText("PRESS / MUTANT KICK ENGINE",juce::dontSendNotification); tagline.setFont(juce::FontOptions("Consolas",10,juce::Font::bold)); tagline.setColour(juce::Label::textColourId,juce::Colour(0xff9da2a8));
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
        const int factoryCount=proc.factoryPresetNames().size();
        if(id>=1&&id<=factoryCount) proc.loadFactoryPreset(id-1);
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
    const auto factory = proc.factoryPresetNames();

    if (factory.size() == 250)
    {
        const char* families[] = { "ROUND", "PUNCH", "HARD", "INDUSTRIAL", "RAVE" };
        const char* banks[] = { "CORE", "TIGHT", "HEAVY", "SUSTAIN", "MUTANT" };

        for (int i = 0; i < factory.size(); ++i)
        {
            const int familyIndex = i / 50;
            const int withinFamily = i % 50;
            if (withinFamily % 10 == 0)
            {
                const int bankIndex = withinFamily / 10;
                presetBox.addSectionHeading(juce::String(families[familyIndex])
                                            + " / " + banks[bankIndex]);
            }
            presetBox.addItem(factory[i], i + 1);
        }
    }
    else
    {
        const char* families[] = { "ROUND / SUB", "PUNCH", "HARD / CLIPPED",
                                   "INDUSTRIAL", "RAVE / SAW" };
        const int block = factory.size() >= 5 ? juce::jmax(1, factory.size() / 5) : factory.size();

        for (int i = 0; i < factory.size(); ++i)
        {
            if (block > 0 && i % block == 0 && i / block < 5)
                presetBox.addSectionHeading(families[i / block]);
            presetBox.addItem(factory[i], i + 1);
        }
    }

    const auto user = proc.presets();
    if (!user.isEmpty())
    {
        presetBox.addSeparator();
        presetBox.addSectionHeading("USER PRESETS");
        for (int i = 0; i < user.size(); ++i)
            presetBox.addItem(user[i].getFileNameWithoutExtension(), 1001 + i);
    }

    presetBox.setTextWhenNothingSelected(juce::String(factory.size()) + " FACTORY / BANK");
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

    const auto black = juce::Colour(0xff050607);
    const auto pale = juce::Colour(0xffe7e6df);
    const auto steel = juce::Colour(0xff676d70);
    const auto red = juce::Colour(0xffe51735);
    const auto amber = juce::Colour(0xffc89222);

    if (backgroundImage.isValid())
        g.drawImage(backgroundImage, 0, 0, (int)baseW, (int)baseH,
                    0, 0, backgroundImage.getWidth(), backgroundImage.getHeight(), false);
    g.setColour(juce::Colour(0x96050607));
    g.fillRect(0.0f, 0.0f, baseW, baseH);
    // stage113b-proc: procedural industrial chassis (no external asset)
    {
        juce::Random rnd(909u);
        for (int i = 0; i < 26; ++i)
        {
            const float rx = (float)rnd.nextInt((int)baseW);
            const float ry = (float)rnd.nextInt((int)baseH);
            const float rr = 8.0f + (float)rnd.nextInt(30);
            const bool edge = (rx < 60.0f || rx > baseW - 60.0f || ry < 60.0f || ry > baseH - 60.0f);
            juce::ColourGradient rust(juce::Colour(edge ? 0x6a6a3a16 : 0x306a3a16), rx, ry,
                                      juce::Colour(0x006a3a16), rx, ry + rr, true);
            g.setGradientFill(rust);
            g.fillEllipse(rx - rr, ry - rr * 0.7f, rr * 2.0f, rr * 1.4f);
        }
        g.setColour(juce::Colour(0x14ffffff));
        for (int i = 0; i < 40; ++i)
        {
            const float x1 = (float)rnd.nextInt((int)baseW);
            const float y1 = (float)rnd.nextInt((int)baseH);
            const float x2 = x1 + 20.0f + (float)rnd.nextInt(60);
            const float y2 = y1 + 4.0f - (float)rnd.nextInt(8);
            g.drawLine(juce::Line<float>(x1, y1, x2, y2), 1.0f);
        }
    }
    for (const float side : { 6.0f, baseW - 12.0f })
    {
        juce::Path cable;
        cable.startNewSubPath(side + 3.0f, 0.0f);
        cable.cubicTo(side - 4.0f, baseH * 0.3f, side + 10.0f, baseH * 0.6f, side + 3.0f, baseH);
        g.setColour(juce::Colour(0xff0c0e10));
        g.strokePath(cable, juce::PathStrokeType(8.0f));
        g.setColour(juce::Colour(0x2affffff));
        g.strokePath(cable, juce::PathStrokeType(1.6f));
        for (const float gy : { baseH * 0.28f, baseH * 0.62f })
        {
            g.setColour(juce::Colour(0xff565c60));
            g.fillRoundedRectangle(side - 4.0f, gy, 14.0f, 18.0f, 2.0f);
            g.setColour(juce::Colour(0xff0a0c0d));
            g.drawRoundedRectangle(side - 4.0f, gy, 14.0f, 18.0f, 2.0f, 1.0f);
        }
    }
    {
        juce::Rectangle<float> stick(baseW - 96.0f, 96.0f, 44.0f, 32.0f);
        g.setColour(juce::Colour(0xffd7b414));
        g.fillRoundedRectangle(stick, 3.0f);
        juce::Path tri;
        tri.addTriangle(stick.getCentreX(), stick.getY() + 6.0f,
                        stick.getX() + 8.0f, stick.getBottom() - 7.0f,
                        stick.getRight() - 8.0f, stick.getBottom() - 7.0f);
        g.setColour(juce::Colour(0xff141414));
        g.fillPath(tri);
        g.setColour(juce::Colour(0xffd7b414));
        g.setFont(juce::FontOptions("Consolas", 10.0f, juce::Font::bold));
        g.drawText("!", stick, juce::Justification::centred);
    }
    {
        juce::Rectangle<float> pipe(0.0f, baseH - 12.0f, baseW, 7.0f);
        juce::ColourGradient pg(juce::Colour(0xff585e62), 0.0f, pipe.getY(),
                                juce::Colour(0xff1e2226), 0.0f, pipe.getBottom(), false);
        g.setGradientFill(pg);
        g.fillRect(pipe);
        for (float cx = 40.0f; cx < baseW; cx += 260.0f)
        {
            g.setColour(juce::Colour(0xff787e82));
            g.fillRect(cx, pipe.getY() - 3.0f, 12.0f, pipe.getHeight() + 6.0f);
            g.setColour(juce::Colour(0xff0a0c0d));
            g.drawRect(cx, pipe.getY() - 3.0f, 12.0f, pipe.getHeight() + 6.0f, 1.0f);
        }
    }

    for (float x : { 0.0f, baseW - 20.0f })
    {
        juce::ColourGradient rail(juce::Colour(0xff4b5052), x, 0.0f,
                                  juce::Colour(0xff111416), x + 20.0f, 0.0f, false);
        g.setGradientFill(rail);
        g.fillRect(x, 0.0f, 20.0f, baseH);
    }
    g.setColour(black);
    g.fillRect(20.0f, 0.0f, 3.0f, baseH);
    g.fillRect(baseW - 23.0f, 0.0f, 3.0f, baseH);

    for (float y : { 341.0f, 637.0f })
    {
        g.setColour(juce::Colour(0xff090b0d));
        g.fillRect(18.0f, y, baseW - 36.0f, 9.0f);
        g.setColour(juce::Colour(0xff454a4d));
        g.fillRect(22.0f, y + 2.0f, baseW - 44.0f, 2.0f);
    }

    auto drawBolt = [&](juce::Point<float> p, float radius = 4.2f)
    {
        g.setColour(black);
        g.fillEllipse(p.x - radius, p.y - radius, radius * 2.0f, radius * 2.0f);
        g.setColour(juce::Colour(0xff777c7e));
        g.drawEllipse(p.x - radius, p.y - radius, radius * 2.0f, radius * 2.0f, 1.0f);
        g.setColour(juce::Colour(0xff323638));
        g.drawLine(p.x - radius * 0.55f, p.y, p.x + radius * 0.55f, p.y, 1.2f);
    };

    for (int y = 20; y < 910; y += 48)
    {
        drawBolt({ 10.0f, (float)y }, 3.4f);
        drawBolt({ baseW - 10.0f, (float)y }, 3.4f);
    }

    juce::ColourGradient header(juce::Colour(0xff272c2f), 0.0f, 0.0f,
                                juce::Colour(0xff090b0d), 0.0f, 82.0f, false);
    g.setGradientFill(header);
    g.fillRect(20.0f, 0.0f, baseW - 40.0f, 82.0f);
    g.setColour(juce::Colour(0xff555b5e));
    g.fillRect(22.0f, 3.0f, baseW - 44.0f, 2.0f);
    g.setColour(red);
    g.fillRect(20.0f, 78.0f, baseW - 40.0f, 4.0f);

    juce::Rectangle<float> titlePlate(27.0f, 11.0f, 296.0f, 56.0f);
    g.setColour(black);
    g.fillRect(titlePlate.translated(3.0f, 4.0f));
    juce::ColourGradient titleMetal(juce::Colour(0xff373c3e), titlePlate.getX(), titlePlate.getY(),
                                    juce::Colour(0xff101315), titlePlate.getRight(), titlePlate.getBottom(), false);
    g.setGradientFill(titleMetal);
    g.fillRect(titlePlate);
    g.setColour(steel);
    g.drawRect(titlePlate, 1.2f);
    drawBolt({ 38.0f, 22.0f }, 3.0f);
    drawBolt({ 312.0f, 22.0f }, 3.0f);
    drawBolt({ 38.0f, 56.0f }, 3.0f);
    drawBolt({ 312.0f, 56.0f }, 3.0f);

    g.setColour(pale);
    g.setFont(juce::FontOptions("Impact", 32.0f, juce::Font::plain));
    g.drawText("INDUSTRY KICK", 50, 18, 248, 38, juce::Justification::centredLeft);
    g.setColour(red);
    g.fillRect(50.0f, 57.0f, 96.0f, 3.0f);

    juce::Rectangle<float> dataPlate(450.0f, 16.0f, 252.0f, 42.0f);
    g.setColour(juce::Colour(0xff0a0c0e));
    g.fillRect(dataPlate);
    g.setColour(juce::Colour(0xff565c5f));
    g.drawRect(dataPlate, 1.0f);
    g.setColour(juce::Colour(0xff9da1a0));
    g.setFont(juce::FontOptions("Consolas", 8.2f, juce::Font::bold));
    g.drawText("PRESS / MUTANT KICK ENGINE", dataPlate.getX() + 10.0f, dataPlate.getY() + 5.0f,
               dataPlate.getWidth() - 20.0f, 12.0f, juce::Justification::centredLeft);
    g.setColour(red);
    g.drawText("IK-71  //  FAMILY DSP + MASTER GLUE", dataPlate.getX() + 10.0f, dataPlate.getY() + 21.0f,
               dataPlate.getWidth() - 20.0f, 12.0f, juce::Justification::centredLeft);

    auto panel = [&](float x, float y, float w, float h,
                     const juce::String& code, const juce::String& titleText,
                     const juce::String& subtitle, bool masterPanel = false)
    {
        const juce::Rectangle<float> r(x, y, w, h);
        g.setColour(juce::Colour(0x90000000));
        g.fillRoundedRectangle(r.translated(5.0f, 6.0f), 3.0f);
                g.setColour(juce::Colour(0xd822262a));
        g.fillRoundedRectangle(r, 3.0f);
        g.setColour(juce::Colour(0xd8070809));
        g.fillRoundedRectangle(r.reduced(3.0f), 2.0f);

                juce::ColourGradient inner(masterPanel ? juce::Colour(0xc81b1717) : juce::Colour(0xc8171b1e),
                                   x + 5.0f, y + 5.0f,
                                   juce::Colour(0xc8090b0d), x + w, y + h, false);
        g.setGradientFill(inner);
        g.fillRoundedRectangle(r.reduced(7.0f), 2.0f);
        g.setColour(juce::Colour(0xff42484b));
        g.drawRoundedRectangle(r.reduced(7.0f), 2.0f, 1.0f);
        g.setColour(juce::Colour(0x60000000));
        g.drawRoundedRectangle(r.reduced(11.0f), 1.0f, 1.0f);

        juce::Rectangle<float> tag(x + 13.0f, y + 10.0f, juce::jmin(245.0f, w - 30.0f), 28.0f);
        g.setColour(juce::Colour(0xff292e31));
        g.fillRect(tag);
        g.setColour(juce::Colour(0xff666c6f));
        g.drawRect(tag, 1.0f);
        g.setColour(red);
        g.fillRect(tag.getX(), tag.getY(), 5.0f, tag.getHeight());

        g.setColour(juce::Colour(0xffb7bab6));
        g.setFont(juce::FontOptions("Consolas", 8.5f, juce::Font::bold));
        g.drawText(code, tag.getX() + 12.0f, tag.getY() + 5.0f, 34.0f, 18.0f,
                   juce::Justification::centredLeft);

        g.setColour(pale);
        g.setFont(juce::FontOptions("Bahnschrift SemiCondensed", 15.0f, juce::Font::bold));
        g.drawText(titleText, tag.getX() + 48.0f, tag.getY() + 3.0f,
                   tag.getWidth() - 54.0f, 21.0f, juce::Justification::centredLeft);

        g.setColour(juce::Colour(0xff777d80));
        g.setFont(juce::FontOptions("Consolas", 8.0f, juce::Font::bold));
        g.drawText(subtitle, x + w - 255.0f, y + 15.0f, 230.0f, 18.0f,
                   juce::Justification::centredRight);

        for (const auto p : { juce::Point<float>(x + 14.0f, y + 14.0f),
                              juce::Point<float>(x + w - 14.0f, y + 14.0f),
                              juce::Point<float>(x + 14.0f, y + h - 14.0f),
                              juce::Point<float>(x + w - 14.0f, y + h - 14.0f) })
            drawBolt(p, 3.4f);

        g.setColour(juce::Colour(0xff555b5e));
        g.drawLine(x + 22.0f, y + h - 12.0f, x + 50.0f, y + h - 12.0f, 1.0f);
        g.drawLine(x + w - 50.0f, y + h - 12.0f, x + w - 22.0f, y + h - 12.0f, 1.0f);
    };

    panel(20, 92, 700, 246, "01", "CORE", "PITCH / BODY / TRANSIENT");
    panel(735, 92, 685, 246, "02", "MATERIAL", "SATURATION / HARMONICS");
    panel(20, 354, 900, 280, "03", "SPACE", "IR CHAMBER / TAIL");
    panel(935, 354, 485, 280, "04", "BODY MIX", "SUB / KICK / TAIL / CRUNCH");
    panel(20, 650, 1050, 250, "05", "MUTANT", "SHAPE / EVOLVE / DESTROY");
    panel(1085, 650, 335, 250, "06", "MASTER", "FIXED GLUE CHAIN", true);

    g.setColour(juce::Colour(0xff0a0c0e));
    g.fillRoundedRectangle(48.0f, 857.0f, 990.0f, 20.0f, 8.0f);
    g.setColour(juce::Colour(0xff3e4447));
    g.drawRoundedRectangle(48.0f, 857.0f, 990.0f, 20.0f, 8.0f, 2.0f);
    for (float x : { 250.0f, 525.0f, 800.0f })
    {
        g.setColour(juce::Colour(0xff555b5e));
        g.fillRect(x, 854.0f, 14.0f, 26.0f);
        g.setColour(black);
        g.drawRect(x, 854.0f, 14.0f, 26.0f, 1.0f);
    }

    g.setColour(juce::Colour(0xff858a8c));
    g.setFont(juce::FontOptions("Consolas", 8.5f, juce::Font::bold));
    g.drawText("FAMILY SELECT", 38, 298, 102, 20, juce::Justification::centredLeft);

    juce::Rectangle<float> waveBox(455, 294, 235, 33);
    g.setColour(black);
    g.fillRect(waveBox.translated(2.0f, 2.0f));
    g.setColour(juce::Colour(0xff1b2023));
    g.fillRect(waveBox);
    g.setColour(steel);
    g.drawRect(waveBox, 1.0f);

    for (int i = 1; i < 4; ++i)
    {
        const float gx = waveBox.getX() + waveBox.getWidth() * (float)i / 4.0f;
        g.setColour(juce::Colour(0x30545a5d));
        g.drawVerticalLine(juce::roundToInt(gx), waveBox.getY() + 5.0f, waveBox.getBottom() - 5.0f);
    }
    g.setColour(juce::Colour(0x40545a5d));
    g.drawHorizontalLine(juce::roundToInt(waveBox.getCentreY()),
                         waveBox.getX() + 5.0f, waveBox.getRight() - 5.0f);

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
        const float py = waveBox.getCentreY() - value * 11.0f;
        if (i == 0) wavePreview.startNewSubPath(px, py);
        else wavePreview.lineTo(px, py);
    }
    g.setColour(red);
    g.strokePath(wavePreview, juce::PathStrokeType(1.8f));

    juce::Rectangle<float> scopeFrame(1202.0f, 130.0f, 204.0f, 142.0f);
    g.setColour(juce::Colour(0xff34393c));
    g.fillRect(scopeFrame);
    g.setColour(black);
    g.fillRect(scopeFrame.reduced(5.0f));
    drawBolt({ 1209.0f, 137.0f }, 2.6f);
    drawBolt({ 1399.0f, 137.0f }, 2.6f);
    drawBolt({ 1209.0f, 265.0f }, 2.6f);
    drawBolt({ 1399.0f, 265.0f }, 2.6f);

    juce::Rectangle<float> scope = scopeFrame.reduced(10.0f);
    g.setColour(juce::Colour(0xff070a0b));
    g.fillRect(scope);
    for (int i = 1; i < 4; ++i)
    {
        g.setColour(juce::Colour(0x2c545a5d));
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
        {
        juce::Path fill(scopeWave);
        fill.lineTo(scope.getRight() - 5.0f, scope.getCentreY());
        fill.lineTo(scope.getX() + 5.0f, scope.getCentreY());
        fill.closeSubPath();
        juce::ColourGradient scopeFill(juce::Colour(0x90e51735), 0.0f, scope.getY(),
                                       juce::Colour(0x10e51735), 0.0f, scope.getBottom(), false);
        g.setGradientFill(scopeFill);
        g.fillPath(fill);
    }
    g.setColour(red);
    g.strokePath(scopeWave, juce::PathStrokeType(1.6f));

    g.setColour(juce::Colour(0xff8a8f91));
    g.setFont(juce::FontOptions("Consolas", 7.8f, juce::Font::bold));
    g.drawText(waveformSelect.getText(),
               scope.getX() + 6.0f, scope.getY() + 5.0f,
               scope.getWidth() - 12.0f, 13.0f, juce::Justification::centredRight);

    juce::Rectangle<float> chamberFrame(487, 389, 420, 190);
    g.setColour(juce::Colour(0xff3c4144));
    g.fillRect(chamberFrame);
    g.setColour(black);
    g.fillRect(chamberFrame.reduced(6.0f));
    for (const auto p : { juce::Point<float>(495.0f, 397.0f),
                          juce::Point<float>(899.0f, 397.0f),
                          juce::Point<float>(495.0f, 571.0f),
                          juce::Point<float>(899.0f, 571.0f) })
        drawBolt(p, 3.0f);

    juce::Rectangle<float> chamber(500, 402, 394, 164);
    g.setColour(black);
    g.fillRect(chamber);
    if (chamberAtlas.isValid())
    {
                const int irIndex = juce::jlimit(0, 19, chamberSelect.getSelectedItemIndex());
        const int selected = irIndex < 10 ? 0 : (irIndex < 15 ? 1 : 2);
        const bool tightCrop = irIndex < 5;
        const float sourceW = (float)chamberAtlas.getWidth() / 3.0f;
        const auto destination = chamber.reduced(4.0f).toNearestInt();
        float sx = selected * sourceW;
        float sw = sourceW;
        float sy = 0.0f;
        float sh = (float)chamberAtlas.getHeight();
        if (tightCrop) { sx += sourceW * 0.25f; sw = sourceW * 0.5f; }
        const float destAR = (float)destination.getWidth() / (float)destination.getHeight();
        const float srcAR = sw / sh;
        if (srcAR > destAR) { const float w2 = sh * destAR; sx += (sw - w2) * 0.5f; sw = w2; }
        else { const float h2 = sw / destAR; sy = (sh - h2) * 0.5f; sh = h2; }
        g.drawImage(chamberAtlas,
                    destination.getX(), destination.getY(),
                    destination.getWidth(), destination.getHeight(),
                    juce::roundToInt(sx), juce::roundToInt(sy),
                    juce::roundToInt(sw), juce::roundToInt(sh), false);
    }
    g.setColour(red);
    g.fillRect(chamber.getX(), chamber.getY(), 4.0f, chamber.getHeight());

    const int irIndex = juce::jlimit(0, 19, chamberSelect.getSelectedItemIndex());
    const juce::String category = irIndex < 5 ? "TIGHT"
                               : (irIndex < 10 ? "ROOM"
                               : (irIndex < 15 ? "PASSAGE" : "METAL"));
    g.setColour(juce::Colour(0xdc050708));
    g.fillRect(chamber.getX() + 4.0f, chamber.getBottom() - 27.0f,
               chamber.getWidth() - 4.0f, 27.0f);
    g.setColour(pale);
    g.setFont(juce::FontOptions("Bahnschrift SemiCondensed", 11.5f, juce::Font::bold));
    g.drawText(category + " / TRUE IR CHAMBER",
               chamber.getX() + 14.0f, chamber.getBottom() - 24.0f,
               chamber.getWidth() - 28.0f, 19.0f, juce::Justification::centredLeft);

    g.setColour(juce::Colour(0xff353a3d));
    g.fillRect(1167.0f, 395.0f, 2.0f, 219.0f);
    g.fillRect(955.0f, 504.0f, 446.0f, 2.0f);

        // stage113g: mutant backplates removed

        // stage113f-fix: master vents removed

    const char* chainLabels[] = { "SAT", "GLUE 4:1", "HARD CLIP" };
    const float chainX[] = { 1099.0f, 1192.0f, 1290.0f };
    const float chainW[] = { 82.0f, 91.0f, 111.0f };
    for (int i = 0; i < 3; ++i)
    {
        juce::Rectangle<float> block(chainX[i], 835.0f, chainW[i], 25.0f);
        g.setColour(juce::Colour(0xff101315));
        g.fillRect(block);
        g.setColour(i == 2 ? red : juce::Colour(0xff555b5e));
        g.drawRect(block, 1.0f);
        g.setColour(i == 2 ? red : juce::Colour(0xffa5a9a6));
        g.setFont(juce::FontOptions("Consolas", 7.6f, juce::Font::bold));
        g.drawText(chainLabels[i], block, juce::Justification::centred);
    }

    juce::Rectangle<float> meter(1288.0f, 713.0f, 30.0f, 116.0f);
    g.setColour(black);
    g.fillRect(meter);
    g.setColour(juce::Colour(0xff555b5e));
    g.drawRect(meter, 1.0f);

    const auto meterHeight = [&](float gain)
    {
        const float db = juce::Decibels::gainToDecibels(juce::jmax(gain, 0.001f), -60.0f);
        return juce::jmap(db, -60.0f, 0.0f, 0.0f, meter.getHeight() - 18.0f);
    };
    const auto meterColour = [&](float gain)
    {
        const float db = juce::Decibels::gainToDecibels(juce::jmax(gain, 0.001f), -60.0f);
        return db > -3.0f ? red : (db > -12.0f ? amber : pale);
    };
        const float hL = meterHeight(meterL);
    const float hR = meterHeight(meterR);
    for (float segY = 0.0f; segY < meter.getHeight() - 18.0f; segY += 6.0f)
    {
        const float yy = meter.getBottom() - 5.0f - segY - 4.0f;
        const bool onL = segY < hL;
        const bool onR = segY < hR;
        const float db = juce::jmap(segY, 0.0f, meter.getHeight() - 18.0f, -60.0f, 0.0f);
        const auto col = db > -3.0f ? red : (db > -12.0f ? amber : pale);
        g.setColour(onL ? col : juce::Colour(0xff22262a));
        g.fillRect(meter.getX() + 5.0f, yy, 7.0f, 4.0f);
        g.setColour(onR ? col : juce::Colour(0xff22262a));
        g.fillRect(meter.getX() + 18.0f, yy, 7.0f, 4.0f);
    }
    g.setColour(juce::Colour(0xff8d9293));
    g.setFont(juce::FontOptions("Consolas", 7.0f, juce::Font::bold));
    g.drawText("L R", meter.getX(), meter.getY() + 2.0f, meter.getWidth(), 9.0f,
               juce::Justification::centred);

    for (int x = 1098; x < 1402; x += 28)
    {
        juce::Path stripe;
        stripe.addQuadrilateral((float)x + 2.0f, 872.0f,
                                (float)x + 13.0f, 872.0f,
                                (float)x + 21.0f, 883.0f,
                                (float)x + 10.0f, 883.0f);
                g.setColour((x / 28) % 2 == 0 ? amber : juce::Colour(0xff1b1d1e));
        g.fillPath(stripe);
    }

    {
        juce::Rectangle<float> tube(430.0f, 876.0f, 580.0f, 12.0f);
        g.setColour(juce::Colour(0xff0a0c0d));
        g.fillRoundedRectangle(tube.expanded(3.0f), 8.0f);
        juce::ColourGradient tubeGrad(juce::Colour(0xff3a0510), tube.getX(), tube.getY(),
                                      juce::Colour(0xffe51735), tube.getX(), tube.getBottom(), false);
        g.setGradientFill(tubeGrad);
        g.fillRoundedRectangle(tube, 6.0f);
        g.setColour(juce::Colour(0x60e51735));
        g.drawRoundedRectangle(tube.expanded(6.0f), 9.0f, 5.0f);
        g.setColour(juce::Colour(0xff0b0d0e));
        g.setFont(juce::FontOptions("Consolas", 8.0f, juce::Font::bold));
        g.drawText("/// BUILT TO KICK ///", tube, juce::Justification::centred);
    }

    {
        juce::Rectangle<float> serial(60.0f, 876.0f, 150.0f, 20.0f);
        g.setColour(juce::Colour(0xffb9bcc0));
        g.fillRect(serial);
        g.setColour(juce::Colour(0xff17191b));
        for (float bx = serial.getX() + 6.0f; bx < serial.getRight() - 26.0f; bx += 5.0f)
            g.fillRect(bx, serial.getY() + 4.0f, ((int)bx % 10) < 5 ? 2.0f : 1.0f, 9.0f);
        g.setFont(juce::FontOptions("Consolas", 6.5f, juce::Font::bold));
        g.drawText("IK-71 // 909V", serial.getX() + 4.0f, serial.getY() + 12.0f, 120.0f, 8.0f, juce::Justification::centredLeft);
        g.setColour(juce::Colour(0xff35c442));
        g.fillEllipse(serial.getRight() - 16.0f, serial.getY() + 6.0f, 5.0f, 5.0f);
        g.setColour(red);
        g.fillEllipse(serial.getRight() - 8.0f, serial.getY() + 6.0f, 5.0f, 5.0f);
    }

    g.setColour(juce::Colour(0xe207090b));
    g.fillRect(58.0f, 859.0f, 960.0f, 16.0f);
    g.setColour(juce::Colour(0xff858a8c));
    g.setFont(juce::FontOptions("Consolas", 7.6f, juce::Font::bold));
    g.drawText("FAMILY DSP  >  BODY / SUB CONTROL  >  MASTER GLUE  //  FACTORY BANK",
               66, 860, 944, 14, juce::Justification::centred);
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
