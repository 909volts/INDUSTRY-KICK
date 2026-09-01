@echo off
setlocal enabledelayedexpansion
cd /d "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts"

echo ========================================
echo INDUSTRY KICK - DISTRIBUTION BUILDER
echo ========================================
echo.

echo [1/6] CHECKING BINARIES...
if not exist "Project\build\KICKCRAFTER_artefacts\Release\VST3" (
    echo FAIL: VST3 not found. Run the stage runner first.
    pause
    exit /b 1
)
if not exist "Project\build\KICKCRAFTER_artefacts\Release\Standalone\INDUSTRY KICK.exe" (
    echo FAIL: Standalone not found. Run the stage runner first.
    pause
    exit /b 1
)
echo BINARIES=OK

echo [2/6] CREATING DISTRIBUTION FOLDER...
if exist "Distribution\INDUSTRY_KICK_v1.0_Windows" rd /s /q "Distribution\INDUSTRY_KICK_v1.0_Windows"
mkdir "Distribution\INDUSTRY_KICK_v1.0_Windows\VST3"
mkdir "Distribution\INDUSTRY_KICK_v1.0_Windows\Standalone"
echo FOLDER=CREATED

echo [3/6] COPYING BINARIES...
xcopy /E /I /Y "Project\build\KICKCRAFTER_artefacts\Release\VST3\*" "Distribution\INDUSTRY_KICK_v1.0_Windows\VST3\" >nul
copy /Y "Project\build\KICKCRAFTER_artefacts\Release\Standalone\INDUSTRY KICK.exe" "Distribution\INDUSTRY_KICK_v1.0_Windows\Standalone\" >nul
echo BINARIES_COPIED

echo [4/6] CREATING README.txt...
(
echo INDUSTRY KICK v1.0 - by 909Volts
echo ========================================
echo.
echo INSTALLAZIONE WINDOWS
echo.
echo 1. VST3 (per DAW: Ableton, FL Studio, Cubase, Reaper, Bitwig, ecc.^)
echo    - Copia la cartella "INDUSTRY KICK.vst3" in:
echo      C:\Program Files\Common Files\VST3\
echo    - Riavvia la DAW e scan dei plugin.
echo.
echo 2. STANDALONE (uso senza DAW^)
echo    - Apri "Standalone\INDUSTRY KICK.exe"
echo    - Nessuna installazione richiesta.
echo.
echo REQUISITI
echo - Windows 10/11 (64-bit^)
echo - CPU moderna (Intel/AMD^)
echo - 200 MB RAM
echo.
echo SUPPORTO
echo https://909volts.gumroad.com
) > "Distribution\INDUSTRY_KICK_v1.0_Windows\README.txt"
echo README=CREATED

echo [5/6] CREATING CHANGELOG.txt...
(
echo INDUSTRY KICK - CHANGELOG
echo.
echo v1.0 (Stage 11.3 - 2026-09-01^)
echo -------------------------------
echo - GUI industriale "heavy machine" completa
echo - Texture ruggine procedurale sui pannelli
echo - Segnale HIGH VOLTAGE ISO 7010 su sezione MASTER
echo - Catena laterale, conduit inferiore, sticker warning
echo - Meter LED segmentati
echo - Scope con riempimento rosso
echo - Tubo luminoso "/// BUILT TO KICK ///"
echo - 250 preset factory validati
echo - DSP Faust stabile e congelato
echo - VST3 + Standalone Windows 64-bit
echo.
echo Build validated: pluginval PASS, DspSmoke PASS, 250 presets PASS
) > "Distribution\INDUSTRY_KICK_v1.0_Windows\CHANGELOG.txt"
echo CHANGELOG=CREATED

echo [6/6] CREATING ZIP...
if exist "Distribution\INDUSTRY_KICK_v1.0_Windows.zip" del /f "Distribution\INDUSTRY_KICK_v1.0_Windows.zip"
powershell -NoProfile -Command "Compress-Archive -Path 'Distribution\INDUSTRY_KICK_v1.0_Windows\*' -DestinationPath 'Distribution\INDUSTRY_KICK_v1.0_Windows.zip' -CompressionLevel Optimal"
if not exist "Distribution\INDUSTRY_KICK_v1.0_Windows.zip" (
    echo FAIL: zip not created
    pause
    exit /b 1
)

echo.
echo ========================================
echo DISTRIBUTION READY
echo ========================================
echo.
echo File: Distribution\INDUSTRY_KICK_v1.0_Windows.zip
powershell -NoProfile -Command "(Get-Item 'Distribution\INDUSTRY_KICK_v1.0_Windows.zip').Length / 1MB" 
echo MB
echo.
echo Upload this file to Gumroad as the new version.
echo.
pause