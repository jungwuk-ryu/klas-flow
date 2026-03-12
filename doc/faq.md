# FAQ

## 왜 `endpoints.*` 대신 `user/course` 객체 구조로 바꿨나요?

앱 개발자가 endpoint 명세를 외우지 않고도 기능을 사용할 수 있게 하기 위해서입니다.
이제 `client.login() -> user -> course` 흐름으로 호출합니다.

## 세션 만료는 어떻게 처리되나요?

기존과 동일하게 내부 자동 재로그인 정책(`maxSessionRenewRetries`)을 적용합니다.
자동 복구가 불가능하면 `SessionExpiredException`을 던집니다.

## 과목 컨텍스트는 어떻게 선택하나요?

`user.courses()`에서 강의 객체를 받고, 해당 `KlasCourse` 객체 메서드를 호출하면
그 강의 컨텍스트가 자동 적용됩니다.

## 운영 진단은 어떻게 하나요?

`client.runHealthCheck()`와 `tool/live_account_scenarios.dart`를 사용합니다.

## 실 테스트 상태는 어디서 확인하나요?

`doc/live_feature_coverage.md`에서 공개 기능별 자동 테스트/수동 테스트 상태를 확인할 수 있습니다.

## 왜 `dart analyze` 대신 `dart analyze lib test tool`를 쓰나요?

이 저장소에는 Flutter 기반 `example/` 앱이 함께 들어 있습니다.
라이브러리 품질 게이트는 Dart 라이브러리 본체 기준으로 보는 것이 목적이므로,
기본 점검은 `dart analyze lib test tool`로 수행합니다.
Flutter example까지 보고 싶으면 `cd example && flutter analyze`를 별도로 실행합니다.

## 보안상 주의할 점은?

- 실계정 테스트는 읽기 전용 API만 사용
- 민감정보 로그 금지
- 비공개 명세 문서 커밋 금지
