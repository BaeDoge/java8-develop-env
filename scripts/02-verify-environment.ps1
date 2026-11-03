[CmdletBinding()]
param(
    [string]$KitRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$JavaHome = $env:JAVA_HOME
)

$ErrorActionPreference = "Stop"
$GradleBat = Join-Path $KitRoot "tools\gradle-7.0.2\bin\gradle.bat"

if (-not $JavaHome) {
    throw "JAVA_HOME이 설정되지 않았습니다. 승인된 JDK 8 경로를 JAVA_HOME에 설정하세요."
}
if (-not (Test-Path (Join-Path $JavaHome "bin\java.exe"))) {
    throw "JAVA_HOME 아래에서 bin\java.exe를 찾을 수 없습니다: $JavaHome"
}
if (-not (Test-Path $GradleBat)) {
    throw "Gradle 실행 파일이 없습니다. 먼저 01-prepare-gradle.ps1을 실행하세요."
}

$env:JAVA_HOME = $JavaHome
$env:PATH = "$(Join-Path $JavaHome 'bin');$env:PATH"
$env:GRADLE_USER_HOME = Join-Path $KitRoot "cache\gradle"

Write-Host "Java:"
# java -version은 stderr로 출력되므로 cmd.exe에서 stdout으로 합쳐 표시합니다.
$JavaExe = Join-Path $JavaHome "bin\java.exe"
& $env:ComSpec /d /c "`"$JavaExe`" -version 2>&1" | ForEach-Object { Write-Host $_ }

Write-Host "`nGradle:"
& $GradleBat --version
