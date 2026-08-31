@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"

echo INDUSTRY KICK V2 - Stage 6.9C
echo FORCE DspSmoke REBUILD
echo No DSP or validator changes.
echo.

if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing
if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing

copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail

copy /Y "%HERE%Payload\Tools\RunStage69C.ps1" "%PROJECT%\Tools\RunStage69C.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"residualNumericallySilent" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"Stage69BTestRenders" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail

echo SOURCE COPY VERIFY: PASS
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage69C.ps1"

set "RC=%ERRORLEVEL%"
echo.
echo Exit code: %RC%

if "%RC%"=="0" (
  echo PASS - upload Stage69BTestRenders.zip
) else (
  echo FAIL - send Stage69C_DspSmoke.log or the final error block.
)

pause
exit /b %RC%

:missing
echo ERROR: expected project files not found.
pause
exit /b 1

:copyfail
echo ERROR: file copy failed.
pause
exit /b 1

:verifyfail
echo ERROR: copied DspSmoke is not Stage 6.9B.
pause
exit /b 1
