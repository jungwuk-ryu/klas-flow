# 05. 공지사항/자료실 조회

공지사항과 강의자료실은 구조가 매우 비슷합니다.  
차이는 "어떤 보드 객체를 쓰느냐"입니다.

## 1) 공지사항 목록: `course.noticeBoard.listPosts`

```dart
final notices = await course.noticeBoard.listPosts(page: 0);
for (final post in notices.posts) {
  print('${post.title} / 작성자=${post.authorName}');
}
```

추가 검색도 가능합니다.

```dart
final filtered = await course.noticeBoard.listPosts(
  page: 0,
  keyword: '중간고사',
  searchCondition: 'ALL',
);
```

## 2) 자료실 목록: `course.materialBoard.listPosts`

```dart
final materials = await course.materialBoard.listPosts(page: 0);
for (final post in materials.posts) {
  print('${post.title} / 첨부수=${post.fileCount ?? 0}');
}
```

## 3) 페이지 정보 사용

```dart
final page = notices.page;
if (page != null) {
  print('현재=${page.currentPage}, 전체=${page.totalPages}');
}
```

목록 하단 페이지네이터 UI를 만들 때 `KlasPageInfo`를 그대로 사용하세요.

## 4) 상세 조회 방식 2가지

### 방식 A: 보드 객체에서 직접 조회

```dart
final detail = await course.noticeBoard.getPost(boardNo: 123456);
```

### 방식 B: 목록 요약에서 바로 조회

```dart
final first = notices.posts.first;
final detail = await first.getPost();
```

`first.getPost()`는 보드 컨텍스트를 이어받기 때문에 초급자에게 특히 편합니다.

다음: [06. 첨부파일 다운로드](06-attachments-download.md)

