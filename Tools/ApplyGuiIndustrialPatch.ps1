$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root 'Project\Source\PluginEditor.cpp'
$refNew = Join-Path $root 'Reference\PluginEditor_STAGE113.cpp'

$txt = [System.IO.File]::ReadAllText($target)
$txt = $txt.Replace("`r`n", "`n")

$pairs = @(
 @("    juce::ColourGradient chassis(juce::Colour(0xff24282b), 0.0f, 0.0f,`n                                 juce::Colour(0xff070809), baseW, baseH, true);`n    g.setGradientFill(chassis);`n    g.fillRect(0.0f, 0.0f, baseW, baseH);",
   "    if (backgroundImage.isValid())`n        g.drawImage(backgroundImage, 0, 0, (int)baseW, (int)baseH,`n                    0, 0, backgroundImage.getWidth(), backgroundImage.getHeight(), false);`n    g.setColour(juce::Colour(0x96050607));`n    g.fillRect(0.0f, 0.0f, baseW, baseH);"),
 @("        g.setColour(juce::Colour(0xff303538));`n        g.fillRoundedRectangle(r, 3.0f);`n        g.setColour(black);`n        g.fillRoundedRectangle(r.reduced(3.0f), 2.0f);",
   "        g.setColour(juce::Colour(0xd822262a));`n        g.fillRoundedRectangle(r, 3.0f);`n        g.setColour(juce::Colour(0xd8070809));`n        g.fillRoundedRectangle(r.reduced(3.0f), 2.0f);"),
 @("        juce::ColourGradient inner(masterPanel ? juce::Colour(0xff1b1717) : juce::Colour(0xff171b1e),`n                                   x + 5.0f, y + 5.0f,`n                                   juce::Colour(0xff090b0d), x + w, y + h, false);",
   "        juce::ColourGradient inner(masterPanel ? juce::Colour(0xc81b1717) : juce::Colour(0xc8171b1e),`n                                   x + 5.0f, y + 5.0f,`n                                   juce::Colour(0xc8090b0d), x + w, y + h, false);"),
 @("    juce::ColourGradient bezelGrad(juce::Colour(0xff8a8e91),`n                                    c.x - radius, c.y - radius,`n                                    juce::Colour(0xff161a1e),`n                                    c.x + radius, c.y + radius, false);",
   "    juce::ColourGradient bezelGrad(juce::Colour(0xff5d5a52),`n                                    c.x - radius, c.y - radius,`n                                    juce::Colour(0xff14100c),`n                                    c.x + radius, c.y + radius, false);"),
 @("    g.setColour(juce::Colour(0xff050607));`n    g.strokePath(bezel, juce::PathStrokeType(2.2f));",
   "    g.setColour(juce::Colour(0xff050607));`n    g.strokePath(bezel, juce::PathStrokeType(2.2f));`n    g.setColour(juce::Colour(0x7a5a3016));`n    g.strokePath(bezel, juce::PathStrokeType(1.0f));"),
 @("    juce::ColourGradient face(juce::Colour(0xff3b4044),",
   "    juce::ColourGradient face(juce::Colour(0xff33302b),"),
 @("    const float hL = meterHeight(meterL);`n    const float hR = meterHeight(meterR);`n    g.setColour(meterColour(meterL));`n    g.fillRect(meter.getX() + 5.0f, meter.getBottom() - 5.0f - hL, 7.0f, hL);`n    g.setColour(meterColour(meterR));`n    g.fillRect(meter.getX() + 18.0f, meter.getBottom() - 5.0f - hR, 7.0f, hR);",
   "    const float hL = meterHeight(meterL);`n    const float hR = meterHeight(meterR);`n    for (float segY = 0.0f; segY < meter.getHeight() - 18.0f; segY += 6.0f)`n    {`n        const float yy = meter.getBottom() - 5.0f - segY - 4.0f;`n        const bool onL = segY < hL;`n        const bool onR = segY < hR;`n        const float db = juce::jmap(segY, 0.0f, meter.getHeight() - 18.0f, -60.0f, 0.0f);`n        const auto col = db > -3.0f ? red : (db > -12.0f ? amber : pale);`n        g.setColour(onL ? col : juce::Colour(0xff22262a));`n        g.fillRect(meter.getX() + 5.0f, yy, 7.0f, 4.0f);`n        g.setColour(onR ? col : juce::Colour(0xff22262a));`n        g.fillRect(meter.getX() + 18.0f, yy, 7.0f, 4.0f);`n    }"),
 @("    g.setColour(red);`n    g.strokePath(scopeWave, juce::PathStrokeType(1.6f));",
   "    {`n        juce::Path fill(scopeWave);`n        fill.lineTo(scope.getRight() - 5.0f, scope.getCentreY());`n        fill.lineTo(scope.getX() + 5.0f, scope.getCentreY());`n        fill.closeSubPath();`n        juce::ColourGradient scopeFill(juce::Colour(0x90e51735), 0.0f, scope.getY(),`n                                       juce::Colour(0x10e51735), 0.0f, scope.getBottom(), false);`n        g.setGradientFill(scopeFill);`n        g.fillPath(fill);`n    }`n    g.setColour(red);`n    g.strokePath(scopeWave, juce::PathStrokeType(1.6f));"),
 @("        g.setColour((x / 28) % 2 == 0 ? amber : juce::Colour(0xff1b1d1e));`n        g.fillPath(stripe);`n    }",
   "        g.setColour((x / 28) % 2 == 0 ? amber : juce::Colour(0xff1b1d1e));`n        g.fillPath(stripe);`n    }`n`n    {`n        juce::Rectangle<float> tube(430.0f, 876.0f, 580.0f, 12.0f);`n        g.setColour(juce::Colour(0xff0a0c0d));`n        g.fillRoundedRectangle(tube.expanded(3.0f), 8.0f);`n        juce::ColourGradient tubeGrad(juce::Colour(0xff3a0510), tube.getX(), tube.getY(),`n                                      juce::Colour(0xffe51735), tube.getX(), tube.getBottom(), false);`n        g.setGradientFill(tubeGrad);`n        g.fillRoundedRectangle(tube, 6.0f);`n        g.setColour(juce::Colour(0x60e51735));`n        g.drawRoundedRectangle(tube.expanded(6.0f), 9.0f, 5.0f);`n        g.setColour(juce::Colour(0xff0b0d0e));`n        g.setFont(juce::FontOptions(""Consolas"", 8.0f, juce::Font::bold));`n        g.drawText(""/// BUILT TO KICK ///"", tube, juce::Justification::centred);`n    }`n`n    {`n        juce::Rectangle<float> serial(60.0f, 876.0f, 150.0f, 20.0f);`n        g.setColour(juce::Colour(0xffb9bcc0));`n        g.fillRect(serial);`n        g.setColour(juce::Colour(0xff17191b));`n        for (float bx = serial.getX() + 6.0f; bx < serial.getRight() - 26.0f; bx += 5.0f)`n            g.fillRect(bx, serial.getY() + 4.0f, ((int)bx % 10) < 5 ? 2.0f : 1.0f, 9.0f);`n        g.setFont(juce::FontOptions(""Consolas"", 6.5f, juce::Font::bold));`n        g.drawText(""IK-71 // 909V"", serial.getX() + 4.0f, serial.getY() + 12.0f, 120.0f, 8.0f, juce::Justification::centredLeft);`n        g.setColour(juce::Colour(0xff35c442));`n        g.fillEllipse(serial.getRight() - 16.0f, serial.getY() + 6.0f, 5.0f, 5.0f);`n        g.setColour(red);`n        g.fillEllipse(serial.getRight() - 8.0f, serial.getY() + 6.0f, 5.0f, 5.0f);`n    }")
)

if ($txt.Contains('BUILT TO KICK')) {
    Write-Host 'GUI_INDUSTRIAL_PATCH=ALREADY_APPLIED'
} else {
    foreach ($p in $pairs) {
        $old = $p[0]; $new = $p[1]
        $c = ([regex]::Matches($txt, [regex]::Escape($old))).Count
        if ($c -ne 1) { throw "REPLACEMENT_NOT_UNIQUE_OR_MISSING found=$c : $($old.Substring(0,40))" }
        $txt = $txt.Replace($old, $new)
    }
    [System.IO.File]::WriteAllText($target, $txt)
    Write-Host 'GUI_INDUSTRIAL_PATCH=APPLIED'
}

if (-not (Test-Path $refNew)) {
    Copy-Item -LiteralPath $target -Destination $refNew
    Write-Host 'REFERENCE_CREATED=PluginEditor_STAGE113.cpp'
}
