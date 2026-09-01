$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$target=Join-Path $root 'Project\Source\PluginEditor.cpp'
$refNew=Join-Path $root 'Reference\PluginEditor_STAGE113.cpp'
$txt=[System.IO.File]::ReadAllText($target)

function Apply($t, $pat, $repl, $name){
  $m=[regex]::Matches($t,$pat)
  if($m.Count -ne 1){ throw "$name found=$($m.Count)" }
  return $t.Replace($m[0].Value,$repl)
}

if ($txt.Contains('stage113b-proc')) {
  'GUI_PATCH_D=ALREADY_APPLIED'
} else {

$rep1=@'
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
'@
$txt=Apply $txt '    juce::ColourGradient chassis\(juce::Colour\(0xff24282b\), 0\.0f, 0\.0f,\s+juce::Colour\(0xff070809\), baseW, baseH, true\);\s+g\.setGradientFill\(chassis\);\s+g\.fillRect\(0\.0f, 0\.0f, baseW, baseH\);' $rep1 'OP1'

$rep2=@'
        g.setColour(juce::Colour(0xd822262a));
        g.fillRoundedRectangle(r, 3.0f);
        g.setColour(juce::Colour(0xd8070809));
        g.fillRoundedRectangle(r.reduced(3.0f), 2.0f);
'@
$txt=Apply $txt 'g\.setColour\(juce::Colour\(0xff303538\)\);\s+g\.fillRoundedRectangle\(r, 3\.0f\);\s+g\.setColour\(black\);\s+g\.fillRoundedRectangle\(r\.reduced\(3\.0f\), 2\.0f\);' $rep2 'OP2'

$rep3=@'
        juce::ColourGradient inner(masterPanel ? juce::Colour(0xc81b1717) : juce::Colour(0xc8171b1e),
                                   x + 5.0f, y + 5.0f,
                                   juce::Colour(0xc8090b0d), x + w, y + h, false);
'@
$txt=Apply $txt 'juce::ColourGradient inner\(masterPanel \? juce::Colour\(0xff1b1717\) : juce::Colour\(0xff171b1e\),\s+x \+ 5\.0f, y \+ 5\.0f,\s+juce::Colour\(0xff090b0d\), x \+ w, y \+ h, false\);' $rep3 'OP3'

$rep4=@'
    juce::ColourGradient bezelGrad(juce::Colour(0xff5d5a52),
                                    c.x - radius, c.y - radius,
                                    juce::Colour(0xff14100c),
                                    c.x + radius, c.y + radius, false);
'@
$txt=Apply $txt 'juce::ColourGradient bezelGrad\(juce::Colour\(0xff8a8e91\),\s+c\.x - radius, c\.y - radius,\s+juce::Colour\(0xff161a1e\),\s+c\.x \+ radius, c\.y \+ radius, false\);' $rep4 'OP4'

$rep5=@'
    g.setColour(juce::Colour(0xff050607));
    g.strokePath(bezel, juce::PathStrokeType(2.2f));
    g.setColour(juce::Colour(0x7a5a3016));
    g.strokePath(bezel, juce::PathStrokeType(1.0f));
'@
$txt=Apply $txt 'g\.setColour\(juce::Colour\(0xff050607\)\);\s+g\.strokePath\(bezel, juce::PathStrokeType\(2\.2f\)\);' $rep5 'OP5'

$rep6='    juce::ColourGradient face(juce::Colour(0xff33302b),'
$txt=Apply $txt 'juce::ColourGradient face\(juce::Colour\(0xff3b4044\),' $rep6 'OP6'

$rep7=@'
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
'@
$txt=Apply $txt 'const float hL = meterHeight\(meterL\);\s+const float hR = meterHeight\(meterR\);\s+g\.setColour\(meterColour\(meterL\)\);\s+g\.fillRect\(meter\.getX\(\) \+ 5\.0f, meter\.getBottom\(\) - 5\.0f - hL, 7\.0f, hL\);\s+g\.setColour\(meterColour\(meterR\)\);\s+g\.fillRect\(meter\.getX\(\) \+ 18\.0f, meter\.getBottom\(\) - 5\.0f - hR, 7\.0f, hR\);' $rep7 'OP7'

$rep8=@'
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
'@
$txt=Apply $txt 'g\.setColour\(red\);\s+g\.strokePath\(scopeWave, juce::PathStrokeType\(1\.6f\)\);' $rep8 'OP8'

$rep9=@'
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
'@
$txt=Apply $txt 'g\.setColour\(\(x / 28\) % 2 == 0 \? amber : juce::Colour\(0xff1b1d1e\)\);\s+g\.fillPath\(stripe\);\s+\}' $rep9 'OP9'

[System.IO.File]::WriteAllText($target,$txt)
'GUI_PATCH_D=APPLIED'
}

if (Test-Path $refNew) { Remove-Item $refNew -Force }
Copy-Item -LiteralPath $target -Destination $refNew
'REFERENCE_RECREATED=PluginEditor_STAGE113.cpp'