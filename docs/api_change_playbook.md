# API Change Playbook

KLAS API가 바뀌어 요청이 실패할 때의 표준 대응 절차입니다.

## 1) 현상 재현

1. `dart run tool/live_account_scenarios.dart`
2. 실패한 시나리오/endpoint ID 기록
3. 실패 유형 분류
- 인증 실패
- 상태 코드 변경(404/405/500)
- 응답 필드 변경(파싱 실패)

## 2) 영향 범위 파악

- `client.endpoints.*` 호출인지
- `client.api.call*` 호출인지
- 공통 parser/transport 레벨 영향인지

## 3) 단기 복구

- endpoint 경로 변경이면 `ApiPaths` override로 임시 복구
- parser 변경이면 최소 필드만 우선 파싱되도록 완화
- 세션 흐름 변경이면 `auth_flow/auth_api` 우선 수정

## 4) 장기 수정

- 실패 케이스를 단위 테스트로 추가
- `runHealthCheck()` 항목 상세화
- 문서(README/튜토리얼) 업데이트

## 5) 릴리스 전 확인

- `dart run tool/check_all.dart`
- `dart run tool/prepublish_check.dart`
- 실계정 read-only 시나리오 재실행
