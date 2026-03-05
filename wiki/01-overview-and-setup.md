# 01. 개요와 설치

이 페이지에서는 `klasflow`를 어떤 철학으로 사용해야 하는지, 그리고 최소 실행 환경을 어떻게 준비하는지 설명합니다.

## 1) klasflow를 왜 쓰나요?

보통 KLAS 연동을 직접 구현하면 아래처럼 코드가 저수준으로 흐르기 쉽습니다.

- 어떤 URL을 호출해야 하는지 매번 기억해야 함
- 요청마다 `payload` 키를 수동으로 조합해야 함
- 세션 만료/컨텍스트(`학기`, `과목`)를 매번 신경 써야 함

`klasflow`는 이 문제를 줄이기 위해 다음 흐름을 권장합니다.

1. `KlasClient.login()`
2. `KlasUser` 획득
3. `KlasCourse` 선택
4. `course.learning`, `course.noticeBoard` 같은 기능 객체 사용

## 2) 설치

아직 pub.dev 배포 전이므로 `path` 또는 `git` 의존성을 사용합니다.

`pubspec.yaml` (`path` 예시):

```yaml
dependencies:
  klasflow:
    path: ../klasflow
```

`pubspec.yaml` (`git` 예시):

```yaml
dependencies:
  klasflow:
    git:
      url: https://github.com/jungwuk-ryu/klas-flow.git
      ref: main
```

## 3) 가장 작은 실행 코드

```dart
import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final client = KlasClient();

  try {
    final user = await client.login('학번', '비밀번호');
    final courses = await user.courses(refresh: true);
    print('수강 과목 수: ${courses.length}');
  } finally {
    client.close();
  }
}
```

## 4) 이 페이지의 핵심

- 클래스 이름을 "API 클라이언트"보다 "도메인 객체" 관점으로 이해하세요.
- 저수준 상세보다 "사용자 -> 과목 -> 기능" 구조를 먼저 익히는 것이 중요합니다.

다음: [02. 로그인과 세션 관리](02-login-and-session.md)
