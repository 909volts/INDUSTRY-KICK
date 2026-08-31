@echo off
setlocal EnableExtensions

rem ================================================================
rem INDUSTRY KICK - STAGE 7.2E
rem CMD-ONLY DSP FREEZE / PRE-GUI GATE
rem No PowerShell script. No DSP source changes.
rem ================================================================

set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "BUILD=%PROJECT%\build"
set "VALID=%PROJECT%\Stage72EValidation"
set "BUNDLE=%PROJECT%\Stage72EValidationBundle.zip"
set "CHECKPOINT=%PROJECT%\Checkpoints\Stage7_1_DSP_APPROVED_FINAL_72E"

set "FAUST=%PROJECT%\Faust\IndustryKickV2_R4_Freeze.dsp"
set "SMOKESRC=%PROJECT%\Tests\DspSmoke.cpp"
set "SMOKEEXE=%BUILD%\KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
set "VST3BUNDLE=%BUILD%\KICKCRAFTER_artefacts\Release\VST3\INDUSTRY KICK.vst3"
set "VST3BIN=%VST3BUNDLE%\Contents\x86_64-win\INDUSTRY KICK.vst3"

set "SOURCE_IDENTITY=NOT_TESTED"
set "CHECKPOINT_STATUS=NOT_TESTED"
set "CLEAN_DSP_BUILD=NOT_TESTED"
set "DSP_SMOKE=NOT_TESTED"
set "FACTORY_50=NOT_TESTED"
set "RANDOMIZER=NOT_TESTED"
set "STATE_ROUNDTRIP=NOT_TESTED"
set "VST3_BUILD=NOT_TESTED"
set "STANDALONE_BUILD=NOT_TESTED"
set "PLUGINVAL=NOT_TESTED"
set "STEINBERG_VALIDATOR=NOT_TESTED"
set "DAW_TEST=NOT_TESTED"
set "PRE_GUI_DSP_GATE=NOT_TESTED"
set "RELEASE_READY=NO"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"

echo INDUSTRY KICK - STAGE 7.2E
echo CMD-ONLY DSP FREEZE / PRE-GUI GATE
echo NO POWERSHELL RUNNER
echo NO DSP SOURCE CHANGES
echo.

if exist "%VALID%" rmdir /s /q "%VALID%"
mkdir "%VALID%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: cannot create validation directory.
    exit /b 2
)

call :WriteStatus

rem ----------------------------------------------------------------
rem 1. Source identity
rem ----------------------------------------------------------------
echo [1/8] SOURCE IDENTITY

if not exist "%FAUST%" (
    set "FAILURE_CLASS=SOURCE"
    set "FAILED_STEP=Faust source missing"
    set "SOURCE_IDENTITY=FAIL"
    goto :FAIL
)

if not exist "%SMOKESRC%" (
    set "FAILURE_CLASS=SOURCE"
    set "FAILED_STEP=DspSmoke source missing"
    set "SOURCE_IDENTITY=FAIL"
    goto :FAIL
)

findstr /C:"Stage 7.1B compile fix" "%FAUST%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"stage7Round" "%FAUST%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"stage7Punch" "%FAUST%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"stage7Hard" "%FAUST%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"stage7Industrial" "%FAUST%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"stage7Rave" "%FAUST%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"co.compressor_mono(4,-9.5,0.030,0.030)" "%FAUST%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"stage7MasterHardClip" "%FAUST%" >nul
if errorlevel 1 goto :SOURCE_FAIL

findstr /C:"stageGate=7.1" "%SMOKESRC%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"approvedStage7Reference=30ms_release" "%SMOKESRC%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"lowBandShapeParityPass" "%SMOKESRC%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"crestParityPass" "%SMOKESRC%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"maxSafetyClampEngagementPercent = 0.10" "%SMOKESRC%" >nul
if errorlevel 1 goto :SOURCE_FAIL
findstr /C:"numericalSilenceRms = 1.0e-12" "%SMOKESRC%" >nul
if errorlevel 1 goto :SOURCE_FAIL

set "SOURCE_IDENTITY=PASS"
call :WriteStatus
echo SOURCE_IDENTITY=PASS
goto :SOURCE_DONE

:SOURCE_FAIL
set "SOURCE_IDENTITY=FAIL"
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Stage 7.1 approved source identity"
goto :FAIL

:SOURCE_DONE

rem ----------------------------------------------------------------
rem 2. Freeze checkpoint + hashes
rem ----------------------------------------------------------------
echo.
echo [2/8] CHECKPOINT

