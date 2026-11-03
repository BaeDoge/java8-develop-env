[CmdletBinding()]
param(
    [string]$KitRoot = (Split-Path -Parent $PSScriptRoot),
    [int]$MaxRetries = 5,
    [int]$TimeoutSeconds = 900
)

$ErrorActionPreference = "Stop"
$Version = "7.0.2"
$ZipName = "gradle-$Version-bin.zip"
$Url = "https://services.gradle.org/distributions/$ZipName"
$ToolsDir = Join-Path $KitRoot "tools"
$DistDir = Join-Path $ToolsDir "distributions"
$InstallDir = Join-Path $ToolsDir "gradle-$Version"
$ZipPath = Join-Path $DistDir $ZipName
$TempPath = "$ZipPath.download"

New-Item -ItemType Directory -Force -Path $DistDir, $ToolsDir | Out-Null

Write-Host "[1/5] Java 확인"
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
if ($javaCmd) {
    java -version 2>&1 | ForEach-Object { Write-Host $_ }
} else {
    Write-Warning "Java를 찾지 못했습니다. 다운로드는 계속합니다. Gradle 실행 전 승인된 JDK 8이 필요합니다."
}

Write-Host "[2/5] 기존 다운로드 파일 확인"
if ((Test-Path $ZipPath) -and ((Get-Item $ZipPath).Length -gt 10MB)) {
    Write-Host "기존 ZIP 파일이 있습니다. 재다운로드를 건너뜁니다."
} else {
    if (Test-Path $TempPath) { Remove-Item $TempPath -Force }

    $downloaded = $false

    # 우선 Windows 기본 curl.exe 사용: 리다이렉트 및 재시도 처리
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        Write-Host "[3/5] curl.exe로 다운로드 시도 (최대 $MaxRetries회, 회당 최대 $TimeoutSeconds초)"
        for ($i = 1; $i -le $MaxRetries; $i++) {
            Write-Host "다운로드 시도 $i/$MaxRetries"
            if (Test-Path $TempPath) { Remove-Item $TempPath -Force }

            & curl.exe --fail --location --show-error `
                --connect-timeout 45 `
                --max-time $TimeoutSeconds `
                --retry 2 `
                --retry-delay 3 `
                --output $TempPath `
                $Url

            if ($LASTEXITCODE -eq 0 -and (Test-Path $TempPath) -and ((Get-Item $TempPath).Length -gt 10MB)) {
                $downloaded = $true
                break
            }
            Write-Warning "curl 다운로드 실패 (exit code: $LASTEXITCODE)"
            Start-Sleep -Seconds 5
        }
    }

    # curl 실패 시 PowerShell .NET 다운로드로 대체
    if (-not $downloaded) {
        Write-Host "[4/5] PowerShell 대체 다운로드 시도"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        } catch {}

        for ($i = 1; $i -le $MaxRetries; $i++) {
            Write-Host "대체 다운로드 시도 $i/$MaxRetries"
            if (Test-Path $TempPath) { Remove-Item $TempPath -Force }

            $request = [System.Net.HttpWebRequest]::Create($Url)
            $request.Method = "GET"
            $request.AllowAutoRedirect = $true
            $request.Timeout = $TimeoutSeconds * 1000
            $request.ReadWriteTimeout = $TimeoutSeconds * 1000
            $request.UserAgent = "Gradle-Offline-Kit/1.0"

            try {
                $response = $request.GetResponse()
                $inputStream = $response.GetResponseStream()
                $outputStream = [System.IO.File]::Create($TempPath)
                try {
                    $inputStream.CopyTo($outputStream)
                } finally {
                    $outputStream.Dispose()
                    $inputStream.Dispose()
                    $response.Dispose()
                }

                if ((Test-Path $TempPath) -and ((Get-Item $TempPath).Length -gt 10MB)) {
                    $downloaded = $true
                    break
                }
            } catch {
                Write-Warning "PowerShell 다운로드 실패: $($_.Exception.Message)"
                if (Test-Path $TempPath) { Remove-Item $TempPath -Force }
                Start-Sleep -Seconds 5
            }
        }
    }

    if (-not $downloaded) {
        throw @"
Gradle 다운로드에 실패했습니다.
브라우저에서 아래 주소를 직접 열어 ZIP 파일을 다운로드한 뒤 다음 위치에 저장하고
스크립트를 다시 실행하세요.
$Url

저장 위치:
$ZipPath

회사 프록시/VPN/방화벽에서 services.gradle.org 또는 리다이렉트 대상 도메인을
차단하는지도 확인하세요.
"@
    }

    Move-Item -Path $TempPath -Destination $ZipPath -Force
}

Write-Host "[5/5] ZIP 확인 및 압축 해제"
try {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    $entryCount = $archive.Entries.Count
    $archive.Dispose()
    if ($entryCount -lt 10) { throw "ZIP 내부 파일 수가 비정상적으로 적습니다: $entryCount" }
} catch {
    throw "다운로드 파일이 정상 ZIP이 아닙니다. 파일을 삭제하고 다시 다운로드하세요. $($_.Exception.Message)"
}

$Hash = (Get-FileHash -Algorithm SHA256 -Path $ZipPath).Hash.ToLower()
Set-Content -Path "$ZipPath.sha256" -Value "$Hash  $ZipName" -Encoding ASCII
Write-Host "다운로드 파일 SHA-256: $Hash"
Write-Host "참고: 이 값은 다운로드 후 계산한 로컬 해시이며, 공식 배포처 해시와 대조한 인증값은 아닙니다."

if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}
$tempDir = Join-Path $ToolsDir "_extract"
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
Expand-Archive -Path $ZipPath -DestinationPath $tempDir -Force

$extracted = Join-Path $tempDir "gradle-$Version"
if (-not (Test-Path $extracted)) {
    throw "압축 해제 결과에서 gradle-$Version 폴더를 찾지 못했습니다."
}
Move-Item -Path $extracted -Destination $InstallDir
Remove-Item -Recurse -Force $tempDir

Write-Host ""
Write-Host "Gradle 배포본 준비 완료: $InstallDir"
Write-Host "Java가 설치되어 있고 JAVA_HOME/PATH가 설정된 경우에만 버전 확인을 실행합니다."
if (Get-Command java -ErrorAction SilentlyContinue) {
    & (Join-Path $InstallDir "bin\gradle.bat") --version
} else {
    Write-Host "Java 8 준비 후 scripts\02-verify-environment.ps1을 실행하세요."
}
