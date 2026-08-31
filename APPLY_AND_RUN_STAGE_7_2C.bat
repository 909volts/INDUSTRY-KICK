@echo off
setlocal
set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "HERE=%~dp0"
set "RUNNER=%PROJECT%\Tools\RunStage72C.ps1"

echo INDUSTRY KICK - STAGE 7.2C
echo ROBUST DSP FREEZE / PRE-GUI GATE
echo NO DSP SOURCE CHANGES
echo.

if not exist "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :missing
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :missing

copy /Y "%HERE%Payload\Tools\RunStage72C.ps1" "%RUNNER%" >nul
if errorlevel 1 goto :copyfail

echo Running Windows PowerShell parser preflight...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile('%RUNNER%', [ref]$tokens, [ref]$errors) | Out-Null; if($errors.Count -gt 0){ $errors | ForEach-Object { Write-Host ('PARSER_ERROR: ' + $_.Message + ' at line ' + $_.Extent.StartLineNumber) }; exit 90 } else { Write-Host 'POWERSHELL_PARSE_PREFLIGHT=PASS'; exit 0 }"
if errorlevel 1 goto :parsefail

echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%RUNNER%"
set "RC=%ERRORLEVEL%"

echo.
echo Exit code: %RC%
echo Bundle:
echo "%PROJECT%\Stage72CValidationBundle.zip"
echo.

if "%RC%"=="0" (
  echo PRE-GUI DSP GATE: PASS
) else (
  echo PRE-GUI DSP GATE: FAIL
)

echo Upload Stage72CValidationBundle.zip.
pause
exit /b %RC%

:missing
echo ERROR: Stage 7.1 project source not found.
pause
exit /b 1

:copyfail
echo ERROR: could not install Stage 7.2C runner.
pause
exit /b 1

:parsefail
echo.
echo FAILURE_CLASS=RUNNER_PARSER
echo The runner was NOT executed.
echo No DSP/build result can be inferred.
pause
exit /b 90
