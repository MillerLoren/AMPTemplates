@echo off

:: Define paths
set "modlist_file=Valheim\896660\modlist.txt"
set "base_url=https://thunderstore.io/package/download"
set "base_dir=Valheim\896660\BepInEx"
set "plugins_dir=%base_dir%\plugins"
set "whitelist_file=Valheim\896660\mod_whitelist.txt"
set "greylist_file=Valheim\896660\mod_greylist.txt"
set "whitelist_dir=%base_dir%\config\AzuAntiCheat_Whitelist"
set "greylist_dir=%base_dir%\config\AzuAntiCheat_Greylist"

:: Ensure modlist exists
if not exist "%modlist_file%" (
    echo Modlist file not found: %modlist_file%
    exit /b 1
)

:: Set the flags for whitelist and greylist. First argument passed is the flag for whitelist and second is flag for greylist
set "whitelist_flag=%~1"
set "greylist_flag=%~2"

:: Process each mod in the modlist
for /f "usebackq tokens=*" %%m in ("%modlist_file%") do (
    set "mod=%%m"
    if not defined mod (
        goto :continue
    )
    for /f "tokens=1-3 delims=-" %%a in ("%%m") do (
        set "author=%%a"
        set "package=%%b"
        set "version=%%c"
    )
    set "plugin_dir=%plugins_dir%\%author%-%package%"
    
    if exist "%plugin_dir%\manifest.json" (
        for /f "usebackq tokens=*" %%v in (`jq -r ".version_number" "%plugin_dir%\manifest.json"`) do (
            set "existing_version=%%v"
        )
        if "%existing_version%" == "%version%" (
            echo %package% is already up-to-date. Skipping download.
            goto :continue
        )
    )
    
    echo Downloading %package% (%version%)
    mkdir "%plugin_dir%" >nul 2>&1
    set "download_url=%base_url%/%author%/%package%/%version%/"
    curl -s -o plugin.zip "%download_url%"
    tar -xf plugin.zip -C "%plugin_dir%"
    del /q plugin.zip
    rd /s /q "%plugin_dir%\config" 2>nul
    
    :continue
)

:: Handle whitelist
if "%whitelist_flag%" == "true" (
    for /f "usebackq tokens=*" %%m in ("%whitelist_file%") do (
        set "mod=%%m"
        if not defined mod (
            goto :wcontinue
        )
        for /f "tokens=1-3 delims=-" %%a in ("%%m") do (
            set "author=%%a"
            set "package=%%b"
            set "version=%%c"
        )
        set "plugin_whitelist_dir=%whitelist_dir%\%author%-%package%"
        if exist "%plugin_whitelist_dir%\manifest.json" (
            for /f "usebackq tokens=*" %%v in (`jq -r ".version_number" "%plugin_whitelist_dir%\manifest.json"`) do (
                set "existing_version=%%v"
            )
            if "%existing_version%" == "%version%" (
                echo %package% is already up-to-date. Skipping copy.
                goto :wcontinue
            )
        )
        echo Copying %package% (%version%)
        rd /s /q "%plugin_whitelist_dir%" 2>nul
        mkdir "%plugin_whitelist_dir%" >nul 2>&1
        xcopy /e /q "%plugins_dir%\%author%-%package%\*" "%plugin_whitelist_dir%\"
        :wcontinue
    )
)

:: Handle greylist
if "%greylist_flag%" == "true" (
    for /f "usebackq tokens=*" %%m in ("%greylist_file%") do (
        set "mod=%%m"
        if not defined mod (
            goto :gcontinue
        )
        for /f "tokens=1-3 delims=-" %%a in ("%%m") do (
            set "author=%%a"
            set "package=%%b"
            set "version=%%c"
        )
        set "plugin_greylist_dir=%greylist_dir%\%author%-%package%"
        if exist "%plugin_greylist_dir%\manifest.json" (
            for /f "usebackq tokens=*" %%v in (`jq -r ".version_number" "%plugin_greylist_dir%\manifest.json"`) do (
                set "existing_version=%%v"
            )
            if "%existing_version%" == "%version%" (
                echo %package% is already up-to-date. Skipping copy.
                goto :gcontinue
            )
        )
        echo Copying %package% (%version%)
        rd /s /q "%plugin_greylist_dir%" 2>nul
        mkdir "%plugin_greylist_dir%" >nul 2>&1
        xcopy /e /q "%plugins_dir%\%author%-%package%\*" "%plugin_greylist_dir%\"
        :gcontinue
    )
)

:: Remove outdated plugins
for %%d in ("%whitelist_dir%" "%greylist_dir%" "%plugins_dir%") do (
    for /d %%p in ("%%d\*") do (
        set "plugin=%%p"
        for /f "tokens=1-2 delims=-" %%a in ("%%~npxp") do (
            set "author=%%a"
            set "package=%%b"
        )
        findstr /x /i "%author%-%package%" "%modlist_file%" >nul 2>&1 || (
            echo Removing %author%-%package%
            rd /s /q "%%p"
        )
    )
)

echo All mods processed successfully.
