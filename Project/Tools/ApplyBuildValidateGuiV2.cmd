@echo off
setlocal EnableExtensions

set "PROJECT=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project"
set "APPROVED=%PROJECT%\Checkpoints\Stage7_1_DSP_APPROVED_FINAL_72E"
set "HERE=%~dp0.."
set "VALID=%PROJECT%\Stage80GuiV2Validation"
set "BUNDLE=%PROJECT%\Stage80GuiV2ValidationBundle.zip"
set "GUIBACKUP=%PROJECT%\Checkpoints\GUI_V1_before_STAGE8_GUI_V2"

set "DSP_IDENTITY=NOT_TESTED"
set "GUI_PATCH=NOT_TESTED"
set "DSP_SMOKE=NOT_TESTED"
set "FACTORY_50=NOT_TESTED"
set "RANDOMIZER=NOT_TESTED"
set "STATE_ROUNDTRIP=NOT_TESTED"
set "VST3_BUILD=NOT_TESTED"
set "STANDALONE_BUILD=NOT_TESTED"
set "PLUGINVAL=NOT_TESTED"
set "STEINBERG_VALIDATOR=NOT_TESTED"
set "DAW_TEST=NOT_TESTED"
set "GUI_V2_PRE_DAW_GATE=NOT_TESTED"
set "RELEASE_READY=NO"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"

echo INDUSTRY KICK - STAGE 8.0 GUI V2
echo GUI-ONLY PATCH / DSP FROZEN
echo.

if exist "%VALID%" rmdir /s /q "%VALID%"
mkdir "%VALID%" >nul 2>&1
if errorlevel 1 (
  echo ERROR: cannot create validation directory.
  exit /b 2
)
call :WriteStatus

if not exist "%PROJECT%\Source\PluginEditor.cpp" goto :SOURCE_MISSING
if not exist "%PROJECT%\Source\PluginEditor.h" goto :SOURCE_MISSING
if not exist "%APPROVED%\Faust\IndustryKickV2_R4_Freeze.dsp" goto :CHECKPOINT_MISSING

echo [1/7] VERIFY APPROVED DSP IDENTITY
call :VerifyFrozenDSP
if errorlevel 1 (
  set "DSP_IDENTITY=FAIL"
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Current DSP differs from approved Stage7_1 checkpoint"
  goto :FAIL
)
set "DSP_IDENTITY=PASS"
call :WriteStatus
echo DSP_IDENTITY=PASS

echo.
echo [2/7] BACKUP CURRENT GUI + APPLY GUI V2
if not exist "%GUIBACKUP%" mkdir "%GUIBACKUP%" >nul 2>&1
copy /Y "%PROJECT%\Source\PluginEditor.cpp" "%GUIBACKUP%\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL
copy /Y "%PROJECT%\Source\PluginEditor.h" "%GUIBACKUP%\PluginEditor.h" >nul
if errorlevel 1 goto :GUI_FAIL

copy /Y "%HERE%\Source\PluginEditor.cpp" "%PROJECT%\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL

findstr /C:"FAMILY ENGINE / MASTER GLUE SYSTEM" "%PROJECT%\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL
findstr /C:"05 / MUTANT" "%PROJECT%\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL
findstr /C:"LIGHT SAT  >  GLUE 4:1  >  HARD CLIP" "%PROJECT%\Source\PluginEditor.cpp" >nul
if errorlevel 1 goto :GUI_FAIL

set "GUI_PATCH=PASS"
call :WriteStatus
echo GUI_PATCH=PASS
goto :GUI_DONE

:GUI_FAIL
set "GUI_PATCH=FAIL"
set "FAILURE_CLASS=GUI"
set "FAILED_STEP=Apply PluginEditor GUI V2"
goto :FAIL

:GUI_DONE

echo.
echo [3/7] VERIFY DSP STILL BYTE-IDENTICAL
call :VerifyFrozenDSP
if errorlevel 1 (
  set "DSP_IDENTITY=FAIL"
  set "FAILURE_CLASS=SOURCE"
  set "FAILED_STEP=Frozen DSP changed during GUI patch"
  goto :FAIL
)
echo DSP_IDENTITY_AFTER_GUI=PASS

echo.
echo [4/7] CLEAN DSPSMOKE BUILD + REGRESSION
cmake -S "%PROJECT%" -B "%PROJECT%\build" -G "Visual Studio 17 2022" -A x64 > "%VALID%\CMakeConfigure.log" 2>&1
if errorlevel 1 (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=CMake configure"
  goto :FAIL
)

cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_DspSmoke --clean-first > "%VALID%\DspSmokeBuild.log" 2>&1
if errorlevel 1 (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=Clean DspSmoke build"
  goto :FAIL
)

