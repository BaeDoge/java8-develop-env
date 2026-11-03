# takephoto-ls 의존성 수집 프로젝트

이 폴더는 사내 원본 소스코드를 외부 PC로 반출하지 않고, 공개 Gradle 플러그인과 Maven 의존성 캐시를 준비하기 위한 별도 프로젝트입니다.

## 기준 환경

- JDK 8
- Gradle 7.0.2
- Spring Boot 2.7.18
- Spring Framework 5.3.39
- Spring Security 5.8.16
- Logback: Spring Boot 2.7.18 BOM 관리 버전 사용 (1.2.12)

Spring Boot 2.7.18은 Java 8 및 Gradle 7.x를 지원하며 Spring Framework 5.3.31 이상을 요구합니다. Spring Security 5.8.16은 Spring Framework 5.3.39 기반으로 구성합니다.

## 외부 PC에서 실행

저장소 루트에서 아래 명령을 실행합니다.

```cmd
cd /d C:\Users\User\Documents\_Projects\261104_takephoto
set "GRADLE_USER_HOME=%CD%\cache\gradle"
cd dependency-seed
gradle --no-daemon --refresh-dependencies resolveAllDependencies
```

다운로드가 끝난 후 네트워크를 사용할 수 없는 상태에서 캐시 검증을 수행합니다.

```cmd
gradle --offline --no-daemon resolveAllDependencies
```

두 번째 명령이 성공해야 이 프로젝트에서 해석한 의존성 구성이 Gradle 캐시만으로 다시 해석되는지 확인할 수 있습니다. 이것은 실제 사내 애플리케이션의 전체 빌드 성공을 보장하지는 않습니다.

## 포함 범위 및 제한

- 이 프로젝트는 Maven Central 및 Gradle Plugin Portal의 공개 아티팩트를 대상으로 합니다.
- 사내 Nexus 전용 아티팩트, 사내 저장소 인증정보, 사내 소스코드는 포함하지 않습니다.
- 원본 프로젝트의 `lib/*.jar` 파일은 별도 반입 대상입니다. 이 저장소에 사내 JAR를 업로드하지 마세요.
- 원본 프로젝트의 `agent2api.jar` 등 사내/비공개 JAR도 별도 확인이 필요합니다.
- Gradle 캐시는 프로젝트 파일이 아니며, 실제 캐시 위치는 `GRADLE_USER_HOME`에 따라 달라집니다.
- Gradle Wrapper 파일은 이 seed 프로젝트에 포함하지 않습니다. 준비된 Gradle 7.0.2를 직접 실행합니다.

## 별도 관리 대상: EJS 및 Minimist

EJS와 Minimist는 Java/Gradle 의존성이 아니라 JavaScript 패키지입니다. 현재 준비 키트에서는 Node.js/npm을 사용하지 않으므로 이 두 패키지는 Gradle 캐시에 포함되지 않습니다. 실제 애플리케이션에서 사용되는 위치와 배포 방식을 확인한 뒤 별도 절차로 처리해야 합니다.

## Logback 예외

요청된 Logback 최소 버전 1.6.0은 Java 8 환경과 호환되지 않습니다. 따라서 이번 Java 8 유지 범위에서는 Spring Boot 2.7.18이 관리하는 Logback 1.2.12를 사용하고, 최소 요구 버전 미충족 예외로 기록합니다. JDK 업그레이드 시 다시 검토해야 합니다.
