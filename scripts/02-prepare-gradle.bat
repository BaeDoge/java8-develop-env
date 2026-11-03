@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "KIT_ROOT=%~dp0.."
for %%I in ("%KIT_ROOT%") do set "KIT_ROOT=%%~fI"
set "TOOLS_DIR=%KIT_ROOT%\tools"
set "DIST_DIR=%TOOLS_DIR%\distributions"
set "VERSION=7.0.2"
set "ZIP_NAME=gradle-%VERSION%-bin.zip"
set "ZIP_PATH=%DIST_DIR%\%ZIP_NAME%"
set "TEMP_PATH=%ZIP_PATH%.download"
set "INSTALL_DIR=%TOOLS_DIR%\gradle-%VERSION%"
set "URL=https://services.gradle.org/distributions/%ZIP_NAME%"

echo [Gradle 1/4] Checking CMD tools
where curl.exe >nul 2>nul
if errorlevel 1 (
  echo ERROR: curl.exe was not found.
  exit /b 1
)
where tar.exe >nul 2>nul
if errorlevel 1 (
  echo ERROR: tar.exe was not found. Windows 10 build 1803 or later is required.
  exit /b 1
)
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"

echo [Gradle 2/4] Checking Gradle ZIP
if not exist "%ZIP_PATH%" (
  if exist "%TEMP_PATH%" del /q "%TEMP_PATH%"
  echo Downloading %URL%
  curl.exe --fail --location --show-error --ssl-no-revoke --connect-timeout 45 --max-time 1800 --retry 5 --retry-delay 5 --output "%TEMP_PATH%" "%URL%"
  if errorlevel 1 (
    echo ERROR: Gradle download failed.
    if exist "%TEMP_PATH%" del /q "%TEMP_PATH%"
    exit /b 1
  )
  move /y "%TEMP_PATH%" "%ZIP_PATH%" >nul
  if errorlevel 1 (
    echo ERROR: Could not move Gradle ZIP into distributions.
    exit /b 1
  )
) else (
  echo Existing Gradle ZIP found. Reusing it.
)

echo [Gradle 3/4] Validating ZIP and calculating local SHA-256
tar.exe -tf "%ZIP_PATH%" >nul
if errorlevel 1 (
  echo ERROR: Gradle ZIP is invalid. Delete "%ZIP_PATH%" and retry.
  exit /b 1
)
set "GRADLE_SHA="
for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%ZIP_PATH%" SHA256') do (
  if not defined GRADLE_SHA set "GRADLE_SHA=%%H"
)
set "GRADLE_SHA=!GRADLE_SHA: =!"
>"%ZIP_PATH%.sha256" echo !GRADLE_SHA!  %ZIP_NAME%
echo Local SHA-256: !GRADLE_SHA!
echo NOTE: This local hash is not an official publisher checksum verification.

echo [Gradle 4/4] Extracting Gradle
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
tar.exe -xf "%ZIP_PATH%" -C "%TOOLS_DIR%"
if errorlevel 1 (
  echo ERROR: Gradle ZIP extraction failed.
  exit /b 1
)
if not exist "%INSTALL_DIR%\bin\gradle.bat" (
  echo ERROR: gradle.bat was not found at "%INSTALL_DIR%\bin\gradle.bat".
  exit /b 1
)
echo Gradle prepared: %INSTALL_DIR%
exit /b 0
