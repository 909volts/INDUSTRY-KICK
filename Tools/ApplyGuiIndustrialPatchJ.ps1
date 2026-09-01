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

if ($txt.Contains('stage113j')) {
  'GUI_PATCH_J=ALREADY_APPLIED'
} else {

$txt=Apply $txt 'g\.setColour\(juce::Colour\(0xa822262a\)\);\s+g\.fillRoundedRectangle\(r, 3\.0f\);\s+g\.setColour\(juce::Colour\(0xa8070809\)\);\s+g\.fillRoundedRectangle\(r\.reduced\(3\.0f\), 2\.0f\);' (@'
        // stage113j: panels more opaque for readability
        g.setColour(juce::Colour(0xe022262a));
        g.fillRoundedRectangle(r, 3.0f);
        g.setColour(juce::Colour(0xe0070809));
        g.fillRoundedRectangle(r.reduced(3.0f), 2.0f);
'@) 'OPJ1a'

$txt=Apply $txt 'juce::ColourGradient inner\(masterPanel \? juce::Colour\(0xa01b1717\) : juce::Colour\(0xa0171b1e\),\s+x \+ 5\.0f, y \+ 5\.0f,\s+juce::Colour\(0xa0090b0d\), x \+ w, y \+ h, false\);' (@'
        juce::ColourGradient inner(masterPanel ? juce::Colour(0xd81b1717) : juce::Colour(0xd8171b1e),
                                   x + 5.0f, y + 5.0f,
                                   juce::Colour(0xd8090b0d), x + w, y + h, false);
'@) 'OPJ1b'

$txt=Apply $txt 'g\.setColour\(juce::Colour\(0x96050607\)\);' (@'
    // stage113j: lighter base overlay, background more visible
    g.setColour(juce::Colour(0x50050607));
'@) 'OPJ2'

$txt=Apply $txt '// stage113i-overlay: industrial objects over panels \(heavy machine, with sense\)\s+g\.setOpacity\(0\.30f\);' (@'
    // stage113i-overlay: industrial objects over panels (heavy machine, with sense)
    // stage113j: keep instruments crisp (no texture veil)
    g.excludeClipRegion(juce::Rectangle<int>(1202, 130, 204, 142));
    g.excludeClipRegion(juce::Rectangle<int>(1288, 713, 30, 116));
    g.excludeClipRegion(juce::Rectangle<int>(455, 294, 235, 33));
    g.setOpacity(0.30f);
'@) 'OPJ3'

[System.IO.File]::WriteAllText($target,$txt)
'GUI_PATCH_J=APPLIED'
}

if (Test-Path $refNew) { Remove-Item $refNew -Force }
Copy-Item -LiteralPath $target -Destination $refNew
'REFERENCE_RECREATED=PluginEditor_STAGE113.cpp'