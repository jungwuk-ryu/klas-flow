## Unreleased

- (none)

## 1.1.0 - 2026-03-05

- BREAKING: 공개 API를 도메인 객체 중심으로 재구성
  - `login()` 반환 타입 변경: `Future<void>` -> `Future<KlasUser>`
  - `KlasUser`/`KlasCourse` 및 feature 메서드 도입
  - `client.endpoints.*`, `client.api.call*`, `loginAndBootstrap()`, `setContext()` 제거
- 강의 컨텍스트를 `KlasCourse` 객체에 바인딩해 강의 단위 호출 일관성 강화
- 품질 파이프라인 단순화
  - `tool/check_all.dart`에서 typed endpoint 생성/검증 단계 제거
  - 저수준 생성 도구/산출물(`generate_typed_endpoints.dart`, `typed_endpoints.dart`) 제거
- 문서/예제 전면 갱신
  - README, 튜토리얼, FAQ, Flutter 가이드, 마이그레이션 문서 업데이트
  - example 앱을 `user -> course` 흐름으로 교체

## 1.0.0

- KlasClient 중심의 고수준 API 초기 구현
- 다단계 로그인 오케스트레이션 구현
- 세션 쿠키 자동 관리 및 만료 예외 처리 구현
- 과목 컨텍스트 자동 초기화/주입 구현
- JSON/HTML/파일 응답 분리 Transport 구현
- 예외 체계 및 모델 계층 구현
- Mock 기반 테스트 스위트와 커버리지 기준(80%+) 충족
