@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"
set "BACKUP=%PROJECT%\Checkpoints\Stage6_9B_before_6_10"

echo INDUSTRY KICK V2 - Stage 6.10
echo RAVE final-tail contour + validation-method correction
echo Technical and approved-shape thresholds remain unchanged.
echo.

if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing

if not exist "%BACKUP%" (
  mkdir "%BACKUP%\Faust" >nul 2>&1
  mkdir "%BACKUP%\Tests" >nul 2>&1
  mkdir "%BACKUP%\Tools" >nul 2>&1
  copy /Y "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%BACKUP%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
  copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\Tests\DspSmoke.cpp" >nul
  if exist "%PROJECT%\Tools\RunStage69B.ps1" copy /Y "%PROJECT%\Tools\RunStage69B.ps1" "%BACKUP%\Tools\RunStage69B.ps1" >nul
  echo Checkpoint saved.
)

copy /Y "%HERE%Payload\Faust\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tools\RunStage610.ps1" "%PROJECT%\Tools\RunStage610.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"Stage 6.10: final RAVE decay contour" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"stageGate=6.10" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"familyEnvelopeCorrelationDiagnostic" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage610.ps1"
set "RC=%ERRORLEVEL%"

echo.
echo Gate exit code: %RC%
if "%RC%"=="0" (
  echo PASS - upload Stage610TestRenders.zip
) else (
  echo FAIL - send Stage610_DspSmoke.log or the final error block.
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
echo ERROR: Stage 6.10 patch verification failed.
pause
exit /b 1
