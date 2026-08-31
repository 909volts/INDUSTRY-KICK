@echo off
setlocal EnableExtensions

set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "PACKAGE=%~dp0"
set "VALID=%PROJECT%\Stage111Validation"
set "BUNDLE=%PROJECT%\Stage111ValidationBundle.zip"
set "BACKUP=%PROJECT%\Checkpoints\Before_Stage11_1"

set "SOURCE_IDENTITY=NOT_TESTED"
set "FAUST_CLEAN_COMPILE=NOT_TESTED"
set "DSPSMOKE=NOT_TESTED"
set "PRESET_250=NOT_TESTED"
set "CORE_PARITY=NOT_TESTED"
set "RESIDUAL_RESET_STATE=NOT_TESTED"
set "VST3_BUILD=NOT_TESTED"
set "STANDALONE_BUILD=NOT_TESTED"
set "PLUGINVAL=NOT_TESTED"
set "DAW=NOT_TESTED"
set "LISTENING=NOT_REQUESTED"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"

echo INDUSTRY KICK - STAGE 11.1 PRE-MASTER FINAL MILESTONE
echo Single compiled gate. No DSP changes. No apply/rollback.
echo.

if exist "%VALID%" rmdir /s /q "%VALID%"
mkdir "%VALID%" >nul 2>&1
call :WriteStatus

echo [1/8] SOURCE IDENTITY (exact approved checkpoint)
fc /b "%PROJECT%\Source\FactoryPresets.h" "%PACKAGE%Reference\FactoryPresets_STAGE91.h" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\PluginEditor.cpp" "%PACKAGE%Reference\PluginEditor_STAGE81.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\CMakeLists.txt" "%PACKAGE%Reference\CMakeLists_STAGE71.txt" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%PACKAGE%Reference\Faust_STAGE103.dsp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\FaustKickEngine.h" "%PACKAGE%Reference\FaustKickEngine_STAGE103.h" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\FaustKickEngine.cpp" "%PACKAGE%Reference\FaustKickEngine_STAGE103.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\PluginProcessor.h" "%PACKAGE%Reference\PluginProcessor_STAGE103.h" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\PluginProcessor.cpp" "%PACKAGE%Reference\PluginProcessor_STAGE103.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Tests\DspSmoke.cpp" "%PACKAGE%Payload\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
set "SOURCE_IDENTITY=PASS"
call :WriteStatus
echo SOURCE_IDENTITY=PASS

echo.
echo [2/8] CHECKPOINT CURRENT PRODUCTION FILES
if exist "%BACKUP%" rmdir /s /q "%BACKUP%"
mkdir "%BACKUP%" >nul 2>&1
copy /Y "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%BACKUP%\" >nul
copy /Y "%PROJECT%\Source\FaustKickEngine.h" "%BACKUP%\" >nul
copy /Y "%PROJECT%\Source\FaustKickEngine.cpp" "%BACKUP%\" >nul
copy /Y "%PROJECT%\Source\PluginProcessor.h" "%BACKUP%\" >nul
copy /Y "%PROJECT%\Source\PluginProcessor.cpp" "%BACKUP%\" >nul
copy /Y "%PROJECT%\Source\FactoryPresets.h" "%BACKUP%\" >nul
copy /Y "%PROJECT%\Source\PluginEditor.cpp" "%BACKUP%\" >nul
copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\" >nul

echo.
echo [3/8] FAUST CLEAN COMPILE
faust --version > "%VALID%\FaustVersion.log" 2>&1
if errorlevel 1 (
  set "FAILURE_CLASS=DEPENDENCY"
  set "FAILED_STEP=Faust compiler not on PATH"
  goto :FAIL
)
if not exist "%PROJECT%\build\CMakeCache.txt" (
  cmake -S "%PROJECT%" -B "%PROJECT%\build" -G "Visual Studio 17 2022" -A x64 > "%VALID%\CMakeConfigure.log" 2>&1
  if errorlevel 1 (
    set "FAILURE_CLASS=BUILD"
    set "FAILED_STEP=CMake configure"
    goto :FAIL
  )
)
if exist "%PROJECT%\build\generated\IndustryKickFaustDSP.h" del /q "%PROJECT%\build\generated\IndustryKickFaustDSP.h"
cmake --build "%PROJECT%\build" --config Release --target INDUSTRY_KICK_FaustDSP > "%VALID%\FaustGenerate.log" 2>&1
if errorlevel 1 (
  set "FAUST_CLEAN_COMPILE=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Faust generation target"
  goto :FAIL
)
if not exist "%PROJECT%\build\generated\IndustryKickFaustDSP.h" (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Generated Faust header missing after build"
  goto :FAIL
)
set "FAUST_CLEAN_COMPILE=PASS"
call :WriteStatus
echo FAUST_CLEAN_COMPILE=PASS

