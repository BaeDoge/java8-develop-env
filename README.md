# Gradle 7.0.2 오프라인 반입 준비 키트 (Windows)

이 키트는 **Node.js/npm을 전혀 사용하지 않습니다.**
현재 확인된 조건(Java 8, Gradle 7.0.2, 외부 PC Windows)을 기준으로
Gradle 실행 배포본과 반입 폴더 구조를 준비하기 위한 기본 골격입니다.

## 폴더 구성

- tools/gradle-7.0.2/ : 다운로드한 Gradle 실행 파일이 풀릴 위치
- tools/distributions/ : 원본 Gradle ZIP 보관 위치
- cache/gradle/ : 외부에서 Gradle 실행 시 만들어지는 Gradle 사용자 홈/캐시
- project-meta/ : 프로젝트에서 반출이 허용된 빌드 메타데이터를 둘 위치
- output/ : 반입용 ZIP 및 체크섬 파일 생성 위치
- scripts/ : 준비/검증 스크립트

## 1. 외부 Windows PC에서 Gradle 배포본 준비

PowerShell을 열고 키트 루트 폴더에서 실행합니다.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\01-prepare-gradle.ps1
```

스크립트는 Gradle 7.0.2 공식 배포 ZIP을 다운로드하고 SHA-256을 기록한 뒤 압축을 풉니다.
JDK는 자동 반입하지 않습니다. 내부 빌드 서버에 호환되는 Java 8이 있으면 그 JDK를 사용하세요.
외부 PC에 Java 8이 없다면, 회사에서 승인한 동일 계열 JDK를 별도로 확보해야 합니다.

## 2. 내부망 반입

키트의 `tools/gradle-7.0.2`, `tools/distributions`, `scripts`, `README.md`를 반입합니다.
Gradle 캐시는 프로젝트 의존성을 실제로 resolve해야 채워지므로, 현재처럼 내부 소스/빌드 설정을
외부에 제공하지 않는 조건에서는 완성된 의존성 캐시를 미리 만들 수 없습니다.

## 3. 내부망에서 Gradle 실행

Gradle 배포본을 반입한 후 프로젝트 루트에서 다음처럼 실행할 수 있습니다.

```powershell
$env:JAVA_HOME = "C:\Path\To\Approved\JDK8"
$env:GRADLE_USER_HOME = "D:\offline-build\cache\gradle"
& "D:\offline-build\tools\gradle-7.0.2\bin\gradle.bat" --version
```

프로젝트가 Gradle Wrapper를 포함한다면 Wrapper를 우선 사용하되,
`gradle-wrapper.properties`의 distributionUrl이 외부 다운로드를 시도하지 않도록
사내 반입한 배포본을 사용하도록 맞춰야 합니다. 프로젝트 파일 수정은 변경관리 절차에 따라 진행하세요.

## 4. 의존성 확보에 대한 중요한 제한

Gradle 배포본과 프로젝트 라이브러리는 서로 다릅니다.

- Gradle 배포본: Gradle 자체를 실행하는 프로그램
- Gradle Plugin / Maven 의존성: 프로젝트 빌드에 필요한 별도 파일

프로젝트의 `settings.gradle`, `build.gradle`, `gradle.properties`, `buildSrc`,
포함 빌드 및 사용 중인 저장소 정보 없이 어떤 라이브러리와 버전이 필요한지 알 수 없습니다.
따라서 이 키트는 임의의 Maven 패키지를 추측해서 포함하지 않습니다.

내부 소스 코드를 외부로 가져오지 않는 조건을 유지하려면 다음 중 하나가 필요합니다.

1. 보안 검토 후 빌드 설정 파일만 민감정보/사내 URL/인증정보를 제거해 외부에서 의존성을 resolve
2. 내부망에서 Gradle의 누락 의존성 목록을 수집하고, 승인된 절차로 외부 반입 요청
3. 사내 Nexus/Artifactory 등의 저장소에 필요한 Maven 아티팩트를 승인된 방식으로 등록

빌드 설정 파일을 외부로 전혀 가져갈 수 없다면, 정확한 의존성 캐시를 외부에서 선제적으로 만드는 것은 불가능합니다.

## 5. 체크섬

`tools/distributions/gradle-7.0.2-bin.zip.sha256` 파일에 다운로드한 ZIP의 SHA-256이 기록됩니다.
반입 후 회사에서 승인한 도구로 동일한 해시를 재검증하세요.


## 다운로드 시간 초과 시

`01-prepare-gradle.ps1`은 curl.exe를 우선 사용하고, 최대 5회 재시도합니다.
각 다운로드 시도는 최대 15분까지 기다립니다. curl이 없거나 실패하면 PowerShell 방식으로 재시도합니다.

계속 실패하면 브라우저에서 아래 주소를 열어 `gradle-7.0.2-bin.zip`을 직접 다운로드하고
다음 위치에 저장한 뒤 스크립트를 다시 실행하세요.

`tools/distributions/gradle-7.0.2-bin.zip`

다운로드가 계속 실패하면 PC의 프록시/VPN/방화벽 정책에서
`services.gradle.org` 및 리다이렉트되는 배포 파일 호스트 접근이 가능한지 확인해야 합니다.

## 인증서 폐기 여부 확인 오류 (CRYPT_E_NO_REVOCATION_CHECK)

사내망/프록시 정책으로 인증서 폐기 목록(CRL) 또는 OCSP 조회가 차단되면
Windows curl(Schannel)이 `CRYPT_E_NO_REVOCATION_CHECK` 오류를 낼 수 있습니다.

현재 준비 스크립트는 이 경우에 한해 다음 설정을 사용합니다.

- curl: `--ssl-no-revoke`
- PowerShell 대체 다운로드: 인증서 폐기 여부 조회만 비활성화

이 설정은 **인증서 폐기 여부 조회를 생략**하는 것이며, 인증서의 신뢰 체인과 유효기간 검증을 무시하는 `-k` / `--insecure`와는 다릅니다.
다만 폐기된 인증서를 확인하지 못할 수 있으므로 회사 보안 정책상 허용되는 환경에서만 사용하세요.
보안 정책상 허용되지 않으면 이 옵션을 사용하지 말고 사내 프록시/보안 담당자에게 CRL/OCSP 조회 경로 허용 여부를 확인하거나 승인된 브라우저/반입 절차를 이용하세요.

PowerShell 스크립트는 Windows PowerShell 5의 한글 출력 깨짐을 줄이기 위해 UTF-8 BOM으로 저장합니다.
