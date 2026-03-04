# 아키텍처 설계

## 레이어 구조

`Client` -> `User/Course Domain` -> `SessionCoordinator` -> `API` -> `Transport` -> `Parsers` -> `Models`

## 주요 구성 요소

### Client Layer

- 파일: `lib/klas_client.dart`
- 역할: 로그인, heartbeat, health check, 도메인 객체 생성

### Domain Layer

- 파일: `lib/src/domain/klas_user.dart`
- 역할: `KlasUser`, `KlasCourse`와 feature 객체 제공
- 앱은 endpoint ID 대신 도메인 메서드만 사용

### Session / Context Layer

- 파일: `lib/src/auth/session_coordinator.dart`
- 역할: 로그인/자동 재로그인 정책
- 파일: `lib/src/context/context_manager.dart`
- 역할: 컨텍스트 저장(내부 전용)

### API Layer

- 파일: `lib/src/api/readonly_api.dart`
- 역할: 65개 읽기 전용 endpoint 호출과 타입 검증
- 파일: `lib/src/domain/domain_executor.dart`
- 역할: 도메인 호출을 endpoint 호출로 중계

### Transport / Parsing / Models

- 파일: `lib/src/transport/*`, `lib/src/parsers/*`, `lib/src/models/*`
- 역할: HTTP, 응답 파싱, 타입 모델링

## 설계 원칙

- 공개 API에서 endpoint ID와 payload map을 제거한다.
- 과목 컨텍스트는 `KlasCourse` 객체에 바인딩한다.
- 세션/재로그인/쿠키 처리는 내부 정책으로 캡슐화한다.
- API 변경은 내부 도메인 매퍼에서 흡수한다.
