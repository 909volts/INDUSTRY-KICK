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

if ($txt.Contains('stage113f-fix')) {
  'GUI_PATCH_F=ALREADY_APPLIED'
} else {

$txt=Apply $txt '"05", "MUTANT PRESS",' '"05", "MUTANT",' 'RENAME_MUTANT'
$txt=Apply $txt '"06", "MASTER PRESS",' '"06", "MASTER",' 'RENAME_MASTER'

$repBP=@'
        g.setColour(juce::Colour(0x50292e31));
        g.fillRoundedRectangle(cx - 104.0f, 676.0f, 208.0f, 180.0f, 3.0f);
        g.setColour(juce::Colour(0x504d5356));
        g.drawRoundedRectangle(cx - 104.0f, 676.0f, 208.0f, 180.0f, 3.0f, 1.0f);
'@
$txt=Apply $txt 'g\.setColour\(juce::Colour\(0xff292e31\)\);\s+g\.fillRoundedRectangle\(cx - 104\.0f, 676\.0f, 208\.0f, 180\.0f, 3\.0f\);\s+g\.setColour\(juce::Colour\(0xff4d5356\)\);\s+g\.drawRoundedRectangle\(cx - 104\.0f, 676\.0f, 208\.0f, 180\.0f, 3\.0f, 1\.0f\);' $repBP 'BACKPLATES'

$txt=Apply $txt 'for \(int x = 1102; x < 1398; x \+= 17\)\s+\{\s+g\.setColour\(juce::Colour\(0xff303538\)\);\s+g\.fillRoundedRectangle\(\(float\)x, 674\.0f, 9\.0f, 25\.0f, 2\.0f\);\s+\}' '    // stage113f-fix: master vents removed' 'VENTS'

$repCH=@'
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
'@
$txt=Apply $txt 'const int irIndex = juce::jlimit\(0, 19, chamberSelect\.getSelectedItemIndex\(\)\);\s+const int selected = irIndex < 10 \? 0 : \(irIndex < 15 \? 1 : 2\);\s+const float sourceW = \(float\)chamberAtlas\.getWidth\(\) / 3\.0f;\s+const auto destination = chamber\.reduced\(4\.0f\)\.toNearestInt\(\);\s+g\.drawImage\(chamberAtlas,\s+destination\.getX\(\), destination\.getY\(\),\s+destination\.getWidth\(\), destination\.getHeight\(\),\s+juce::roundToInt\(selected \* sourceW\), 0,\s+juce::roundToInt\(sourceW\), chamberAtlas\.getHeight\(\), false\);' $repCH 'CHAMBER'

[System.IO.File]::WriteAllText($target,$txt)
'GUI_PATCH_F=APPLIED'
}

if (Test-Path $refNew) { Remove-Item $refNew -Force }
Copy-Item -LiteralPath $target -Destination $refNew
'REFERENCE_RECREATED=PluginEditor_STAGE113.cpp'