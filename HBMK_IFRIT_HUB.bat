@echo off
setlocal EnableExtensions

:: Configuration
set "VERSION=0.1"
set "CREDITS_FILE=credits.txt"
set "ALIAS=Handburger"
set "MODKIT_NAME=Ifrit"

:: ANSI Color Codes
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "MAGENTA=[95m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"

:MAIN
cls
echo.
echo %RED%▄████████████████████████████████████▄
echo %RED%█%RESET%                                   %YELLOW%Handburger's Modkit - %MODKIT_NAME% v%VERSION%%RED%                                         █
echo %RED%█%RESET%                                      %CYAN%Custom MHGU Modding Toolkit%RED%                                           █
echo %RED%▀████████████████████████████████████▀%RESET%
echo.
echo.
echo [%GREEN%/vol%RESET%]    Volume Tuner - Audio level adjustments
echo [%GREEN%/adg%RESET%]    MCA ADPCM Group - Batch conversion utility
echo [%GREEN%/ads%RESET%]    MCA ADPCM Single - Individual file processor
echo [%GREEN%/aud%RESET%]    Audio Converter - Multi-format transcoder
echo [%GREEN%/opus%RESET%]   OPUS Editor - Advanced audio manipulation
echo [%GREEN%/zip%RESET%]    ZIP Scanner - Archive validation system
echo [%GREEN%/stqr%RESET%]   STQR Editor - Configuration interface
echo [%GREEN%/credits%RESET%] Show development credits
echo [%GREEN%/exit%RESET%]   Terminate application
echo.
set /p "input=%WHITE%Enter command:%RESET% "

call :PROCESS_CMD "%input%"
goto MAIN

:PROCESS_CMD
if /i "%~1"=="/vol" (
    start "" "VolumeTuner.bat"
    goto :EOF
)
if /i "%~1"=="/adg" (
    start "" "MCA_ADPCM_Converter_Group.bat"
    goto :EOF
)
if /i "%~1"=="/ads" (
    start "" "MCA_ADPCM_Converter_Single.bat"
    goto :EOF
)
if /i "%~1"=="/aud" (
    start "" "AudioConverter.bat"
    goto :EOF
)
if /i "%~1"=="/opus" (
    start "" "OpusEditor.bat"
    goto :EOF
)
if /i "%~1"=="/zip" (
    start "" "ZipScanner.bat"
    goto :EOF
)
if /i "%~1"=="/stqr" (
    start "" "STQREditor.html"
    goto :EOF
)
if /i "%~1"=="/credits" (
    cls
    echo %YELLOW%Development Credits:%RESET%
    if exist "%CREDITS_FILE%" (
        type "%CREDITS_FILE%"
    ) else (
        echo %RED%Credits file missing!%RESET%
    )
    echo.
    echo %GREEN%Lead Coder/Primary Developer: %ALIAS%%RESET%
    pause
    goto :EOF
)
if /i "%~1"=="/exit" (
    exit
)

echo %RED%Invalid command!%RESET% Type one of the listed options
pause
goto :EOF