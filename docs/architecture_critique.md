# Architecture Critique

이 문서는 현재 `klasflow` 구조를 비판적으로 검토한 결과입니다.

## What Works Well

- 앱 코드 단순화
  - 로그인, 세션, 컨텍스트 처리가 `KlasClient` 뒤로 숨겨진다.
- 변경 격리
  - 로그인 프로토콜 변경이 `auth/parsers` 계층에서 해결 가능하다.
- 운영 진단 가능성
  - `runHealthCheck()`와 라이브 시나리오 러너로 장애 지점 파악이 가능하다.

## Weak Points

- 동적 JSON 의존
  - 많은 endpoint가 `Map<String, dynamic>`/`List<dynamic>`라 컴파일 타임 안정성이 낮다.
- 카탈로그 유지비
  - endpoint 변화가 잦으면 catalog + wrapper 관리 비용이 누적된다.
- 세션 정책 표준화 부족
  - 앱마다 “자동 재로그인 vs 수동 재로그인” UX 기준이 다르다.

## Why This Can Still Be Adopted

실무 채택의 핵심은 “완벽한 구조”보다 “운영 가능한 구조”다.
- 빠른 통합 가능
- 장애 진단 루트 존재
- 보안 체크 도구 포함

즉, 초기에 채택하기엔 충분히 실용적이다.

## Alternatives Considered

1. Fully typed domain SDK
- 장점: 안정성 높음
- 단점: 구현/유지 비용 큼, KLAS 응답 변경 시 비용 급증

2. Thin HTTP wrapper only
- 장점: 단순
- 단점: 앱마다 로그인/세션/컨텍스트 로직을 반복 구현

현재 구조는 두 극단 사이에서 균형을 선택한 상태다.

## Recommended Next Refactors

1. 사용 빈도 높은 endpoint부터 강타입 모델 도입
2. health check 실패 유형별 자동 분류(인증/경로변경/파싱)
3. Flutter 레퍼런스 앱 제공으로 채택 마찰 감소