if exist "%CHECKPOINT%" rmdir /s /q "%CHECKPOINT%"
mkdir "%CHECKPOINT%" >nul 2>&1
if errorlevel 1 goto :CHECKPOINT_FAIL

robocopy "%PROJECT%\Faust" "%CHECKPOINT%\Faust" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto :CHECKPOINT_FAIL

robocopy "%PROJECT%\Source" "%CHECKPOINT%\Source" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto :CHECKPOINT_FAIL

robocopy "%PROJECT%\Tests" "%CHECKPOINT%\Tests" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto :CHECKPOINT_FAIL

copy /Y "%PROJECT%\CMakeLists.txt" "%CHECKPOINT%\CMakeLists.txt" >nul
if errorlevel 1 goto :CHECKPOINT_FAIL

if exist "%PROJECT%\Assets" robocopy "%PROJECT%\Assets" "%CHECKPOINT%\Assets" /E /NFL /NDL /NJH /NJS /NP >nul
if exist "%PROJECT%\Resources" robocopy "%PROJECT%\Resources" "%CHECKPOINT%\Resources" /E /NFL /NDL /NJH /NJS /NP >nul
if exist "%PROJECT%\Presets" robocopy "%PROJECT%\Presets" "%CHECKPOINT%\Presets" /E /NFL /NDL /NJH /NJS /NP >nul

certutil -hashfile "%FAUST%" SHA256 > "%VALID%\HASH_FAUST_SHA256.txt" 2>&1
certutil -hashfile "%SMOKESRC%" SHA256 > "%VALID%\HASH_DSPSMOKE_SHA256.txt" 2>&1
certutil -hashfile "%PROJECT%\CMakeLists.txt" SHA256 > "%VALID%\HASH_CMAKELISTS_SHA256.txt" 2>&1
echo %CHECKPOINT%> "%VALID%\CHECKPOINT_PATH.txt"

set "CHECKPOINT_STATUS=PASS"
call :WriteStatus
echo CHECKPOINT=PASS
goto :CHECKPOINT_DONE

:CHECKPOINT_FAIL
set "CHECKPOINT_STATUS=FAIL"
set "FAILURE_CLASS=FILE_IO"
set "FAILED_STEP=Approved DSP checkpoint"
goto :FAIL

:CHECKPOINT_DONE

rem ----------------------------------------------------------------
rem 3. Configure + clean DspSmoke build
rem ----------------------------------------------------------------
echo.
echo [3/8] CLEAN DSPSMOKE BUILD

cmake -S "%PROJECT%" -B "%BUILD%" -G "Visual Studio 17 2022" -A x64 > "%VALID%\CMakeConfigure.log" 2>&1
if errorlevel 1 goto :DSP_BUILD_FAIL

cmake --build "%BUILD%" --config Release --target KICKCRAFTER_DspSmoke --clean-first > "%VALID%\DspSmokeBuild.log" 2>&1
if errorlevel 1 goto :DSP_BUILD_FAIL

if not exist "%SMOKEEXE%" goto :DSP_BUILD_FAIL

set "CLEAN_DSP_BUILD=PASS"
call :WriteStatus
echo CLEAN_DSP_BUILD=PASS
goto :DSP_BUILD_DONE

:DSP_BUILD_FAIL
set "CLEAN_DSP_BUILD=FAIL"
set "FAILURE_CLASS=BUILD"
set "FAILED_STEP=Clean DspSmoke build"
goto :FAIL

:DSP_BUILD_DONE

rem ----------------------------------------------------------------
rem 4. Full DspSmoke gate
rem ----------------------------------------------------------------
echo.
echo [4/8] COMPILED DSP GATE

"%SMOKEEXE%" > "%VALID%\DspSmoke.log" 2>&1
set "SMOKERC=%ERRORLEVEL%"

findstr /C:"stageGate=7.1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (
    set "DSP_SMOKE=FAIL"
    set "FAILURE_CLASS=BUILD"
    set "FAILED_STEP=DspSmoke runtime identity"
    goto :FAIL
)

findstr /C:"allFactoryPresetsTechnical=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (
    set "FACTORY_50=FAIL"
) else (
    set "FACTORY_50=PASS"
)

findstr /C:"randomizerTechnical=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (
    set "RANDOMIZER=FAIL"
) else (
    set "RANDOMIZER=PASS"
)

