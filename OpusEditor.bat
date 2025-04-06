@echo off
setlocal enabledelayedexpansion

:Main
cls
echo Opus Header Editor by Handburger
echo ===============================
echo This tool edits .Opus files for adding loop start and end points.
echo It does this via modifying the two 32-bit unsigned integers at offset 8 in .opus files.
echo.

:: Tutorial for getting loop data from Audacity
echo Tutorial for Getting Loop Data from Audacity:
echo 1. Open your audio file in Audacity.
echo 2. Listen to the audio and identify your desired loop start and end points.
echo 3. Click and drag to select the region you want to loop.
echo 4. At the bottom of the window, change the selection format from "hh:mm:ss + milliseconds" to "samples".
echo 5. Note the displayed sample numbers - these are the values you need for the Opus Header Editor.
echo 6. To get the total samples, click the "Skip to End" button and note the sample number shown.
echo.

:: Check if file was provided as an argument
if "%~1"=="" (
    echo Drag and drop an .opus file onto this script or
    set /p "opusFile=Enter file path: "
) else (
    set "opusFile=%~1"
)

:: Verify file exists and has .opus extension
:VerifyFile
if not exist "!opusFile!" (
    echo Error: File does not exist.
    set /p "opusFile=Enter file path: "
    goto :VerifyFile
)

:: Check for .opus extension
set "fileExt=%opusFile:~-5%"
if /i not "!fileExt!"==".opus" (
    echo Error: File must be an .opus file.
    set /p "opusFile=Enter file path: "
    goto :VerifyFile
)

:: Create displayable filename
for %%F in ("!opusFile!") do set "displayName=%%~nxF"

:PrepareDisplay
:: Process the file information before showing the menu
set "displayError=0"

:: Get file size in bytes
for %%A in ("!opusFile!") do set fileSize=%%~zA

:: Initialize variables
set "currentStart=Unknown"
set "currentEnd=Unknown"
set "currentStartHex=Unknown"
set "currentEndHex=Unknown"

:: Read the opus header values directly using PowerShell
set "psCommand=$bytes = [System.IO.File]::ReadAllBytes('!opusFile!'); $start = [System.BitConverter]::ToUInt32($bytes, 8); $end = [System.BitConverter]::ToUInt32($bytes, 12); $startHex = [System.BitConverter]::ToString($bytes[8..11]).Replace('-',''); $endHex = [System.BitConverter]::ToString($bytes[12..15]).Replace('-',''); Write-Output \"$start,$end,$startHex,$endHex\""
for /f "usebackq tokens=1,2,3,4 delims=," %%a in (`powershell -Command "!psCommand!" 2^>nul`) do (
    set "currentStart=%%a"
    set "currentEnd=%%b"
    set "currentStartHex=%%c"
    set "currentEndHex=%%d"
)

:: Check if values were set successfully
if not defined currentStart set "displayError=1"

:DisplayMenu
echo File: "!displayName!"
echo.

echo File Information:
echo -----------------
echo Size of file: !fileSize! bytes
echo Total samples: !totalSamples! (please note this value for your reference)
echo Loop start: !currentStart! samples [!currentStartHex!] (Offset 08-0B)
echo Loop end: !currentEnd! samples [!currentEndHex!] (Offset 0C-0F)
echo.

if "!displayError!"=="1" (
    echo Warning: Could not read file header correctly. File may be corrupted or have an unsupported format.
    echo.
)

echo [A] Edit loop points
echo [B] Set total samples
echo [C] Rename file
echo [D] Exit
choice /c ABCD /n /m "Choose option: "
set "choice=!errorlevel!"

if !choice! equ 1 goto :EditLoop
if !choice! equ 2 goto :SetTotalSamples
if !choice! equ 3 goto :RenameFile
if !choice! equ 4 goto :Exit

goto :DisplayMenu

:SetTotalSamples
cls
echo Enter the total number of samples in the audio:
echo (You can find this in Audacity by clicking "Skip to End" and noting the sample number shown)
echo.

set "totalSamples="
set /p "totalSamples=Total samples: "
echo !totalSamples!| findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo Invalid input! Must be a number.
    pause
    goto :SetTotalSamples
)
echo You entered: !totalSamples!
pause
goto :PrepareDisplay

:EditLoop
cls
echo Editing Loop Points for: "!displayName!"
echo.

:: Display current values
echo Current loop start: !currentStart! samples [!currentStartHex!]
echo Current loop end: !currentEnd! samples [!currentEndHex!]

:GetStart
echo.
set "decimalValue1="
set /p "decimalValue1=Enter new loop start sample (decimal): "
echo !decimalValue1!| findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo Invalid input! Must be a number between 0-4294967295
    goto :GetStart
)
if !decimalValue1! gtr 4294967295 (
    echo Invalid input! Must be less than or equal to 4294967295
    goto :GetStart
)

