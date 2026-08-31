@echo off
setlocal EnableExtensions

set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "APPROVED=%PROJECT%\Checkpoints\Stage7_1_DSP_APPROVED_FINAL_72E"
set "PACKAGE=%~dp0..\.."
set "VALID=%PROJECT%\Stage91Validation"
set "BUNDLE=%PROJECT%\Stage91ValidationBundle.zip"
set "BACKUP=%PROJECT%\Checkpoints\Stage9_0_before_Stage9_1"

set "DSP_IDENTITY=NOT_TESTED"
set "GUI81_IDENTITY=NOT_TESTED"
set "BASE90_IDENTITY=NOT_TESTED"
set "FACTORY250_TECHNICAL=NOT_TESTED"
set "AUDIT_EXPORT=NOT_TESTED"
set "RANDOMIZER=NOT_TESTED"
set "STATE_ROUNDTRIP=NOT_TESTED"
set "VST3_BUILD=NOT_TESTED"
set "STANDALONE_BUILD=NOT_TESTED"
set "PRESET_LISTENING=NOT_TESTED"
set "RELEASE_READY=NO"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"

echo INDUSTRY KICK - STAGE 9.1
echo 250 PRESET DIVERSITY REVISION
echo ROUND + PUNCH STAGE 9.0 PRESERVED
echo HARD / INDUSTRIAL / RAVE REVISED
echo FAUST DSP + MASTER FROZEN
echo.

if exist "%VALID%" rmdir /s /q "%VALID%"
mkdir "%VALID%" >nul 2>&1
if errorlevel 1 exit /b 2
call :WriteStatus

echo [1/7] VERIFY FROZEN ENGINE
call :VerifyFrozenEngine
if errorlevel 1 (
  set "DSP_IDENTITY=FAIL"
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Frozen Stage 7.1 engine differs from approved checkpoint"
  goto :FAIL
)
set "DSP_IDENTITY=PASS"
call :WriteStatus
echo DSP_IDENTITY=PASS

echo.
echo [2/7] VERIFY GUI 8.1 + STAGE 9.0 BASE
fc /b "%PROJECT%\Source\PluginEditor.cpp" "%PACKAGE%\Reference\PluginEditor_STAGE81.cpp" >nul
if errorlevel 1 (
  set "GUI81_IDENTITY=FAIL"
  set "FAILURE_CLASS=GUI"
  set "FAILED_STEP=Current GUI is not validated Stage 8.1 source"
  goto :FAIL
)
set "GUI81_IDENTITY=PASS"

fc /b "%PROJECT%\Source\FactoryPresets.h" "%PACKAGE%\Reference\FactoryPresets_STAGE90.h" >nul
if errorlevel 1 (
  set "BASE90_IDENTITY=FAIL"
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Current factory bank is not Stage 9.0 validated bank"
  goto :FAIL
)

fc /b "%PROJECT%\Tests\DspSmoke.cpp" "%PACKAGE%\Reference\DspSmoke_STAGE90.cpp" >nul
if errorlevel 1 (
  set "BASE90_IDENTITY=FAIL"
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Current DspSmoke is not Stage 9.0 validated source"
  goto :FAIL
)

set "BASE90_IDENTITY=PASS"
call :WriteStatus
echo GUI81_IDENTITY=PASS
echo BASE90_IDENTITY=PASS

echo.
echo [3/7] CHECKPOINT STAGE 9.0 BANK + TEST
if not exist "%BACKUP%" mkdir "%BACKUP%" >nul 2>&1
copy /Y "%PROJECT%\Source\FactoryPresets.h" "%BACKUP%\FactoryPresets.h" >nul
if errorlevel 1 goto :FILE_FAIL
copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\DspSmoke.cpp" >nul
if errorlevel 1 goto :FILE_FAIL

echo.
echo [4/7] APPLY STAGE 9.1 BANK + AUDIT SOURCE
copy /Y "%PACKAGE%\Payload\Source\FactoryPresets.h" "%PROJECT%\Source\FactoryPresets.h" >nul
if errorlevel 1 goto :APPLY_FAIL
copy /Y "%PACKAGE%\Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL

