import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:klasflow/klasflow.dart';

import 'mobile_qr_fixture.dart';

const syllabusRoot = '/std/cps/atnlc/';
const syllabusReadPaths = <String>[
  'LctrePlanStopFlag.do',
  'LectrePlanData.do',
  'CultureOptOneInfo.do',
  'LectreTimeInfo.do',
  'LectreAstnt.do',
  'LectreTeam.do',
];

/// All fields are synthetic and unrelated to live KLAS contents or contacts.
Map<String, dynamic> syllabusRow() => {
  'openMajorCode': 'CSE',
  'openGrade': '3',
  'openGwamokNo': '101',
  'bunbanNo': '01',
  'gwamokKname': '자료구조',
  'gwamokEname': 'Data Structures',
  'gwamokkename': '자료구조-Data Structures',
  'codeName1': '전선',
  'hakjumNum': '3',
  'sisuNum': 3,
  'getScore1': 2.5,
  'getScore2': '0.5',
  'getScore3': null,
  'memberName': '테스트 교수',
  'jikgeubName': '교수',
  'telNo': '000-000-0000',
  'hpNo': null,
  'email': 'professor@example.com',
  'summary': '자료구조 이해\n알고리즘 설계',
  'purpose': '스택과 큐를 구현한다.',
  'gwamokAble': '문제해결',
  'preGwamok': '기초 프로그래밍',
  'pairGwamok': '자료구조 실습',
  'postGwamok': '알고리즘',
  'attendBiyul': 10,
  'middleBiyul': '30',
  'lastBiyul': '30.5',
  'reportBiyul': 24.5,
  'learnBiyul': 0,
  'quizBiyul': 5,
  'presentationBiyul': 0,
  'discussionBiyul': 0,
  'gitaBiyul': null,
  'gitaDetail': '문제는 강의내용을 기준으로 한다.',
  'bookName': 'Synthetic Data Structures',
  'writeName': 'Test Author',
  'companyName': 'Example Publisher',
  'printYear': 2025,
  'book1Name': 'Synthetic Algorithms',
  'write1Name': 'Second Author',
  'company1Name': 'Example Publisher',
  'print1Year': null,
  'bigo': '교재 구매는 선택이다.',
  'week1Lecture': '소개\n기본 개념',
  'week5Lecture': '스택과 큐',
  'week5Bigo': '연습 과제',
  'week5Subs': '보강 동영상',
  'week16Lecture': '기말고사',
  'weekGita': '일정은 변경될 수 있다.',
  'reflectPer1': '50',
  'studyResultShort1': '기초 지식',
  'result1': '자료구조를 설명할 수 있다.',
  'reflectPer8': 50,
  'studyResultShort8': '문제해결',
  'result8': '문제를 구현한다.',
  'studyResultShort2': '기재되지 않은 성과',
  'tblOpt': 'Y',
  'pblOpt': 'N',
  'typeBlended': '1',
  'facerecOpt': 'Y',
  'face100Opt': 'N',
};

final class SyllabusFixture {
  late final MobileQrFixture _auth;
  final bool shared;
  final FutureOr<http.Response?> Function(http.Request)? handle;

  SyllabusFixture({this.shared = false, this.handle}) {
    _auth = MobileQrFixture(
      handle: (request) async {
        final custom = await handle?.call(request);
        if (custom != null) return custom;
        switch (request.url.path) {
          case '${syllabusRoot}LctrePlanStopFlag.do':
            return http.Response('', 200);
          case '${syllabusRoot}LectrePlanData.do':
            return qrJson([syllabusRow()]);
          case '${syllabusRoot}CultureOptOneInfo.do':
            return shared
                ? qrJson({'cultureOpt': 'Y'})
                : http.Response('', 200);
          case '${syllabusRoot}LectrePlanInputTabOneFixedInfo.do':
            return qrJson({
              'summary': '분반 공통 개요',
              'purpose': '공통 학습목표',
              'preGwamok': '공통 선수과목',
              'postGwamok': '공통 후수과목',
              'lAttendBiyul': '20',
              'lMiddleBiyul': 20,
              'lLastBiyul': 40,
              'lReportBiyul': 10,
              'lLearnBiyul': 0,
              'lQuizBiyul': 0,
              'lPresentationBiyul': 5,
              'lDiscussionBiyul': 5,
              'lGitaBiyul': null,
              'fixedLectureOpt': 'Y',
              'fixedDiscussionOpt': true,
              'fixedPresentationOpt': null,
              'fixedExperimentOpt': 0,
              'fixedShortReportOpt': '',
              'lessonProcess': '강의와 토론을 진행한다.',
            });
          case '${syllabusRoot}LectreTimeInfo.do':
            return qrJson([
              {
                'dayname1': '월',
                'timeNo1': 3,
                'timeNo2': '4',
                'timeNo3': null,
                'timeNo4': null,
                'locHname': '테스트101',
                'locHname2': '테스트102',
              },
              {'dayname1': '수', 'timeNo1': 7, 'locHname': null},
            ]);
          case '${syllabusRoot}LectreAstnt.do':
            return qrJson([
              {'name': '테스트 조교', 'astntemail': 'assistant@example.com'},
            ]);
          case '${syllabusRoot}LectreTeam.do':
            return qrJson([
              {'teamName': '공동 교수', 'teamEmail': 'co@example.com'},
            ]);
        }
        return null;
      },
    );
  }

  KlasClient get client => _auth.client;
  List<http.Request> get requests => _auth.requests;
  List<http.Request> calls(String path) => _auth.calls('$syllabusRoot$path');
  Future<KlasUser> login() => _auth.login();
  Future<KlasCourse> course() async => (await (await login()).defaultCourse())!;
  void close() => client.close();
}

Map<String, dynamic> syllabusBody(http.Request request) =>
    jsonDecode(request.body) as Map<String, dynamic>;
