@echo off
setlocal
set "HERE=%~dp0"

echo INDUSTRY KICK - STAGE 8.1 + 9.0
echo Industrial GUI + 250 preset compiled audit
echo.

call "%HERE%Payload\Tools\RunStage8190.cmd"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo.
if "%RC%"=="0" (
  echo PASS - upload:
  echo E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\Stage8190ValidationBundle.zip
) else (
  echo FAIL - upload Stage8190ValidationBundle.zip if it exists.
)
pause
exit /b %RC%
