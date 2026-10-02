import 'package:http/http.dart' as http;
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

import 'support/mobile_qr_fixture.dart';
import 'support/syllabus_fixture.dart';

void main() {
  test(
    'ordinary syllabus preserves course contents, contacts and optional values',
    () async {
      final fixture = SyllabusFixture();
      addTearDown(fixture.close);
      final course = await fixture.course();
      final plan = (await course.syllabus())!;
      expect(plan.courseId, course.courseId);
      expect(plan.termId, course.termId);
      expect(plan.title, '자료구조');
      expect(plan.englishTitle, 'Data Structures');
      expect(plan.academicNumber, 'CSE-3-101-01');
      expect(plan.category, '전선');
      expect(plan.credits, 3);
      expect(plan.classHours, 3);
      expect(plan.theoryCredits, 2.5);
      expect(plan.laboratoryCredits, 0.5);
      expect(plan.designCredits, isNull);
      expect(plan.instructor.name, '테스트 교수');
      expect(plan.instructor.role, '교수');
      expect(plan.instructor.phone, '000-000-0000');
      expect(plan.instructor.mobilePhone, isNull);
      expect(plan.instructor.email, 'professor@example.com');
      expect(plan.coInstructors.single.email, 'co@example.com');
      expect(plan.assistants.single.email, 'assistant@example.com');
      expect(plan.classTimes.first.day, '월');
      expect(plan.classTimes.first.periods, [3, 4]);
      expect(plan.classTimes.first.rooms, ['테스트101', '테스트102']);
      expect(plan.classTimes.last.rooms, isEmpty);
      expect(plan.summary, '자료구조 이해\n알고리즘 설계');
      expect(plan.objectives, '스택과 큐를 구현한다.');
      expect(plan.competency, '문제해결');
      expect(plan.prerequisites, '기초 프로그래밍');
      expect(plan.concurrentCourses, '자료구조 실습');
      expect(plan.followUpCourses, '알고리즘');
      expect(plan.teachingMethods, ['TBL강의', '원격수업 (50% 이상)']);
      expect(plan.deliveryModes, ['대면+사전녹화강의']);
      final percentages = {
        for (final a in plan.assessments) a.category: a.percentage,
      };
      expect(percentages[KlasSyllabusAssessmentCategory.finalExam], 30.5);
      expect(percentages[KlasSyllabusAssessmentCategory.participation], 0);
      expect(percentages[KlasSyllabusAssessmentCategory.other], isNull);
      expect(plan.assessmentNotes, '문제는 강의내용을 기준으로 한다.');
      expect(plan.textbooks, hasLength(2));
      expect(plan.textbooks.first.isPrimary, isTrue);
      expect(plan.textbooks.first.publicationYear, '2025');
      expect(plan.textbooks.last.isPrimary, isFalse);
      expect(plan.textbookNotes, '교재 구매는 선택이다.');
      expect(plan.weeks.map((w) => w.week), [1, 5, 16]);
      expect(plan.weeks.first.content, '소개\n기본 개념');
      expect(plan.weeks[1].notes, '연습 과제');
      expect(plan.weeks[1].makeUpPlan, '보강 동영상');
      expect(plan.weeklyNotes, '일정은 변경될 수 있다.');
      expect(plan.learningOutcomes.map((o) => o.number), [1, 8]);
      expect(plan.learningOutcomes.first.reflectionPercentage, 50);
      expect(plan.usesSharedPlan, isFalse);
      expect(plan.weeks.first.content, isNot(contains('{{')));
      for (final path in syllabusReadPaths) {
        final request = fixture.calls(path).single;
        expect(request.method, 'POST');
        if (path == 'LctrePlanStopFlag.do') continue;
        expect(syllabusBody(request)['selectSubj'], qrSubjectId);
        expect(syllabusBody(request)['selectYear'], '2026');
        expect(syllabusBody(request)['selecthakgi'], '1');
      }
    },
  );

  test(
    'shared syllabus uses common contents and assessments with section-specific weeks',
    () async {
      final fixture = SyllabusFixture(shared: true);
      addTearDown(fixture.close);
      final plan = (await (await fixture.course()).syllabus())!;
      expect(plan.usesSharedPlan, isTrue);
      expect(plan.summary, '분반 공통 개요');
      expect(plan.objectives, '공통 학습목표');
      expect(plan.prerequisites, '공통 선수과목');
      expect(plan.followUpCourses, '공통 후수과목');
      expect(plan.concurrentCourses, isNull);
      expect(plan.assessments.first.percentage, 20);
      expect(
        plan.assessments
            .where(
              (a) => a.category == KlasSyllabusAssessmentCategory.presentation,
            )
            .single
            .percentage,
        5,
      );
      expect(plan.teachingMethods, ['강의', '토론']);
      expect(plan.teachingNotes, '강의와 토론을 진행한다.');
      expect(plan.weeks.first.content, '소개\n기본 개념');
      expect(plan.textbooks.first.title, 'Synthetic Data Structures');
      expect(fixture.calls('LectrePlanInputTabOneFixedInfo.do'), hasLength(1));
      expect(fixture.calls('LectreTeam.do'), isEmpty);
    },
  );

  for (final response in <Object?>[null, [], '']) {
    test(
      'missing syllabus rows ($response) return null without extra reads',
      () async {
        final fixture = SyllabusFixture(
          handle: (r) => r.url.path.endsWith('/LectrePlanData.do')
              ? qrJson(response)
              : null,
        );
        addTearDown(fixture.close);
        expect(await (await fixture.course()).syllabus(), isNull);
        expect(fixture.calls('CultureOptOneInfo.do'), isEmpty);
        expect(fixture.calls('LectreTimeInfo.do'), isEmpty);
      },
    );
  }

  test('a closed course returns null without reading its contents', () async {
    final fixture = SyllabusFixture(
      handle: (r) => r.url.path.endsWith('/LectrePlanData.do')
          ? qrJson([
              {...syllabusRow(), 'closeOpt': 'Y'},
            ])
          : null,
    );
    addTearDown(fixture.close);
    expect(await (await fixture.course()).syllabus(), isNull);
    expect(fixture.calls('CultureOptOneInfo.do'), isEmpty);
  });

  test(
    'unregistered summary returns null but a registered blank summary is allowed',
    () async {
      var summary = null as String?;
      final fixture = SyllabusFixture(
        handle: (r) => r.url.path.endsWith('/LectrePlanData.do')
            ? qrJson([
                {...syllabusRow(), 'summary': summary},
              ])
            : null,
      );
      addTearDown(fixture.close);
      final course = await fixture.course();
      expect(await course.syllabus(), isNull);
      expect(fixture.calls('LectreTimeInfo.do'), isEmpty);
      summary = '';
      expect((await course.syllabus())!.summary, isNull);
      expect(fixture.calls('LectreTimeInfo.do'), hasLength(1));
    },
  );

  test(
    'temporary access restriction fails before reading a syllabus',
    () async {
      final fixture = SyllabusFixture(
        handle: (r) => r.url.path.endsWith('/LctrePlanStopFlag.do')
            ? qrJson({'stopFlag': 'Y'})
            : null,
      );
      addTearDown(fixture.close);
      final course = await fixture.course();
      await expectLater(
        course.syllabus(),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(fixture.calls('LectrePlanData.do'), isEmpty);
    },
  );

  for (final response in <Object?>[
    null,
    '',
    {'stopFlag': 'N'},
  ]) {
    test(
      'unrestricted access response ($response) continues reading',
      () async {
        final fixture = SyllabusFixture(
          handle: (r) => r.url.path.endsWith('/LctrePlanStopFlag.do')
              ? qrJson(response)
              : null,
        );
        addTearDown(fixture.close);
        expect(await (await fixture.course()).syllabus(), isNotNull);
      },
    );
  }

  for (final response in <Object?>[
    {},
    {'stopFlag': 'unknown'},
    true,
  ]) {
    test(
      'invalid restriction response ($response) is not mistaken for unrestricted access',
      () async {
        final fixture = SyllabusFixture(
          handle: (r) => r.url.path.endsWith('/LctrePlanStopFlag.do')
              ? qrJson(response)
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        await expectLater(course.syllabus(), throwsA(isA<ParsingException>()));
        expect(fixture.calls('LectrePlanData.do'), isEmpty);
      },
    );
  }

  test(
    'an empty common plan is an error, not a fallback to section data',
    () async {
      final fixture = SyllabusFixture(
        shared: true,
        handle: (r) => r.url.path.endsWith('/LectrePlanInputTabOneFixedInfo.do')
            ? qrJson({})
            : null,
      );
      addTearDown(fixture.close);
      final course = await fixture.course();
      await expectLater(course.syllabus(), throwsA(isA<ParsingException>()));
      expect(fixture.calls('LectreTimeInfo.do'), isEmpty);
    },
  );

  for (final response in <Object?>[
    {'summary': 'not an array'},
    [true],
    [syllabusRow(), syllabusRow()],
  ]) {
    test(
      'invalid or ambiguous syllabus rows produce a parsing error',
      () async {
        final fixture = SyllabusFixture(
          handle: (r) => r.url.path.endsWith('/LectrePlanData.do')
              ? qrJson(response)
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        await expectLater(course.syllabus(), throwsA(isA<ParsingException>()));
      },
    );
  }

  for (final value in <Object>['not a percentage', -1, 101, 'NaN']) {
    test(
      'invalid assessment value ($value) is not converted to zero or null',
      () async {
        final fixture = SyllabusFixture(
          handle: (r) => r.url.path.endsWith('/LectrePlanData.do')
              ? qrJson([
                  {...syllabusRow(), 'attendBiyul': value},
                ])
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        await expectLater(course.syllabus(), throwsA(isA<ParsingException>()));
      },
    );
  }

  test('a mismatched course response is rejected', () async {
    final fixture = SyllabusFixture(
      handle: (r) => r.url.path.endsWith('/LectrePlanData.do')
          ? qrJson([
              {...syllabusRow(), 'bunbanNo': '02'},
            ])
          : null,
    );
    addTearDown(fixture.close);
    final course = await fixture.course();
    await expectLater(course.syllabus(), throwsA(isA<ParsingException>()));
    expect(fixture.calls('LectreTimeInfo.do'), isEmpty);
  });

  test(
    'interleaved course queries keep their own semester and section',
    () async {
      const secondSubject = 'U20262101CSE023';
      final fixture = SyllabusFixture(
        handle: (request) {
          if (request.url.path.endsWith('/YearhakgiAtnlcSbjectList.do')) {
            return qrJson({
              'data': [
                {
                  'selectYearhakgi': '20261',
                  'selectSubj': qrSubjectId,
                  'selectChangeYn': 'N',
                  'isDefault': true,
                },
                {
                  'selectYearhakgi': '2026,2',
                  'selectSubj': secondSubject,
                  'selectChangeYn': 'Y',
                  'isDefault': false,
                },
              ],
            });
          }
          if (request.url.path.endsWith('/LectrePlanData.do')) {
            final second = syllabusBody(request)['selectSubj'] == secondSubject;
            return qrJson([
              {...syllabusRow(), 'bunbanNo': second ? '02' : '01'},
            ]);
          }
          return null;
        },
      );
      addTearDown(fixture.close);
      final courses = await (await fixture.login()).courses();
      final plans = await Future.wait([
        courses.last.syllabus(),
        courses.first.syllabus(),
      ]);
      expect(plans.first!.courseId, secondSubject);
      expect(plans.first!.termId, '2026,2');
      expect(plans.first!.academicNumber, 'CSE-3-101-02');
      expect(plans.last!.courseId, qrSubjectId);
      for (final request in fixture.requests.where(
        (r) =>
            r.url.path.startsWith(syllabusRoot) &&
            !r.url.path.endsWith('/LctrePlanStopFlag.do'),
      )) {
        final body = syllabusBody(request);
        final second = body['selectSubj'] == secondSubject;
        expect(body['selectYearhakgi'], second ? '2026,2' : '20261');
        expect(body['selectYear'], '2026');
        expect(body['selecthakgi'], second ? '2' : '1');
        expect(body['selectChangeYn'], second ? 'Y' : 'N');
      }
    },
  );

  test(
    'HTTP and malformed JSON failures are kept distinct from a missing plan',
    () async {
      var response = http.Response('Unavailable', 503);
      final fixture = SyllabusFixture(
        handle: (r) =>
            r.url.path.endsWith('/LectrePlanData.do') ? response : null,
      );
      addTearDown(fixture.close);
      final course = await fixture.course();
      await expectLater(
        course.syllabus(),
        throwsA(isA<ServiceUnavailableException>()),
      );
      response = http.Response(
        '{broken',
        200,
        headers: {'content-type': 'application/json'},
      );
      await expectLater(course.syllabus(), throwsA(isA<ParsingException>()));
    },
  );

  test('empty time and contact lists preserve a usable syllabus', () async {
    final fixture = SyllabusFixture(
      handle: (r) =>
          [
            'LectreTimeInfo.do',
            'LectreAstnt.do',
            'LectreTeam.do',
          ].any(r.url.path.endsWith)
          ? qrJson([])
          : null,
    );
    addTearDown(fixture.close);
    final plan = (await (await fixture.course()).syllabus())!;
    expect(plan.classTimes, isEmpty);
    expect(plan.assistants, isEmpty);
    expect(plan.coInstructors, isEmpty);
    expect(plan.summary, isNotNull);
    expect(() => plan.weeks.clear(), throwsUnsupportedError);
    expect(() => plan.assessments.clear(), throwsUnsupportedError);
  });
}
