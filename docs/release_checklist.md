# Public Release Checklist

## 1) 코드/테스트

- 통합 점검: `dart run tool/check_all.dart`
- `dart pub get`
- `dart analyze`
- `dart test`
- `dart run tool/generate_typed_endpoints.dart`
- `git diff --exit-code -- lib/src/api/typed_endpoints.dart`
- `dart pub outdated`로 주요 의존성 업데이트 가능 여부 점검

## 2) 보안/비공개 문서

- 비공개 명세 파일이 git tracked 상태가 아닌지 확인
  - `klas-api-spec.md`
  - `klasflow_LLM_RFP_with_API_Spec.md`
- `dart run tool/prepublish_check.dart` 실행
- 필요 시 차단 문자열 검사
  - `dart run tool/prepublish_check.dart --block="value1,value2"`

## 3) 문서/예제

- README 예제 코드가 최신 API 시그니처와 일치하는지 확인
- `example/` Flutter 데모 앱이 실제로 실행되는지 확인
  - `cd example`
  - `flutter pub get`
  - `flutter run`
- 위험한 쓰기 API 예제가 포함되지 않았는지 확인

## 4) 배포 메타데이터

- `pubspec.yaml`의 `version`, `homepage`, `repository`, `issue_tracker` 갱신
- `CHANGELOG.md`에 변경 사항 기록
