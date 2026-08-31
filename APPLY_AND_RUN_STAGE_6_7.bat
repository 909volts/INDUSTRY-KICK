@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"
set "BACKUP=%PROJECT%\Checkpoints\Stage6_5_PASS_before_6_7"

echo INDUSTRY KICK V2 - Stage 6.7
echo User-approved family diversity -> compiled Faust candidate
echo Target: %PROJECT%
echo.

if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing
if not exist "%PROJECT%\Tools\RunStage6Gate.ps1" goto :missing

if not exist "%BACKUP%" (
    mkdir "%BACKUP%\Faust" >nul 2>&1
    mkdir "%BACKUP%\Tests" >nul 2>&1
    mkdir "%BACKUP%\Tools" >nul 2>&1
    copy /Y "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%BACKUP%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
    copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\Tests\DspSmoke.cpp" >nul
    copy /Y "%PROJECT%\Tools\RunStage6Gate.ps1" "%BACKUP%\Tools\RunStage6Gate.ps1" >nul
    echo Stage 6.5 checkpoint saved.
) else (
    echo Existing Stage 6.5 checkpoint preserved.
)

copy /Y "%HERE%Payload\Faust\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tools\RunStage6Gate.ps1" "%PROJECT%\Tools\RunStage6Gate.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"Stage 6.7: ROUND" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"familyEnvelopeDiversity" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"Stage 6.7 Compiled Diversity Build Gate" "%PROJECT%\Tools\RunStage6Gate.ps1" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
echo Starting complete build gate...
echo.
powershell -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage6Gate.ps1"
set "RC=%ERRORLEVEL%"
echo.
echo Gate exit code: %RC%
if "%RC%"=="0" (
    echo PASS candidate. Stage67TestRenders.zip is in the Project folder.
) else (
    echo Gate failed. Stage 6.5 checkpoint remains available for rollback.
)
pause
exit /b %RC%

:missing
echo ERROR: Expected project files were not found.
pause
exit /b 1

:copyfail
echo ERROR: Patch copy failed.
pause
exit /b 1

:verifyfail
echo ERROR: Stage 6.7 patch verification failed.
pause
exit /b 1
