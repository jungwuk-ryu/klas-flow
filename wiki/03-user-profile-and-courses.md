# 03. 사용자 정보와 수강 과목 컨텍스트

이 페이지는 `KlasUser`와 `KlasCourse`를 제대로 이해하는 데 집중합니다.

## 1) 사용자 프로필

```dart
final profile = await user.profile(refresh: true);
print(profile.userName);
print(profile.userId);
```

- `refresh: false`(기본): 캐시된 값 사용
- `refresh: true`: 서버에서 다시 조회

## 2) 개인정보(학번/이름/이메일 등)

```dart
final info = await user.personalInfo(refresh: true);
print(info.userName);
print(info.userId);
print(info.email);
```

`profile()`이 빈 값을 줄 때 `personalInfo()`가 더 풍부한 값을 줄 수 있습니다.

## 3) 수강 과목 목록

```dart
final courses = await user.courses(refresh: true);
for (final c in courses) {
  print('${c.title} / ${c.professorName} / ${c.termId}');
}
```

`KlasCourse`는 과목 컨텍스트를 이미 포함합니다.  
그래서 이후 기능 호출 시 과목/학기 정보를 따로 넣지 않아도 됩니다.

## 4) 기본 과목 선택

```dart
final course = await user.defaultCourse();
if (course == null) return;
print(course.courseId);
```

앱 첫 화면에서는 보통 `defaultCourse()`를 먼저 사용합니다.

## 5) `KlasCourse` 주요 속성

- `courseId`: 과목 식별자
- `termId`: 학기 식별자
- `title`: 과목명
- `professorName`: 교수명
- `isDefault`: 기본 과목 여부
- `rawContext`: 원본 컨텍스트
- `owner`: 이 과목을 소유한 `KlasUser`

다음: [04. 과목 개요와 과제 조회](04-course-overview-and-tasks.md)