findstr /C:"stateRoundTrip=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (
    set "STATE_ROUNDTRIP=FAIL"
) else (
    set "STATE_ROUNDTRIP=PASS"
)

findstr /C:"result=PASS" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (
    set "DSP_SMOKE=FAIL"
) else (
    if "%SMOKERC%"=="0" (
        set "DSP_SMOKE=PASS"
    ) else (
        set "DSP_SMOKE=FAIL"
    )
)

if exist "%PROJECT%\Stage71TestRenders" (
    robocopy "%PROJECT%\Stage71TestRenders" "%VALID%\Stage71TestRenders" /E /NFL /NDL /NJH /NJS /NP >nul
)

call :WriteStatus

findstr /C:"allFactoryPresetsTechnical=" /C:"randomizerTechnical=" /C:"stateRoundTrip=" /C:"result=" "%VALID%\DspSmoke.log"

if not "%DSP_SMOKE%"=="PASS" (
    set "FAILURE_CLASS=DSP_OR_VALIDATION"
    set "FAILED_STEP=DspSmoke result"
    goto :FAIL
)
if not "%FACTORY_50%"=="PASS" (
    set "FAILURE_CLASS=DSP_OR_VALIDATION"
    set "FAILED_STEP=50 factory presets"
    goto :FAIL
)
if not "%RANDOMIZER%"=="PASS" (
    set "FAILURE_CLASS=DSP_OR_VALIDATION"
    set "FAILED_STEP=Randomizer"
    goto :FAIL
)
if not "%STATE_ROUNDTRIP%"=="PASS" (
    set "FAILURE_CLASS=DSP_OR_VALIDATION"
    set "FAILED_STEP=State round-trip"
    goto :FAIL
)

echo DSP_SMOKE=PASS
echo FACTORY_50=PASS
echo RANDOMIZER=PASS
echo STATE_ROUNDTRIP=PASS

rem ----------------------------------------------------------------
rem 5. VST3 Release
rem ----------------------------------------------------------------
echo.
echo [5/8] VST3 RELEASE BUILD

cmake --build "%BUILD%" --config Release --target KICKCRAFTER_VST3 > "%VALID%\VST3Build.log" 2>&1
if errorlevel 1 goto :VST3_FAIL

if not exist "%VST3BIN%" goto :VST3_FAIL

certutil -hashfile "%VST3BIN%" SHA256 > "%VALID%\VST3_SHA256.txt" 2>&1
echo %VST3BUNDLE%> "%VALID%\VST3_PATH.txt"

set "VST3_BUILD=PASS"
call :WriteStatus
echo VST3_BUILD=PASS
goto :VST3_DONE

:VST3_FAIL
set "VST3_BUILD=FAIL"
set "FAILURE_CLASS=BUILD"
set "FAILED_STEP=VST3 Release build"
goto :FAIL

:VST3_DONE

rem ----------------------------------------------------------------
rem 6. Standalone if configured
rem ----------------------------------------------------------------
echo.
echo [6/8] STANDALONE

if not exist "%BUILD%\KICKCRAFTER_Standalone.vcxproj" goto :NO_STANDALONE

cmake --build "%BUILD%" --config Release --target KICKCRAFTER_Standalone > "%VALID%\StandaloneBuild.log" 2>&1
if errorlevel 1 (
    set "STANDALONE_BUILD=FAIL"
    set "FAILURE_CLASS=BUILD"
    set "FAILED_STEP=Standalone Release build"
    goto :FAIL
)

set "STANDALONE_BUILD=PASS"
call :WriteStatus
echo STANDALONE_BUILD=PASS
goto :STANDALONE_DONE

:NO_STANDALONE
set "STANDALONE_BUILD=NOT_CONFIGURED"
call :WriteStatus
echo STANDALONE_BUILD=NOT_CONFIGURED

:STANDALONE_DONE

rem ----------------------------------------------------------------
rem 7. pluginval if installed
rem ----------------------------------------------------------------
echo.
echo [7/8] PLUGINVAL

set "PLUGINVAL_EXE="
for /f "delims=" %%P in ('where pluginval.exe 2^>nul') do if not defined PLUGINVAL_EXE set "PLUGINVAL_EXE=%%P"

if not defined PLUGINVAL_EXE if exist "%PROJECT%\Tools\pluginval.exe" set "PLUGINVAL_EXE=%PROJECT%\Tools\pluginval.exe"
if not defined PLUGINVAL_EXE if exist "C:\Program Files\pluginval\pluginval.exe" set "PLUGINVAL_EXE=C:\Program Files\pluginval\pluginval.exe"
if not defined PLUGINVAL_EXE if exist "C:\Program Files (x86)\pluginval\pluginval.exe" set "PLUGINVAL_EXE=C:\Program Files (x86)\pluginval\pluginval.exe"

