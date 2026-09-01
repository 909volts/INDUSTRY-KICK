$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$target=Join-Path $root 'Project\Source\PluginEditor.cpp'
$refNew=Join-Path $root 'Reference\PluginEditor_STAGE113.cpp'
$txt=[System.IO.File]::ReadAllText($target)

function Apply($t,$pat,$repl,$name){
  $m=[regex]::Matches($t,$pat)
  if($m.Count -ne 1){ throw "$name found=$($m.Count)" }
  return $t.Replace($m[0].Value,$repl)
}

if ($txt.Contains('stage113i-overlay')) {
  'GUI_PATCH_I=ALREADY_APPLIED'
} else {

$txt=Apply $txt 'g\.setColour\(juce::Colour\(0xd822262a\)\);\s+g\.fillRoundedRectangle\(r, 3\.0f\);\s+g\.setColour\(juce::Colour\(0xd8070809\)\);\s+g\.fillRoundedRectangle\(r\.reduced\(3\.0f\), 2\.0f\);' (@'
        g.setColour(juce::Colour(0xa822262a));
        g.fillRoundedRectangle(r, 3.0f);
        g.setColour(juce::Colour(0xa8070809));
        g.fillRoundedRectangle(r.reduced(3.0f), 2.0f);
'@) 'OPA'

$txt=Apply $txt 'juce::ColourGradient inner\(masterPanel \? juce::Colour\(0xc81b1717\) : juce::Colour\(0xc8171b1e\),\s+x \+ 5\.0f, y \+ 5\.0f,\s+juce::Colour\(0xc8090b0d\), x \+ w, y \+ h, false\);' (@'
        juce::ColourGradient inner(masterPanel ? juce::Colour(0xa01b1717) : juce::Colour(0xa0171b1e),
                                   x + 5.0f, y + 5.0f,
                                   juce::Colour(0xa0090b0d), x + w, y + h, false);
'@) 'OPB'

$txt=Apply $txt 'g\.setColour\(juce::Colour\(0x7a5a3016\)\);\s+g\.strokePath\(bezel, juce::PathStrokeType\(1\.0f\)\);' (@'
    g.setColour(juce::Colour(0x7a5a3016));
    g.strokePath(bezel, juce::PathStrokeType(1.0f));
    for (const float ra : { 0.7f, 2.4f, 4.2f })
    {
        juce::Path rustArc;
        rustArc.addCentredArc(c.x, c.y, radius + 11.0f, radius + 11.0f, 0.0f, ra, ra + 0.5f, true);
        g.setColour(juce::Colour(0x8a6a3a16));
        g.strokePath(rustArc, juce::PathStrokeType(2.0f));
    }
'@) 'OPD'

$ovl=@'
    // stage113i-overlay: industrial objects over panels (heavy machine, with sense)
    g.setOpacity(0.30f);
    if (backgroundImage.isValid())
        g.drawImage(backgroundImage, 0, 0, (int)baseW, (int)baseH,
                    0, 0, backgroundImage.getWidth(), backgroundImage.getHeight(), false);
    g.setOpacity(1.0f);
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
    {
        const auto qb = [](float t, float p0, float p1, float p2)
        {
            const float u = 1.0f - t;
            return u * u * p0 + 2.0f * u * t * p1 + t * t * p2;
        };
        g.setColour(juce::Colour(0xff565c60));
        g.fillRoundedRectangle(4.0f, 100.0f, 16.0f, 10.0f, 2.0f);
        for (int i = 0; i < 22; ++i)
        {
            const float t = (float)i / 21.0f;
            const float px = qb(t, 12.0f, 30.0f, 15.0f);
            const float py = qb(t, 110.0f, 300.0f, 500.0f);
            const bool vert = (i % 2 == 0);
            g.setColour(juce::Colour(0xff787e82));
            g.drawEllipse(px - (vert ? 3.0f : 5.0f), py - (vert ? 6.0f : 3.5f),
                          (vert ? 3.0f : 5.0f) * 2.0f, (vert ? 6.0f : 3.5f) * 2.0f, 1.6f);
        }
    }
    {
        juce::Rectangle<float> sign(baseW - 68.0f, 656.0f, 52.0f, 40.0f);
        g.setColour(juce::Colour(0xffd7b414));
        g.fillRoundedRectangle(sign, 3.0f);
        g.setColour(juce::Colour(0xff141414));
        g.drawRoundedRectangle(sign, 3.0f, 2.0f);
        juce::Path bolt;
        const float bx = sign.getCentreX();
        bolt.startNewSubPath(bx - 3.0f, sign.getY() + 6.0f);
        bolt.lineTo(bx + 5.0f, sign.getY() + 6.0f);
        bolt.lineTo(bx + 1.5f, sign.getY() + 15.0f);
        bolt.lineTo(bx + 6.0f, sign.getY() + 15.0f);
        bolt.lineTo(bx - 4.0f, sign.getY() + 30.0f);
        bolt.lineTo(bx - 0.5f, sign.getY() + 18.0f);
        bolt.lineTo(bx - 5.0f, sign.getY() + 18.0f);
        bolt.closeSubPath();
        g.setColour(juce::Colour(0xff141414));
        g.fillPath(bolt);
        g.setColour(juce::Colour(0xffd7b414));
        g.setFont(juce::FontOptions("Consolas", 7.0f, juce::Font::bold));
        g.drawText("HIGH VOLTAGE", sign.getX() - 14.0f, sign.getBottom() + 2.0f, 80.0f, 10.0f,
                   juce::Justification::centred);
    }
    g.setColour(juce::Colour(0xffe51735));
    g.setFont(juce::FontOptions("Consolas", 9.0f, juce::Font::bold));
    g.drawText("BUILD 11.3I", 220.0f, 878.0f, 140.0f, 14.0f, juce::Justification::centredLeft);
'@
$m=[regex]::Matches($txt,'g\.drawText\("FAMILY DSP  >  BODY / SUB CONTROL  >  MASTER GLUE  //  FACTORY BANK",\s+66, 860, 944, 14, juce::Justification::centred\);')
if ($m.Count -ne 1) { throw "OPE found=$($m.Count)" }
$txt=$txt.Replace($m[0].Value, $m[0].Value + "`n" + $ovl)

[System.IO.File]::WriteAllText($target,$txt)
'GUI_PATCH_I=APPLIED'
}

if (Test-Path $refNew) { Remove-Item $refNew -Force }
Copy-Item -LiteralPath $target -Destination $refNew
'REFERENCE_RECREATED=PluginEditor_STAGE113.cpp'