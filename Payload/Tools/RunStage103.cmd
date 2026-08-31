@echo off
setlocal EnableExtensions

set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "PACKAGE=%~dp0..\.."
set "VALID=%PROJECT%\Stage103Validation"
set "BUNDLE=%PROJECT%\Stage103ValidationBundle.zip"
set "BACKUP=%PROJECT%\Checkpoints\Stage9_1_before_Stage10_3"

set "SOURCE_IDENTITY=NOT_TESTED"
set "FAUST_BUILD=NOT_TESTED"
set "DSP_SMOKE=NOT_TESTED"
set "FACTORY_250=NOT_TESTED"
set "ACCENT_BANK_MAPPING=NOT_TESTED"
set "ACCENT_BANK_STATE=NOT_TESTED"
set "RANDOMIZER=NOT_TESTED"
set "STATE_ROUNDTRIP=NOT_TESTED"
set "VST3_BUILD=NOT_TESTED"
set "STANDALONE_BUILD=NOT_TESTED"
set "LISTENING=NOT_REQUESTED"
set "RELEASE_READY=NO"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"

echo INDUSTRY KICK - STAGE 10.3
echo COMPILED SAFETY FIX - HEAVY ADDED PATH ONLY
echo ORIGINAL KICK / CORE / VALIDATOR THRESHOLDS UNCHANGED
echo.

if exist "%VALID%" rmdir /s /q "%VALID%"
mkdir "%VALID%" >nul 2>&1
if errorlevel 1 exit /b 2
call :WriteStatus

echo [1/8] VERIFY ROLLED-BACK STAGE 9.1 BASE
fc /b "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%PACKAGE%\Reference\Faust_STAGE71.dsp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\FaustKickEngine.h" "%PACKAGE%\Reference\FaustKickEngine_STAGE71.h" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\FaustKickEngine.cpp" "%PACKAGE%\Reference\FaustKickEngine_STAGE71.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\PluginProcessor.h" "%PACKAGE%\Reference\PluginProcessor_STAGE71.h" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\PluginProcessor.cpp" "%PACKAGE%\Reference\PluginProcessor_STAGE71.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\FactoryPresets.h" "%PACKAGE%\Reference\FactoryPresets_STAGE91.h" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Tests\DspSmoke.cpp" "%PACKAGE%\Reference\DspSmoke_STAGE91.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\Source\PluginEditor.cpp" "%PACKAGE%\Reference\PluginEditor_STAGE81.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\CMakeLists.txt" "%PACKAGE%\Reference\CMakeLists_STAGE71.txt" >nul
if errorlevel 1 goto :SOURCE_FAIL

set "SOURCE_IDENTITY=PASS"
call :WriteStatus
echo SOURCE_IDENTITY=PASS

echo.
echo [2/8] CHECKPOINT
if not exist "%BACKUP%" mkdir "%BACKUP%" >nul 2>&1
copy /Y "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%BACKUP%\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :FILE_FAIL
copy /Y "%PROJECT%\Source\FaustKickEngine.h" "%BACKUP%\FaustKickEngine.h" >nul
copy /Y "%PROJECT%\Source\FaustKickEngine.cpp" "%BACKUP%\FaustKickEngine.cpp" >nul
copy /Y "%PROJECT%\Source\PluginProcessor.h" "%BACKUP%\PluginProcessor.h" >nul
copy /Y "%PROJECT%\Source\PluginProcessor.cpp" "%BACKUP%\PluginProcessor.cpp" >nul
copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\DspSmoke.cpp" >nul

echo.
echo [3/8] APPLY STAGE 10.3
copy /Y "%PACKAGE%\Payload\Faust\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :APPLY_FAIL
copy /Y "%PACKAGE%\Payload\Source\FaustKickEngine.h" "%PROJECT%\Source\FaustKickEngine.h" >nul
copy /Y "%PACKAGE%\Payload\Source\FaustKickEngine.cpp" "%PROJECT%\Source\FaustKickEngine.cpp" >nul
copy /Y "%PACKAGE%\Payload\Source\PluginProcessor.h" "%PROJECT%\Source\PluginProcessor.h" >nul
copy /Y "%PACKAGE%\Payload\Source\PluginProcessor.cpp" "%PROJECT%\Source\PluginProcessor.cpp" >nul
copy /Y "%PACKAGE%\Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul

findstr /C:"stage10FamPick(0.70,0.30,0.85,1.00,0.25)" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :APPLY_FAIL
findstr /C:"presetAuditStage=10.3" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL
findstr /C:"maxSafetyClampEngagementPercent = 0.10" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL

