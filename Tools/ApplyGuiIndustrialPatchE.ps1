$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$target=Join-Path $root 'Project\Source\PluginEditor.cpp'
$refNew=Join-Path $root 'Reference\PluginEditor_STAGE113.cpp'
$txt=[System.IO.File]::ReadAllText($target)

if ($txt.Contains('stage113g')) {
  'GUI_PATCH_G=ALREADY_APPLIED'
} else {
  $m=[regex]::Matches($txt,'for \(float cx : \{ 236\.0f, 556\.0f, 876\.0f \}\)\s+\{\s+g\.setColour\(juce::Colour\(0x50292e31\)\);\s+g\.fillRoundedRectangle\(cx - 104\.0f, 676\.0f, 208\.0f, 180\.0f, 3\.0f\);\s+g\.setColour\(juce::Colour\(0x504d5356\)\);\s+g\.drawRoundedRectangle\(cx - 104\.0f, 676\.0f, 208\.0f, 180\.0f, 3\.0f, 1\.0f\);\s+g\.setColour\(juce::Colour\(0xff111416\)\);\s+g\.fillRect\(cx - 92\.0f, 689\.0f, 184\.0f, 5\.0f\);\s+\}')
  if ($m.Count -ne 1) { throw "BACKPLATES found=$($m.Count)" }
  $txt=$txt.Replace($m[0].Value,'    // stage113g: mutant backplates removed')
  [System.IO.File]::WriteAllText($target,$txt)
  'GUI_PATCH_G=APPLIED'
}

if (Test-Path $refNew) { Remove-Item $refNew -Force }
Copy-Item -LiteralPath $target -Destination $refNew
'REFERENCE_RECREATED=PluginEditor_STAGE113.cpp'