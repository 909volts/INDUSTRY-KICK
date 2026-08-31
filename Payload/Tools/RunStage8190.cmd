@echo off
setlocal EnableExtensions

set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "APPROVED=%PROJECT%\Checkpoints\Stage7_1_DSP_APPROVED_FINAL_72E"
set "PACKAGE=%~dp0..\.."
set "VALID=%PROJECT%\Stage8190Validation"
set "BUNDLE=%PROJECT%\Stage8190ValidationBundle.zip"
set "BACKUP=%PROJECT%\Checkpoints\Stage8_0_before_8_1_Stage9_0"

set "DSP_IDENTITY=NOT_TESTED"
set "GUI81_APPLIED=NOT_TESTED"
set "GUI81_BUILD=NOT_TESTED"
set "FACTORY250_APPLIED=NOT_TESTED"
set "FACTORY250_TECHNICAL=NOT_TESTED"
set "PRESET_AUDIT_EXPORT=NOT_TESTED"
set "RANDOMIZER=NOT_TESTED"
set "STATE_ROUNDTRIP=NOT_TESTED"
set "VST3_BUILD=NOT_TESTED"
set "STANDALONE_BUILD=NOT_TESTED"
set "PRESET_LISTENING=NOT_TESTED"
set "RELEASE_READY=NO"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"

echo INDUSTRY KICK - STAGE 8.1 + 9.0
echo INDUSTRIAL GUI REDESIGN + 250 PRESET COMPILED AUDIT
echo DSP TOPOLOGY / MASTER CHAIN FROZEN
echo.

if exist "%VALID%" rmdir /s /q "%VALID%"
mkdir "%VALID%" >nul 2>&1
if errorlevel 1 exit /b 2
call :WriteStatus

if not exist "%APPROVED%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :BASE_FAIL
if not exist "%PROJECT%\Source\PluginEditor.cpp" goto :BASE_FAIL
if not exist "%PROJECT%\Source\FactoryPresets.h" goto :BASE_FAIL
if not exist "%PROJECT%\Tests\DspSmoke.cpp" goto :BASE_FAIL

echo [1/9] VERIFY FROZEN ENGINE + STAGE 8 BASE
call :VerifyFrozenEngine
if errorlevel 1 (
  set "DSP_IDENTITY=FAIL"
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Frozen Stage 7.1 engine differs from approved checkpoint"
  goto :FAIL
)

fc /b "%PROJECT%\Source\FactoryPresets.h" "%APPROVED%\Source\FactoryPresets.h" >nul
if errorlevel 1 (
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Expected approved 50-preset bank not found"
  goto :FAIL
)

fc /b "%PROJECT%\Tests\DspSmoke.cpp" "%APPROVED%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 (
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Expected approved Stage 7.1 DspSmoke not found"
  goto :FAIL
)

fc /b "%PROJECT%\Source\PluginEditor.cpp" "%PACKAGE%\Reference\PluginEditor_STAGE8.cpp" >nul
if errorlevel 1 (
  set "FAILURE_CLASS=GUI"
  set "FAILED_STEP=Current PluginEditor is not validated Stage 8.0 source"
  goto :FAIL
)

set "DSP_IDENTITY=PASS"
call :WriteStatus
echo DSP_IDENTITY=PASS

echo.
echo [2/9] CHECKPOINT CURRENT STAGE 8 + PRESET TEST SOURCES
if not exist "%BACKUP%" mkdir "%BACKUP%" >nul 2>&1
copy /Y "%PROJECT%\Source\PluginEditor.cpp" "%BACKUP%\PluginEditor.cpp" >nul
if errorlevel 1 goto :FILE_FAIL
copy /Y "%PROJECT%\Source\FactoryPresets.h" "%BACKUP%\FactoryPresets.h" >nul
if errorlevel 1 goto :FILE_FAIL
copy /Y "%PROJECT%\Tests\DspSmoke.cpp" "%BACKUP%\DspSmoke.cpp" >nul
if errorlevel 1 goto :FILE_FAIL

echo.
echo [3/9] APPLY GUI 8.1 INDUSTRIAL REDESIGN
copy /Y "%PACKAGE%\Payload\Source\PluginEditor.cpp" "%PROJECT%\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL
fc /b "%PROJECT%\Source\PluginEditor.cpp" "%PACKAGE%\Payload\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL

findstr /C:"PRESS / MUTANT KICK ENGINE" "%PROJECT%\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL
findstr /C:"MUTANT PRESS" "%PROJECT%\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL
findstr /C:"factory.size() == 250" "%PROJECT%\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL

set "GUI81_APPLIED=PASS"
call :WriteStatus
echo GUI81_APPLIED=PASS

echo.
echo [4/9] COMPILE GUI 8.1 AGAINST APPROVED 50-PRESET BANK
cmake -S "%PROJECT%" -B "%PROJECT%\build" -G "Visual Studio 17 2022" -A x64 > "%VALID%\CMakeConfigure_GUI81.log" 2>&1
if errorlevel 1 goto :GUI_BUILD_FAIL

cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_Standalone > "%VALID%\GUI81_StandaloneBuild.log" 2>&1
if errorlevel 1 goto :GUI_BUILD_FAIL

set "GUI81_BUILD=PASS"
call :WriteStatus
echo GUI81_BUILD=PASS

echo.
echo [5/9] APPLY 250-PRESET CANDIDATE BANK + AUDIT-ONLY DSPSMOKE EXTENSION
copy /Y "%PACKAGE%\Payload\Source\FactoryPresets.h" "%PROJECT%\Source\FactoryPresets.h" >nul
if errorlevel 1 goto :PRESET_APPLY_FAIL
copy /Y "%PACKAGE%\Payload\Tests\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :PRESET_APPLY_FAIL

findstr /C:"array<FactoryPreset,250>" "%PROJECT%\Source\FactoryPresets.h" >nul
if errorlevel 1 goto :PRESET_APPLY_FAIL
findstr /C:"names.size() == 250" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :PRESET_APPLY_FAIL
findstr /C:"anchorIndices { 0, 50, 100, 150, 200 }" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :PRESET_APPLY_FAIL
findstr /C:"factoryPresetAuditExport" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :PRESET_APPLY_FAIL

rem The fixed technical thresholds must still be present.
findstr /C:"maxSafetyClampEngagementPercent = 0.10" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :PRESET_APPLY_FAIL
findstr /C:"numericalSilenceRms = 1.0e-12" "%PROJECT%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 goto :PRESET_APPLY_FAIL

call :VerifyFrozenEngine
if errorlevel 1 (
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Frozen engine changed while applying preset/test patch"
  goto :PRESET_ROLLBACK_FAIL
)

set "FACTORY250_APPLIED=PASS"
call :WriteStatus
echo FACTORY250_APPLIED=PASS

echo.
echo [6/9] CLEAN BUILD + FULL 250-PRESET COMPILED AUDIO AUDIT
echo This stage renders all 250 presets through the real compiled processor.
echo It may take several minutes. Do not close this window.
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_DspSmoke --clean-first > "%VALID%\DspSmoke250Build.log" 2>&1
if errorlevel 1 (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=DspSmoke 250 build"
  goto :PRESET_ROLLBACK_FAIL
)

set "SMOKEEXE=%PROJECT%\build\KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
if not exist "%SMOKEEXE%" (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=DspSmoke executable missing"
  goto :PRESET_ROLLBACK_FAIL
)

if exist "%PROJECT%\Stage90PresetAudit" rmdir /s /q "%PROJECT%\Stage90PresetAudit"
pushd "%PROJECT%"
"%SMOKEEXE%" > "%VALID%\DspSmoke250.log" 2>&1
set "SMOKERC=%ERRORLEVEL%"
popd

if exist "%PROJECT%\Stage90PresetAudit" (
  robocopy "%PROJECT%\Stage90PresetAudit" "%VALID%\Stage90PresetAudit" /E /NFL /NDL /NJH /NJS /NP >nul
)

findstr /C:"factoryBank=1 count=250" "%VALID%\DspSmoke250.log" >nul
if errorlevel 1 set "FACTORY250_TECHNICAL=FAIL"

findstr /C:"allFactoryPresetsTechnical=1" "%VALID%\DspSmoke250.log" >nul
if errorlevel 1 (set "FACTORY250_TECHNICAL=FAIL") else (set "FACTORY250_TECHNICAL=PASS")

findstr /C:"factoryPresetAuditExport=1" "%VALID%\DspSmoke250.log" >nul
if errorlevel 1 (set "PRESET_AUDIT_EXPORT=FAIL") else (set "PRESET_AUDIT_EXPORT=PASS")

findstr /C:"randomizerTechnical=1" "%VALID%\DspSmoke250.log" >nul
if errorlevel 1 (set "RANDOMIZER=FAIL") else (set "RANDOMIZER=PASS")

findstr /C:"stateRoundTrip=1" "%VALID%\DspSmoke250.log" >nul
if errorlevel 1 (set "STATE_ROUNDTRIP=FAIL") else (set "STATE_ROUNDTRIP=PASS")

findstr /C:"result=PASS" "%VALID%\DspSmoke250.log" >nul
if errorlevel 1 goto :PRESET_GATE_FAIL
if not "%SMOKERC%"=="0" goto :PRESET_GATE_FAIL
if not "%FACTORY250_TECHNICAL%"=="PASS" goto :PRESET_GATE_FAIL
if not "%PRESET_AUDIT_EXPORT%"=="PASS" goto :PRESET_GATE_FAIL
if not "%RANDOMIZER%"=="PASS" goto :PRESET_GATE_FAIL
if not "%STATE_ROUNDTRIP%"=="PASS" goto :PRESET_GATE_FAIL

