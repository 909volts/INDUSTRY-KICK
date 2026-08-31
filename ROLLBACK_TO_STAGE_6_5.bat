@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "BACKUP=%PROJECT%\Checkpoints\Stage6_5_PASS_before_6_7"

if not exist "%BACKUP%\Faust\IndustryKickV2_R4_Freeze.dsp" (
    echo ERROR: Stage 6.5 checkpoint not found.
    pause
    exit /b 1
)

copy /Y "%BACKUP%\Faust\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
copy /Y "%BACKUP%\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
copy /Y "%BACKUP%\Tools\RunStage6Gate.ps1" "%PROJECT%\Tools\RunStage6Gate.ps1" >nul

echo STAGE_6_5_CHECKPOINT_RESTORED
echo Re-run the build gate if you need the compiled Stage 6.5 binary again.
pause
