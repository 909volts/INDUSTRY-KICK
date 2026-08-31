@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "BACKUP=%PROJECT%\Checkpoints\Stage8_0_before_8_1_Stage9_0"

echo INDUSTRY KICK - ROLLBACK STAGE 8.1 + 9.0
echo.

if not exist "%BACKUP%\PluginEditor.cpp" goto :missing
if not exist "%BACKUP%\FactoryPresets.h" goto :missing
if not exist "%BACKUP%\DspSmoke.cpp" goto :missing

copy /Y "%BACKUP%\PluginEditor.cpp" "%PROJECT%\Source\PluginEditor.cpp" >nul
copy /Y "%BACKUP%\FactoryPresets.h" "%PROJECT%\Source\FactoryPresets.h" >nul
copy /Y "%BACKUP%\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul

echo PASS - Stage 8.0 GUI / approved 50 presets / Stage 7.1 DspSmoke restored.
pause
exit /b 0

:missing
echo ERROR: rollback checkpoint not found.
pause
exit /b 1
