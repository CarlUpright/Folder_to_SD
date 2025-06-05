@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Folder to SD Card Copier

:start
echo.
echo ==========================================
echo        Folder to SD Card Copier
echo ==========================================
echo.

REM Ask for source folder
set /p "source_folder=Enter source folder path: "

REM Remove quotes if user added them
set "source_folder=%source_folder:"=%"

if not exist "%source_folder%" (
    echo Error: Source folder does not exist!
    echo Tried: "%source_folder%"
    pause
    goto start
)

:select_sd
echo.
echo Available removable drives:
echo.

REM List removable drives and their capacities
set drive_count=0
for /f "skip=1 tokens=1,2,3" %%a in ('wmic logicaldisk where "DriveType=2" get DeviceID^,Size^,VolumeName') do (
    if "%%a" neq "" if "%%b" neq "" (
        set /a drive_count+=1
        set "drive_!drive_count!=%%a"
        set "size_!drive_count!=%%b"
        set "label_!drive_count!=%%c"
        
        REM Convert size to GB for display (using PowerShell for large numbers)
        for /f %%x in ('powershell -command "[math]::Round(%%b/1GB,2)"') do set "size_gb=%%x"
        echo !drive_count!. %%a - !size_gb! GB - %%c
    )
)

if %drive_count%==0 (
    echo No removable drives found!
    echo Please insert an SD card and press any key to refresh...
    pause >nul
    goto select_sd
)

echo.
set /p "drive_choice=Select drive number (1-%drive_count%): "

REM Validate choice
if %drive_choice% lss 1 goto select_sd
if %drive_choice% gtr %drive_count% goto select_sd

REM Get selected drive info
set "selected_drive=!drive_%drive_choice%!"
set "selected_size=!size_%drive_choice%!"
set "output_folder=%selected_drive%\"

echo.
echo Selected: %selected_drive% (!size_%drive_choice%! bytes)
echo Source: %source_folder%
echo Destination: %output_folder%
echo.

REM Ask about ejecting after copy
set /p "eject_after=Export device after copying? (Y/n): "
if /i "%eject_after%"=="" set "eject_after=Y"
if /i "%eject_after%"=="n" set "eject_after=N"

REM Ask about loop operation
set /p "loop_operation=Loop operation? (Y/n): "
if /i "%loop_operation%"=="" set "loop_operation=Y"
if /i "%loop_operation%"=="n" set "loop_operation=N"

:copy_operation
echo.
echo Starting robocopy operation...
echo.

REM Set temp variables for robocopy to avoid delayed expansion issues
set "temp_source=%source_folder%"
set "temp_dest=!output_folder!"

echo Source: "%temp_source%"
echo Destination: %temp_dest%
echo.

REM Execute the exact robocopy command (no quotes around destination since it's just a drive letter)
robocopy "%temp_source%" %temp_dest% /MIR /COPY:DAT /DCOPY:T /R:3 /W:5

REM Check robocopy exit code
if %errorlevel% gtr 7 (
    echo.
    echo Error: Robocopy failed with error code %errorlevel%
    pause
    exit /b %errorlevel%
)

echo.
echo Copy operation completed successfully!

REM Eject if requested
if /i "%eject_after%"=="Y" (
    echo.
    echo Getting current SD card ID...
    
    REM Get the volume serial number (unique ID) of current card
    for /f "skip=1 tokens=2" %%a in ('wmic logicaldisk where "DeviceID='!selected_drive!'" get VolumeSerialNumber') do (
        if "%%a" neq "" (
            set "current_card_id=%%a"
            goto got_id
        )
    )
    :got_id
    echo Current card ID: !current_card_id!
    
    echo Ejecting !selected_drive!...
    powershell -command "(New-Object -comObject Shell.Application).Namespace(17).ParseName('!selected_drive!').InvokeVerb('Eject')"
    echo Device ejected safely.
)

REM Loop if requested
if /i "%loop_operation%"=="Y" (
    if /i "%eject_after%"=="Y" (
        echo.
        echo Waiting for card to be removed...
        echo Press Ctrl+C to exit
        
        REM Wait for card to be actually removed
        :wait_for_removal
        timeout /t 1 /nobreak >nul 2>&1
        for /f "skip=1 tokens=1" %%a in ('wmic logicaldisk where "DeviceID='!selected_drive!'" get DeviceID 2^>nul') do (
            if "%%a"=="!selected_drive!" (
                goto wait_for_removal
            )
        )
        
        echo Card removed. Waiting for new SD card...
        
        REM Wait for a new card to be inserted
        :wait_for_new_card
        timeout /t 1 /nobreak >nul 2>&1
        
        REM Check if the same drive letter is available again
        for /f "skip=1 tokens=1,2,3" %%a in ('wmic logicaldisk where "DeviceID='!selected_drive!'" get DeviceID^,Size^,VolumeSerialNumber 2^>nul') do (
            if "%%a"=="!selected_drive!" (
                REM Check if it's a different card (different ID)
                if "%%c" neq "!current_card_id!" (
                    REM Check if size is the same
                    if "%%b"=="!selected_size!" (
                        echo.
                        echo New SD card detected with same capacity. Starting copy operation...
                        goto copy_operation
                    ) else (
                        echo.
                        echo Warning: Different capacity SD card detected!
                        echo Previous: !selected_size! bytes
                        echo Current:  %%b bytes
                        set /p "continue_different=Do you want to continue anyway? (y/N): "
                        if /i "!continue_different!"=="y" (
                            set "selected_size=%%b"
                            goto copy_operation
                        ) else (
                            echo Operation cancelled. Waiting for correct SD card...
                        )
                    )
                ) else (
                    echo Same card detected, waiting for a different one...
                )
            )
        )
        goto wait_for_new_card
    ) else (
        echo.
        echo Loop operation selected but auto-eject disabled.
        echo Please manually prepare next operation.
        pause
        goto start
    )
) else (
    echo.
    echo Operation completed.
    pause
)

exit /b 0