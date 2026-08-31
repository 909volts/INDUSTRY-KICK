@echo off
setlocal
set "HERE=%~dp0"
echo INDUSTRY KICK - STAGE 10.3C
echo Robust targeted HEAVY safety gate only.
echo.
call "%HERE%Payload\Tools\RunStage103C.cmd"
set "RC=%ERRORLEVEL%"
echo.
echo Exit code: %RC%
echo Upload:
echo E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\Stage103CHeavyValidationBundle.zip
pause
exit /b %RC%
