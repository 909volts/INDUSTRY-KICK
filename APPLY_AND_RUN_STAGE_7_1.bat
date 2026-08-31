@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"
set "BACKUP=%PROJECT%\Checkpoints\Stage6_10_before_Stage7_1"

echo INDUSTRY KICK - STAGE 7.1
echo Approved family processing + common master integration
echo.

if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing

if not exist "%BACKUP%" (
  mkdir "%BACKUP%\Faust" >nul 2>&1
  mkdir "%BACKUP%\Tests" >nul 2>&1
  mkdir "%BACKUP%\Tools" >nul 2>&1
  copy /Y "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%BACKUP%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
  copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\Tests\DspSmoke.cpp" >nul
  echo Stage 6.10 checkpoint saved.
)

copy /Y "%HERE%Payload\Faust\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tools\RunStage71.ps1" "%PROJECT%\Tools\RunStage71.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"stage7MasterHardClip" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"co.compressor_mono(4,-9.5,0.030,0.030)" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"stageGate=7.1" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"lowBandShapeParityPass" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage71.ps1"
set "RC=%ERRORLEVEL%"

echo.
echo Gate exit code: %RC%
if "%RC%"=="0" (
  echo PASS - upload Stage71TestRenders.zip for final compiled/reference analysis.
) else (
  echo FAIL - Stage71TestRenders.zip should still have been created.
  echo Upload Stage71TestRenders.zip plus Stage71_DspSmoke.log.
)
pause
exit /b %RC%

:missing
echo ERROR: expected project files not found.
pause
exit /b 1

:copyfail
echo ERROR: patch copy failed.
pause
exit /b 1

:verifyfail
echo ERROR: Stage 7.1 verification failed.
pause
exit /b 1