if not defined PLUGINVAL_EXE goto :NO_PLUGINVAL

"%PLUGINVAL_EXE%" --strictness-level 10 "%VST3BUNDLE%" > "%VALID%\pluginval.log" 2>&1
if errorlevel 1 (
    set "PLUGINVAL=FAIL"
) else (
    set "PLUGINVAL=PASS"
)
echo %PLUGINVAL_EXE%> "%VALID%\PLUGINVAL_PATH.txt"
call :WriteStatus
echo PLUGINVAL=%PLUGINVAL%
goto :PLUGINVAL_DONE

:NO_PLUGINVAL
set "PLUGINVAL=NOT_TESTED_NOT_FOUND"
echo pluginval.exe not found. Test NOT_TESTED.> "%VALID%\pluginval.log"
call :WriteStatus
echo PLUGINVAL=NOT_TESTED_NOT_FOUND

:PLUGINVAL_DONE

rem ----------------------------------------------------------------
rem 8. Steinberg VST3 Validator if installed
rem ----------------------------------------------------------------
echo.
echo [8/8] STEINBERG VST3 VALIDATOR

set "VALIDATOR_EXE="
for /f "delims=" %%V in ('where validator.exe 2^>nul') do if not defined VALIDATOR_EXE set "VALIDATOR_EXE=%%V"

if not defined VALIDATOR_EXE if exist "%PROJECT%\Tools\validator.exe" set "VALIDATOR_EXE=%PROJECT%\Tools\validator.exe"
if not defined VALIDATOR_EXE if exist "C:\VST3_SDK\build\bin\Release\validator.exe" set "VALIDATOR_EXE=C:\VST3_SDK\build\bin\Release\validator.exe"
if not defined VALIDATOR_EXE if exist "C:\VST_SDK\vst3sdk\build\bin\Release\validator.exe" set "VALIDATOR_EXE=C:\VST_SDK\vst3sdk\build\bin\Release\validator.exe"

if not defined VALIDATOR_EXE goto :NO_VALIDATOR

"%VALIDATOR_EXE%" -e "%VST3BUNDLE%" > "%VALID%\steinberg_validator.log" 2>&1
if errorlevel 1 (
    set "STEINBERG_VALIDATOR=FAIL"
) else (
    set "STEINBERG_VALIDATOR=PASS"
)
echo %VALIDATOR_EXE%> "%VALID%\STEINBERG_VALIDATOR_PATH.txt"
call :WriteStatus
echo STEINBERG_VALIDATOR=%STEINBERG_VALIDATOR%
goto :VALIDATOR_DONE

:NO_VALIDATOR
set "STEINBERG_VALIDATOR=NOT_TESTED_NOT_FOUND"
echo Steinberg validator.exe not found. Test NOT_TESTED.> "%VALID%\steinberg_validator.log"
call :WriteStatus
echo STEINBERG_VALIDATOR=NOT_TESTED_NOT_FOUND

:VALIDATOR_DONE

rem ----------------------------------------------------------------
rem Mandatory pre-GUI gate aggregation
rem ----------------------------------------------------------------
if not "%SOURCE_IDENTITY%"=="PASS" goto :MANDATORY_FAIL
if not "%CHECKPOINT_STATUS%"=="PASS" goto :MANDATORY_FAIL
if not "%CLEAN_DSP_BUILD%"=="PASS" goto :MANDATORY_FAIL
if not "%DSP_SMOKE%"=="PASS" goto :MANDATORY_FAIL
if not "%FACTORY_50%"=="PASS" goto :MANDATORY_FAIL
if not "%RANDOMIZER%"=="PASS" goto :MANDATORY_FAIL
if not "%STATE_ROUNDTRIP%"=="PASS" goto :MANDATORY_FAIL
if not "%VST3_BUILD%"=="PASS" goto :MANDATORY_FAIL
if "%STANDALONE_BUILD%"=="FAIL" goto :MANDATORY_FAIL

set "PRE_GUI_DSP_GATE=PASS"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"
call :WriteStatus
goto :SUCCESS

:MANDATORY_FAIL
set "PRE_GUI_DSP_GATE=FAIL"
set "FAILURE_CLASS=VALIDATION"
set "FAILED_STEP=Mandatory pre-GUI aggregation"
goto :FAIL

