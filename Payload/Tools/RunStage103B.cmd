@echo off
setlocal EnableExtensions

set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "PACKAGE=%~dp0..\.."
set "VALID=%PROJECT%\Stage103BHeavyValidation"
set "BUNDLE=%PROJECT%\Stage103BHeavyValidationBundle.zip"
set "BACKUP=%PROJECT%\Checkpoints\Stage9_1_before_Stage10_3B"

set "SOURCE_IDENTITY=NOT_TESTED"
set "TARGET_BUILD=NOT_TESTED"
set "HEAVY_50=NOT_TESTED"
set "PREVIOUS_7=NOT_TESTED"
set "FULL_250=DEFERRED_TO_FINAL_MILESTONE"
set "VST3_BUILD=DEFERRED_TO_FINAL_MILESTONE"
set "STANDALONE_BUILD=DEFERRED_TO_FINAL_MILESTONE"
set "LISTENING=NOT_REQUESTED"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"

echo INDUSTRY KICK - STAGE 10.3B
echo TARGETED HEAVY SAFETY GATE ONLY
echo 50 HEAVY PRESETS - NO FULL 250 RUN - NO VST3 - NO STANDALONE
echo.

if exist "%VALID%" rmdir /s /q "%VALID%"
mkdir "%VALID%" >nul 2>&1
if errorlevel 1 exit /b 2
call :WriteStatus

echo [1/6] VERIFY CURRENT STAGE 9.1 BASE
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
fc /b "%PROJECT%\Tests\SafetyProbe.cpp" "%PACKAGE%\Reference\SafetyProbe_ORIGINAL.cpp" >nul
if errorlevel 1 goto :SOURCE_FAIL
fc /b "%PROJECT%\CMakeLists.txt" "%PACKAGE%\Reference\CMakeLists_STAGE71.txt" >nul
if errorlevel 1 goto :SOURCE_FAIL

set "SOURCE_IDENTITY=PASS"
call :WriteStatus
echo SOURCE_IDENTITY=PASS

echo.
echo [2/6] CHECKPOINT ONLY FILES THAT WILL CHANGE
if not exist "%BACKUP%" mkdir "%BACKUP%" >nul 2>&1
copy /Y "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" "%BACKUP%\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :FILE_FAIL
copy /Y "%PROJECT%\Source\FaustKickEngine.h" "%BACKUP%\FaustKickEngine.h" >nul
copy /Y "%PROJECT%\Source\FaustKickEngine.cpp" "%BACKUP%\FaustKickEngine.cpp" >nul
copy /Y "%PROJECT%\Source\PluginProcessor.h" "%BACKUP%\PluginProcessor.h" >nul
copy /Y "%PROJECT%\Source\PluginProcessor.cpp" "%BACKUP%\PluginProcessor.cpp" >nul
copy /Y "%PROJECT%\Tests\SafetyProbe.cpp" "%BACKUP%\SafetyProbe.cpp" >nul

echo.
echo [3/6] APPLY STAGE 10.3 PRODUCTION SOURCE + TEMPORARY TARGETED PROBE
copy /Y "%PACKAGE%\Payload\Faust\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :APPLY_FAIL
copy /Y "%PACKAGE%\Payload\Source\FaustKickEngine.h" "%PROJECT%\Source\FaustKickEngine.h" >nul
copy /Y "%PACKAGE%\Payload\Source\FaustKickEngine.cpp" "%PROJECT%\Source\FaustKickEngine.cpp" >nul
copy /Y "%PACKAGE%\Payload\Source\PluginProcessor.h" "%PROJECT%\Source\PluginProcessor.h" >nul
copy /Y "%PACKAGE%\Payload\Source\PluginProcessor.cpp" "%PROJECT%\Source\PluginProcessor.cpp" >nul
copy /Y "%PACKAGE%\Payload\Tests\SafetyProbe.cpp" "%PROJECT%\Tests\SafetyProbe.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL

findstr /C:"stage10FamPick(0.70,0.30,0.85,1.00,0.25)" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if errorlevel 1 goto :APPLY_FAIL
findstr /C:"HEAVY_SAFETY_GATE=" "%PROJECT%\Tests\SafetyProbe.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL

