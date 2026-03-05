# 13. 오류 처리와 운영 패턴

초급자가 앱 품질을 빠르게 올릴 수 있는 운영 패턴을 정리합니다.

## 1) 예외 타입 기준 처리

```dart
try {
  final user = await client.login(id, password);
  final course = await user.defaultCourse();
  if (course == null) return;
  final notices = await course.noticeBoard.listPosts(page: 0);
  print(notices.posts.length);
} on KlasException catch (e) {
  // KLAS 요청/응답 계층 예외
  print('KLAS 오류: $e');
} catch (e) {
  // 네트워크/앱 일반 예외
  print('일반 오류: $e');
}
```

## 2) 화면별 로딩 전략

- 초기 진입: `Future.wait`로 병렬 조회
- 탭 전환: 캐시 + 수동 새로고침
- 무한 스크롤: `page` 증가 호출

## 3) 게시글 상세 안정화 패턴

일부 서버 환경은 "목록 -> 상세" 흐름이 중요합니다.  
`post.getPost()` 또는 `noticeBoard.getPost()`를 사용하면 SDK가 필요한 절차를 내부 처리합니다.

## 4) 첨부파일 다운로드 안정화 패턴

- `listByAttachId()` 결과에서 `KlasAttachedFile.download()`를 호출하세요.
- `attachId`, `fileSn`을 직접 조합하는 방식보다 안전합니다.

## 5) 세션 만료 대응

```dart
client.startSessionHeartbeat(
  interval: const Duration(minutes: 5),
  onError: (error, stackTrace) {
    // 토스트, 재로그인 유도 등
  },
);
```

## 6) 운영 체크리스트

1. 앱 종료 시 `client.close()`
2. 로그에 민감정보(학번/비밀번호/쿠키) 출력 금지
3. 실계정 테스트는 읽기 전용 시나리오만 실행

다음: [14. 고수준 API 전체 인덱스](14-high-level-api-index.md)

