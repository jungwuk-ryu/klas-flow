## Unreleased

- `KlasClient.loginAndBootstrap()` 추가(로그인 + 초기 상태 반환)
- `KlasClient.runHealthCheck()` 추가(세션/컨텍스트/핵심 endpoint 진단)
- `KlasClientConfig.cacheCredentialsForAutoRenewal` 추가(자격증명 메모리 캐시 제어)
- KLAS 신규 로그인 프로토콜(`publicKey` 기반 JSON 플로우) 대응
- `YearhakgiAtnlcSbjectList` 응답 구조(`year/subjList`) 파싱 보강
- 실계정 10개 읽기 전용 시나리오 러너 추가
- Quick Tutorial/FAQ/Bootstrap+Health demo 문서/예제 추가
- `KlasClient.endpoints` 그룹형 자동완성 API 추가 (65개 카탈로그 래퍼)
- `tool/generate_typed_endpoints.dart` 추가 및 CI 생성 동기화 검증
- `KlasClient.startSessionHeartbeat` 오류 콜백(`onError`) 및 실행 상태 getter 추가
- 세션 자동 재로그인 재시도 횟수 설정(`maxSessionRenewRetries`) 검증 테스트 강화
- `tool/prepublish_check.dart` 추가 (비공개 명세/민감 문자열 누출 점검)
- GitHub Actions CI 추가 (`analyze`, `test`, prepublish check)
- Flutter 연동/배포 체크리스트/heartbeat 데모 문서 추가

## 1.0.0

- KlasClient 중심의 고수준 API 초기 구현
- 다단계 로그인 오케스트레이션 구현
- 세션 쿠키 자동 관리 및 만료 예외 처리 구현
- 과목 컨텍스트 자동 초기화/주입 구현
- JSON/HTML/파일 응답 분리 Transport 구현
- 예외 체계 및 모델 계층 구현
- Mock 기반 테스트 스위트와 커버리지 기준(80%+) 충족
