import 'dart:convert';

import '../exceptions/klas_exceptions.dart';
import '../models/course_context.dart';
import '../models/syllabus.dart';
import 'request_executor.dart';

const _root = '/std/cps/atnlc/';

/// 과목에 바인딩된 강의계획서를 읽고 앱에서 사용할 모델로 변환합니다.
final class SyllabusApi {
  final RequestExecutor _requests;

  SyllabusApi(this._requests);

  Future<KlasSyllabus?> fetch(CourseContext context) async {
    final payload = <String, dynamic>{
      ...context.toFormData(),
      'incLc': 'popup',
    };
    final term = RegExp(
      r'^(\d{4})[,\-]?(\d)$',
    ).firstMatch(context.selectYearhakgi.trim());
    if (term != null) {
      payload['selectYear'] = term[1];
      payload['selecthakgi'] = term[2];
      payload['selectYearHakgi'] = '${term[1]},${term[2]}';
    }

    final stop = await _post('LctrePlanStopFlag.do', const {});
    if (stop != null && stop != '') {
      final flag = _object(stop)['stopFlag'];
      if (flag == 'Y') {
        throw const ServiceUnavailableException(
          'Syllabus access is temporarily restricted by KLAS.',
        );
      }
      if (flag != 'N') {
        throw const ParsingException('Invalid syllabus access restriction.');
      }
    }

    final rows = _rows(await _post('LectrePlanData.do', payload));
    if (rows.isEmpty) return null;
    if (rows.length != 1) {
      throw const ParsingException(
        'Expected one syllabus for the selected course.',
      );
    }
    final info = rows.single;
    if (_text(info, 'closeOpt') == 'Y') return null;
    _checkCourse(info, context);

    final culture = await _post('CultureOptOneInfo.do', payload);
    final shared =
        culture != null &&
        culture != '' &&
        _object(culture)['cultureOpt'] != null;
    final content = shared
        ? _object(await _post('LectrePlanInputTabOneFixedInfo.do', payload))
        : info;
    if (content.isEmpty && shared) {
      throw const ParsingException('Shared syllabus content is missing.');
    }
    if (content['summary'] == null) return null;

    final times = _rows(await _post('LectreTimeInfo.do', payload));
    final assistants = _rows(await _post('LectreAstnt.do', payload));
    final team = shared
        ? const <Map<String, dynamic>>[]
        : _rows(await _post('LectreTeam.do', payload));
    return _parseSyllabus(
      context,
      info,
      content,
      shared,
      times,
      assistants,
      team,
    );
  }

  Future<Object?> _post(String path, Map<String, dynamic> payload) async {
    final text = await _requests.postJsonText(
      '$_root$path',
      payload: payload,
      includeContext: false,
    );
    if (text.trim().isEmpty) return null;
    try {
      final result = jsonDecode(text);
      return result is Map && result.length == 1 && result.containsKey('data')
          ? result['data']
          : result;
    } on FormatException {
      throw const ParsingException('Invalid syllabus JSON response.');
    }
  }
}

