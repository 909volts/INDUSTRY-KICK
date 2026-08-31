@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"
set "RUNNER=%PROJECT%\Tools\RunStage72B.ps1"

echo INDUSTRY KICK - STAGE 7.2B
echo POWERSHELL PARSER FIX ONLY
echo NO DSP / TEST THRESHOLD / PROJECT SOURCE CHANGES
echo.

if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing

copy /Y "%HERE%Payload\Tools\RunStage72B.ps1" "%RUNNER%" >nul
if errorlevel 1 goto :copyfail

echo Running PowerShell parser preflight...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile('%RUNNER%', [ref]$tokens, [ref]$errors) | Out-Null; if($errors.Count -gt 0){ $errors | ForEach-Object { Write-Host ('PARSER_ERROR: ' + $_.Message + ' at line ' + $_.Extent.StartLineNumber) }; exit 90 } else { Write-Host 'POWERSHELL_PARSE_PREFLIGHT=PASS'; exit 0 }"
if errorlevel 1 goto :parsefail

echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%RUNNER%"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo Validation bundle:
echo "%PROJECT%\Stage72ValidationBundle.zip"
echo.

if "%RC%"=="0" (
  echo PRE-GUI DSP GATE: PASS
  echo Upload Stage72ValidationBundle.zip.
) else (
  echo PRE-GUI DSP GATE: FAIL
  echo If Stage72ValidationBundle.zip exists, upload it.
  echo If it does not exist, send the final error block.
)

pause
exit /b %RC%

:missing
echo ERROR: Stage 7.1 project source not found.
pause
exit /b 1

:copyfail
echo ERROR: could not install Stage 7.2B runner.
pause
exit /b 1

:parsefail
echo.
echo FAILURE_CLASS=RUNNER_PARSER
echo The Stage 7.2B runner did not execute.
echo No build/test/checkpoint result should be inferred from this run.
pause
exit /b 90
