import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/klasflow.dart';
import 'package:klasflow/src/api/readonly_api.dart';
import 'package:test/test.dart';

void main() {
  group('High-level feature coverage', () {
    test(
      'all catalog endpoints are reachable through high-level API',
      () async {
        final calledPaths = <String, int>{};
        final missingCourseContext = <String>[];

        const courseContextPaths = <String>{
          '/std/lis/evltn/AnytmQuizStdList.do',
          '/std/lis/evltn/DscsnStdList.do',
          '/std/lis/evltn/LctrumHomeStdInfo.do',
          '/std/lis/evltn/LrnSttusStdAtendList.do',
          '/std/lis/evltn/LrnSttusStdAtendListSub.do',
          '/std/lis/evltn/LrnSttusStdDscsnList.do',
          '/std/lis/evltn/LrnSttusStdOne.do',
          '/std/lis/evltn/LrnSttusStdRtprgsList.do',
          '/std/lis/evltn/LrnSttusStdTaskList.do',
          '/std/lis/evltn/LrnSttusStdTeamPrjctList.do',
          '/std/lis/evltn/LrnSttusStdTestAnQuizList.do',
          '/std/lis/evltn/OnlineTestStdList.do',
          '/std/lis/evltn/SelectOnlineCntntsStdList.do',
          '/std/lis/evltn/TaskStdList.do',
          '/std/lis/evltn/TaskStdView.do',
          '/std/lis/sport/6972896bfe72408eb72926780e85d041/BoardStdList.do',
          '/std/lis/sport/6972896bfe72408eb72926780e85d041/BoardStdView.do',
          '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardStdList.do',
          '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardStdView.do',
          '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardViewStdPage.do',
          '/std/lis/sport/QustnrStdList.do',
          '/std/lis/sport/QustnrStdPage.do',
          '/std/lis/lctre/EClassStdList.do',
          '/std/cmn/frame/LctrumSchdulInfo.do',
        };

        final mock = MockClient((request) async {
          final path = request.url.path;
          calledPaths.update(path, (value) => value + 1, ifAbsent: () => 1);

          if (request.method == 'POST') {
            final contentType = request.headers['content-type'] ?? '';
            if (contentType.contains('application/json')) {
              final decoded = jsonDecode(request.body);
              if (decoded is Map && courseContextPaths.contains(path)) {
                final payload = decoded.cast<String, dynamic>();
                if (payload['selectYearhakgi'] != '20261' ||
                    payload['selectSubj'] != 'CSE101' ||
                    payload['selectChangeYn'] != 'Y') {
                  missingCourseContext.add(path);
                }
              }
            } else if (contentType.contains(
              'application/x-www-form-urlencoded',
            )) {
              if (courseContextPaths.contains(path)) {
                final form = request.bodyFields;
                if (form['selectYearhakgi'] != '20261' ||
                    form['selectSubj'] != 'CSE101' ||
                    form['selectChangeYn'] != 'Y') {
                  missingCourseContext.add(path);
                }
              }
            }
          }

          switch (path) {
            case '/usr/cmn/login/LoginSecurity.do':
              return _jsonResponse({
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-1',
                },
              });
            case '/usr/cmn/login/LoginCaptcha.do':
              return _jsonResponse(0);
            case '/usr/cmn/login/LoginConfirm.do':
              return _jsonResponse({'success': true});
            case '/usr/cmn/login/captchaImg.do':
              return http.Response.bytes(
                [1, 2, 3],
                200,
                headers: {'content-type': 'image/png'},
              );
            case '/std/cmn/frame/KlasStop.do':
              return _textResponse(
                '<html><head><title>KLAS</title></head></html>',
                contentType: 'text/html; charset=utf-8',
              );
            case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
              return _jsonResponse({
                'data': [
                  {
                    'selectYearhakgi': '20261',
                    'selectSubj': 'CSE101',
                    'selectChangeYn': 'Y',
                    'isDefault': true,
                    'subjectName': '자료구조 - 김교수',
                  },
                ],
              });
            case '/api/v1/session/info':
              return _jsonResponse({
                'authenticated': true,
                'userId': 'test-user',
                'userName': '테스터',
                'remainingTime': 300,
              });
            case '/std/ads/admst/IdModifySpvInfo.do':
              return _jsonResponse({
                'kname': '테스터',
                'hakbun': 'test-user',
                'emailId': 'tester',
                'emailHost': 'example.com',
              });
            case '/common/file/UploadFileList.do':
              final body = jsonDecode(request.body);
              if (body is! Map) {
                return http.Response('Bad Request', 400);
              }
              final payload = body.cast<String, dynamic>();
              if (payload['attachId'] != 'attach-1' ||
                  payload['storageId'] != 'CLS_BOARD') {
                return http.Response('Server Error', 500);
              }
              return _jsonResponse([
                {
                  'atchFileId': 'attach-1',
                  'fileSn': '1',
                  'orignlFileNm': 'demo.pdf',
                  'fileMg': 1234,
                },
              ]);
            case '/common/file/DownloadFile/attach-1/1':
              return http.Response.bytes(
                [0xff, 0xd8, 0xff, 0x00],
                200,
                headers: {
                  'content-type': 'application/octet-stream',
                  'content-disposition': 'attachment; filename="demo.pdf"',
                },
              );
            case '/std/ads/admst/KwAttendStdGwakmokList.do':
              return _jsonResponse([
                {
                  'thisYear': '2026',
                  'hakgi': '1',
                  'openMajorCode': 'CSE',
                  'openGrade': '3',
                  'openGwamokNo': '101',
                  'bunbanNo': '01',
                  'gwamokKname': '자료구조',
                  'codeName1': '전공필수',
                  'hakjumNum': '3',
                  'sisuNum': '3',
                  'memberName': '김교수',
                  'currentNum': '45',
                  'yoil': '월',
                  'subj': 'CSE101',
                  'subjNm': '자료구조',
                  'prfsrNm': '김교수',
                  'yearhakgi': '20261',
                },
              ]);
            case '/mst/ads/admst/KwAttendStdAttendList.do':
              return _jsonResponse([
                {
                  'weekNo': '3',
                  'attendOpenYn': 'Y',
                },
              ]);
            case '/std/lis/evltn/CertiPushSucStd.do':
              return _jsonResponse({'randomKey': 'rk-1'});
            case '/mst/ads/admst/KwAttendQRCodeInsert.do':
              return _jsonResponse({'status': 'ok'});
            default:
              final endpoint = _specByPath(path);
              if (endpoint == null) {
                return http.Response('Not Found', 404);
              }

              return switch (endpoint.responseType) {
                KlasEndpointResponseType.jsonObject => _jsonResponse(
                  <String, dynamic>{},
                ),
                KlasEndpointResponseType.jsonArray => _jsonResponse(
                  <dynamic>[],
                ),
                KlasEndpointResponseType.jsonScalar => _jsonResponse(0),
                KlasEndpointResponseType.text => _textResponse('ok'),
                KlasEndpointResponseType.binary => http.Response.bytes(
                  [0],
                  200,
                  headers: {'content-type': 'application/octet-stream'},
                ),
              };
          }
        });

        final client = KlasClient(
          config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
          httpClient: mock,
        );
        addTearDown(client.close);

        final captcha = await client.requestCaptchaImage();
        expect(captcha.bytes, isNotEmpty);

        final user = await client.login('test-user', 'test-password');
        final profile = await user.profile(refresh: true);
        expect(profile.authenticated, isTrue);
        expect(profile.userId, equals('test-user'));
        final personal = await user.personalInfo();
        expect(personal.userId, equals('test-user'));

        await user.sessionStatus();
        await user.keepAlive();
        await user.findCourseById('CSE101');
        await user.findCourseByTitle('자료구조');

        final courses = await user.courses(refresh: true);
        expect(courses, isNotEmpty);
        final course = courses.first;

        await course.overview();
        await course.scheduleText();
        await course.listTasks(page: 0);

        await course.learning.listAnytimeQuizzes(page: 0);
        await course.learning.listDiscussions(page: 0);
        await course.learning.homeInfo();
        await course.learning.attendanceStatus();
        await course.learning.attendanceStatusDetail();
        await course.learning.discussionStatus();
        await course.learning.summary();
        await course.learning.realtimeProgress();
        await course.learning.taskStatus();
        await course.learning.teamProjects();
        await course.learning.testAndQuizStatus();
        await course.learning.onlineTests(page: 0);
        await course.learning.onlineContents(page: 0);
        await course.learning.getTaskDetail(ordseq: 1);

        await course.noticeBoard.listPosts(page: 0);
        await course.noticeBoard.getPost(boardNo: 1);
        await course.noticeBoard.openPostPage(boardNo: 1);
        await course.materialBoard.listPosts(page: 0);
        await course.materialBoard.getPost(boardNo: 1);
        await course.materialBoard.openPostPage(boardNo: 1);

        await course.surveys.openPage(query: {'linkUrl': '/sample'});
        await course.surveys.list();
        await course.eclass.listItems(page: 0);

        await user.frame.homeOverview();
        await user.frame.scheduleSummary();
        await user.frame.gyojikExamCheck();

        await user.enrollment.listYears();
        await user.enrollment.listColleges();
        await user.enrollment.listDepartments();
        await user.enrollment.lecturePlanStopFlag();
        await user.enrollment.listTimetable();
        await user.enrollment.listTimetableEntries();
        await user.enrollment.timetable();
        await user.timetable();

        await user.attendance.listSubjects();
        final attendanceSubjects = await user.attendance.listSubjectItems();
        await user.attendance.qrCheckInRaw(
          subject: attendanceSubjects.first,
          qrCode: 'qr-token',
        );
        await user.attendance.qrCheckIn(
          subject: attendanceSubjects.first,
          qrCode: 'qr-token',
        );
        await course.qrCheckIn('qr-token');
        await user.attendance.monthList();
        await user.attendance.monthTable();

        await user.academic.checkTerm();
        await user.academic.hakjukInfo();
        await user.academic.programCategory();
        await user.academic.sugangOption();
        await user.academic.listGrades();
        await user.academic.gradeSummary();
        await user.academic.listDeletedApplications();
        await user.academic.deletedHakjukInfo();
        await user.academic.listDeletedGrades();
        await user.academic.gyoyangInfo();
        await user.academic.listPortfolio();
        await user.academic.listScholarshipHistory();
        await user.academic.listScholarships();
        await user.academic.listLectureEvalCourses();
        await user.academic.listLectureEvalDepartments();
        await user.academic.listStanding();
        await user.academic.listToeicInfo();
        await user.academic.toeicLevelText();
        await user.academic.listToeicRecords();

        await user.studentRecord.temporaryLeaveHakjuk();
        await user.studentRecord.temporaryLeaveStatus();

        final attachedFiles = await user.files.listByAttachId(
          attachId: 'attach-1',
        );
        expect(attachedFiles, hasLength(1));
        final downloaded = await attachedFiles.first.download();
        expect(downloaded.bytes, isNotEmpty);

        final expectedPaths = KlasEndpointCatalog.byId.values
            .map((spec) => spec.path)
            .where((path) => !path.contains('{attachId}'))
            .toSet();

        for (final path in expectedPaths) {
          expect(
            calledPaths.containsKey(path),
            isTrue,
            reason: 'Missing call: $path',
          );
        }

        expect(
          calledPaths.keys.any(
            (path) => path.startsWith('/common/file/DownloadFile/'),
          ),
          isTrue,
        );
        expect(missingCourseContext, isEmpty);
      },
    );
  });
}

KlasEndpointSpec? _specByPath(String path) {
  for (final spec in KlasEndpointCatalog.byId.values) {
    if (!spec.path.contains('{') && spec.path == path) {
      return spec;
    }
  }
  return null;
}

http.Response _jsonResponse(Object payload) {
  return http.Response(
    jsonEncode(payload),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

http.Response _textResponse(String body, {String? contentType}) {
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: {'content-type': contentType ?? 'text/plain; charset=utf-8'},
  );
}

const String _modulus =
    'd3b0a5d2e6f8c1b4998e77aa31bc4d2f3a7cb9e1ffacde099812f3aa1c8d9e07'
    '84a79b7654f0cc22a1346d8eaf3b70c9d11be9ee02baf7a90876efbda12340fd'
    'c7a8f9d01234abcdeffedcba98765432100112233445566778899aabbccddeeff';
