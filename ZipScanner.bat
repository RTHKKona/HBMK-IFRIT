@echo off
setlocal

REM Check if a file is dropped onto the script
if "%~1"=="" (
    echo Drag and drop a .zip file onto this script.
    pause
    exit /b
)

REM Set the path to the zip file
set "zipfile=%~1"

REM Set the output text file name
set "outputfile=%~dpn1.txt"

REM Use PowerShell to list the contents of the zip file
powershell -Command "& { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::OpenRead('%zipfile%').Entries.FullName | Out-File '%outputfile%' }"

echo File list saved to %outputfile%
pause