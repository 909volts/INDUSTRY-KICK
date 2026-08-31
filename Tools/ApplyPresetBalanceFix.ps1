$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root 'Project\Source\FactoryPresets.h'
$refNew = Join-Path $root 'Reference\FactoryPresets_STAGE112.h'

$txt = [System.IO.File]::ReadAllText($target)

$pairs = @(
 @('{"Techno Nail", 1, 0, 58.489,0.6797,',              '{"Techno Nail", 1, 0, 53.489,0.7797,'),
 @('{"Techno Nail / TIGHT", 1, 0, 60.289,0.6097,',      '{"Techno Nail / TIGHT", 1, 0, 54.289,0.7597,'),
 @('{"Front Row", 1, 0, 56.133,0.4997,',                '{"Front Row", 1, 0, 51.133,0.6797,'),
 @('{"Front Row / TIGHT", 1, 0, 57.933,0.4297,',        '{"Front Row / TIGHT", 1, 0, 52.933,0.6297,'),
 @('1.000,0.6600,0.8768,',                              '1.000,0.7800,0.8768,'),
 @('{"Saw Pressure", 4, 0, 56.511,0.4927,',             '{"Saw Pressure", 4, 0, 51.511,0.6627,'),
 @('0.4319,0.9294,',                                    '0.4319,0.7500,'),
 @('1.000,0.6826,',                                     '1.000,0.8000,'),
 @('{"Saw Pressure / TIGHT", 4, 0, 58.511,0.4200,',     '{"Saw Pressure / TIGHT", 4, 0, 53.511,0.6000,'),
 @('0.4519,0.9500,0.7109,',                             '0.4519,0.7800,0.7109,'),
 @('1.000,0.5600,0.9520,',                              '1.000,0.7200,0.9520,'),
 @('{"Saw Pressure / MUTANT", 4, 0, 59.511,0.4200,',    '{"Saw Pressure / MUTANT", 4, 0, 54.511,0.6000,'),
 @('0.4619,0.9500,0.8709,',                             '0.4619,0.8000,0.8709,'),
 @('1.000,0.5600,0.9320,',                              '1.000,0.7200,0.9320,'),
 @('0.4726,0.4201,0.9000,',                             '0.4726,0.4201,0.7200,'),
 @('1.000,0.7712,0.8360,0.000,0.8600,',                 '1.000,0.8800,0.8360,0.000,0.7000,')
)

if ($txt.Contains('{"Techno Nail", 1, 0, 53.489,0.7797,')) {
    Write-Host 'PRESET_BALANCE_FIX=ALREADY_APPLIED'
} else {
    foreach ($p in $pairs) {
        $old = $p[0]; $new = $p[1]
        $c = ([regex]::Matches($txt, [regex]::Escape($old))).Count
        if ($c -ne 1) { throw "REPLACEMENT_NOT_UNIQUE_OR_MISSING found=$c : $old" }
        $txt = $txt.Replace($old, $new)
    }
    [System.IO.File]::WriteAllText($target, $txt)
    Write-Host 'PRESET_BALANCE_FIX=APPLIED'
}

if (-not (Test-Path $refNew)) {
    Copy-Item -LiteralPath $target -Destination $refNew
    Write-Host 'REFERENCE_CREATED=FactoryPresets_STAGE112.h'
}
