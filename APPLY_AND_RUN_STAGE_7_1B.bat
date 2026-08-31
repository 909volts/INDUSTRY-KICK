@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"
set "BACKUP=%PROJECT%\Checkpoints\Stage7_1_compile_fail_before_7_1B"

echo INDUSTRY KICK - STAGE 7.1B
echo Faust compile repair only.
echo Sonic design and validator thresholds unchanged.
echo.

if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing

if not exist "%BACKUP%" (
  mkdir "%BACKUP%\Faust" >nul 2>&1
  mkdir "%BACKUP%\Tests" >nul 2>&1
  mkdir "%BACKUP%\Tools" >nul 2>&1
  copy /Y "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%BACKUP%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
  copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\Tests\DspSmoke.cpp" >nul
  echo Stage 7.1 compile-fail checkpoint saved.
)

copy /Y "%HERE%Payload\Faust\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :copyfail

copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail

copy /Y "%HERE%Payload\Tools\RunStage71B.ps1" "%PROJECT%\Tools\RunStage71B.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"Stage 7.1B compile fix" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :verifyfail

findstr /C:"0.800499021761" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :verifyfail

findstr /C:"stageGate=7.1" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage71B.ps1"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
if "%RC%"=="0" (
  echo PASS - upload Stage71TestRenders.zip.
) else (
  echo FAIL - read FAILURE_CLASS above.
  echo BUILD: send the final build error block.
  echo DSP_OR_VALIDATION: upload Stage71TestRenders.zip and Stage71B_DspSmoke.log.
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
echo ERROR: Stage 7.1B patch verification failed.
pause
exit /b 1
