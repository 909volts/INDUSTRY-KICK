@echo off
setlocal
set "HERE=%~dp0"

echo INDUSTRY KICK - STAGE 9.1
echo PRESET DIVERSITY REVISION
echo.

call "%HERE%Payload\Tools\RunStage91.cmd"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo.
echo Upload:
echo E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\Stage91ValidationBundle.zip
pause
exit /b %RC%
