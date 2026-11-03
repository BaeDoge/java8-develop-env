@echo off
setlocal EnableExtensions
set "KIT_ROOT=%~dp0.."
for %%I in ("%KIT_ROOT%") do set "KIT_ROOT=%%~fI"
if not defined JAVA_HOME (echo ERROR: JAVA_HOME is not set. Run 03-register-environment.bat and open a new CMD.& exit /b 1)
if not defined GRADLE_HOME (echo ERROR: GRADLE_HOME is not set. Run 03-register-environment.bat and open a new CMD.& exit /b 1)
if not exist "%JAVA_HOME%\bin\java.exe" (echo ERROR: java.exe missing under JAVA_HOME.& exit /b 1)
if not exist "%JAVA_HOME%\bin\javac.exe" (echo ERROR: javac.exe missing under JAVA_HOME. A JDK is required.& exit /b 1)
if not exist "%GRADLE_HOME%\bin\gradle.bat" (echo ERROR: gradle.bat missing under GRADLE_HOME.& exit /b 1)
set "PATH=%JAVA_HOME%\bin;%GRADLE_HOME%\bin;%PATH%"
if not defined GRADLE_USER_HOME set "GRADLE_USER_HOME=%KIT_ROOT%\cache\gradle"
echo [1/4] java -version
java -version 2>&1
if errorlevel 1 exit /b 1
echo.
echo [2/4] javac -version
javac -version
if errorlevel 1 exit /b 1
echo.
echo [3/4] gradle --version
gradle --version
if errorlevel 1 exit /b 1
echo.
echo [4/4] Command locations
where java
where javac
where gradle
echo.
echo Environment verification passed.
exit /b 0