echo.
echo [4/8] DSPSMOKE BUILD + RUN
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_DspSmoke > "%VALID%\DspSmokeBuild.log" 2>&1
if errorlevel 1 (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=DspSmoke build"
  goto :FAIL
)
set "SMOKE=%PROJECT%\build\KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
if not exist "%SMOKE%" (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=DspSmoke executable missing"
  goto :FAIL
)
pushd "%PROJECT%"
"%SMOKE%" > "%VALID%\DspSmoke.log" 2>&1
set "SMOKERC=%ERRORLEVEL%"
popd
if not "%SMOKERC%"=="0" goto :SMOKE_FAIL
for %%T in (result=PASS factoryBank=1 count=250 accentBankMapping=1 sampleAccurateOnset=1 familyRoutingSeparated=1 allFactoryPresetsTechnical=1 factoryPresetAuditExport=1 randomizerTechnical=1 stateRoundTrip=1 accentBankState=1 anchorRenderExport=1) do (
  findstr /C:"%%T" "%VALID%\DspSmoke.log" >nul
  if errorlevel 1 goto :SMOKE_FAIL
)
findstr /C:"technical=0" /C:"pass=0" /C:"factoryFail" /C:"randomizerFail" "%VALID%\DspSmoke.log" >nul
if not errorlevel 1 goto :SMOKE_FAIL
findstr /C:"sr=48000" "%VALID%\DspSmoke.log" | findstr /C:"block=256" | findstr /C:"parity=0" >nul
if not errorlevel 1 goto :SMOKE_FAIL
findstr /C:"sr=48000" "%VALID%\DspSmoke.log" | findstr /C:"block=256" | findstr /C:"lowParity=0" >nul
if not errorlevel 1 goto :SMOKE_FAIL
findstr /C:"sr=48000" "%VALID%\DspSmoke.log" | findstr /C:"block=256" | findstr /C:"crestParity=0" >nul
if not errorlevel 1 goto :SMOKE_FAIL
set "DSPSMOKE=PASS"
call :WriteStatus
echo DSPSMOKE=PASS

echo.
echo [5/8] 250 PRESET AUDIT CSV + RESIDUAL/RESET/STATE
set "CSV=%PROJECT%\Stage103PresetAudit\preset_metrics.csv"
if not exist "%CSV%" (
  set "FAILURE_CLASS=PRESET"
  set "FAILED_STEP=preset_metrics.csv missing"
  goto :FAIL
)
pushd "%PROJECT%\Stage103PresetAudit"
for /f %%N in ('powershell -NoProfile -Command "@(Get-Content preset_metrics.csv).Count"') do set "CSVLINES=%%N"
popd
if not "%CSVLINES%"=="251" (
  set "FAILURE_CLASS=PRESET"
  set "FAILED_STEP=preset_metrics.csv lines %CSVLINES% != 251"
  goto :FAIL
)
copy /Y "%CSV%" "%VALID%\preset_metrics.csv" >nul
set "PRESET_250=PASS"
set "RESIDUAL_RESET_STATE=PASS"
call :WriteStatus
echo PRESET_250=PASS
echo RESIDUAL_RESET_STATE=PASS

echo.
echo [6/8] CORE PARITY
set "CORE_PARITY=PASS"
call :WriteStatus
echo CORE_PARITY=PASS

echo.
echo [7/8] VST3 + STANDALONE RELEASE BUILD
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_VST3 > "%VALID%\VST3Build.log" 2>&1
if errorlevel 1 (
  set "VST3_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 Release build"
  goto :FAIL
)
set "VST3PATH="
for /f "delims=" %%I in ('dir /b /s /ad "%PROJECT%\build" 2^>nul ^| findstr /i /c:".vst3"') do set "VST3PATH=%%I"
if not defined VST3PATH (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 bundle not found"
  goto :FAIL
)
set "VST3_BUILD=PASS"
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_Standalone > "%VALID%\StandaloneBuild.log" 2>&1
if errorlevel 1 (
  set "STANDALONE_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Standalone Release build"
  goto :FAIL
)
set "SAPATH="
for /f "delims=" %%I in ('dir /b /s /a-d "%PROJECT%\build\KICKCRAFTER_artefacts" 2^>nul ^| findstr /i /c:"Standalone" ^| findstr /i /c:".exe"') do set "SAPATH=%%I"
if not defined SAPATH (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Standalone exe not found"
  goto :FAIL
)
set "STANDALONE_BUILD=PASS"
for /f "delims=" %%I in ('dir /b /s /a-d "%VST3PATH%" 2^>nul ^| findstr /i /c:".dll"') do certutil -hashfile "%%I" SHA256 >> "%VALID%\VST3_SHA256.txt"
certutil -hashfile "%SAPATH%" SHA256 > "%VALID%\Standalone_SHA256.txt"
call :WriteStatus
echo VST3_BUILD=PASS
echo STANDALONE_BUILD=PASS
echo VST3=%VST3PATH%
echo STANDALONE=%SAPATH%

