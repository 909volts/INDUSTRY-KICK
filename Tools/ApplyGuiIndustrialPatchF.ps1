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

if ($txt.Contains('stage113e-grime')) {
  'GUI_PATCH_E=ALREADY_APPLIED'
} else {

$rep10a=@'
        g.setColour(juce::Colour(0xa822262a));
        g.fillRoundedRectangle(r, 3.0f);
        g.setColour(juce::Colour(0xa8070809));
        g.fillRoundedRectangle(r.reduced(3.0f), 2.0f);
'@
$txt=Apply $txt 'g\.setColour\(juce::Colour\(0xd822262a\)\);\s+g\.fillRoundedRectangle\(r, 3\.0f\);\s+g\.setColour\(juce::Colour\(0xd8070809\)\);\s+g\.fillRoundedRectangle\(r\.reduced\(3\.0f\), 2\.0f\);' $rep10a 'OP10a'

$rep10b=@'
        juce::ColourGradient inner(masterPanel ? juce::Colour(0xa01b1717) : juce::Colour(0xa0171b1e),
                                   x + 5.0f, y + 5.0f,
                                   juce::Colour(0xa0090b0d), x + w, y + h, false);
'@
$txt=Apply $txt 'juce::ColourGradient inner\(masterPanel \? juce::Colour\(0xc81b1717\) : juce::Colour\(0xc8171b1e\),\s+x \+ 5\.0f, y \+ 5\.0f,\s+juce::Colour\(0xc8090b0d\), x \+ w, y \+ h, false\);' $rep10b 'OP10b'

$rep11=@'
    // stage113e-grime: industrial wear drawn over panels (under controls)
    {
        juce::Random rnd(113u);
        for (int i = 0; i < 40; ++i)
        {
            const float rx = (float)rnd.nextInt((int)baseW);
            const float ry = (float)rnd.nextInt((int)baseH);
            const float rr = 4.0f + (float)rnd.nextInt(18);
            juce::ColourGradient gr(juce::Colour(0x3c6a3a16), rx, ry,
                                    juce::Colour(0x006a3a16), rx, ry + rr, true);
            g.setGradientFill(gr);
            g.fillEllipse(rx - rr, ry - rr * 0.6f, rr * 2.0f, rr * 1.2f);
        }
        g.setColour(juce::Colour(0x10ffffff));
        for (int i = 0; i < 60; ++i)
        {
            const float x1 = (float)rnd.nextInt((int)baseW);
            const float y1 = (float)rnd.nextInt((int)baseH);
            const float x2 = x1 + 10.0f + (float)rnd.nextInt(40);
            const float y2 = y1 + 3.0f - (float)rnd.nextInt(6);
            g.drawLine(juce::Line<float>(x1, y1, x2, y2), 1.0f);
        }
        for (int i = 0; i < 10; ++i)
        {
            const float dx = (float)rnd.nextInt((int)baseW);
            const float dy = (float)rnd.nextInt((int)baseH / 2);
            g.setColour(juce::Colour(0x26000000));
            g.fillRect(dx, dy, 2.0f, 30.0f + (float)rnd.nextInt(60));
        }
    }
'@
$txt=Apply $txt 'g\.setColour\(red\);\s+g\.fillEllipse\(serial\.getRight\(\) - 8\.0f, serial\.getY\(\) \+ 6\.0f, 5\.0f, 5\.0f\);\s+\}' $rep11 'OP11'

[System.IO.File]::WriteAllText($target,$txt)
'GUI_PATCH_E=APPLIED'
}

if (Test-Path $refNew) { Remove-Item $refNew -Force }
Copy-Item -LiteralPath $target -Destination $refNew
'REFERENCE_RECREATED=PluginEditor_STAGE113.cpp'