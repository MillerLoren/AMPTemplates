@echo off

:: Define paths
set "modlist_file=Valheim\896660\modlist.txt"
set "base_url=https://thunderstore.io/package/download"
set "base_dir=Valheim\896660\BepInEx"
set "plugins_dir=%base_dir%\plugins"

:: Ensure modlist exists
if not exist "%modlist_file%" (
    echo Modlist file not found: %modlist_file%
    exit /b 1
)

:: Set flags
set "whitelist_flag=%1"
set "greylist_flag=%2"

:: Process each mod in the modlist
for /f "usebackq delims=" %%L in ("%modlist_file%") do (
    set "line=%%L"
    call :process_mod "%%L"
)
goto :done

:process_mod
setlocal enabledelayedexpansion
set "mod=%~1"
if "%mod%"=="" (endlocal & goto :eof)

for /f "tokens=1-3 delims=-" %%a in ("%mod%") do (
    set "author=%%a"
    set "package=%%b"
    set "version=%%c"
)

set "plugin_dir=%plugins_dir%\%author%-%package%"

:: Check if plugin already exists and version matches
if exist "%plugin_dir%\manifest.json" (
    for /f "delims=" %%v in ('jq -r .version_number "%plugin_dir%\manifest.json"') do set "existing_version=%%v"
    if "%existing_version%"=="%version%" (
        echo %package% is already up-to-date. Skipping download.
        endlocal & goto :eof
    )
)

:: Download and extract plugin
echo Downloading %package% (%version%)
mkdir "%plugin_dir%"
set "download_url=%base_url%/%author%/%package%/%version%/"
wget -q -O plugin.zip "%download_url%"
7z x plugin.zip -o"%plugin_dir%" >nul
if exist plugin.zip del plugin.zip
endlocal & goto :eof

:done
:: Process whitelist
if /i "%whitelist_flag%"=="true" call :process_list "mod_whitelist.txt" "AzuAntiCheat_Whitelist"

:: Process greylist
if /i "%greylist_flag%"=="true" call :process_list "mod_greylist.txt" "AzuAntiCheat_Greylist"

goto :cleanup

:process_list
set "list_file=Valheim\896660\%~1"
set "list_dir=%base_dir%\config\%~2"

for /f "usebackq delims=" %%L in ("%list_file%") do (
    set "line=%%L"
    call :copy_plugin "%%L" "%list_dir%"
)
endlocal & goto :eof

:copy_plugin
setlocal enabledelayedexpansion
set "mod=%~1"
set "target_dir=%~2"
if "%mod%"=="" (endlocal & goto :eof)

for /f "tokens=1-3 delims=-" %%a in ("%mod%") do (
    set "author=%%a"
    set "package=%%b"
    set "version=%%c"
)

set "plugin_dir=%plugins_dir%\%author%-%package%"
set "plugin_target_dir=%target_dir%\%author%-%package%"

:: Check if plugin already exists and version matches
if exist "%plugin_target_dir%\manifest.json" (
    for /f "delims=" %%v in ('jq -r .version_number "%plugin_target_dir%\manifest.json"') do set "existing_version=%%v"
    if "%existing_version%"=="%version%" (
        echo %package% is already up-to-date. Skipping copy.
        endlocal & goto :eof
    )
)

:: Copy plugin
echo Copying %package% (%version%)
if exist "%plugin_target_dir%" rmdir /s /q "%plugin_target_dir%"
mkdir "%plugin_target_dir%"
xcopy /e /q "%plugin_dir%\*" "%plugin_target_dir%\"
endlocal & goto :eof

:cleanup
:: Clean up temporary files
echo All mods processed successfully.
exit /b 0