rem These must remain untouched.
fc /b "%PROJECT%\Source\FactoryPresets.h" "%PACKAGE%\Reference\FactoryPresets_STAGE91.h" >nul
if errorlevel 1 goto :APPLY_FAIL
fc /b "%PROJECT%\Tests\DspSmoke.cpp" "%PACKAGE%\Reference\DspSmoke_STAGE91.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL
fc /b "%PROJECT%\Source\PluginEditor.cpp" "%PACKAGE%\Reference\PluginEditor_STAGE81.cpp" >nul
if errorlevel 1 goto :APPLY_FAIL
fc /b "%PROJECT%\CMakeLists.txt" "%PACKAGE%\Reference\CMakeLists_STAGE71.txt" >nul
if errorlevel 1 goto :APPLY_FAIL

echo.
echo [4/6] CONFIGURE ONLY IF BUILD CACHE IS MISSING
if not exist "%PROJECT%\build\CMakeCache.txt" (
  cmake -S "%PROJECT%" -B "%PROJECT%\build" -G "Visual Studio 17 2022" -A x64 > "%VALID%\CMakeConfigure.log" 2>&1
  if errorlevel 1 (
    set "FAILURE_CLASS=BUILD"
    set "FAILED_STEP=CMake configure"
    goto :ROLLBACK_FAIL
  )
) else (
  > "%VALID%\CMakeConfigure.log" echo Existing CMake cache reused.
)

rem Force only the Faust generated header to refresh; do NOT clean the full build.
if exist "%PROJECT%\build\generated\IndustryKickFaustDSP.h" del /q "%PROJECT%\build\generated\IndustryKickFaustDSP.h"

echo.
echo [5/6] BUILD + RUN ONLY THE EXISTING SAFETY PROBE TARGET
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_SafetyProbe > "%VALID%\HeavySafetyBuild.log" 2>&1
if errorlevel 1 (
  set "TARGET_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Targeted SafetyProbe build"
  goto :ROLLBACK_FAIL
)
set "TARGET_BUILD=PASS"

set "PROBE=%PROJECT%\build\KICKCRAFTER_SafetyProbe_artefacts\Release\KICKCRAFTER_SafetyProbe.exe"
if not exist "%PROBE%" (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Targeted SafetyProbe executable missing"
  goto :ROLLBACK_FAIL
)

pushd "%PROJECT%"
"%PROBE%" > "%VALID%\HeavySafety.log" 2>&1
set "PROBERC=%ERRORLEVEL%"
popd

if exist "%PROJECT%\Stage103HeavySafety.csv" copy /Y "%PROJECT%\Stage103HeavySafety.csv" "%VALID%\Stage103HeavySafety.csv" >nul

findstr /C:"heavyTested=50" "%VALID%\HeavySafety.log" >nul
if errorlevel 1 goto :GATE_FAIL
findstr /C:"HEAVY_SAFETY_GATE=PASS" "%VALID%\HeavySafety.log" >nul
if errorlevel 1 goto :GATE_FAIL
findstr /C:"result=PASS" "%VALID%\HeavySafety.log" >nul
if errorlevel 1 goto :GATE_FAIL
if not "%PROBERC%"=="0" goto :GATE_FAIL

set "HEAVY_50=PASS"

rem The seven prior failure indices must now each report technical=1.
for %%I in (26 27 70 79 226 227 229) do (
  findstr /R /C:"heavy index=%%I .*technical=1" "%VALID%\HeavySafety.log" >nul
  if errorlevel 1 goto :PREVIOUS_FAIL
)
set "PREVIOUS_7=PASS"

echo.
echo [6/6] RESTORE TEMPORARY TEST SOURCE, KEEP STAGE 10.3 PRODUCTION SOURCE
copy /Y "%BACKUP%\SafetyProbe.cpp" "%PROJECT%\Tests\SafetyProbe.cpp" >nul
if errorlevel 1 (
  set "FAILURE_CLASS=FILE_IO"
  set "FAILED_STEP=Restore original SafetyProbe"
  goto :FAIL
)

fc /b "%PROJECT%\Tests\SafetyProbe.cpp" "%PACKAGE%\Reference\SafetyProbe_ORIGINAL.cpp" >nul
if errorlevel 1 (
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=SafetyProbe restore identity"
  goto :FAIL
)

