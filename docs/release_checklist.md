# Public Release Checklist

## 1) 코드/테스트

- `dart pub get`
- `dart analyze`
- `dart test`

## 2) 보안/비공개 문서

- 비공개 명세 파일이 git tracked 상태가 아닌지 확인
  - `klas-api-spec.md`
  - `klasflow_LLM_RFP_with_API_Spec.md`
- `dart run tool/prepublish_check.dart` 실행
- 필요 시 차단 문자열 검사
  - PowerShell: `$env:KLASFLOW_BLOCKED_LITERALS="value1,value2"`
  - 그 다음 `dart run tool/prepublish_check.dart`

## 3) 문서/예제

- README 예제 코드가 최신 API 시그니처와 일치하는지 확인
- `example/*.dart` 실행 커맨드가 실제로 동작하는지 확인
- 위험한 쓰기 API 예제가 포함되지 않았는지 확인

## 4) 배포 메타데이터

- `pubspec.yaml`의 `version`, `homepage`, `repository`, `issue_tracker` 갱신
- `CHANGELOG.md`에 변경 사항 기록