KlasSyllabus _parseSyllabus(
  CourseContext context,
  Map<String, dynamic> info,
  Map<String, dynamic> content,
  bool shared,
  List<Map<String, dynamic>> times,
  List<Map<String, dynamic>> assistants,
  List<Map<String, dynamic>> team,
) {
  final textbooks = <KlasSyllabusTextbook>[];
  for (var index = 0; index < 4; index++) {
    final suffix = index == 0 ? '' : '$index';
    final title = _text(info, 'book${suffix}Name');
    final author = _text(info, 'write${suffix}Name');
    final publisher = _text(info, 'company${suffix}Name');
    final year = _text(info, 'print${suffix}Year');
    if ([title, author, publisher, year].every((value) => value == null)) {
      continue;
    }
    textbooks.add(
      KlasSyllabusTextbook(
        isPrimary: index == 0,
        title: title,
        author: author,
        publisher: publisher,
        publicationYear: year,
      ),
    );
  }
  final weeks = <KlasSyllabusWeek>[];
  for (var week = 1; week <= 16; week++) {
    final lecture = _text(info, 'week${week}Lecture');
    final notes = _text(info, 'week${week}Bigo');
    final makeUp = _text(info, 'week${week}Subs');
    if (lecture == null && notes == null && makeUp == null) continue;
    weeks.add(
      KlasSyllabusWeek(
        week: week,
        content: lecture,
        notes: notes,
        makeUpPlan: makeUp,
      ),
    );
  }
  final outcomes = <KlasSyllabusLearningOutcome>[];
  for (var number = 1; number <= 20; number++) {
    // The official view shows outcomes with a configured reflection percentage.
    if (info['reflectPer$number'] == null) continue;
    outcomes.add(
      KlasSyllabusLearningOutcome(
        number: number,
        title: _text(info, 'studyResultShort$number'),
        description: _text(info, 'result$number'),
        reflectionPercentage: _percentage(info, 'reflectPer$number'),
      ),
    );
  }
  final assessmentFields = shared ? _sharedAssessments : _assessments;
  return KlasSyllabus(
    courseId: context.selectSubj,
    termId: context.selectYearhakgi,
    title: _text(info, 'gwamokKname') ?? _text(info, 'gwamokkename'),
    englishTitle: _text(info, 'gwamokEname'),
    academicNumber: _academicNumber(info),
    category: _text(info, 'codeName1'),
    credits: _number(info, 'hakjumNum'),
    classHours: _number(info, 'sisuNum'),
    theoryCredits: _number(info, 'getScore1'),
    laboratoryCredits: _number(info, 'getScore2'),
    designCredits: _number(info, 'getScore3'),
    instructor: KlasSyllabusInstructor(
      name: _text(info, 'memberName'),
      role: _text(info, 'jikgeubName'),
      phone: _text(info, 'telNo'),
      mobilePhone: _text(info, 'hpNo'),
      email: _text(info, 'email'),
    ),
    coInstructors: team
        .map(
          (row) => KlasSyllabusInstructor(
            name: _text(row, 'teamName'),
            email: _text(row, 'teamEmail'),
          ),
        )
        .toList(),
    assistants: assistants
        .map(
          (row) => KlasSyllabusInstructor(
            name: _text(row, 'name'),
            email: _text(row, 'astntemail'),
          ),
        )
        .toList(),
    classTimes: times.map(_classTime).toList(),
    usesSharedPlan: shared,
    summary: _text(content, 'summary'),
    objectives: _text(content, 'purpose'),
    competency: _text(info, 'gwamokAble'),
    prerequisites: _text(content, 'preGwamok'),
    concurrentCourses: shared ? null : _text(info, 'pairGwamok'),
    followUpCourses: _text(content, 'postGwamok'),
    teachingNotes: _text(content, 'lessonProcess'),
    teachingMethods: _selected(
      content,
      shared ? _sharedMethods : _methods,
      truthy: shared,
    ),
    deliveryModes: _selected(info, _deliveryModes),
    assessments: assessmentFields.entries
        .map(
          (entry) => KlasSyllabusAssessment(
            category: entry.key,
            percentage: _percentage(content, entry.value),
          ),
        )
        .toList(),
    assessmentNotes: _text(info, 'gitaDetail'),
    textbooks: textbooks,
    textbookNotes: _text(info, 'bigo'),
    weeks: weeks,
    weeklyNotes: _text(info, 'weekGita'),
    learningOutcomes: outcomes,
  );
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const ParsingException('Expected a syllabus object.');
  }
  return value;
}

List<Map<String, dynamic>> _rows(Object? value) {
  if (value == null || value == '') return const [];
  if (value is! List) throw const ParsingException('Expected syllabus rows.');
  return value.map(_object).toList();
}