:GetEnd
set "decimalValue2="
set /p "decimalValue2=Enter new loop end sample (decimal): "
echo !decimalValue2!| findstr /r "^[0-9]*$" >nul
if errorlevel 1 (
    echo Invalid input! Must be a number between 0-4294967295
    goto :GetEnd
)
if !decimalValue2! gtr 4294967295 (
    echo Invalid input! Must be less than or equal to 4294967295
    goto :GetEnd
)

:: Get hex values
echo Computing hexadecimal values...
set "hexValue1=Unknown"
set "hexValue2=Unknown"
for /f "usebackq tokens=1,2 delims=," %%a in (`powershell -Command "$start = [uint32]::Parse('!decimalValue1!'); $end = [uint32]::Parse('!decimalValue2!'); $startHex = [System.BitConverter]::ToString([System.BitConverter]::GetBytes($start)).Replace('-',''); $endHex = [System.BitConverter]::ToString([System.BitConverter]::GetBytes($end)).Replace('-',''); Write-Output \"$startHex,$endHex\"" 2^>nul`) do (
    set "hexValue1=%%a"
    set "hexValue2=%%b"
)

:: Display what will be written
echo.
echo New values to write:
echo Loop start: !decimalValue1! samples [!hexValue1!]
echo Loop end: !decimalValue2! samples [!hexValue2!]
echo.

:: Backup the original file
echo Creating backup...
copy "!opusFile!" "!opusFile!.bak" >nul 2>&1
if errorlevel 1 (
    echo Error creating backup. Operation aborted.
    pause
    goto :DisplayMenu
)

:: Update the file with new loop points
echo Writing new values to file...
set "updateStatus=Error"
for /f "usebackq delims=" %%a in (`powershell -Command "try { $file = '!opusFile!'; $bytes = [System.IO.File]::ReadAllBytes($file); $startNum = [uint32]::Parse('!decimalValue1!'); $endNum = [uint32]::Parse('!decimalValue2!'); $startBytes = [System.BitConverter]::GetBytes($startNum); $endBytes = [System.BitConverter]::GetBytes($endNum); for($i=0; $i -lt 4; $i++) { $bytes[8+$i] = $startBytes[$i]; $bytes[12+$i] = $endBytes[$i]; } [System.IO.File]::WriteAllBytes($file, $bytes); Write-Output 'Success' } catch { Write-Output 'Error' }" 2^>nul`) do (
    set "updateStatus=%%a"
)

if not "!updateStatus!"=="Success" (
    echo Error writing to file. Please check if the file is writable.
    pause
    goto :DisplayMenu
)

:: Verify the changes
echo.
echo Verifying changes...
for /f "usebackq delims=" %%a in (`powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('!opusFile!'); $start = [System.BitConverter]::ToUInt32($bytes, 8); $end = [System.BitConverter]::ToUInt32($bytes, 12); $startHex = [System.BitConverter]::ToString($bytes[8..11]).Replace('-',''); $endHex = [System.BitConverter]::ToString($bytes[12..15]).Replace('-',''); Write-Output \"Updated loop start: $start samples [$startHex]\"; Write-Output \"Updated loop end: $end samples [$endHex]\"" 2^>nul`) do (
    echo %%a
)

echo.
echo Loop points updated successfully!
echo Backup saved as "!opusFile!.bak"
echo.
pause
goto :PrepareDisplay

:RenameFile
cls
echo Renaming file: "!displayName!"
echo.
echo Enter the new filename (without extension):
set /p "newName="
if "!newName!"=="" (
    echo No name entered. Renaming cancelled.
    pause
    goto :PrepareDisplay
)
set "newFileName=!newName!.opus"
for %%F in ("!opusFile!") do set "fileDir=%%~dpF"
set "newFilePath=!fileDir!!newFileName!"
if exist "!newFilePath!" (
    echo Error: File "!newFileName!" already exists in the directory.
    echo Please choose a different name.
    pause
    goto :RenameFile
)
echo Renaming "!displayName!" to "!newFileName!"...
move "!opusFile!" "!newFilePath!" >nul 2>&1
if errorlevel 1 (
    echo Error renaming file. Please check permissions.
    pause
    goto :PrepareDisplay
) else (
    echo File renamed successfully to "!newFileName!"
    set "opusFile=!newFilePath!"
    for %%F in ("!opusFile!") do set "displayName=%%~nxF"
    pause
    goto :PrepareDisplay
)

:Exit
echo.
echo Thank you for using Opus Header Editor by Handburger.
echo Exiting...
timeout /t 2 >nul
exit