rem ----------------------------------------------------------------
rem Final paths
rem ----------------------------------------------------------------
:SUCCESS
echo.
echo ================================================================
echo PRE_GUI_DSP_GATE=PASS
echo RELEASE_READY=NO
echo ================================================================
call :WriteStatus
call :WriteChecklist
call :Bundle
echo.
echo VALIDATION_BUNDLE=%BUNDLE%
exit /b 0

:FAIL
set "PRE_GUI_DSP_GATE=FAIL"
call :WriteStatus
call :WriteChecklist
call :Bundle
echo.
echo ================================================================
echo PRE_GUI_DSP_GATE=FAIL
echo FAILURE_CLASS=%FAILURE_CLASS%
echo FAILED_STEP=%FAILED_STEP%
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 1

rem ----------------------------------------------------------------
rem Status writer
rem ----------------------------------------------------------------
:WriteStatus
> "%VALID%\RELEASE_STATUS.txt" echo SOURCE_IDENTITY=%SOURCE_IDENTITY%
>>"%VALID%\RELEASE_STATUS.txt" echo CHECKPOINT=%CHECKPOINT_STATUS%
>>"%VALID%\RELEASE_STATUS.txt" echo CLEAN_DSP_BUILD=%CLEAN_DSP_BUILD%
>>"%VALID%\RELEASE_STATUS.txt" echo DSP_SMOKE=%DSP_SMOKE%
>>"%VALID%\RELEASE_STATUS.txt" echo FACTORY_50=%FACTORY_50%
>>"%VALID%\RELEASE_STATUS.txt" echo RANDOMIZER=%RANDOMIZER%
>>"%VALID%\RELEASE_STATUS.txt" echo STATE_ROUNDTRIP=%STATE_ROUNDTRIP%
>>"%VALID%\RELEASE_STATUS.txt" echo VST3_BUILD=%VST3_BUILD%
>>"%VALID%\RELEASE_STATUS.txt" echo STANDALONE_BUILD=%STANDALONE_BUILD%
>>"%VALID%\RELEASE_STATUS.txt" echo PLUGINVAL=%PLUGINVAL%
>>"%VALID%\RELEASE_STATUS.txt" echo STEINBERG_VALIDATOR=%STEINBERG_VALIDATOR%
>>"%VALID%\RELEASE_STATUS.txt" echo DAW_TEST=%DAW_TEST%
>>"%VALID%\RELEASE_STATUS.txt" echo PRE_GUI_DSP_GATE=%PRE_GUI_DSP_GATE%
>>"%VALID%\RELEASE_STATUS.txt" echo RELEASE_READY=%RELEASE_READY%
>>"%VALID%\RELEASE_STATUS.txt" echo FAILURE_CLASS=%FAILURE_CLASS%
>>"%VALID%\RELEASE_STATUS.txt" echo FAILED_STEP=%FAILED_STEP%
exit /b 0

rem ----------------------------------------------------------------
rem DAW checklist
rem ----------------------------------------------------------------
:WriteChecklist
> "%VALID%\DAW_TEST_CHECKLIST.txt" echo INDUSTRY KICK - FINAL DAW REGRESSION CHECKLIST
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo.
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo Run after final GUI integration.
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo.
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] DAW scan
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Instantiate/remove repeatedly
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] 44.1 / 48 / 96 kHz
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Small / medium / large buffers
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Preset changes stopped and playing
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Automation
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Save / close / reopen / state recall
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Bypass
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Silence and extreme parameters
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Rapid parameter stress
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Multiple instances
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] CPU / memory sanity
>>"%VALID%\DAW_TEST_CHECKLIST.txt" echo [ ] Final five approved anchors listening regression
exit /b 0

rem ----------------------------------------------------------------
rem Bundle maker: tar.exe first. Single-line PowerShell fallback only.
rem ----------------------------------------------------------------
:Bundle
if exist "%BUNDLE%" del /q "%BUNDLE%"

where tar.exe >nul 2>&1
if errorlevel 1 goto :BUNDLE_FALLBACK

pushd "%VALID%"
tar.exe -a -c -f "%BUNDLE%" *
set "TARRC=%ERRORLEVEL%"
popd
if "%TARRC%"=="0" exit /b 0

:BUNDLE_FALLBACK
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%VALID%\*' -DestinationPath '%BUNDLE%' -Force"
exit /b 0
