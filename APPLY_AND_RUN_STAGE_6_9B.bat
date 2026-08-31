@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"
set "BACKUP=%PROJECT%\Checkpoints\Stage6_9_before_6_9B_validator_fix"

echo INDUSTRY KICK V2 - Stage 6.9B
echo Numerical-silence validator fix ONLY.
echo No Faust DSP / preset / headroom / sonic-threshold changes.
echo.

if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing
if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing

if not exist "%BACKUP%" (
  mkdir "%BACKUP%\Tests" >nul 2>&1
  copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\Tests\DspSmoke.cpp" >nul
)

copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tools\RunStage69B.ps1" "%PROJECT%\Tools\RunStage69B.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"residualNumericallySilent" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"numericalSilenceRms = 1.0e-12" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"maxSafetyClampEngagementPercent = 0.10" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"maxEnvCorr < 0.82" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage69B.ps1"
set "RC=%ERRORLEVEL%"

echo.
echo Gate exit code: %RC%
if "%RC%"=="0" (
  echo PASS - upload Stage69BTestRenders.zip
) else (
  echo FAIL - send the final gate block.
)
pause
exit /b %RC%

:missing
echo ERROR: expected Stage 6.9 project files not found.
pause
exit /b 1
:copyfail
echo ERROR: patch copy failed.
pause
exit /b 1
:verifyfail
echo ERROR: validator patch verification failed.
pause
exit /b 1
