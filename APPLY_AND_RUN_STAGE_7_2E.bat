@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"

echo INDUSTRY KICK - STAGE 7.2E
echo INSTALL CMD-ONLY PRE-GUI GATE
echo.

if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing

copy /Y "%HERE%Payload\Tools\RunStage72E.cmd" "%PROJECT%\Tools\RunStage72E.cmd" >nul
if errorlevel 1 goto :copyfail

call "%PROJECT%\Tools\RunStage72E.cmd"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo Bundle:
echo "%PROJECT%\Stage72EValidationBundle.zip"
echo.
echo Upload Stage72EValidationBundle.zip.
pause
exit /b %RC%

:missing
echo ERROR: Stage 7.1 approved project source not found.
pause
exit /b 1

:copyfail
echo ERROR: could not install RunStage72E.cmd.
pause
exit /b 1
