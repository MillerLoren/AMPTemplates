### Windows Batch Script ###
@echo off

:: Define paths
set modlist_file=Valheim\896660\modlist.txt
set base_url=https://thunderstore.io/package/download
set base_dir=Valheim\896660\BepInEx
set plugins_dir=%base_dir%\plugins

:: Ensure modlist exists
if not exist "%modlist_file%" (
    echo Modlist file not found: %modlist_file%
    exit /b 1
)

:: Process each mod in the modlist
for /f "delims=" %%A in (%modlist_file%) do (
    set "mod=%%A"
    if "!mod!"=="" (
        goto :continue
    )

    for /f "tokens=1-3 delims=-" %%B in ("!mod!") do (
        set "author=%%B"
        set "package=%%C"
        set "version=%%D"
    )

    set "plugin_dir=%plugins_dir%\!author!-!package!"

    :: Check if plugin already exists and version matches
    if exist "!plugin_dir!\manifest.json" (
        for /f "delims=" %%E in ('powershell -Command "(Get-Content '!plugin_dir!\\manifest.json' | ConvertFrom-Json).version_number"') do (
            set "existing_version=%%E"
        )
        if "!existing_version!"=="!version!" (
            echo !package! is already up-to-date. Skipping download.
            goto :continue
        )
    )

    echo Downloading !package! (!version!)
    mkdir "!plugin_dir!" 2>nul

    :: Download and extract plugin
    set "download_url=%base_url%/!author!/!package!/!version!/"
    powershell -Command "(New-Object Net.WebClient).DownloadFile('!download_url!', 'plugin.zip')"
    powershell -Command "Expand-Archive -Path 'plugin.zip' -DestinationPath '!plugin_dir!' -Force"
    del plugin.zip

    :continue
)

echo All mods processed successfully.