rem Immutable source still untouched.
fc /b "%PROJECT%\Source\FactoryPresets.h" "%PACKAGE%\Reference\FactoryPresets_STAGE91.h" >nul
if errorlevel 1 goto :FAIL
fc /b "%PROJECT%\Tests\DspSmoke.cpp" "%PACKAGE%\Reference\DspSmoke_STAGE91.cpp" >nul
if errorlevel 1 goto :FAIL
fc /b "%PROJECT%\Source\PluginEditor.cpp" "%PACKAGE%\Reference\PluginEditor_STAGE81.cpp" >nul
if errorlevel 1 goto :FAIL

certutil -hashfile "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" SHA256 > "%VALID%\FAUST_STAGE103_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\Source\PluginProcessor.cpp" SHA256 > "%VALID%\PROCESSOR_STAGE103_SHA256.txt" 2>&1

set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"
call :WriteStatus
call :Bundle

echo.
echo ================================================================
echo STAGE103B_TARGETED_GATE=PASS
echo HEAVY_50=PASS
echo PREVIOUS_7=PASS
echo FULL_250=DEFERRED_TO_FINAL_MILESTONE
echo VST3_BUILD=DEFERRED_TO_FINAL_MILESTONE
echo STANDALONE_BUILD=DEFERRED_TO_FINAL_MILESTONE
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 0

:PREVIOUS_FAIL
set "PREVIOUS_7=FAIL"
set "FAILURE_CLASS=DSP_OR_PRESET_VALIDATION"
set "FAILED_STEP=One of the seven prior HEAVY failures still fails"
goto :ROLLBACK_FAIL

:GATE_FAIL
set "HEAVY_50=FAIL"
set "FAILURE_CLASS=DSP_OR_PRESET_VALIDATION"
set "FAILED_STEP=Targeted 50-HEAVY safety gate"
goto :ROLLBACK_FAIL

:SOURCE_FAIL
set "SOURCE_IDENTITY=FAIL"
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Current project is not expected Stage 9.1 rolled-back base"
goto :FAIL

:FILE_FAIL
set "FAILURE_CLASS=FILE_IO"
set "FAILED_STEP=Checkpoint"
goto :FAIL

:APPLY_FAIL
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Apply Stage 10.3B"
goto :ROLLBACK_FAIL

:ROLLBACK_FAIL
echo.
echo Targeted gate failed. Restoring Stage 9.1 production source and original SafetyProbe.
if exist "%BACKUP%\IndustryKickV2_R4_Freeze.dsp" copy /Y "%BACKUP%\IndustryKickV2_R4_Freeze.dsp" "%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp" >nul
if exist "%BACKUP%\FaustKickEngine.h" copy /Y "%BACKUP%\FaustKickEngine.h" "%PROJECT%\Source\FaustKickEngine.h" >nul
if exist "%BACKUP%\FaustKickEngine.cpp" copy /Y "%BACKUP%\FaustKickEngine.cpp" "%PROJECT%\Source\FaustKickEngine.cpp" >nul
if exist "%BACKUP%\PluginProcessor.h" copy /Y "%BACKUP%\PluginProcessor.h" "%PROJECT%\Source\PluginProcessor.h" >nul
if exist "%BACKUP%\PluginProcessor.cpp" copy /Y "%BACKUP%\PluginProcessor.cpp" "%PROJECT%\Source\PluginProcessor.cpp" >nul
if exist "%BACKUP%\SafetyProbe.cpp" copy /Y "%BACKUP%\SafetyProbe.cpp" "%PROJECT%\Tests\SafetyProbe.cpp" >nul
goto :FAIL

:FAIL
call :WriteStatus
call :Bundle
echo.
echo ================================================================
echo STAGE103B_TARGETED_GATE=FAIL
echo FAILURE_CLASS=%FAILURE_CLASS%
echo FAILED_STEP=%FAILED_STEP%
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 1

:WriteStatus
> "%VALID%\STATUS.txt" echo SOURCE_IDENTITY=%SOURCE_IDENTITY%
>>"%VALID%\STATUS.txt" echo TARGET_BUILD=%TARGET_BUILD%
>>"%VALID%\STATUS.txt" echo HEAVY_50=%HEAVY_50%
>>"%VALID%\STATUS.txt" echo PREVIOUS_7=%PREVIOUS_7%
>>"%VALID%\STATUS.txt" echo FULL_250=%FULL_250%
>>"%VALID%\STATUS.txt" echo VST3_BUILD=%VST3_BUILD%
>>"%VALID%\STATUS.txt" echo STANDALONE_BUILD=%STANDALONE_BUILD%
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
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
