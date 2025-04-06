@echo off
setlocal enabledelayedexpansion

:: Check for certUtil
where certutil >nul 2>&1 || (
    echo Error: certUtil not found. Required for SHA-256 hashing.
    pause
    exit /b 1
)

:: Configure settings
set "hash_file=hashes.txt"
if "%~1"=="" (set "target_dir=.") else (set "target_dir=%~1")

:: Verify hash file exists
if not exist "%hash_file%" (
    echo Error: Hash file "%hash_file%" not found.
    pause
    exit /b 1
)

:: Initialize counters
set error_count=0
set files_checked=0
set files_missing=0

echo Verifying files against "%hash_file%"
echo ================================

pushd "%target_dir%" 2>nul || (
    echo Error: Cannot access directory "%target_dir%"
    pause
    exit /b 1
)

:: Create temporary file for found files
set "temp_file=%temp%\found_files.tmp"
if exist "%temp_file%" del "%temp_file%"

for /f "usebackq tokens=1,* delims=:" %%a in ("%hash_file%") do (
    set "filename=%%a"
    set "stored_hash=%%b"
    
    :: Clean values
    set "filename=!filename:"=!"
    set "filename=!filename: =!"
    set "stored_hash=!stored_hash: =!"
    
    if not "!filename!"=="" if not "!stored_hash!"=="" (
        set file_found=0
        
        :: Check if we already processed this file
        findstr /i /c:"!filename!" "%temp_file%" >nul 2>&1
        if errorlevel 1 (
            <nul set /p "=Checking - !filename! ..."
            
            :: Search for the file (non-recursive first)
            if exist "!filename!" (
                set "file_path=!filename!"
            ) else (
                :: If not found, try recursive search
                for /r %%F in ("!filename!") do (
                    if exist "%%F" (
                        set "file_path=%%F"
                        goto :verify_hash
                    )
                )
            )
            
            if exist "!file_path!" (
                :verify_hash
                set /a files_checked+=1
                set file_found=1
                
                :: Mark file as processed
                echo !filename!>>"%temp_file%"
                
                :: Get current file hash
                for /f "delims=" %%H in ('certutil -hashfile "!file_path!" SHA256 ^| find /v "hash" ^| find /v "CertUtil"') do (
                    set "current_hash=%%H"
                    set "current_hash=!current_hash: =!"
                    
                    :: Compare hashes (case-insensitive)
                    if /i "!current_hash!"=="!stored_hash!" (
                        echo OK
                    ) else (
                        echo FAIL
                        echo Expected: !stored_hash!
                        echo Actual:   !current_hash!
                        set /a error_count+=1
                    )
                )
            )
            
            if !file_found! equ 0 (
                echo MISSING
                set /a files_missing+=1
            )
        )
    )
)

:: Clean up
if exist "%temp_file%" del "%temp_file%"
popd

echo ================================
echo Summary:
echo Files checked: !files_checked!
echo Failed checks: !error_count!
echo Missing files: !files_missing!

if !error_count! equ 0 (
    if !files_missing! equ 0 (
        echo All files verified successfully.
    ) else (
        echo All found files match, but !files_missing! files missing.
    )
) else (
    echo Verification completed with !error_count! failures.
)
pause