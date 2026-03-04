# Adoption Questions Checklist

프로젝트 채택 전에 아래 질문을 검토하면 운영 리스크를 크게 줄일 수 있습니다.

## Product Fit

- 이 SDK가 우리 앱의 KLAS 사용 범위(조회/다운로드/알림)에 정확히 맞는가?
- 팀이 원하는 추상화 수준이 `login -> user -> course` 도메인 API와 맞는가?
- 사용자에게 보여줄 핵심 가치(안정성, 개발 속도, 유지보수성)가 문서에 드러나는가?

## Architecture

- 앱 레이어가 `KlasClient` 외 내부 구현(`lib/src`)에 의존하고 있지 않은가?
- 세션 만료 정책(`maxSessionRenewRetries`)이 앱 UX와 충돌하지 않는가?
- 과목 컨텍스트를 `KlasCourse` 객체 단위로 다루는 기준이 팀 내에서 합의되었는가?

## Reliability

- CI에서 `dart run tool/check_all.dart`를 필수 게이트로 쓰는가?
- 배포 전에 `runHealthCheck()` 또는 `tool/live_account_scenarios.dart`를 실행하는가?
- 장애 발생 시 어떤 로그(민감정보 마스킹 포함)를 남길지 정의되어 있는가?

## Security & Compliance

- 학번/비밀번호/쿠키/토큰이 로그나 crash report에 남지 않도록 필터링했는가?
- 비공개 문서가 git tracked/history에 들어가지 않도록 점검했는가?
- 실계정 테스트 시 읽기 전용 API만 호출하도록 절차를 강제했는가?

## API Drift Response

- KLAS 응답 필드/상태 코드가 바뀌면 누가 어떻게 대응하는가?
- parser 수정 후 회귀 테스트 케이스를 추가하는 규칙이 있는가?
- 특정 feature가 실패할 때 임시 비활성화/대체 UX 절차가 있는가?

## Developer Experience

- 신규 팀원이 튜토리얼만 보고 30분 내 첫 호출을 성공할 수 있는가?
- README에서 “어떤 파일부터 읽어야 하는지”가 명확한가?
- 예제 코드가 실제 앱 패턴(Riverpod/BLoC)과 가깝게 제공되는가?
