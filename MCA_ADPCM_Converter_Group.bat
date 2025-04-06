@echo off
setlocal EnableDelayedExpansion

echo Handburger's WAV-to-ADPCM/MCA Converter v1
echo =========================================================
echo Original Code by Fexty
echo.

REM Set the working directory to the batch file's location
cd /d "%~dp0"

REM Check if the script is in the same directory as the batch file
set "script_path=%~dp0wav2adpcm.py"
if not exist "!script_path!" (
    echo Error: wav2adpcm.py not found in the batch file directory
    echo Please place wav2adpcm.py in the same directory as this batch file
    pause
    exit /b 1
)

REM Check for FFmpeg in the local directory first
set "ffmpeg_path=%~dp0ffmpeg.exe"
if exist "!ffmpeg_path!" (
    REM Temporarily add the current directory to PATH for this session
    set "PATH=%~dp0;%PATH%"
    echo FFmpeg found in local directory.
) else (
    REM Check if FFmpeg is in system PATH
    where ffmpeg >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo Error: FFmpeg not found!
        echo Place ffmpeg.exe in this directory or add it to your system PATH.
        echo Download from: https://ffmpeg.org/download.html
        pause
        exit /b 1
    )
    echo FFmpeg found in system PATH.
)

REM Check if launched with drag and drop
if "%~1"=="" (
    REM No arguments - show instructions
    echo Instructions:
    echo - Drag and drop a directory onto this batch file to convert all WAV files
    echo   in the directory and its subdirectories to Capcom ADPCM format
    echo - Requires: Python, ffmpeg.exe, and AdpcmEncoder.exe in this directory or PATH
    echo.
    echo Credits:
    echo - Fexty: Original wav2adpcm script
    echo - Handburger: Batch file adaptation
    echo - eviltrainer: Inspiration
    echo - ffmpeg: Audio manipulation
    echo.
	echo. WARNING: The wav-adpcm process will convert ALL wav files RECURSIVELY within the directory. 
	echo. PICK WISELY. 
	echo.
    pause
    exit /b 0
)

REM Check if dropped item is a directory
if not exist "%~1\*" (
    echo Error: Please drop a directory, not a file
    pause
    exit /b 1
)

REM Run the Python script with main_dirtree
echo Converting WAV files in %1 to Capcom ADPCM format...
python "%script_path%" "%~1"
if %ERRORLEVEL% neq 0 (
    echo Error: Conversion failed. Check the error messages above.
) else (
    echo Conversion complete!
)
pause