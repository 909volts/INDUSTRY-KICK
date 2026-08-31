@echo off
setlocal
set "HERE=%~dp0"
echo INDUSTRY KICK - STAGE 10.3
echo Compiled safety fix. No listening pack.
echo.
call "%HERE%Payload\Tools\RunStage103.cmd"
set "RC=%ERRORLEVEL%"
echo.
echo Exit code: %RC%
echo Upload:
echo E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\Stage103ValidationBundle.zip
pause
exit /b %RC%
