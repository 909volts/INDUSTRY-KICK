@echo off
setlocal
set "HERE=%~dp0"

echo INDUSTRY KICK - STAGE 10.3B
echo Targeted HEAVY safety check only.
echo This does NOT run all 250 presets and does NOT build VST3/Standalone.
echo.

call "%HERE%Payload\Tools\RunStage103B.cmd"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo Upload:
echo E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\Stage103BHeavyValidationBundle.zip
pause
exit /b %RC%
