# Java 8 + Gradle 7.0.2 CMD 오프라인 준비 키트 (Windows)

이 키트는 **CMD 배치 파일만 사용**합니다. PowerShell, Node.js, npm은 사용하지 않습니다.

현재 외부 준비 PC에서는 Java 8 Runtime은 확인됐지만 `javac`가 없어 JDK가 필요합니다. Gradle 로그의 `OS: Windows 10 ... x86`은 실행 중인 Java의 아키텍처를 나타내며 Windows OS 자체의 비트 수를 확정하지는 않습니다. 따라서 JDK 준비 스크립트는 CMD의 Windows 아키텍처 환경변수를 확인해 32비트 Windows에는 i686 JDK, 64비트 Windows에는 x64 JDK를 선택합니다. Azul Zulu Community의 Java 8 JDK 메타데이터에서 다운로드 URL과 공식 SHA-256을 조회합니다.

## 폴더 구성

- `tools/jdk8/`: 압축 해제한 JDK 8
- `tools/gradle-7.0.2/`: 압축 해제한 Gradle
- `tools/distributions/`: 원본 ZIP 및 체크섬/메타데이터
- `cache/gradle/`: Gradle 사용자 홈 및 의존성 캐시 위치
- `project-meta/`: 반출이 허용된 빌드 메타데이터
- `output/`: 내부망 반입 패키지 출력 위치
- `scripts/`: CMD 배치 스크립트

## 1. 외부 Windows PC에서 한 번에 준비

CMD를 열고 키트 루트 폴더로 이동합니다.

```cmd
cd /d C:\Users\User\Documents\_Projects\261104_takephoto
SETUP-CMD.bat
```

또는 단계를 나눠 실행할 수 있습니다.

```cmd
scripts\01-prepare-jdk8.bat
scripts\02-prepare-gradle.bat
scripts\03-register-environment.bat
scripts\04-verify-environment.bat
```

준비 과정은 다음과 같습니다.

1. Windows 아키텍처를 감지한 뒤 Azul Metadata API에서 알맞은 Java 8 JDK ZIP의 다운로드 URL과 SHA-256 조회
2. JDK ZIP 다운로드 및 공식 메타데이터의 SHA-256 대조
3. JDK 압축 해제 후 `java -version`, `javac -version` 확인
4. Gradle 7.0.2 ZIP 확인 및 압축 해제
5. 사용자 환경변수 `JAVA_HOME`, `GRADLE_HOME`, `GRADLE_USER_HOME` 등록
6. Java/Gradle 버전 및 명령어 위치 검증

필요 도구는 Windows의 `curl.exe`, `tar.exe`, `certutil.exe`, 기본 CMD 명령입니다. Windows 10 최신 업데이트 환경을 권장합니다. 관리자 권한은 필요하지 않습니다.

## 2. 환경변수 PATH 등록

`03-register-environment.bat`은 사용자 환경변수 세 개를 영구 등록합니다. 기존 PATH를 잘라내거나 덮어쓰는 위험을 피하기 위해 PATH 자체는 자동 수정하지 않습니다.

Windows의 사용자 환경변수 Path에 아래 두 항목을 추가하세요.

```text
%JAVA_HOME%\bin
%GRADLE_HOME%\bin
```

기존 Path 항목은 삭제하거나 교체하지 마세요. 환경변수 창을 닫은 뒤 새 CMD를 열어야 변경사항이 반영됩니다. 이후 어느 폴더에서든 다음 명령을 사용할 수 있습니다.

```cmd
java -version
javac -version
gradle --version
```

새 CMD에서 확인이 필요하면 키트 폴더에서 `scripts\04-verify-environment.bat`를 실행하세요. 검증 스크립트는 JAVA_HOME/GRADLE_HOME 경로를 우선 PATH에 추가해 검사합니다.

## 3. 내부망 반입

외부에서 준비한 다음 항목을 회사의 승인된 반입 절차로 옮깁니다.

- `tools/jdk8/`
- `tools/gradle-7.0.2/`
- `tools/distributions/` (원본 ZIP, SHA-256, JDK 메타데이터)
- `scripts/`
- `README.md`

내부망 PC에서도 JDK와 Gradle 경로를 해당 위치에 두고 `03-register-environment.bat`를 실행한 뒤 사용자 Path에 두 경로를 추가하세요.

## 4. Gradle 프로젝트 의존성은 별도 준비 필요

Gradle 배포본과 프로젝트 라이브러리는 서로 다릅니다.

- Gradle 배포본: Gradle 자체를 실행하는 프로그램
- Gradle Plugin / Maven 의존성: 실제 프로젝트 빌드에 필요한 외부 라이브러리

프로젝트의 `settings.gradle`, `build.gradle`, `gradle.properties`, `buildSrc`, 포함 빌드 및 저장소 정보 없이는 정확한 의존성 목록을 알 수 없습니다. 이 파일들은 사내 URL이나 인증정보를 포함할 수 있으므로 보안 검토 없이 외부로 반출하면 안 됩니다.

소스코드를 외부로 가져오지 않으려면 내부망에서 Gradle resolve 실패 로그와 누락된 Maven 좌표를 수집하고, 회사의 승인된 반입 절차로 아티팩트를 확보해 사내 Nexus/Artifactory 등에 등록하는 방식이 적절합니다. 이 키트는 임의의 라이브러리를 추측해서 다운로드하지 않습니다.

## 5. 체크섬 주의사항

JDK ZIP은 Azul Metadata API가 제공한 SHA-256과 비교합니다. Gradle ZIP은 다운로드 후 로컬 SHA-256을 기록합니다. Gradle의 로컬 해시는 공식 배포처의 해시와 대조한 인증값이 아닙니다.

## 6. 다운로드 오류

사내 프록시/방화벽이 CRL/OCSP 조회를 막는 경우 Windows curl에서 `CRYPT_E_NO_REVOCATION_CHECK` 오류가 날 수 있어 다운로드에 `--ssl-no-revoke`를 사용합니다. 이는 인증서 폐기 여부 조회만 생략하며, 인증서 신뢰 체인/유효기간 검증을 끄는 `--insecure`와 다릅니다. 회사 보안 정책상 허용되는 경우에만 사용하세요.

JDK 메타데이터 조회 또는 다운로드가 실패하면 `scripts\01-prepare-jdk8.bat`의 최신 버전을 먼저 `git pull`로 가져왔는지 확인하세요. 메타데이터 URL의 쿼리 구분자는 CMD의 따옴표 안에서 `&`를 그대로 사용해야 합니다. 프록시/방화벽에서 `api.azul.com`, `cdn.azul.com`, `services.gradle.org` 및 리다이렉트 대상에 접근 가능한지 확인하세요.
