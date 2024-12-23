# Clean up temporary files
rm -rf /tmp/main_package

echo "Done!"

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

set base_url=https://thunderstore.io/package/download
set download_url=%base_url%/%author%/%package%/%version%/

:: Define paths
set base_dir=Valheim\896660\BepInEx
set config_dir=%base_dir%\config
set plugins_dir=%base_dir%\plugins

:: Create necessary directories
mkdir "%config_dir%" 2>nul
mkdir "%plugins_dir%" 2>nul

:: Download and extract main package
echo Downloading %download_url%...
powershell -Command "(New-Object Net.WebClient).DownloadFile('%download_url%', 'main_package.zip')"
powershell -Command "Expand-Archive -Path 'main_package.zip' -DestinationPath 'temp_main_package' -Force"
del main_package.zip

:: Merge the config folder
xcopy /E /I /Q /Y temp_main_package\config\* "%config_dir%" 2>nul

:: Remove existing plugins folder and recreate it
rmdir /S /Q "%plugins_dir%"
mkdir "%plugins_dir%"

:: Read and process dependencies from manifest.json
set manifest_path=temp_main_package\manifest.json
echo Reading dependencies from %manifest_path%...

if exist "%manifest_path%" (
    for /f "delims=" %%D in ('powershell -Command "(Get-Content '%manifest_path%' | ConvertFrom-Json).dependencies"') do (
        set dep=%%D
        for /f "tokens=1-3 delims=-" %%A in ("!dep!") do (
            set dep_author=%%A
            set dep_package=%%B
            set dep_version=%%C
        )

        set dep_url=%base_url%/!dep_author!/!dep_package!/!dep_version!/
        echo Downloading dependency: !dep! (!dep_url!)

        set dep_plugin_dir=%plugins_dir%\!dep_package!
        mkdir "!dep_plugin_dir!" 2>nul

        powershell -Command "(New-Object Net.WebClient).DownloadFile('!dep_url!', 'dependency.zip')"
        powershell -Command "Expand-Archive -Path 'dependency.zip' -DestinationPath '!dep_plugin_dir!' -Force"
        del dependency.zip
    )
) else (
    echo manifest.json not found or no dependencies listed.
)

:: Clean up temporary files
rmdir /S /Q temp_main_package

echo Done!