findstr /C:"array<FactoryPreset,250>" "%PROJECT%\Source\FactoryPresets.h" >nul
if errorlevel 1 goto :APPLY_FAIL
findstr /C:"presetAuditStage=9.1" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL
findstr /C:"Stage91PresetAudit" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL
findstr /C:"anchorIndices { 0, 50, 100, 150, 200 }" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL
findstr /C:"maxSafetyClampEngagementPercent = 0.10" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL
findstr /C:"numericalSilenceRms = 1.0e-12" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL

call :VerifyFrozenEngine
if errorlevel 1 (
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Frozen engine changed during Stage 9.1 apply"
  goto :ROLLBACK_FAIL
)

echo APPLY_STAGE91=PASS

echo.
echo [5/7] CLEAN BUILD + ALL 250 COMPILED AUDIT
cmake -S "%PROJECT%" -B "%PROJECT%\build" -G "Visual Studio 17 2022" -A x64 > "%VALID%\CMakeConfigure.log" 2>&1
if errorlevel 1 (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=CMake configure"
  goto :ROLLBACK_FAIL
)

cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_DspSmoke --clean-first > "%VALID%\DspSmokeBuild.log" 2>&1
if errorlevel 1 (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=DspSmoke Stage 9.1 build"
  goto :ROLLBACK_FAIL
)

set "SMOKEEXE=%PROJECT%\build\KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
if not exist "%SMOKEEXE%" (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=DspSmoke executable missing"
  goto :ROLLBACK_FAIL
)

if exist "%PROJECT%\Stage91PresetAudit" rmdir /s /q "%PROJECT%\Stage91PresetAudit"

pushd "%PROJECT%"
"%SMOKEEXE%" > "%VALID%\DspSmoke.log" 2>&1
set "SMOKERC=%ERRORLEVEL%"
popd

if exist "%PROJECT%\Stage91PresetAudit" (
  robocopy "%PROJECT%\Stage91PresetAudit" "%VALID%\Stage91PresetAudit" /E /NFL /NDL /NJH /NJS /NP >nul
)

findstr /C:"presetAuditStage=9.1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 goto :GATE_FAIL

findstr /C:"factoryBank=1 count=250" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 goto :GATE_FAIL

findstr /C:"allFactoryPresetsTechnical=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "FACTORY250_TECHNICAL=FAIL") else (set "FACTORY250_TECHNICAL=PASS")

findstr /C:"factoryPresetAuditExport=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "AUDIT_EXPORT=FAIL") else (set "AUDIT_EXPORT=PASS")

findstr /C:"randomizerTechnical=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "RANDOMIZER=FAIL") else (set "RANDOMIZER=PASS")

findstr /C:"stateRoundTrip=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "STATE_ROUNDTRIP=FAIL") else (set "STATE_ROUNDTRIP=PASS")

findstr /C:"result=PASS" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 goto :GATE_FAIL

if not "%SMOKERC%"=="0" goto :GATE_FAIL
if not "%FACTORY250_TECHNICAL%"=="PASS" goto :GATE_FAIL
if not "%AUDIT_EXPORT%"=="PASS" goto :GATE_FAIL
if not "%RANDOMIZER%"=="PASS" goto :GATE_FAIL
if not "%STATE_ROUNDTRIP%"=="PASS" goto :GATE_FAIL

call :WriteStatus
echo FACTORY250_TECHNICAL=PASS
echo AUDIT_EXPORT=PASS
echo RANDOMIZER=PASS
echo STATE_ROUNDTRIP=PASS

echo.
echo [6/7] VST3 + STANDALONE RELEASE
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_VST3 > "%VALID%\VST3Build.log" 2>&1
if errorlevel 1 (
  set "VST3_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 Stage 9.1 build"
  goto :FAIL
)

set "VST3BIN=%PROJECT%\build\KICKCRAFTER_artefacts\Release\VST3\INDUSTRY KICK.vst3\Contents\x86_64-win\INDUSTRY KICK.vst3"
if not exist "%VST3BIN%" (
  set "VST3_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 Stage 9.1 binary missing"
  goto :FAIL
)
certutil -hashfile "%VST3BIN%" SHA256 > "%VALID%\VST3_SHA256.txt" 2>&1
set "VST3_BUILD=PASS"

cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_Standalone > "%VALID%\StandaloneBuild.log" 2>&1
if errorlevel 1 (
  set "STANDALONE_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Standalone Stage 9.1 build"
  goto :FAIL
)
set "STANDALONE_BUILD=PASS"
call :WriteStatus
echo VST3_BUILD=PASS
echo STANDALONE_BUILD=PASS

echo.
echo [7/7] HASH + BUNDLE
certutil -hashfile "%PROJECT%\Source\FactoryPresets.h" SHA256 > "%VALID%\FACTORY91_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\Tests\DspSmoke.cpp" SHA256 > "%VALID%\DSPSMOKE91_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\Source\PluginEditor.cpp" SHA256 > "%VALID%\GUI81_SHA256.txt" 2>&1
robocopy "%PACKAGE%\Analysis" "%VALID%\PackageAnalysis" /E /NFL /NDL /NJH /NJS /NP >nul

set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"
call :WriteStatus
call :Bundle

echo.
echo ================================================================
echo STAGE91_TECHNICAL=PASS
echo PRESET_LISTENING=NOT_TESTED
echo RELEASE_READY=NO
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 0

:GATE_FAIL
set "FAILURE_CLASS=DSP_OR_PRESET_VALIDATION"
set "FAILED_STEP=Stage 9.1 compiled 250-preset audit"
goto :ROLLBACK_FAIL

:APPLY_FAIL
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Apply Stage 9.1 bank/test"
goto :ROLLBACK_FAIL

:ROLLBACK_FAIL
echo.
echo Stage 9.1 candidate failed. Restoring Stage 9.0 bank and test source.
copy /Y "%BACKUP%\FactoryPresets.h" "%PROJECT%\Source\FactoryPresets.h" >nul
copy /Y "%BACKUP%\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
call :WriteStatus
goto :FAIL

:FILE_FAIL
set "FAILURE_CLASS=FILE_IO"
set "FAILED_STEP=Checkpoint Stage 9.0 bank/test"
goto :FAIL

:FAIL
call :WriteStatus
call :Bundle
echo.
echo ================================================================
echo STAGE91_TECHNICAL=FAIL
echo FAILURE_CLASS=%FAILURE_CLASS%
echo FAILED_STEP=%FAILED_STEP%
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 1

:VerifyFrozenEngine
fc /b "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%APPROVED%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 exit /b 1
fc /b "%PROJECT%\Source\PluginProcessor.cpp" "%APPROVED%\Source\PluginProcessor.cpp" >nul
if errorlevel 1 exit /b 1
fc /b "%PROJECT%\Source\PluginProcessor.h" "%APPROVED%\Source\PluginProcessor.h" >nul
if errorlevel 1 exit /b 1
fc /b "%PROJECT%\Source\FaustKickEngine.cpp" "%APPROVED%\Source\FaustKickEngine.cpp" >nul
if errorlevel 1 exit /b 1
fc /b "%PROJECT%\Source\FaustKickEngine.h" "%APPROVED%\Source\FaustKickEngine.h" >nul
if errorlevel 1 exit /b 1
fc /b "%PROJECT%\CMakeLists.txt" "%APPROVED%\CMakeLists.txt" >nul
if errorlevel 1 exit /b 1
exit /b 0

:WriteStatus
> "%VALID%\STATUS.txt" echo DSP_IDENTITY=%DSP_IDENTITY%
>>"%VALID%\STATUS.txt" echo GUI81_IDENTITY=%GUI81_IDENTITY%
>>"%VALID%\STATUS.txt" echo BASE90_IDENTITY=%BASE90_IDENTITY%
>>"%VALID%\STATUS.txt" echo FACTORY250_TECHNICAL=%FACTORY250_TECHNICAL%
>>"%VALID%\STATUS.txt" echo AUDIT_EXPORT=%AUDIT_EXPORT%
>>"%VALID%\STATUS.txt" echo RANDOMIZER=%RANDOMIZER%
>>"%VALID%\STATUS.txt" echo STATE_ROUNDTRIP=%STATE_ROUNDTRIP%
>>"%VALID%\STATUS.txt" echo VST3_BUILD=%VST3_BUILD%
>>"%VALID%\STATUS.txt" echo STANDALONE_BUILD=%STANDALONE_BUILD%
>>"%VALID%\STATUS.txt" echo PRESET_LISTENING=%PRESET_LISTENING%
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