call :WriteStatus
echo FACTORY250_TECHNICAL=PASS
echo PRESET_AUDIT_EXPORT=PASS
echo RANDOMIZER=PASS
echo STATE_ROUNDTRIP=PASS

echo.
echo [7/9] VST3 RELEASE BUILD WITH 250-PRESET BANK
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_VST3 > "%VALID%\VST3Build.log" 2>&1
if errorlevel 1 (
  set "VST3_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 Release build"
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
call :WriteStatus
echo VST3_BUILD=PASS

echo.
echo [8/9] STANDALONE RELEASE BUILD WITH 250-PRESET BANK
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_Standalone > "%VALID%\Standalone250Build.log" 2>&1
if errorlevel 1 (
  set "STANDALONE_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Standalone 250 build"
  goto :FAIL
)
set "STANDALONE_BUILD=PASS"
call :WriteStatus
echo STANDALONE_BUILD=PASS

echo.
echo [9/9] FREEZE EVIDENCE + BUNDLE
certutil -hashfile "%PROJECT%\Source\PluginEditor.cpp" SHA256 > "%VALID%\GUI81_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\Source\FactoryPresets.h" SHA256 > "%VALID%\FACTORY250_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\Tests\DspSmoke.cpp" SHA256 > "%VALID%\DSPSMOKE90_SHA256.txt" 2>&1
robocopy "%PACKAGE%\Analysis" "%VALID%\StaticAnalysis" /E /NFL /NDL /NJH /NJS /NP >nul

set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"
call :WriteStatus
call :Bundle

echo.
echo ================================================================
echo STAGE_8_1_GUI_BUILD=PASS
echo FACTORY250_TECHNICAL=PASS
echo AUDIO_AUDIT_READY=PASS
echo PRESET_LISTENING=NOT_TESTED
echo RELEASE_READY=NO
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 0

:PRESET_GATE_FAIL
set "FAILURE_CLASS=DSP_OR_PRESET_VALIDATION"
set "FAILED_STEP=250-preset compiled audit"
goto :PRESET_ROLLBACK_FAIL

:PRESET_APPLY_FAIL
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Apply 250-preset candidate/test patch"
goto :PRESET_ROLLBACK_FAIL

:PRESET_ROLLBACK_FAIL
echo.
echo Candidate bank/test failed. Restoring approved 50-preset bank and Stage 7.1 DspSmoke.
copy /Y "%BACKUP%\FactoryPresets.h" "%PROJECT%\Source\FactoryPresets.h" >nul
copy /Y "%BACKUP%\DspSmoke.cpp" "%PROJECT%\Tests\DspSmoke.cpp" >nul
set "FACTORY250_APPLIED=ROLLED_BACK"
call :WriteStatus
robocopy "%PACKAGE%\Analysis" "%VALID%\StaticAnalysis" /E /NFL /NDL /NJH /NJS /NP >nul
goto :FAIL

:GUI_FAIL
set "GUI81_APPLIED=FAIL"
set "FAILURE_CLASS=GUI"
set "FAILED_STEP=Apply GUI 8.1"
if exist "%BACKUP%\PluginEditor.cpp" copy /Y "%BACKUP%\PluginEditor.cpp" "%PROJECT%\Source\PluginEditor.cpp" >nul
goto :FAIL

:GUI_BUILD_FAIL
set "GUI81_BUILD=FAIL"
set "FAILURE_CLASS=BUILD"
set "FAILED_STEP=GUI 8.1 Standalone compile"
if exist "%BACKUP%\PluginEditor.cpp" copy /Y "%BACKUP%\PluginEditor.cpp" "%PROJECT%\Source\PluginEditor.cpp" >nul
goto :FAIL

:FILE_FAIL
set "FAILURE_CLASS=FILE_IO"
set "FAILED_STEP=Checkpoint current GUI/preset/test"
goto :FAIL

:BASE_FAIL
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Required project/checkpoint source missing"
goto :FAIL

:FAIL
call :WriteStatus
call :Bundle
echo.
echo ================================================================
echo STAGE_8_1_9_0=FAIL
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
>>"%VALID%\STATUS.txt" echo GUI81_APPLIED=%GUI81_APPLIED%
>>"%VALID%\STATUS.txt" echo GUI81_BUILD=%GUI81_BUILD%
>>"%VALID%\STATUS.txt" echo FACTORY250_APPLIED=%FACTORY250_APPLIED%
>>"%VALID%\STATUS.txt" echo FACTORY250_TECHNICAL=%FACTORY250_TECHNICAL%
>>"%VALID%\STATUS.txt" echo PRESET_AUDIT_EXPORT=%PRESET_AUDIT_EXPORT%
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
if errorlevel 1 (
  echo tar.exe not found. Validation folder remains at:
  echo "%VALID%"
  exit /b 0
)
pushd "%VALID%"
tar.exe -a -c -f "%BUNDLE%" *
set "TARRC=%ERRORLEVEL%"
popd
exit /b %TARRC%
