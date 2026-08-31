@echo off
setlocal
set "HERE=%~dp0"

echo INDUSTRY KICK - STAGE 10.2
echo Compiled Faust accent/bus integration
echo No listening pack will be generated.
echo.

call "%HERE%Payload\Tools\RunStage102.cmd"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo Upload this file:
echo E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\Stage102ValidationBundle.zip
pause
exit /b %RC%
