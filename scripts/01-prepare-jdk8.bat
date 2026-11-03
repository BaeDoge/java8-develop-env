@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "KIT_ROOT=%~dp0.."
for %%I in ("%KIT_ROOT%") do set "KIT_ROOT=%%~fI"
set "TOOLS_DIR=%KIT_ROOT%\tools"
set "DIST_DIR=%TOOLS_DIR%\distributions"
set "JDK_DIR=%TOOLS_DIR%\jdk8"
set "JDK_ZIP=%DIST_DIR%\zulu8-windows-x86-jdk.zip"
set "JDK_TEMP=%JDK_ZIP%.download"
set "META=%DIST_DIR%\zulu8-windows-x86-jdk.json"
set "META_URL=https://api.azul.com/metadata/v1/zulu/packages/?java_version=8^&os=windows^&arch=xi686^&java_package_type=jdk^&archive_type=zip^&release_status=ga^&availability_types=CA^&latest=true^&include_fields=download_url,sha256_hash^&page_size=1"

echo [JDK 1/5] Checking CMD download and archive tools
where curl.exe >nul 2>nul
if errorlevel 1 (
  echo ERROR: curl.exe was not found. Windows 10 curl.exe or an approved download tool is required.
  exit /b 1
)
where tar.exe >nul 2>nul
if errorlevel 1 (
  echo ERROR: tar.exe was not found. Windows 10 build 1803 or later is required for ZIP extraction.
  exit /b 1
)

if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"

if exist "%JDK_DIR%" (
  for /d %%D in ("%JDK_DIR%\*") do (
    if exist "%%~fD\bin\javac.exe" (
      echo Existing JDK found: %%~fD
      exit /b 0
    )
  )
  if exist "%JDK_DIR%\bin\javac.exe" (
    echo Existing JDK found: %JDK_DIR%
    exit /b 0
  )
)

echo [JDK 2/5] Retrieving the latest Azul Zulu Java 8 x86 JDK package metadata
curl.exe --fail --location --show-error --ssl-no-revoke --connect-timeout 45 --max-time 120 --retry 3 --retry-delay 3 --output "%META%" "%META_URL%"
if errorlevel 1 (
  echo ERROR: Could not retrieve JDK metadata from api.azul.com.
  exit /b 1
)

set "JDK_URL="
set "EXPECTED_SHA="
for /f "tokens=2,* delims=:" %%A in ('findstr /i "download_url" "%META%"') do (
  set "JDK_URL=%%B"
  goto :url_found
)
:url_found
for /f "tokens=2,* delims=:" %%A in ('findstr /i "sha256_hash" "%META%"') do (
  set "EXPECTED_SHA=%%B"
  goto :hash_found
)
:hash_found
set "JDK_URL=!JDK_URL: =!"
set "JDK_URL=!JDK_URL:"=!"
set "JDK_URL=!JDK_URL:,=!"
set "EXPECTED_SHA=!EXPECTED_SHA: =!"
set "EXPECTED_SHA=!EXPECTED_SHA:"=!"
set "EXPECTED_SHA=!EXPECTED_SHA:,=!"

if not defined JDK_URL (
  echo ERROR: No JDK download URL was returned by Azul metadata API.
  type "%META%"
  exit /b 1
)
if not defined EXPECTED_SHA (
  echo ERROR: No SHA-256 checksum was returned by Azul metadata API.
  type "%META%"
  exit /b 1
)
echo Selected package URL: !JDK_URL!

echo [JDK 3/5] Downloading JDK ZIP
if not exist "%JDK_ZIP%" (
  if exist "%JDK_TEMP%" del /q "%JDK_TEMP%"
  curl.exe --fail --location --show-error --ssl-no-revoke --connect-timeout 45 --max-time 1800 --retry 5 --retry-delay 5 --output "%JDK_TEMP%" "!JDK_URL!"
  if errorlevel 1 (
    echo ERROR: JDK download failed.
    if exist "%JDK_TEMP%" del /q "%JDK_TEMP%"
    exit /b 1
  )
  move /y "%JDK_TEMP%" "%JDK_ZIP%" >nul
  if errorlevel 1 (
    echo ERROR: Could not move the downloaded JDK ZIP into distributions.
    exit /b 1
  )
) else (
  echo Existing JDK ZIP found. Checking its checksum.
)

echo [JDK 4/5] Verifying official SHA-256 checksum
set "ACTUAL_SHA="
for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%JDK_ZIP%" SHA256') do (
  if not defined ACTUAL_SHA set "ACTUAL_SHA=%%H"
)
set "ACTUAL_SHA=!ACTUAL_SHA: =!"
if /i not "!ACTUAL_SHA!"=="!EXPECTED_SHA!" (
  echo ERROR: JDK ZIP SHA-256 does not match Azul metadata.
  echo Expected: !EXPECTED_SHA!
  echo Actual:   !ACTUAL_SHA!
  echo Delete "%JDK_ZIP%" and run this script again.
  exit /b 1
)
echo JDK SHA-256 verified: !ACTUAL_SHA!

echo [JDK 5/5] Extracting JDK
if exist "%JDK_DIR%" rmdir /s /q "%JDK_DIR%"
mkdir "%JDK_DIR%"
tar.exe -xf "%JDK_ZIP%" -C "%JDK_DIR%"
if errorlevel 1 (
  echo ERROR: JDK ZIP extraction failed.
  exit /b 1
)

set "JDK_HOME="
if exist "%JDK_DIR%\bin\javac.exe" set "JDK_HOME=%JDK_DIR%"
for /d %%D in ("%JDK_DIR%\*") do (
  if exist "%%~fD\bin\javac.exe" set "JDK_HOME=%%~fD"
)
if not defined JDK_HOME (
  echo ERROR: javac.exe was not found after extraction.
  exit /b 1
)
echo JDK prepared: !JDK_HOME!
"!JDK_HOME!\bin\java.exe" -version
"!JDK_HOME!\bin\javac.exe" -version
exit /b 0
