@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"

echo INDUSTRY KICK V2 - Stage 6.7B
echo Validation-only correction. Faust DSP remains unchanged.
echo Target: %PROJECT%
echo.

if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing
if not exist "%PROJECT%\Tools\RunStage6Gate.ps1" goto :missing

copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tools\RunStage6Gate.ps1" "%PROJECT%\Tools\RunStage6Gate.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"residualDecayDropDb" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"Stage 6.7B Residual Validation Build Gate" "%PROJECT%\Tools\RunStage6Gate.ps1" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
echo Faust DSP: UNCHANGED
echo Starting build gate...
echo.
powershell -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage6Gate.ps1"
set "RC=%ERRORLEVEL%"
echo.
echo Gate exit code: %RC%
pause
exit /b %RC%

:missing
echo ERROR: expected Stage 6.7 project files not found.
pause
exit /b 1

:copyfail
echo ERROR: patch copy failed.
pause
exit /b 1

:verifyfail
echo ERROR: patch verification failed.
pause
exit /b 1
