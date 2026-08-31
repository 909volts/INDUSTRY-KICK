@echo off
setlocal
set "HERE=%~dp0"

echo INDUSTRY KICK V2 - Stage 6.8E
echo Diagnostic rebuild fix only.
echo No DSP or validation change.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%RUN_STAGE_6_8E_DIAGNOSTIC.ps1"
set "RC=%ERRORLEVEL%"

echo.
echo Diagnostic exit code: %RC%
if "%RC%"=="0" (
    echo PASS - upload:
    echo E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\Stage68SafetyProbe.csv
) else (
    echo FAIL - send the complete final error block.
)
pause
exit /b %RC%
