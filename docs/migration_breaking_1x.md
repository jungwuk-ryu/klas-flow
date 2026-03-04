# Migration Guide (1.x Breaking)

이 문서는 기존 저수준 호출 방식에서 새 도메인 API로 옮길 때의 치환표입니다.

## 핵심 변경

- `login()` 반환값: `Future<void>` -> `Future<KlasUser>`
- `client.endpoints.*` 제거
- `client.api.call*` 제거
- `setContext()`/`loginAndBootstrap()` 제거

## 치환표

| 이전 API | 새 API |
|---|---|
| `await client.login(id, pw)` | `final user = await client.login(id, pw)` |
| `client.loginAndBootstrap(id, pw)` | `client.login(id, pw)` 후 `user.profile()` + `user.courses()` |
| `client.endpoints.learning.taskStdList(payload: {'currentPage': 0})` | `final course = await user.defaultCourse(); await course?.listTasks(page: 0)` |
| `client.setContext(...)` | `final courses = await user.courses(); final selected = courses[i];` |
| `client.api.callObject('session.info')` | `await user.sessionStatus()` |
| `client.updateSession()` | `await user.keepAlive()` |

## 예시

```dart
final client = KlasClient();
final user = await client.login(id, password);

final profile = await user.profile(refresh: true);
final courses = await user.courses(refresh: true);
final selected = courses.first;

final tasks = await selected.listTasks(page: 0);
final notices = await selected.noticeBoard.listPosts(page: 0);
```