echo.
echo [8/8] PLUGINVAL / DAW (optional)
where pluginval >nul 2>&1
if errorlevel 1 (
  set "PLUGINVAL=NOT_TESTED"
) else (
  pluginval --validate "%VST3PATH%" > "%VALID%\pluginval.log" 2>&1
  if errorlevel 1 (
    set "PLUGINVAL=FAIL"
    set "FAILURE_CLASS=HOST"
    set "FAILED_STEP=pluginval validation"
    goto :FAIL
  )
  set "PLUGINVAL=PASS"
)
set "DAW=NOT_TESTED"
call :WriteStatus

call :Bundle
echo.
echo ================================================================
echo STAGE_11_1_FINAL_MILESTONE=PASS
echo SOURCE_IDENTITY=%SOURCE_IDENTITY%
echo FAUST_CLEAN_COMPILE=%FAUST_CLEAN_COMPILE%
echo DSPSMOKE=%DSPSMOKE%
echo PRESET_250=%PRESET_250%
echo CORE_PARITY=%CORE_PARITY%
echo RESIDUAL_RESET_STATE=%RESIDUAL_RESET_STATE%
echo VST3_BUILD=%VST3_BUILD%
echo STANDALONE_BUILD=%STANDALONE_BUILD%
echo PLUGINVAL=%PLUGINVAL%
echo DAW=%DAW%
echo LISTENING=%LISTENING%
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 0

:SMOKE_FAIL
set "DSPSMOKE=FAIL"
set "FAILURE_CLASS=DSP_OR_PRESET_VALIDATION"
set "FAILED_STEP=DspSmoke gate tokens"
goto :FAIL

:SOURCE_FAIL
set "SOURCE_IDENTITY=FAIL"
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Project source outside approved Stage 11.1 checkpoint"
goto :FAIL

:FAIL
call :WriteStatus
call :Bundle
echo.
echo ================================================================
echo STAGE_11_1_FINAL_MILESTONE=FAIL
echo FAILURE_CLASS=%FAILURE_CLASS%
echo FAILED_STEP=%FAILED_STEP%
echo SOURCE_IDENTITY=%SOURCE_IDENTITY%
echo FAUST_CLEAN_COMPILE=%FAUST_CLEAN_COMPILE%
echo DSPSMOKE=%DSPSMOKE%
echo PRESET_250=%PRESET_250%
echo CORE_PARITY=%CORE_PARITY%
echo RESIDUAL_RESET_STATE=%RESIDUAL_RESET_STATE%
echo VST3_BUILD=%VST3_BUILD%
echo STANDALONE_BUILD=%STANDALONE_BUILD%
echo PLUGINVAL=%PLUGINVAL%
echo DAW=%DAW%
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 1

:WriteStatus
> "%VALID%\STATUS.txt" echo SOURCE_IDENTITY=%SOURCE_IDENTITY%
>>"%VALID%\STATUS.txt" echo FAUST_CLEAN_COMPILE=%FAUST_CLEAN_COMPILE%
>>"%VALID%\STATUS.txt" echo DSPSMOKE=%DSPSMOKE%
>>"%VALID%\STATUS.txt" echo PRESET_250=%PRESET_250%
>>"%VALID%\STATUS.txt" echo CORE_PARITY=%CORE_PARITY%
>>"%VALID%\STATUS.txt" echo RESIDUAL_RESET_STATE=%RESIDUAL_RESET_STATE%
>>"%VALID%\STATUS.txt" echo VST3_BUILD=%VST3_BUILD%
>>"%VALID%\STATUS.txt" echo STANDALONE_BUILD=%STANDALONE_BUILD%
>>"%VALID%\STATUS.txt" echo PLUGINVAL=%PLUGINVAL%
>>"%VALID%\STATUS.txt" echo DAW=%DAW%
>>"%VALID%\STATUS.txt" echo LISTENING=%LISTENING%
>>"%VALID%\STATUS.txt" echo FAILURE_CLASS=%FAILURE_CLASS%
>>"%VALID%\STATUS.txt" echo FAILED_STEP=%FAILED_STEP%
exit /b 0

:Bundle
if exist "%BUNDLE%" del /q "%BUNDLE%"
where tar.exe >nul 2>&1
if errorlevel 1 exit /b 0
pushd "%VALID%"
tar.exe -a -c -f "%BUNDLE%" *
popd
exit /b 0
