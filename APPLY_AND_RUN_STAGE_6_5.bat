@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"

echo INDUSTRY KICK V2 - Stage 6.5
echo Target: %PROJECT%
echo.

copy /Y "%HERE%Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tools\RunStage6Gate.ps1" "%PROJECT%\Tools\RunStage6Gate.ps1" >nul
if errorlevel 1 goto :copyfail

findstr /C:"residualSafetyPass" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"Stage 6.5 Validation Build Gate" "%PROJECT%\Tools\RunStage6Gate.ps1" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
echo Starting build gate...
echo.
powershell -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage6Gate.ps1"
set "RC=%ERRORLEVEL%"
echo.
echo Gate exit code: %RC%
pause
exit /b %RC%

:copyfail
echo COPY FAILED.
pause
exit /b 1

:verifyfail
echo PATCH VERIFY FAILED.
pause
exit /b 1
