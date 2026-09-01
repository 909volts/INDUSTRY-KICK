@echo off
cd /d "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts"
set ISCC=
for /f "delims=" %%i in ('dir /b /s "C:\Program Files\Inno Setup*\ISCC.exe" 2^>nul') do set "ISCC=%%i"
for /f "delims=" %%i in ('dir /b /s "C:\Program Files (x86)\Inno Setup*\ISCC.exe" 2^>nul') do set "ISCC=%%i"
if "%ISCC%"=="" (
    echo Inno Setup non trovato. Scaricalo da: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)
echo Uso: %ISCC%
"%ISCC%" "INDUSTRY_KICK_installer.iss"
echo.
echo ========================================
echo INSTALLER PRONTO:
echo Distribution\INDUSTRY_KICK_v1.0_Setup.exe
echo ========================================
pause