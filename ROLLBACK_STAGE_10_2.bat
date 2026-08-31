@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "BACKUP=%PROJECT%\Checkpoints\Stage9_1_before_Stage10_2"

if not exist "%BACKUP%\IndustryKickV2_R4_Freeze.dsp" goto :missing

copy /Y "%BACKUP%\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
copy /Y "%BACKUP%\FaustKickEngine.h" "%PROJECT%\Source\FaustKickEngine.h" >nul
copy /Y "%BACKUP%\FaustKickEngine.cpp" "%PROJECT%\Source\FaustKickEngine.cpp" >nul
copy /Y "%BACKUP%\PluginProcessor.h" "%PROJECT%\Source\PluginProcessor.h" >nul
copy /Y "%BACKUP%\PluginProcessor.cpp" "%PROJECT%\Source\PluginProcessor.cpp" >nul
copy /Y "%BACKUP%\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul

echo PASS - Stage 10.2 source rolled back.
pause
exit /b 0

:missing
echo ERROR - Stage 10.2 rollback checkpoint not found.
pause
exit /b 1
