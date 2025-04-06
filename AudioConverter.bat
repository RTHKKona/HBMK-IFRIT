@echo off
setlocal enabledelayedexpansion

:: Configuration
set "MANIFEST_FILE=Directory"
set "SCRIPT_DIR=%~dp0"
title Audio Conversion Tool - by Handburger

:: Credit Information
set "AUTHOR=Handburger"
set "NXAENC_CREDIT=Fexty"

:: Audio Settings
set "SAMPLE_RATE=48000"

:: Error Code Definitions
set "ERROR_HEADER=═══════════════════════════════════════════════════"
set "ERROR_FOOTER=═══════════════════════════════════════════════════"
set "ERR_MANIFEST=1"
set "ERR_DEPENDENCY=2"
set "ERR_TEMP_DIR=3"
set "ERR_INPUT_FILE=4"
set "ERR_WAV_CONVERSION=5"
set "ERR_RAW_CONVERSION=6"
set "ERR_OPUS_ENCODING=7"
set "ERR_OUTPUT_FILE=8"

:: Check if run by double-click (no arguments)
if "%~1"=="" (
    call :show_interactive_prompt
    goto persist
)

:: Process files
set "success_count=0"
set "error_count=0"

for %%F in (%*) do (
    echo.
    echo Processing: %%~nxF
    call :process_file "%%~F"
    if errorlevel 1 (
        set /a "error_count+=1"
    ) else (
        set /a "success_count+=1"
    )
    echo -------------------------------
)

echo.
echo Processing Summary:
echo   Successful conversions: %success_count%
echo   Failed conversions: %error_count%
echo.

goto persist

:show_interactive_prompt
    mode con: cols=85 lines=40
    echo ############################################################
    echo #         Audio Conversion Tool        by %AUTHOR%       #
    echo ############################################################
    echo.
    echo [Credits]
    echo   NXAenc update by %NXAENC_CREDIT%
    echo.
    echo [Description]
    echo This tool converts audio files to OPUS format through
    echo multiple processing stages.
    echo.
    echo [Features]
    echo   - Multi-stage audio conversion process
    echo   - OPUS encoding with NXAenc
    echo   - Error handling and recovery options
    echo.
    echo [Usage]
    echo 1. Drag and drop audio files onto this window
    echo 2. Conversion progress will be shown here
    echo 3. Output files will be saved in original directory
    echo    with .opus extension
    echo.
    echo [Error Reference]
    echo E1: Missing manifest file     E5: WAV conversion failed
    echo E2: Missing dependency        E6: RAW conversion failed
    echo E3: Temp directory error      E7: OPUS encoding failed
    echo E4: Input file issue          E8: Output file issue
    echo.
    
    :: Check for manifest file
    if not exist "%SCRIPT_DIR%%MANIFEST_FILE%" (
        call :error_handler %ERR_MANIFEST% "Missing manifest file" "Check if 'Directory' file exists in %SCRIPT_DIR%"
    )

    :: Verify directory structure and files
    set "missing_files="
    if exist "%SCRIPT_DIR%%MANIFEST_FILE%" (
        for /f "usebackq delims=" %%F in ("%SCRIPT_DIR%%MANIFEST_FILE%") do (
            set "item=%%F"
            if "!item:~-1!"=="\" (
                if not exist "%SCRIPT_DIR%!item!nul" (
                    set "missing_files=!missing_files!   - !item! (directory)^
"
                )
            ) else (
                if not exist "%SCRIPT_DIR%!item!" (
                    set "missing_files=!missing_files!   - !item! (file)^
"
                )
            )
        )
    )

    if defined missing_files (
        echo %ERROR_HEADER%
        echo [ERROR E%ERR_DEPENDENCY%] Missing dependencies:
        echo %missing_files%
        echo %ERROR_HEADER%
        echo.
        echo How to resolve:
        echo 1. Ensure all listed files/directories exist
        echo 2. Verify names match exactly
        echo 3. Check case sensitivity
        echo 4. Place them in: %SCRIPT_DIR%
        echo.
        pause
        exit /b %ERR_DEPENDENCY%
    )
    
    echo [Status]
    echo READY: Drag audio files onto this window to start conversion
    echo.
    echo To use this tool, either:
    echo 1. Drag and drop audio files directly onto this window, or
    echo 2. Drag and drop audio files onto the .bat file in Explorer
    echo.
exit /b

:: Error Handling Function
:error_handler
echo.
echo %ERROR_HEADER%
echo [ERROR E%1] %2
echo %ERROR_HEADER%
echo.
echo Possible solutions:
echo %3
echo.
exit /b %1

:process_file
set "input_file=%~1"
set "output_opus=%~dpn1.opus"
set "temp_dir=%TEMP%\%~n1_temp_%RANDOM%"

:: Verify input file exists
if not exist "%input_file%" (
    call :error_handler %ERR_INPUT_FILE% "Input file not found" "Check if file exists: %input_file%"
)

:: Create temp directory
md "%temp_dir%" 2>nul || (
    call :error_handler %ERR_TEMP_DIR% "Temp directory creation failed" "Try cleaning TEMP directory or restarting"
)

:: Conversion Step 1: WAV
echo [1/3] Converting to WAV...
"%SCRIPT_DIR%ffmpeg.exe" -i "%input_file%" -ar %SAMPLE_RATE% -ac 2 -hide_banner -loglevel error "%temp_dir%\processed.wav"
if %errorlevel% neq 0 (
    rd /s /q "%temp_dir%" 2>nul
    call :error_handler %ERR_WAV_CONVERSION% "WAV conversion failed" "Check input file format/supported codecs"
)

:: Conversion Step 2: RAW
echo [2/3] Converting to RAW...
"%SCRIPT_DIR%ffmpeg.exe" -i "%temp_dir%\processed.wav" -f s16le -acodec pcm_s16le -hide_banner -loglevel error "%temp_dir%\processed.raw"
if %errorlevel% neq 0 (
    rd /s /q "%temp_dir%" 2>nul
    call :error_handler %ERR_RAW_CONVERSION% "RAW conversion failed" "This is usually a system resource issue"
)

:: Conversion Step 3: OPUS
echo [3/3] Encoding to OPUS using NXAenc (updated by %NXAENC_CREDIT%)...
"%SCRIPT_DIR%NXAenc.exe" -i "%temp_dir%\processed.raw" -o "%output_opus%"
if %errorlevel% neq 0 (
    rd /s /q "%temp_dir%" 2>nul
    call :error_handler %ERR_OPUS_ENCODING% "OPUS encoding failed" "Check encoder configuration/file permissions"
)

:: Verify output
if not exist "%output_opus%" (
    rd /s /q "%temp_dir%" 2>nul
    call :error_handler %ERR_OUTPUT_FILE% "Output file not created" "Check disk space/write permissions"
)

echo.
echo SUCCESS: Created %~n1.opus (%filesize% bytes)
echo.

rd /s /q "%temp_dir%" 2>nul
exit /b 0

:persist
echo.
echo Press any key to exit...
pause > nul
exit /b