@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"

echo INDUSTRY KICK - STAGE 8.0 GUI V2 INSTALL
echo GUI ONLY / DSP FROZEN
echo.

if not exist "%PROJECT%\Source\PluginEditor.cpp" goto :missing
if not exist "%PROJECT%\Checkpoints\Stage7_1_DSP_APPROVED_FINAL_72E" goto :missing

copy /Y "%HERE%Payload\Tools\ApplyBuildValidateGuiV2.cmd" "%PROJECT%\Tools\ApplyBuildValidateGuiV2.cmd" >nul
if errorlevel 1 goto :fail

if not exist "%PROJECT%\GuiV2Payload" mkdir "%PROJECT%\GuiV2Payload" >nul 2>&1
copy /Y "%HERE%Payload\Source\PluginEditor.cpp" "%PROJECT%\GuiV2Payload\PluginEditor.cpp" >nul
if errorlevel 1 goto :fail

rem Install the payload beside the project runner. The runner expects ..\Source,
rem so temporarily mirror package layout under Project\GuiV2Package.
if exist "%PROJECT%\GuiV2Package" rmdir /s /q "%PROJECT%\GuiV2Package"
mkdir "%PROJECT%\GuiV2Package\Source" >nul 2>&1
mkdir "%PROJECT%\GuiV2Package\Tools" >nul 2>&1
copy /Y "%HERE%Payload\Source\PluginEditor.cpp" "%PROJECT%\GuiV2Package\Source\PluginEditor.cpp" >nul
copy /Y "%HERE%Payload\Tools\ApplyBuildValidateGuiV2.cmd" "%PROJECT%\GuiV2Package\Tools\ApplyBuildValidateGuiV2.cmd" >nul

call "%PROJECT%\GuiV2Package\Tools\ApplyBuildValidateGuiV2.cmd"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo Bundle:
echo "%PROJECT%\Stage80GuiV2ValidationBundle.zip"
echo.
echo Upload Stage80GuiV2ValidationBundle.zip.
pause
exit /b %RC%

:missing
echo ERROR: current Stage 7.1 project or approved checkpoint not found.
pause
exit /b 1

:fail
echo ERROR: could not install GUI V2 package.
pause
exit /b 1
