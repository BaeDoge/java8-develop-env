@echo off
setlocal EnableExtensions
set "KIT_ROOT=%~dp0.."
for %%I in ("%KIT_ROOT%") do set "KIT_ROOT=%%~fI"
set "JDK_DIR=%KIT_ROOT%\tools\jdk8"
set "JAVA_HOME="
if exist "%JDK_DIR%\bin\javac.exe" set "JAVA_HOME=%JDK_DIR%"
for /d %%D in ("%JDK_DIR%\*") do if exist "%%~fD\bin\javac.exe" set "JAVA_HOME=%%~fD"
if not defined JAVA_HOME (echo ERROR: JDK not found. Run 01-prepare-jdk8.bat first.& exit /b 1)
set "GRADLE_HOME=%KIT_ROOT%\tools\gradle-7.0.2"
set "GRADLE_USER_HOME=%KIT_ROOT%\cache\gradle"
if not exist "%GRADLE_HOME%\bin\gradle.bat" (echo ERROR: Gradle not found. Run 02-prepare-gradle.bat first.& exit /b 1)
setx JAVA_HOME "%JAVA_HOME%"
if errorlevel 1 exit /b 1
setx GRADLE_HOME "%GRADLE_HOME%"
if errorlevel 1 exit /b 1
setx GRADLE_USER_HOME "%GRADLE_USER_HOME%"
if errorlevel 1 exit /b 1
echo.
echo User environment variables saved.
echo Add these two entries to your user Path using Windows Environment Variables:
echo %%JAVA_HOME%%\bin
echo %%GRADLE_HOME%%\bin
echo Do not overwrite your existing Path value.
echo Open a new CMD window after updating Path.
exit /b 0