rem immutable project files
fc /b "%PROJECT%\Source\FactoryPresets.h" "%PACKAGE%\Reference\FactoryPresets_STAGE91.h" >nul
if errorlevel 1 goto :APPLY_FAIL
fc /b "%PROJECT%\Source\PluginEditor.cpp" "%PACKAGE%\Reference\PluginEditor_STAGE81.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL
fc /b "%PROJECT%\CMakeLists.txt" "%PACKAGE%\Reference\CMakeLists_STAGE71.txt" >nul
if errorlevel 1 goto :APPLY_FAIL

echo APPLY_STAGE103=PASS

echo.
echo [4/8] CMAKE CONFIGURE
cmake -S "%PROJECT%" -B "%PROJECT%\build" -G "Visual Studio 17 2022" -A x64 > "%VALID%\CMakeConfigure.log" 2>&1
if errorlevel 1 (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=CMake configure"
  goto :ROLLBACK_FAIL
)

echo.
echo [5/8] CLEAN BUILD - FAUST + DSPSMOKE
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_DspSmoke --clean-first > "%VALID%\DspSmokeBuild.log" 2>&1
if errorlevel 1 (
  set "FAUST_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Faust or DspSmoke Stage 10.3 build"
  goto :ROLLBACK_FAIL
)
set "FAUST_BUILD=PASS"

set "SMOKEEXE=%PROJECT%\build\KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
if not exist "%SMOKEEXE%" (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=DspSmoke executable missing"
  goto :ROLLBACK_FAIL
)

echo.
echo [6/8] FULL 250-PRESET COMPILED VALIDATION
if exist "%PROJECT%\Stage103PresetAudit" rmdir /s /q "%PROJECT%\Stage103PresetAudit"

pushd "%PROJECT%"
"%SMOKEEXE%" > "%VALID%\DspSmoke.log" 2>&1
set "SMOKERC=%ERRORLEVEL%"
popd

if exist "%PROJECT%\Stage103PresetAudit" (
  robocopy "%PROJECT%\Stage103PresetAudit" "%VALID%\Stage103PresetAudit" /E /NFL /NDL /NJH /NJS /NP >nul
)

findstr /C:"presetAuditStage=10.3" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 goto :GATE_FAIL
findstr /C:"factoryBank=1 count=250" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 goto :GATE_FAIL

findstr /C:"accentBankMapping=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "ACCENT_BANK_MAPPING=FAIL") else (set "ACCENT_BANK_MAPPING=PASS")
findstr /C:"accentBankState=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "ACCENT_BANK_STATE=FAIL") else (set "ACCENT_BANK_STATE=PASS")
findstr /C:"allFactoryPresetsTechnical=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "FACTORY_250=FAIL") else (set "FACTORY_250=PASS")
findstr /C:"randomizerTechnical=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "RANDOMIZER=FAIL") else (set "RANDOMIZER=PASS")
findstr /C:"stateRoundTrip=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "STATE_ROUNDTRIP=FAIL") else (set "STATE_ROUNDTRIP=PASS")
findstr /C:"result=PASS" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 goto :GATE_FAIL

if not "%SMOKERC%"=="0" goto :GATE_FAIL
if not "%ACCENT_BANK_MAPPING%"=="PASS" goto :GATE_FAIL
if not "%ACCENT_BANK_STATE%"=="PASS" goto :GATE_FAIL
if not "%FACTORY_250%"=="PASS" goto :GATE_FAIL
if not "%RANDOMIZER%"=="PASS" goto :GATE_FAIL
if not "%STATE_ROUNDTRIP%"=="PASS" goto :GATE_FAIL

set "DSP_SMOKE=PASS"
call :WriteStatus

echo.
echo [7/8] VST3 + STANDALONE
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_VST3 > "%VALID%\VST3Build.log" 2>&1
if errorlevel 1 (
  set "VST3_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 Stage 10.3 build"
  goto :FAIL
)
set "VST3BIN=%PROJECT%\build\KICKCRAFTER_artefacts\Release\VST3\INDUSTRY KICK.vst3\Contents\x86_64-win\INDUSTRY KICK.vst3"
if not exist "%VST3BIN%" (
  set "VST3_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 binary missing"
  goto :FAIL
)
certutil -hashfile "%VST3BIN%" SHA256 > "%VALID%\VST3_SHA256.txt" 2>&1
set "VST3_BUILD=PASS"

cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_Standalone > "%VALID%\StandaloneBuild.log" 2>&1
if errorlevel 1 (
  set "STANDALONE_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Standalone Stage 10.3 build"
  goto :FAIL
)
set "STANDALONE_BUILD=PASS"

