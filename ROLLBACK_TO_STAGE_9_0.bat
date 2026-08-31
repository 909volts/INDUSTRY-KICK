@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "BACKUP=%PROJECT%\Checkpoints\Stage9_0_before_Stage9_1"

if not exist "%BACKUP%\FactoryPresets.h" goto :missing
if not exist "%BACKUP%\DspSmoke.cpp" goto :missing

copy /Y "%BACKUP%\FactoryPresets.h" "%PROJECT%\Source\FactoryPresets.h" >nul
copy /Y "%BACKUP%\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
echo PASS - Stage 9.0 factory bank and DspSmoke restored.
pause
exit /b 0

:missing
echo ERROR - Stage 9.0 rollback checkpoint missing.
pause
exit /b 1
