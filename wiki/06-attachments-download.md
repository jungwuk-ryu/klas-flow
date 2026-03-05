# 06. 첨부파일 다운로드

게시글 상세를 열었을 때 첨부파일 목록과 다운로드를 처리하는 실전 예제입니다.

## 1) 게시글에서 `attachId` 꺼내기

```dart
final notices = await course.noticeBoard.listPosts(page: 0);
if (notices.posts.isEmpty) return;

final post = notices.posts.firstWhere((p) => p.hasAttachments);
final attachId = post.attachId;
if (attachId == null || attachId.isEmpty) return;
```

## 2) 첨부파일 목록 조회: `user.files.listByAttachId`

```dart
final files = await user.files.listByAttachId(attachId: attachId);
for (final f in files) {
  print('${f.fileName} (${f.size ?? 0} bytes)');
}
```

- 반환 타입: `List<KlasAttachedFile>`
- 서버 차이를 SDK가 흡수하도록 설계되어 있습니다.

## 3) 다운로드 방식 2가지

### 방식 A: 파일 객체에서 바로 다운로드 (권장)

```dart
final payload = await files.first.download();
print(payload.fileName);
print(payload.bytes.length);
```

### 방식 B: feature 메서드로 직접 다운로드

```dart
final payload = await user.files.download(
  attachId: files.first.attachId!,
  fileSn: files.first.fileSn!,
);
```

## 4) Flutter 저장 예시

```dart
import 'dart:io';

Future<void> saveToTemp(FilePayload payload) async {
  final path = '${Directory.systemTemp.path}/${payload.fileName ?? 'download.bin'}';
  final file = File(path);
  await file.writeAsBytes(payload.bytes, flush: true);
}
```

다음: [07. 온라인 학습 기능](07-learning-features.md)

