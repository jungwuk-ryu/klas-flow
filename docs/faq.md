# FAQ

## 이 아키텍처가 정말 맞나?

현재 구조는 "앱 코드 단순화"를 1순위로 둔 구조입니다.
- `KlasClient`: 앱에서 쓰는 공개 API
- `SessionCoordinator`: 로그인/재로그인 정책
- `RequestExecutor`: 컨텍스트 병합 + 요청 실행
- `readonly_api` + `typed_endpoints`: API 접근 경로 표준화

장점:
- 앱 레이어에서 HTTP/쿠키/파싱 코드가 거의 사라짐
- API 변경 시 수정 범위를 내부 레이어로 제한 가능

한계:
- KLAS 서버가 비정형 응답을 내보내면 parser가 빠르게 깨질 수 있음
- 카탈로그 유지 비용이 필요함(자동 생성/CI로 완화 중)

## 기능이 너무 복잡하지 않나?

복잡도는 내부로 숨기고, 외부 사용 경로는 3단계로 단순화했습니다.
1. `loginAndBootstrap` + typed endpoint
2. `api.call*` 기반 유연 호출
3. heartbeat/healthCheck 같은 운영 기능

## Flutter 앱에서 실제로 쓸 만한가?

실사용을 위해 아래를 제공했습니다.
- Riverpod/BLoC 연동 예시
- 라이브 계정 10개 읽기 전용 시나리오 러너
- 세션 만료 자동 처리와 heartbeat
- 배포 전 보안/품질 자동 점검 스크립트

## README가 충분히 친절한가?

README를 아래 기준으로 재구성했습니다.
- 가치 제안(왜 써야 하는지) 먼저
- 3분 Quick Start
- 사용 경로별 가이드(Simple/Flexible/Advanced)
- 튜토리얼/FAQ/진단 링크 제공

## API가 바뀌면 어떻게 하나?

권장 대응 순서:
1. `runHealthCheck()` 또는 `tool/live_account_scenarios.dart` 실행
2. 실패 endpoint와 에러 패턴 확인
3. parser/endpoint 경로 보강
4. 테스트 추가 후 배포

## 숨겨진 버그나 취약점은 어떻게 찾나?

- 단위 테스트 + 실계정 read-only 시나리오를 같이 돌립니다.
- `tool/check_all.dart`를 CI 게이트로 사용합니다.
- `tool/prepublish_check.dart`로 민감정보/비공개 문서 유출을 차단합니다.
- 앱 로그에 학번/비밀번호/쿠키가 남지 않도록 반드시 마스킹합니다.

## 내가 놓치기 쉬운 질문은?

- 로그인 성공 후 기본 컨텍스트가 항상 존재하는가?
- 특정 학기/과목 데이터가 없을 때 UX는 어떻게 처리할 것인가?
- 세션 만료 직후 사용자에게 재로그인 안내를 어떻게 보여줄 것인가?
- KLAS 응답 필드가 변했을 때 파싱 실패를 어디서 감지하고 알릴 것인가?
- 운영 중 장애 리포트에 민감정보가 섞이지 않는가?
