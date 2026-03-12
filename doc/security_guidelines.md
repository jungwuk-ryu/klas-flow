# Security Guidelines

## 1) Credential Handling

- 학번/비밀번호는 코드에 하드코딩하지 않는다.
- 런타임 주입(환경변수, 안전한 secure storage)만 사용한다.
- 자동 세션 연장이 필요 없으면 `cacheCredentialsForAutoRenewal: false`로 설정한다.

## 2) Logging & Observability

- 아래 값은 로그/분석 시스템에 저장하지 않는다.
  - 학번, 비밀번호
  - 세션 쿠키(`JSESSIONID`, `SESSION` 등)
  - 암호화 로그인 토큰
- 오류 문자열 출력 시 사용자 식별자 마스킹 정책을 적용한다.

## 3) Real Account Testing

- 실계정 테스트는 읽기 전용 API만 호출한다.
- 게시글 등록/수정/삭제, 제출/신청 같은 상태 변경 API는 금지한다.
- 점검 자동화는 `tool/live_account_scenarios.dart`를 기준으로 유지한다.

## 4) Repository Hygiene

- 비공개 명세 문서는 git tracked 상태가 되면 안 된다.
- 배포 전 반드시 아래를 실행한다.
  - `dart run tool/prepublish_check.dart`
  - `dart run tool/check_all.dart`

## 5) Incident Response

- API 변경 징후(파싱 실패 증가, 404/405 급증)를 감지하면:
1. `runHealthCheck()` 실행
2. 실패 endpoint 식별
3. parser/endpoint 경로 보강
4. 회귀 테스트 추가 후 배포
