@echo off
setlocal EnableExtensions
set "KIT_ROOT=%~dp0"
pushd "%KIT_ROOT%"

echo ============================================================
echo Java 8 + Gradle 7.0.2 offline preparation kit
echo CMD only - no Node.js, npm, or PowerShell
echo ============================================================
echo.

call "scripts\01-prepare-jdk8.bat"
if errorlevel 1 goto :failed

call "scripts\02-prepare-gradle.bat"
if errorlevel 1 goto :failed

call "scripts\03-register-environment.bat"
if errorlevel 1 goto :failed

rem setx writes persistent values but does not update this CMD process.
set "JAVA_HOME=%KIT_ROOT%\tools\jdk8"
for /d %%D in ("%KIT_ROOT%\tools\jdk8\*") do if exist "%%~fD\bin\javac.exe" set "JAVA_HOME=%%~fD"
set "GRADLE_HOME=%KIT_ROOT%\tools\gradle-7.0.2"
set "GRADLE_USER_HOME=%KIT_ROOT%\cache\gradle"
set "PATH=%JAVA_HOME%\bin;%GRADLE_HOME%\bin;%PATH%"

call "scripts\04-verify-environment.bat"
if errorlevel 1 goto :failed

echo.
echo Setup completed.
echo Add %%JAVA_HOME%%\bin and %%GRADLE_HOME%%\bin to your user Path first.
echo Then close this CMD window and open a new CMD window to use the
echo permanently registered environment variables everywhere.
popd
exit /b 0

:failed
echo.
echo Setup failed. Read the error message above.
popd
exit /b 1
