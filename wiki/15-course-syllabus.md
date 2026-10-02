# 15. 강의계획서 조회

개발 버전 `1.3.0`에서 로그인한 사용자의 학부 수강 과목에 대해
`course.syllabus()`를 호출하면 `KlasSyllabus?`를 받습니다. 이 기능을 사용할
때는 새 API가 포함된 로컬 SDK 또는 해당 커밋을 가리키는 Git 의존성을 사용하세요.

```dart
import 'package:klasflow/klasflow.dart';

final user = await client.login(id, password);
final course = await user.findCourseByTitle('자료구조');
if (course == null) return;

final syllabus = await course.syllabus();
if (syllabus == null) {
  print('등록된 강의계획서가 없습니다.');
  return;
}

print(syllabus.title);
print(syllabus.summary);
print(syllabus.objectives);
for (final assessment in syllabus.assessments) {
  print('${assessment.category.name}: ${assessment.percentage ?? "미기재"}');
}
for (final week in syllabus.weeks) {
  print('${week.week}주차: ${week.content ?? "미기재"}');
  if (week.notes != null) print(week.notes);
  if (week.makeUpPlan != null) print('보강: ${week.makeUpPlan}');
}
```

SDK가 선택한 과목의 학기와 분반을 사용합니다. 브라우저나 UI를 띄우지 않으므로
Flutter, 서버 프로그램, CLI 등에서 같은 API를 호출할 수 있습니다. 공통
강의계획서를 사용하는 과목은 공통 본문과 평가 비율을 가져오고, 해당 분반의
교재와 주차별 계획을 결합합니다. `usesSharedPlan`으로 이 경우를 확인합니다.

| 항목 | 공개 모델 또는 필드 |
|---|---|
| 과목명, 영문명, 학정번호, 이수구분 | `title`, `englishTitle`, `academicNumber`, `category` |
| 학점, 시간, 이론·실험·설계 학점 | `credits`, `classHours`, `theoryCredits`, `laboratoryCredits`, `designCredits` |
| 교수, 공동 교수, 조교 연락처 | `instructor`, `coInstructors`, `assistants`: `KlasSyllabusInstructor` |
| 요일, 교시, 강의실 | `classTimes`: `KlasSyllabusClassTime` |
| 개요, 학습목표, 대표역량 | `summary`, `objectives`, `competency` |
| 권장 선수·병수·후수 과목 | `prerequisites`, `concurrentCourses`, `followUpCourses` |
| 선택된 강의유형과 운영 방식 | `teachingMethods`, `deliveryModes`, `teachingNotes` |
| 평가 항목과 반영 비율 | `assessments`: `KlasSyllabusAssessment`, `assessmentNotes` |
| 주교재와 부교재 | `textbooks`: `KlasSyllabusTextbook`, `textbookNotes` |
| 주차별 내용, 운영 메모, 보강 계획 | `weeks`: `KlasSyllabusWeek`, `weeklyNotes` |
| 교과목 학습성과와 반영 비율 | `learningOutcomes`: `KlasSyllabusLearningOutcome` |

목록은 수정할 수 없습니다. 미기재 문자열과 숫자는 `null`이고, 비율 `0`은
실제로 기재된 0%입니다. 텍스트의 줄바꿈은 유지됩니다. 주차별 내용·메모·보강
계획이 모두 비어 있는 주차는 목록에서 제외됩니다. 평가 항목 중 미기재 비율은
자동으로 채우지 않으며, 앱에서 합산할 때도 이를 구분하세요.

계획서가 미등록이거나 폐강 과목이면 `null`을 반환합니다. KLAS가 조회를 일시
제한하면 `ServiceUnavailableException`, 예상하지 못한 응답 형식이나 잘못된
과목의 응답은 `ParsingException`이 발생합니다. 네트워크와 인증 오류도
미등록 계획서로 처리되지 않습니다.

이번 기능은 학부 수강 과목의 강의계획서 조회를 지원합니다. 대학원 전용 화면,
수강하지 않는 과목 검색, 공학교육의 별도 실험·설계 상세표, 인쇄와 수강인원
조회는 포함하지 않습니다. `klas-cli`의 강의계획서 명령은 아직 제공하지
않으며, CLI 개발자는 이 SDK API를 통해 구현할 수 있습니다.

2026-10-03 읽기 전용 실계정 검증에서 현재 학기 6과목의 개요·학습목표,
15주차 계획, 시간표와 교재 조회에 성공했고 평가 비율 합계는 각각 100%였습니다.
공통형 계획서는 합성 HTTP 데이터로 검증했습니다. 실제 계정의 응답 원본과
식별자는 저장소에 기록하지 않았습니다.