echo.
echo [8/8] EVIDENCE + BUNDLE
certutil -hashfile "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" SHA256 > "%VALID%\FAUST103_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\Source\PluginProcessor.cpp" SHA256 > "%VALID%\PROCESSOR103_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\Source\FactoryPresets.h" SHA256 > "%VALID%\FACTORY91_UNCHANGED_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\Source\PluginEditor.cpp" SHA256 > "%VALID%\GUI81_UNCHANGED_SHA256.txt" 2>&1

set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"
call :WriteStatus
call :Bundle

echo.
echo ================================================================
echo STAGE103_COMPILED_GATE=PASS
echo LISTENING=NOT_REQUESTED
echo RELEASE_READY=NO
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 0

:GATE_FAIL
set "DSP_SMOKE=FAIL"
set "FAILURE_CLASS=DSP_OR_PRESET_VALIDATION"
set "FAILED_STEP=Stage 10.3 compiled DspSmoke"
goto :ROLLBACK_FAIL

:SOURCE_FAIL
set "SOURCE_IDENTITY=FAIL"
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Current project is not rolled-back Stage 9.1 + GUI 8.1 base"
goto :FAIL

:FILE_FAIL
set "FAILURE_CLASS=FILE_IO"
set "FAILED_STEP=Checkpoint current source"
goto :FAIL

:APPLY_FAIL
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Apply Stage 10.3 source"
goto :ROLLBACK_FAIL

:ROLLBACK_FAIL
echo.
echo Stage 10.3 failed. Restoring Stage 9.1 source.
if exist "%BACKUP%\IndustryKickV2_R4_Freeze.dsp" copy /Y "%BACKUP%\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if exist "%BACKUP%\FaustKickEngine.h" copy /Y "%BACKUP%\FaustKickEngine.h" "%PROJECT%\Source\FaustKickEngine.h" >nul
if exist "%BACKUP%\FaustKickEngine.cpp" copy /Y "%BACKUP%\FaustKickEngine.cpp" "%PROJECT%\Source\FaustKickEngine.cpp" >nul
if exist "%BACKUP%\PluginProcessor.h" copy /Y "%BACKUP%\PluginProcessor.h" "%PROJECT%\Source\PluginProcessor.h" >nul
if exist "%BACKUP%\PluginProcessor.cpp" copy /Y "%BACKUP%\PluginProcessor.cpp" "%PROJECT%\Source\PluginProcessor.cpp" >nul
if exist "%BACKUP%\DspSmoke.cpp" copy /Y "%BACKUP%\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
goto :FAIL

:FAIL
call :WriteStatus
call :Bundle
echo.
echo ================================================================
echo STAGE103_COMPILED_GATE=FAIL
echo FAILURE_CLASS=%FAILURE_CLASS%
echo FAILED_STEP=%FAILED_STEP%
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 1

:WriteStatus
> "%VALID%\STATUS.txt" echo SOURCE_IDENTITY=%SOURCE_IDENTITY%
>>"%VALID%\STATUS.txt" echo FAUST_BUILD=%FAUST_BUILD%
>>"%VALID%\STATUS.txt" echo DSP_SMOKE=%DSP_SMOKE%
>>"%VALID%\STATUS.txt" echo FACTORY_250=%FACTORY_250%
>>"%VALID%\STATUS.txt" echo ACCENT_BANK_MAPPING=%ACCENT_BANK_MAPPING%
>>"%VALID%\STATUS.txt" echo ACCENT_BANK_STATE=%ACCENT_BANK_STATE%
>>"%VALID%\STATUS.txt" echo RANDOMIZER=%RANDOMIZER%
>>"%VALID%\STATUS.txt" echo STATE_ROUNDTRIP=%STATE_ROUNDTRIP%
>>"%VALID%\STATUS.txt" echo VST3_BUILD=%VST3_BUILD%
>>"%VALID%\STATUS.txt" echo STANDALONE_BUILD=%STANDALONE_BUILD%
>>"%VALID%\STATUS.txt" echo LISTENING=%LISTENING%
>>"%VALID%\STATUS.txt" echo RELEASE_READY=%RELEASE_READY%
>>"%VALID%\STATUS.txt" echo FAILURE_CLASS=%FAILURE_CLASS%
>>"%VALID%\STATUS.txt" echo FAILED_STEP=%FAILED_STEP%
exit /b 0

:Bundle
if exist "%BUNDLE%" del /q "%BUNDLE%"
where tar.exe >nul 2>&1
if errorlevel 1 exit /b 0
pushd "%VALID%"
tar.exe -a -c -f "%BUNDLE%" *
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
