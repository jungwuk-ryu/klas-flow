# 아키텍처 설계

## 레이어 구조

`Client` -> `AuthFlow` -> `ContextManager` -> `API` -> `Transport` -> `Parsers` -> `Models`

## 주요 구성 요소

### Client Layer

- 파일: `lib/klas_client.dart`
- 역할: 외부 공개 API 제공, 내부 레이어 조합

### Auth Flow Layer

- 파일: `lib/src/auth/auth_flow.dart`
- 역할: 로그인 다단계 흐름 오케스트레이션

### Context Layer

- 파일: `lib/src/context/context_manager.dart`
- 역할: 학기/과목 컨텍스트 저장 및 요청 자동 주입

### API Layer

- 파일: `lib/src/api/*`
- 역할: 인증/세션/프레임/컨텍스트 엔드포인트 캡슐화

### Transport Layer

- 파일: `lib/src/transport/*`
- 역할: HTTP 호출, 쿠키 보관, 상태 코드 판정, 타입별 응답 처리

### Parsing Layer

- 파일: `lib/src/parsers/*`
- 역할: 로그인 JSON/HTML 응답 파싱

### Models Layer

- 파일: `lib/src/models/*`
- 역할: 클라이언트 외부/내부 데이터 모델링

### Exceptions Layer

- 파일: `lib/src/exceptions/klas_exceptions.dart`
- 역할: 도메인 의미가 분명한 실패 타입 제공

## 설계 원칙

- 로우레벨 HTTP 세부사항을 외부 API에 노출하지 않는다.
- 로그인 단계는 단일 메서드(`login`)로 추상화한다.
- 세션/쿠키는 Transport 레이어에서 일관되게 처리한다.
- 컨텍스트 주입은 `ContextManager` 단일 책임으로 유지한다.
- 응답 포맷(JSON/HTML/파일)은 메서드 수준에서 분리한다.
