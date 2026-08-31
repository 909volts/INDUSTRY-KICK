@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"

echo INDUSTRY KICK - STAGE 7.1C
echo DspSmoke C++ compile fix only.
echo Faust DSP and sonic validation thresholds unchanged.
echo.

if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing
if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing

copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail

copy /Y "%HERE%Payload\Tools\RunStage71C.ps1" "%PROJECT%\Tools\RunStage71C.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"stageGate=7.1" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail

findstr /C:"approvedStage7Reference=30ms_release" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage71C.ps1"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
if "%RC%"=="0" (
  echo PASS - upload Stage71TestRenders.zip.
) else (
  echo FAIL - read FAILURE_CLASS above.
  echo BUILD: send final build error block.
  echo DSP_OR_VALIDATION: upload Stage71TestRenders.zip and Stage71C_DspSmoke.log.
)

pause
exit /b %RC%

:missing
echo ERROR: expected Stage 7.1B project files not found.
pause
exit /b 1

:copyfail
echo ERROR: patch copy failed.
pause
exit /b 1

:verifyfail
echo ERROR: Stage 7.1C source verification failed.
pause
exit /b 1
