@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "BACKUP=%PROJECT%\Checkpoints\GUI_V1_before_STAGE8_GUI_V2"

echo INDUSTRY KICK - GUI V2 ROLLBACK
echo.

if not exist "%BACKUP%\PluginEditor.cpp" (
  echo ERROR: GUI V1 backup not found.
  pause
  exit /b 1
)

copy /Y "%BACKUP%\PluginEditor.cpp" "%PROJECT%\Source\PluginEditor.cpp" >nul
if exist "%BACKUP%\PluginEditor.h" copy /Y "%BACKUP%\PluginEditor.h" "%PROJECT%\Source\PluginEditor.h" >nul

echo GUI V1 source restored.
echo DSP files were never modified by the GUI V2 patch.
pause
exit /b 0
