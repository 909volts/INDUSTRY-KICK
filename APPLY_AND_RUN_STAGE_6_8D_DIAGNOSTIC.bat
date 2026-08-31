@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"
set "BACKUP=%PROJECT%\Checkpoints\Stage6_8_before_pre_safety_probe"

echo INDUSTRY KICK V2 - Stage 6.8D Pre-Safety Diagnostic
echo NO DSP SOUND CHANGE
echo Target: %PROJECT%
echo.

if not exist "%PROJECT%\Source\PluginProcessor.cpp" goto :missing
if not exist "%PROJECT%\Source\PluginProcessor.h" goto :missing
if not exist "%PROJECT%\CMakeLists.txt" goto :missing

if not exist "%BACKUP%" (
  mkdir "%BACKUP%\Source" >nul 2>&1
  copy /Y "%PROJECT%\Source\PluginProcessor.cpp" "%BACKUP%\Source\PluginProcessor.cpp" >nul
  copy /Y "%PROJECT%\Source\PluginProcessor.h" "%BACKUP%\Source\PluginProcessor.h" >nul
  copy /Y "%PROJECT%\CMakeLists.txt" "%BACKUP%\CMakeLists.txt" >nul
  echo Diagnostic checkpoint saved.
)

copy /Y "%HERE%Payload\Source\PluginProcessor.cpp" "%PROJECT%\Source\PluginProcessor.cpp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Source\PluginProcessor.h" "%PROJECT%\Source\PluginProcessor.h" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tests\SafetyProbe.cpp" "%PROJECT%\Tests\SafetyProbe.cpp" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\Tools\RunStage68SafetyProbe.ps1" "%PROJECT%\Tools\RunStage68SafetyProbe.ps1" >nul
if errorlevel 1 goto :copyfail
copy /Y "%HERE%Payload\CMakeLists.txt" "%PROJECT%\CMakeLists.txt" >nul
if errorlevel 1 goto :copyfail

findstr /C:"preSafetyPeak" "%PROJECT%\Source\PluginProcessor.cpp" >nul
if errorlevel 1 goto :verifyfail
findstr /C:"KICKCRAFTER_SafetyProbe" "%PROJECT%\CMakeLists.txt" >nul
if errorlevel 1 goto :verifyfail

echo PATCH VERIFY: PASS
echo Building diagnostic only...
echo.
powershell -ExecutionPolicy Bypass -File "%PROJECT%\Tools\RunStage68SafetyProbe.ps1"

set "RC=%ERRORLEVEL%"
echo.
echo Diagnostic exit code: %RC%
if "%RC%"=="0" (
  echo Send Stage68SafetyProbe.csv.
)
pause
exit /b %RC%

:missing
echo ERROR: expected project files not found.
pause
exit /b 1

:copyfail
echo ERROR: diagnostic copy failed.
pause
exit /b 1

:verifyfail
echo ERROR: diagnostic verification failed.
pause
exit /b 1
