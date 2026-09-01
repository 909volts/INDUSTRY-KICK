$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$target=Join-Path $root 'Project\Source\PluginEditor.cpp'
$refNew=Join-Path $root 'Reference\PluginEditor_STAGE113.cpp'
$txt=[System.IO.File]::ReadAllText($target)

$p1pat='    juce::ColourGradient chassis\(juce::Colour\(0xff24282b\), 0\.0f, 0\.0f,\s+juce::Colour\(0xff070809\), baseW, baseH, true\);\s+g\.setGradientFill\(chassis\);\s+g\.fillRect\(0\.0f, 0\.0f, baseW, baseH\);'
$p1new=@"
    if (backgroundImage.isValid())
        g.drawImage(backgroundImage, 0, 0, (int)baseW, (int)baseH,
                    0, 0, backgroundImage.getWidth(), backgroundImage.getHeight(), false);
    g.setColour(juce::Colour(0x96050607));
    g.fillRect(0.0f, 0.0f, baseW, baseH);
"@
if (-not $txt.Contains('0x96050607')) {
    $m=[regex]::Matches($txt,$p1pat)
    if ($m.Count -ne 1) { throw "P1_FOUND=$($m.Count)" }
    $txt=$txt.Replace($m[0].Value,$p1new)
    'P1=APPLIED'
} else { 'P1=ALREADY' }

$proc=@"
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
"@
$bpat='g\.setColour\(juce::Colour\(0x96050607\)\);\s+g\.fillRect\(0\.0f, 0\.0f, baseW, baseH\);'
if (-not $txt.Contains('stage113b-proc')) {
    $m=[regex]::Matches($txt,$bpat)
    if ($m.Count -ne 1) { throw "B_FOUND=$($m.Count)" }
    $txt=$txt.Replace($m[0].Value, $m[0].Value + "`n" + $proc)
    'B=APPLIED'
} else { 'B=ALREADY' }

[System.IO.File]::WriteAllText($target,$txt)
if (Test-Path $refNew) { Remove-Item $refNew -Force }
Copy-Item -LiteralPath $target -Destination $refNew
'REFERENCE_RECREATED=PluginEditor_STAGE113.cpp'