String? _text(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String && value is! num) {
    throw const ParsingException('Invalid syllabus text field.');
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double? _number(Map<String, dynamic> row, String key) {
  final text = _text(row, key);
  if (text == null) return null;
  final value = double.tryParse(text);
  if (value == null || !value.isFinite || value < 0) {
    throw const ParsingException('Invalid syllabus numeric field.');
  }
  return value;
}

double? _percentage(Map<String, dynamic> row, String key) {
  final value = _number(row, key);
  if (value != null && value > 100) {
    throw const ParsingException('Invalid syllabus percentage.');
  }
  return value;
}

String? _academicNumber(Map<String, dynamic> info) {
  final parts = [
    'openMajorCode',
    'openGrade',
    'openGwamokNo',
    'bunbanNo',
  ].map((key) => _text(info, key)).toList();
  return parts.any((part) => part == null) ? null : parts.join('-');
}

void _checkCourse(Map<String, dynamic> row, CourseContext context) {
  if (_academicNumber(row) == null) return;
  // The undergraduate ID also carries the year/semester and the section number.
  final term = context.selectYearhakgi.replaceAll(RegExp(r'\D'), '');
  final expected =
      'U$term${row['openGwamokNo']}${row['openMajorCode']}'
      '${row['bunbanNo']}${row['openGrade']}';
  if (context.selectSubj.startsWith('U') && context.selectSubj != expected) {
    throw const ParsingException('The syllabus belongs to another course.');
  }
}

KlasSyllabusClassTime _classTime(Map<String, dynamic> row) {
  final periods = <int>[];
  for (var index = 1; index <= 4; index++) {
    final number = _number(row, 'timeNo$index');
    if (number == null) continue;
    if (number == 0 || number != number.truncateToDouble()) {
      throw const ParsingException('Invalid syllabus class period.');
    }
    periods.add(number.toInt());
  }
  return KlasSyllabusClassTime(
    day: _text(row, 'dayname1'),
    periods: periods,
    rooms: [?_text(row, 'locHname'), ?_text(row, 'locHname2')],
  );
}

List<String> _selected(
  Map<String, dynamic> row,
  Map<String, String> fields, {
  bool truthy = false,
}) {
  return [
    for (final entry in fields.entries)
      if (truthy
          ? row[entry.key] != null &&
                row[entry.key] != '' &&
                row[entry.key] != 0 &&
                row[entry.key] != false
          : row[entry.key] == 'Y' ||
                row[entry.key] == '1' ||
                row[entry.key] == 1 ||
                row[entry.key] == true)
        entry.value,
  ];
}

const _assessments = <KlasSyllabusAssessmentCategory, String>{
  KlasSyllabusAssessmentCategory.attendance: 'attendBiyul',
  KlasSyllabusAssessmentCategory.midterm: 'middleBiyul',
  KlasSyllabusAssessmentCategory.finalExam: 'lastBiyul',
  KlasSyllabusAssessmentCategory.assignment: 'reportBiyul',
  KlasSyllabusAssessmentCategory.participation: 'learnBiyul',
  KlasSyllabusAssessmentCategory.quiz: 'quizBiyul',
  KlasSyllabusAssessmentCategory.presentation: 'presentationBiyul',
  KlasSyllabusAssessmentCategory.discussion: 'discussionBiyul',
  KlasSyllabusAssessmentCategory.other: 'gitaBiyul',
};
const _sharedAssessments = <KlasSyllabusAssessmentCategory, String>{
  KlasSyllabusAssessmentCategory.attendance: 'lAttendBiyul',
  KlasSyllabusAssessmentCategory.midterm: 'lMiddleBiyul',
  KlasSyllabusAssessmentCategory.finalExam: 'lLastBiyul',
  KlasSyllabusAssessmentCategory.assignment: 'lReportBiyul',
  KlasSyllabusAssessmentCategory.participation: 'lLearnBiyul',
  KlasSyllabusAssessmentCategory.quiz: 'lQuizBiyul',
  KlasSyllabusAssessmentCategory.presentation: 'lPresentationBiyul',
  KlasSyllabusAssessmentCategory.discussion: 'lDiscussionBiyul',
  KlasSyllabusAssessmentCategory.other: 'lGitaBiyul',
};
const _methods = <String, String>{
  'tblOpt': 'TBL강의',
  'pblOpt': 'PBL강의',
  'typeFlipped': '플립드러닝',
  'seminarOpt': '세미나강의',
  'typeSmall': '소규모강의',
  'typeFusion': '융합강의',
  'typeTeam': '팀티칭강의',
  'typeWork': '일학습병행강의',
  'typeForeigner': '외국인전용강의',
  'typeElearn': '서울권역e-러닝',
  'typeExperiment': '실험실습실기설계강의',
  'typeJibjung': '집중이수제강의',
  'onlineOpt': '원격수업 (100%)',
  'typeBlended': '원격수업 (50% 이상)',
};
const _sharedMethods = <String, String>{
  'fixedLectureOpt': '강의',
  'fixedDiscussionOpt': '토론',
  'fixedPresentationOpt': '발표',
  'fixedExperimentOpt': '실험',
  'fixedShortReportOpt': '단기 보고서',
  'fixedLongReportOpt': '장기 보고서',
  'fixedPracticeOpt': '실습',
  'fixedGitaOpt': '기타',
};
const _deliveryModes = <String, String>{
  'face100Opt': '100%대면강의',
  'faceliveOpt': '대면+실시간 화상강의',
  'facerecOpt': '대면+사전녹화강의',
  'faceliverecOpt': '대면+실시간 화상강의+사전녹화강의',
  'recliveOpt': '실시간 화상강의+사전녹화강의',
  'live100Opt': '100%실시간 화상강의',
  'rec100Opt': '100%사전녹화강의',
};
