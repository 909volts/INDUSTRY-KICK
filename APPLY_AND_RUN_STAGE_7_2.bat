@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"

echo INDUSTRY KICK - STAGE 7.2
echo DSP FREEZE / PRE-GUI TECHNICAL GATE
echo NO DSP SOURCE CHANGES
echo.

if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing

copy /Y "%HERE%Payload\Tools\RunStage72.ps1" "%PROJECT%\Tools\RunStage72.ps1" >nul
if errorlevel 1 goto :copyfail

powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage72.ps1"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo Validation bundle:
echo "%PROJECT%\Stage72ValidationBundle.zip"
echo.
if "%RC%"=="0" (
  echo PRE-GUI DSP GATE: PASS
  echo Upload Stage72ValidationBundle.zip.
) else (
  echo PRE-GUI DSP GATE: FAIL
  echo Upload Stage72ValidationBundle.zip; it contains the logs even on failure.
)

pause
exit /b %RC%

:missing
echo ERROR: Stage 7.1 project source not found.
pause
exit /b 1

:copyfail
echo ERROR: could not install Stage 7.2 runner.
pause
exit /b 1
