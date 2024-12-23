### Windows Batch Script ###
@echo off

:: Ensure script exits on errors
setlocal enabledelayedexpansion

:: Check for input parameter
if "%~1"=="" (
    echo Usage: %~nx0 ^<package-name^>
    exit /b 1
)

:: Parse the input parameter
for /f "tokens=1-3 delims=-" %%A in ("%~1") do (
    set author=%%A
    set package=%%B
    set version=%%C
)

:: Define base paths and URLs
set api_url=https://thunderstore.io/api/experimental/package/%author%/%package%/%version%/
set base_dir=Valheim\896660\BepInEx
set config_dir=%base_dir%\config
set plugins_dir=%base_dir%\plugins

:: Create necessary directories
mkdir "%config_dir%" 2>nul
mkdir "%plugins_dir%" 2>nul

:: Fetch package data using the API
echo Fetching package data from %api_url%...
for /f "delims=" %%D in ('powershell -Command "(Invoke-RestMethod -Uri '%api_url%').full_version.download_url"') do (
    set main_download_url=%%D
)

:: Download and extract main package
echo Downloading main package from %main_download_url%...
powershell -Command "(New-Object Net.WebClient).DownloadFile('%main_download_url%', 'main_package.zip')"
powershell -Command "Expand-Archive -Path 'main_package.zip' -DestinationPath 'temp_main_package' -Force"
del main_package.zip

:: Merge the config folder
xcopy /E /I /Q /Y temp_main_package\config\* "%config_dir%" 2>nul
rmdir /S /Q temp_main_package

:: Remove existing plugins folder and recreate it
rmdir /S /Q "%plugins_dir%"
mkdir "%plugins_dir%"

:: Process dependencies
echo Processing dependencies...
for /f "delims=" %%D in ('powershell -Command "(Invoke-RestMethod -Uri '%api_url%').full_version.dependencies"') do (
    for /f "tokens=1-3 delims=-" %%A in ("%%D") do (
        set dep_author=%%A
        set dep_package=%%B
        set dep_version=%%C
    )
    
    set dep_api_url=https://thunderstore.io/api/experimental/package/%dep_author%/%dep_package%/%dep_version%/
    echo Fetching dependency data from %dep_api_url%...
    for /f "delims=" %%E in ('powershell -Command "(Invoke-RestMethod -Uri '%dep_api_url%').full_version.download_url"') do (
        set dep_download_url=%%E
    )

    echo Downloading dependency: %dep_author%-%dep_package%-%dep_version% (%dep_download_url%)
    set dep_plugin_dir=%plugins_dir%\%dep_package%
    mkdir "%dep_plugin_dir%" 2>nul

    powershell -Command "(New-Object Net.WebClient).DownloadFile('%dep_download_url%', 'dependency.zip')"
    powershell -Command "Expand-Archive -Path 'dependency.zip' -DestinationPath '%dep_plugin_dir%' -Force"
    del dependency.zip
)

echo Done!
