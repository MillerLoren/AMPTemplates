@echo off

REM Define paths
set "modlist_file=Valheim\896660\modlist.txt"
set "base_url=https://thunderstore.io/package/download"
set "base_dir=Valheim\896660\BepInEx"
set "plugins_dir=%base_dir%\plugins"

REM Ensure modlist exists
if not exist "%modlist_file%" (
    echo Modlist file not found: %modlist_file%
    exit /b 1
)

REM Set the flags for whitelist and greylist
set "whitelist_flag=%1"
set "greylist_flag=%2"

REM Process each mod in the modlist
for /f "tokens=* delims=" %%m in (%modlist_file%) do (
    set "mod=%%m"
    call :process_mod
)

goto :process_whitelist

:process_mod
if "%mod%"=="" goto :eof
for /f "tokens=1-3 delims=-" %%a in ("%mod%") do (
    set "author=%%a"
    set "package=%%b"
    set "version=%%c"
)
set "plugin_dir=%plugins_dir%\%author%-%package%"

if exist "%plugin_dir%\manifest.json" (
    for /f "delims=" %%v in ('jq -r ".version_number" "%plugin_dir%\manifest.json"') do set "existing_version=%%v"
    if "%existing_version%"=="%version%" (
        echo %package% is already up-to-date. Skipping download.
        goto :eof
    )
)

echo Downloading %package% (%version%)
mkdir "%plugin_dir%" >nul 2>&1
set "download_url=%base_url%/%author%/%package%/%version%/"
wget -q -O plugin.zip "%download_url%"
unzip -o plugin.zip -d "%plugin_dir%"
del plugin.zip
rmdir /s /q "%plugin_dir%\config" 2>nul

goto :eof

:process_whitelist
set "whitelist_file=Valheim\896660\mod_whitelist.txt"
set "whitelist_dir=%base_dir%\config\AzuAntiCheat_Whitelist"

if /i "%whitelist_flag%"=="true" (
    for /f "tokens=* delims=" %%m in (%whitelist_file%) do (
        set "mod=%%m"
        call :copy_to_whitelist
    )
)

goto :process_greylist

:copy_to_whitelist
if "%mod%"=="" goto :eof
for /f "tokens=1-3 delims=-" %%a in ("%mod%") do (
    set "author=%%a"
    set "package=%%b"
    set "version=%%c"
)
set "plugin_whitelist_dir=%whitelist_dir%\%author%-%package%"

if exist "%plugin_whitelist_dir%\manifest.json" (
    for /f "delims=" %%v in ('jq -r ".version_number" "%plugin_whitelist_dir%\manifest.json"') do set "existing_version=%%v"
    if "%existing_version%"=="%version%" (
        echo %package% is already up-to-date. Skipping copy.
        goto :eof
    )
)

echo Copying %package% (%version%)
rmdir /s /q "%plugin_whitelist_dir%" 2>nul
mkdir "%plugin_whitelist_dir%" >nul 2>&1
xcopy "%plugins_dir%\%author%-%package%\*" "%plugin_whitelist_dir%\" /e /q /y

goto :eof

:process_greylist
set "greylist_file=Valheim\896660\mod_greylist.txt"
set "greylist_dir=%base_dir%\config\AzuAntiCheat_Greylist"

if /i "%greylist_flag%"=="true" (
    for /f "tokens=* delims=" %%m in (%greylist_file%) do (
        set "mod=%%m"
        call :copy_to_greylist
    )
)

goto :cleanup

:copy_to_greylist
if "%mod%"=="" goto :eof
for /f "tokens=1-3 delims=-" %%a in ("%mod%") do (
    set "author=%%a"
    set "package=%%b"
    set "version=%%c"
)
set "plugin_greylist_dir=%greylist_dir%\%author%-%package%"

if exist "%plugin_greylist_dir%\manifest.json" (
    for /f "delims=" %%v in ('jq -r ".version_number" "%plugin_greylist_dir%\manifest.json"') do set "existing_version=%%v"
    if "%existing_version%"=="%version%" (
        echo %package% is already up-to-date. Skipping copy.
        goto :eof
    )
)

echo Copying %package% (%version%)
rmdir /s /q "%plugin_greylist_dir%" 2>nul
mkdir "%plugin_greylist_dir%" >nul 2>&1
xcopy "%plugins_dir%\%author%-%package%\*" "%plugin_greylist_dir%\" /e /q /y

goto :eof

:cleanup
echo All mods processed successfully.
exit /b