set "SMOKEEXE=%PROJECT%\build\KICKCRAFTER_DspSmoke_artefacts\Release\KICKCRAFTER_DspSmoke.exe"
if not exist "%SMOKEEXE%" (
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=DspSmoke executable missing"
  goto :FAIL
)

"%SMOKEEXE%" > "%VALID%\DspSmoke.log" 2>&1
set "SMOKERC=%ERRORLEVEL%"

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

findstr /C:"allFactoryPresetsTechnical=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "FACTORY_50=FAIL") else (set "FACTORY_50=PASS")

findstr /C:"randomizerTechnical=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "RANDOMIZER=FAIL") else (set "RANDOMIZER=PASS")

findstr /C:"stateRoundTrip=1" "%VALID%\DspSmoke.log" >nul
if errorlevel 1 (set "STATE_ROUNDTRIP=FAIL") else (set "STATE_ROUNDTRIP=PASS")

call :WriteStatus
findstr /C:"allFactoryPresetsTechnical=" /C:"randomizerTechnical=" /C:"stateRoundTrip=" /C:"result=" "%VALID%\DspSmoke.log"

if not "%DSP_SMOKE%"=="PASS" (
  set "FAILURE_CLASS=DSP_OR_VALIDATION"
  set "FAILED_STEP=DspSmoke regression"
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
echo DSP_REGRESSION=PASS

echo.
echo [5/7] VST3 RELEASE BUILD
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_VST3 > "%VALID%\VST3Build.log" 2>&1
if errorlevel 1 (
  set "VST3_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 Release build"
  goto :FAIL
)
set "VST3BIN=%PROJECT%\build\KICKCRAFTER_artefacts\Release\VST3\INDUSTRY KICK.vst3\Contents\x86_64-win\INDUSTRY KICK.vst3"
set "VST3BUNDLE=%PROJECT%\build\KICKCRAFTER_artefacts\Release\VST3\INDUSTRY KICK.vst3"
if not exist "%VST3BIN%" (
  set "VST3_BUILD=FAIL"
  set "FAILURE_CLASS=BUILD"
  set "FAILED_STEP=VST3 binary verification"
  goto :FAIL
)
set "VST3_BUILD=PASS"
certutil -hashfile "%VST3BIN%" SHA256 > "%VALID%\VST3_SHA256.txt" 2>&1
echo %VST3BUNDLE%> "%VALID%\VST3_PATH.txt"
call :WriteStatus
echo VST3_BUILD=PASS

echo.
echo [6/7] STANDALONE
if not exist "%PROJECT%\build\KICKCRAFTER_Standalone.vcxproj" goto :NO_STANDALONE
cmake --build "%PROJECT%\build" --config Release --target KICKCRAFTER_Standalone > "%VALID%\StandaloneBuild.log" 2>&1
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

echo.
echo [7/7] OPTIONAL EXTERNAL VALIDATORS
set "PLUGINVAL_EXE="
for /f "delims=" %%P in ('where pluginval.exe 2^>nul') do if not defined PLUGINVAL_EXE set "PLUGINVAL_EXE=%%P"
if not defined PLUGINVAL_EXE if exist "%PROJECT%\Tools\pluginval.exe" set "PLUGINVAL_EXE=%PROJECT%\Tools\pluginval.exe"
if not defined PLUGINVAL_EXE if exist "C:\Program Files\pluginval\pluginval.exe" set "PLUGINVAL_EXE=C:\Program Files\pluginval\pluginval.exe"

if defined PLUGINVAL_EXE (
  "%PLUGINVAL_EXE%" --strictness-level 10 "%VST3BUNDLE%" > "%VALID%\pluginval.log" 2>&1
  if errorlevel 1 (set "PLUGINVAL=FAIL") else (set "PLUGINVAL=PASS")
) else (
  set "PLUGINVAL=NOT_TESTED_NOT_FOUND"
  echo pluginval.exe not found. Test NOT_TESTED.> "%VALID%\pluginval.log"
)

set "VALIDATOR_EXE="
for /f "delims=" %%V in ('where validator.exe 2^>nul') do if not defined VALIDATOR_EXE set "VALIDATOR_EXE=%%V"
if not defined VALIDATOR_EXE if exist "%PROJECT%\Tools\validator.exe" set "VALIDATOR_EXE=%PROJECT%\Tools\validator.exe"
if defined VALIDATOR_EXE (
  "%VALIDATOR_EXE%" -e "%VST3BUNDLE%" > "%VALID%\steinberg_validator.log" 2>&1
  if errorlevel 1 (set "STEINBERG_VALIDATOR=FAIL") else (set "STEINBERG_VALIDATOR=PASS")
) else (
  set "STEINBERG_VALIDATOR=NOT_TESTED_NOT_FOUND"
  echo Steinberg validator.exe not found. Test NOT_TESTED.> "%VALID%\steinberg_validator.log"
)

set "GUI_V2_PRE_DAW_GATE=PASS"
set "FAILURE_CLASS=NONE"
set "FAILED_STEP=NONE"
call :WriteStatus
call :WriteGuiIdentity
call :Bundle

echo.
echo ================================================================
echo GUI_V2_PRE_DAW_GATE=PASS
echo DSP_IDENTITY=PASS
echo RELEASE_READY=NO
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 0

:SOURCE_MISSING
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Current editor source missing"
goto :FAIL

:CHECKPOINT_MISSING
set "FAILURE_CLASS=SOURCE"
set "FAILED_STEP=Approved Stage7_1 checkpoint missing"
goto :FAIL

:FAIL
set "GUI_V2_PRE_DAW_GATE=FAIL"
call :WriteStatus
call :WriteGuiIdentity
call :Bundle
echo.
echo ================================================================
echo GUI_V2_PRE_DAW_GATE=FAIL
echo FAILURE_CLASS=%FAILURE_CLASS%
echo FAILED_STEP=%FAILED_STEP%
echo VALIDATION_BUNDLE=%BUNDLE%
echo ================================================================
exit /b 1

:VerifyFrozenDSP
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
fc /b "%PROJECT%\Source\FactoryPresets.h" "%APPROVED%\Source\FactoryPresets.h" >nul
if errorlevel 1 exit /b 1
fc /b "%PROJECT%\Tests\DspSmoke.cpp" "%APPROVED%\Tests\DspSmoke.cpp" >nul
if errorlevel 1 exit /b 1
fc /b "%PROJECT%\CMakeLists.txt" "%APPROVED%\CMakeLists.txt" >nul
if errorlevel 1 exit /b 1
exit /b 0

:WriteGuiIdentity
> "%VALID%\GUI_V2_IDENTITY.txt" echo INDUSTRY KICK - STAGE 8.0 GUI V2
>>"%VALID%\GUI_V2_IDENTITY.txt" echo GUI patch changes PluginEditor.cpp only.
>>"%VALID%\GUI_V2_IDENTITY.txt" echo.
certutil -hashfile "%PROJECT%\Source\PluginEditor.cpp" SHA256 >> "%VALID%\GUI_V2_IDENTITY.txt" 2>&1
>>"%VALID%\GUI_V2_IDENTITY.txt" echo.
>>"%VALID%\GUI_V2_IDENTITY.txt" echo Expected GUI V2 SHA256:
>>"%VALID%\GUI_V2_IDENTITY.txt" echo ed65d1d199cc69962696b01dd500046c5e259458e938f972af0c56bff6f47604
exit /b 0

:WriteStatus
> "%VALID%\RELEASE_STATUS.txt" echo DSP_IDENTITY=%DSP_IDENTITY%
>>"%VALID%\RELEASE_STATUS.txt" echo GUI_PATCH=%GUI_PATCH%
>>"%VALID%\RELEASE_STATUS.txt" echo DSP_SMOKE=%DSP_SMOKE%
>>"%VALID%\RELEASE_STATUS.txt" echo FACTORY_50=%FACTORY_50%
>>"%VALID%\RELEASE_STATUS.txt" echo RANDOMIZER=%RANDOMIZER%
>>"%VALID%\RELEASE_STATUS.txt" echo STATE_ROUNDTRIP=%STATE_ROUNDTRIP%
>>"%VALID%\RELEASE_STATUS.txt" echo VST3_BUILD=%VST3_BUILD%
>>"%VALID%\RELEASE_STATUS.txt" echo STANDALONE_BUILD=%STANDALONE_BUILD%
>>"%VALID%\RELEASE_STATUS.txt" echo PLUGINVAL=%PLUGINVAL%
>>"%VALID%\RELEASE_STATUS.txt" echo STEINBERG_VALIDATOR=%STEINBERG_VALIDATOR%
>>"%VALID%\RELEASE_STATUS.txt" echo DAW_TEST=%DAW_TEST%
>>"%VALID%\RELEASE_STATUS.txt" echo GUI_V2_PRE_DAW_GATE=%GUI_V2_PRE_DAW_GATE%
>>"%VALID%\RELEASE_STATUS.txt" echo RELEASE_READY=%RELEASE_READY%
>>"%VALID%\RELEASE_STATUS.txt" echo FAILURE_CLASS=%FAILURE_CLASS%
>>"%VALID%\RELEASE_STATUS.txt" echo FAILED_STEP=%FAILED_STEP%
exit /b 0

:Bundle
if exist "%BUNDLE%" del /q "%BUNDLE%"
where tar.exe >nul 2>&1
if errorlevel 1 goto :BUNDLE_PS
pushd "%VALID%"
tar.exe -a -c -f "%BUNDLE%" *
set "TARRC=%ERRORLEVEL%"
popd
if "%TARRC%"=="0" exit /b 0
:BUNDLE_PS
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%VALID%\*' -DestinationPath '%BUNDLE%' -Force"
exit /b 0
