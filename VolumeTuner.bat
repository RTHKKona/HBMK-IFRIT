@echo off
echo Audio Volume Adjuster - Created by Handburger
echo.

REM Check if a file was dragged
if "%1"=="" (
    echo No audio file detected.
    echo Drag and drop an audio file onto this BAT file to adjust its volume.
    pause
    exit /b
)

REM File was dragged, proceed with processing
set "input_file=%~1"
echo Audio file detected: %~nx1
echo Input file path: %input_file%
echo Checking for ffmpeg.exe...

REM Verify ffmpeg exists
if not exist "%~dp0ffmpeg.exe" (
    echo Error: ffmpeg.exe not found in the same folder as this BAT file.
    pause
    exit /b
)
echo ffmpeg.exe found.

:menu
echo.
echo What would you like to do?
echo 1. Make it louder (increase by 3.5dB)
echo 2. Make it much louder (increase by 8dB)
echo 3. Make it softer (decrease by 3.5dB)
echo 4. Make it much softer (decrease by 8dB)
echo 5. Custom volume adjustment (enter your own dB value)
echo 6. Exit
echo.
set "choice="
set /p choice="Enter your choice (1-6): "

REM Process the choice
if "%choice%"=="1" (
    echo Increasing volume by 3.5dB...
    "%~dp0ffmpeg.exe" -i "%input_file%" -af "volume=3.5dB" "%~dpn1_louder%~x1"
    if errorlevel 1 (echo Error: FFmpeg failed.) else (echo Done! Output saved as %~n1_louder%~x1)
    pause
    exit /b
) else if "%choice%"=="2" (
    echo Increasing volume by 8dB...
    "%~dp0ffmpeg.exe" -i "%input_file%" -af "volume=8dB" "%~dpn1_slouder%~x1"
    if errorlevel 1 (echo Error: FFmpeg failed.) else (echo Done! Output saved as %~n1_slouder%~x1)
    pause
    exit /b
) else if "%choice%"=="3" (
    echo Decreasing volume by 3.5dB...
    "%~dp0ffmpeg.exe" -i "%input_file%" -af "volume=-3.5dB" "%~dpn1_softer%~x1"
    if errorlevel 1 (echo Error: FFmpeg failed.) else (echo Done! Output saved as %~n1_softer%~x1)
    pause
    exit /b
) else if "%choice%"=="4" (
    echo Decreasing volume by 8dB...
    "%~dp0ffmpeg.exe" -i "%input_file%" -af "volume=-8dB" "%~dpn1_ssofter%~x1"
    if errorlevel 1 (echo Error: FFmpeg failed.) else (echo Done! Output saved as %~n1_ssofter%~x1)
    pause
    exit /b
) else if "%choice%"=="5" (
    echo Entering custom adjustment...
    goto custom_adjust
) else if "%choice%"=="6" (
    echo Exiting...
    pause
    exit /b
) else (
    echo Invalid choice! Please enter a valid number.
    pause
    goto menu
)

:custom_adjust
echo Custom adjustment selected.
echo Enter a custom dB value (positive to increase, negative to decrease, e.g., 5 or -5):
set "custom_db="
set /p custom_db="dB value: "
if not defined custom_db (
    echo No value entered! Returning to menu.
    pause
    goto menu
)
echo Adjusting volume by %custom_db%dB...
"%~dp0ffmpeg.exe" -i "%input_file%" -af "volume=%custom_db%dB" "%~dpn1_custom_%custom_db%dB%~x1"
if errorlevel 1 (
    echo Error: FFmpeg failed. Check the input file or dB value.
) else (
    echo Done! Output saved as %~n1_custom_%custom_db%dB%~x1
)
pause
exit /b