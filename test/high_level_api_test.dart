import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

void main() {
  group('High-level domain API', () {
    test(
      'login returns user and course.listTasks injects bound context',
      () async {
        final mock = MockClient((request) async {
          switch (request.url.path) {
            case '/usr/cmn/login/LoginSecurity.do':
              return _jsonResponse({
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-1',
                },
              });
            case '/usr/cmn/login/LoginCaptcha.do':
              return http.Response('OK', 200);
            case '/usr/cmn/login/LoginConfirm.do':
              return _jsonResponse({'success': true});
            case '/std/cmn/frame/KlasStop.do':
              return _utf8TextResponse(
                '<html><head><title>KLAS</title></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
              );
            case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
              return _jsonResponse({
                'data': [
                  {
                    'selectYearhakgi': '20261',
                    'selectSubj': 'CSE101',
                    'selectChangeYn': 'N',
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
              });
            case '/std/ads/admst/IdModifySpvInfo.do':
              return _jsonResponse({
                'kname': '테스터',
                'hakbun': '2023000001',
                'emailId': 'tester',
                'emailHost': 'example.com',
              });
            case '/std/lis/evltn/TaskStdList.do':
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body['selectYearhakgi'], equals('20261'));
              expect(body['selectSubj'], equals('CSE101'));
              expect(body['selectChangeYn'], equals('N'));
              expect(body['currentPage'], equals(0));
              return _jsonResponse([
                {
                  'taskNo': 1,
                  'title': 'Homework1',
                  'startdate': '2024-03-22 00:00:00',
                  'expiredate': '2024-04-06 23:59:59',
                  'submityn': 'Y',
                },
              ]);
            default:
              return http.Response('Not Found', 404);
          }
        });

        final client = KlasClient(
          config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
          httpClient: mock,
        );
        addTearDown(client.close);

        final user = await client.login('test-user', 'test-password');
        final profile = await user.profile(refresh: true);
        expect(profile.authenticated, isTrue);
        expect(profile.userId, equals('test-user'));
        final personal = await user.personalInfo();
        expect(personal.userId, equals('2023000001'));
        expect(personal.userName, equals('테스터'));
        expect(personal.email, equals('tester@example.com'));

        final defaultCourse = await user.defaultCourse();
        expect(defaultCourse, isNotNull);
        expect(defaultCourse!.courseId, equals('CSE101'));
        expect(defaultCourse.title, equals('자료구조'));
        expect(defaultCourse.professorName, equals('김교수'));

        final tasks = await defaultCourse.listTasks(page: 0);
        expect(tasks, hasLength(1));
        expect(tasks.first.title, equals('Homework1'));
        expect(tasks.first.submitted, isTrue);
      },
    );

    test('learning online contents are mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/lis/evltn/SelectOnlineCntntsStdList.do':
            return _jsonResponse([
              {
                'cntntsNo': 'C1',
                'cntntsNm': '1주차 강의',
                'startDate': '2026-03-01 09:00:00',
                'endDate': '2026-03-07 23:59:59',
                'progress': '완료',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final course = (await user.defaultCourse())!;
      final rows = await course.learning.listOnlineContentItems(page: 0);

      expect(rows, hasLength(1));
      expect(rows.first.contentId, equals('C1'));
      expect(rows.first.displayTitle, equals('1주차 강의'));
      expect(rows.first.status, equals('완료'));
    });

    test(
      'course label trailing dash is trimmed and professor becomes null',
      () async {
        final mock = MockClient((request) async {
          switch (request.url.path) {
            case '/usr/cmn/login/LoginSecurity.do':
              return _jsonResponse({
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-1',
                },
              });
            case '/usr/cmn/login/LoginCaptcha.do':
              return http.Response('OK', 200);
            case '/usr/cmn/login/LoginConfirm.do':
              return _jsonResponse({'success': true});
            case '/std/cmn/frame/KlasStop.do':
              return _utf8TextResponse(
                '<html><head><title>KLAS</title></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
              );
            case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
              return _jsonResponse({
                'data': [
                  {
                    'selectYearhakgi': '20261',
                    'selectSubj': 'JAVA101',
                    'selectChangeYn': 'Y',
                    'isDefault': true,
                    'subjectName': '자바프로그래밍 (0000-2-3679-01) -',
                  },
                ],
              });
            case '/api/v1/session/info':
              return _jsonResponse({'authenticated': true});
            default:
              return http.Response('Not Found', 404);
          }
        });

        final client = KlasClient(
          config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
          httpClient: mock,
        );
        addTearDown(client.close);

        final user = await client.login('test-user', 'test-password');
        final course = await user.defaultCourse();
        expect(course, isNotNull);
        expect(course!.title, equals('자바프로그래밍 (0000-2-3679-01)'));
        expect(course.professorName, isNull);
      },
    );

    test('learning online tests are mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/lis/evltn/OnlineTestStdList.do':
            return _jsonResponse([
              {
                'testNo': 8,
                'testTitle': '중간고사',
                'startDate': '2026-04-10 10:00:00',
                'endDate': '2026-04-10 10:50:00',
                'status': '응시전',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final course = (await user.defaultCourse())!;
      final rows = await course.learning.listOnlineTestItems(page: 0);

      expect(rows, hasLength(1));
      expect(rows.first.testId, equals('8'));
      expect(rows.first.displayTitle, equals('중간고사'));
      expect(rows.first.status, equals('응시전'));
    });

    test('learning anytime quizzes are mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/lis/evltn/AnytmQuizStdList.do':
            return _jsonResponse([
              {
                'quizNo': 'Q1',
                'quizTitle': '1차 퀴즈',
                'startDate': '2026-03-20 09:00:00',
                'endDate': '2026-03-20 09:20:00',
                'status': '응시전',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final course = (await user.defaultCourse())!;
      final rows = await course.learning.listAnytimeQuizItems(page: 0);

      expect(rows, hasLength(1));
      expect(rows.first.quizId, equals('Q1'));
      expect(rows.first.displayTitle, equals('1차 퀴즈'));
    });

    test('learning discussions are mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/lis/evltn/DscsnStdList.do':
            return _jsonResponse([
              {
                'dscsnNo': 'D1',
                'dscsnTitle': '객체지향 토론',
                'startDate': '2026-03-15 00:00:00',
                'endDate': '2026-03-22 23:59:59',
                'status': '참여중',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final course = (await user.defaultCourse())!;
      final rows = await course.learning.listDiscussionItems(page: 0);

      expect(rows, hasLength(1));
      expect(rows.first.discussionId, equals('D1'));
      expect(rows.first.displayTitle, equals('객체지향 토론'));
      expect(rows.first.status, equals('참여중'));
    });

    test('survey list is mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/lis/sport/QustnrStdList.do':
            return _jsonResponse([
              {
                'qustnrNo': 'S1',
                'qustnrTitle': '수업 만족도 조사',
                'startDate': '2026-06-01 00:00:00',
                'endDate': '2026-06-07 23:59:59',
                'status': '진행중',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final course = (await user.defaultCourse())!;
      final rows = await course.surveys.listSurveyItems();

      expect(rows, hasLength(1));
      expect(rows.first.surveyId, equals('S1'));
      expect(rows.first.displayTitle, equals('수업 만족도 조사'));
      expect(rows.first.status, equals('진행중'));
    });

    test('eclass list is mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/lis/lctre/EClassStdList.do':
            return _jsonResponse([
              {
                'eclassNo': 'E1',
                'eclassTitle': 'eclass 과제 안내',
                'startDate': '2026-03-01',
                'endDate': '2026-03-31',
                'status': '진행중',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final course = (await user.defaultCourse())!;
      final rows = await course.eclass.listEClassItems(page: 0);

      expect(rows, hasLength(1));
      expect(rows.first.itemId, equals('E1'));
      expect(rows.first.displayTitle, equals('eclass 과제 안내'));
      expect(rows.first.status, equals('진행중'));
    });

    test('attendance subjects are mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/ads/admst/KwAttendStdGwakmokList.do':
            return _jsonResponse([
              {
                'subj': 'CSE101',
                'subjNm': '자료구조',
                'prfsrNm': '김교수',
                'yearhakgi': '20261',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final rows = await user.attendance.listSubjectItems();

      expect(rows, hasLength(1));
      expect(rows.first.subjectId, equals('CSE101'));
      expect(rows.first.displayName, equals('자료구조'));
      expect(rows.first.professorName, equals('김교수'));
      expect(rows.first.termId, equals('20261'));
    });

    test('attendance month list is mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/ads/admst/MySchdulMonthList.do':
            return _jsonResponse([
              {
                'schdulNo': 'M1',
                'schdulTitle': '중간고사',
                'schdulDate': '2026-04-20',
                'status': '예정',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final rows = await user.attendance.listMonthlySchedules();

      expect(rows, hasLength(1));
      expect(rows.first.scheduleId, equals('M1'));
      expect(rows.first.displayTitle, equals('중간고사'));
      expect(rows.first.date, equals('2026-04-20'));
    });

    test('attendance month table is mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/ads/admst/MySchdulMonthTableList.do':
            return _jsonResponse([
              {
                'day': '20',
                'dayNm': '월',
                'schdulTitle': '중간고사',
                'status': '예정',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final rows = await user.attendance.listMonthlyScheduleTableItems();

      expect(rows, hasLength(1));
      expect(rows.first.dayOfMonth, equals('20'));
      expect(rows.first.weekday, equals('월'));
      expect(rows.first.displayTitle, equals('중간고사'));
    });

    test('academic grades are mapped to typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/cps/inqire/AtnlcScreSungjukInfo.do':
            return _jsonResponse([
              {
                'subjNm': '자료구조',
                'grade': 'A+',
                'credit': '3',
                'prfsrNm': '김교수',
                'yearhakgi': '20261',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final rows = await user.academic.listGradeEntries();

      expect(rows, hasLength(1));
      expect(rows.first.displaySubjectName, equals('자료구조'));
      expect(rows.first.grade, equals('A+'));
      expect(rows.first.credit, equals('3'));
      expect(rows.first.professorName, equals('김교수'));
      expect(rows.first.termId, equals('20261'));
    });

    test(
      'enrollment timetable matrix rows are parsed into typed entries',
      () async {
        final mock = MockClient((request) async {
          switch (request.url.path) {
            case '/usr/cmn/login/LoginSecurity.do':
              return _jsonResponse({
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-1',
                },
              });
            case '/usr/cmn/login/LoginCaptcha.do':
              return http.Response('OK', 200);
            case '/usr/cmn/login/LoginConfirm.do':
              return _jsonResponse({'success': true});
            case '/std/cmn/frame/KlasStop.do':
              return _utf8TextResponse(
                '<html><head><title>KLAS</title></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
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
              return _jsonResponse({'authenticated': true, 'userId': 'u1'});
            case '/std/cps/atnlc/TimetableStdList.do':
              return _jsonResponse([
                {
                  'wtTime': 1,
                  'wtHasSchedule': 'Y',
                  'wtSpan_1': 2,
                  'wtSubj_1': 'S1',
                  'wtSubjNm_1': '고급프로그래밍',
                  'wtLocHname_1': '새빛204',
                  'wtProfNm_1': '최영근',
                  'wtSpan_5': 2,
                  'wtSubj_5': 'S2',
                  'wtSubjNm_5': '시스템프로그래밍실습',
                  'wtLocHname_5': '새빛303',
                  'wtProfNm_5': '최상호',
                },
                {'wtTime': 2, 'wtHasSchedule': 'Y'},
                {'wtTime': 3, 'wtHasSchedule': 'N'},
              ]);
            default:
              return http.Response('Not Found', 404);
          }
        });

        final client = KlasClient(
          config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
          httpClient: mock,
        );
        addTearDown(client.close);

        final user = await client.login('test-user', 'test-password');
        final timetable = await user.enrollment.timetable();
        final entries = await user.enrollment.listTimetableEntries();

        expect(timetable.entries, hasLength(2));
        expect(entries, hasLength(2));
        expect(entries.first.title, equals('고급프로그래밍'));
        expect(entries.first.dayOfWeek, equals('월'));
        expect(entries.first.periodText, equals('1-2교시'));
        expect(entries.first.scheduleText, equals('월 1-2교시'));
        expect(entries.last.title, equals('시스템프로그래밍실습'));
        expect(entries.last.dayOfWeek, equals('금'));
        expect(entries.last.periodText, equals('1-2교시'));
      },
    );

    test('enrollment timetable matrix placeholder rows are ignored', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true, 'userId': 'u1'});
          case '/std/cps/atnlc/TimetableStdList.do':
            return _jsonResponse([
              {'wtTime': 1, 'wtHasSchedule': 'N'},
              {'wtTime': 2, 'wtHasSchedule': 'N'},
              {'wtTime': 3, 'wtHasSchedule': 'N'},
              {'wtTime': 4, 'wtHasSchedule': 'N'},
              {'wtTime': 5, 'wtHasSchedule': 'N'},
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final timetable = await user.enrollment.timetable();
      final entries = await user.enrollment.listTimetableEntries();

      expect(timetable.entries, isEmpty);
      expect(entries, isEmpty);
    });

    test('enrollment timetable is exposed as high-level typed model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true, 'userId': 'u1'});
          case '/std/cps/atnlc/TimetableStdList.do':
            return _jsonResponse([
              {
                'subjNm': '자료구조',
                'prfsrNm': '김교수',
                'dayNm': '월',
                'startTime': '09:00',
                'endTime': '10:15',
                'room': '새빛관 101',
              },
              {
                'subjectName': '운영체제',
                'teacherName': '박교수',
                'lctreTime': '수 13:00~14:15',
                'classroom': '한울관 303',
              },
            ]);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final entries = await user.enrollment.listTimetableEntries();
      final timetable = await user.enrollment.timetable();
      final byUser = await user.timetable();

      expect(entries, hasLength(2));
      expect(entries.first.title, equals('자료구조'));
      expect(entries.first.professorName, equals('김교수'));
      expect(entries.first.dayOfWeek, equals('월'));
      expect(entries.first.scheduleText, equals('월 09:00-10:15'));
      expect(entries[1].dayOfWeek, equals('수'));
      expect(entries[1].startTime, equals('13:00'));
      expect(entries[1].endTime, equals('14:15'));

      expect(timetable.entries, hasLength(2));
      expect(timetable.groupedByWeekday.keys, containsAll(<String>['월', '수']));
      expect(byUser.entries, hasLength(2));
    });

    test(
      'two course objects keep their own contexts without global mutation',
      () async {
        final receivedSubj = <String>[];
        final mock = MockClient((request) async {
          switch (request.url.path) {
            case '/usr/cmn/login/LoginSecurity.do':
              return _jsonResponse({
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-1',
                },
              });
            case '/usr/cmn/login/LoginCaptcha.do':
              return http.Response('OK', 200);
            case '/usr/cmn/login/LoginConfirm.do':
              return _jsonResponse({'success': true});
            case '/std/cmn/frame/KlasStop.do':
              return _utf8TextResponse(
                '<html><head><title>KLAS</title></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
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
                  {
                    'selectYearhakgi': '20261',
                    'selectSubj': 'CSE102',
                    'selectChangeYn': 'Y',
                    'isDefault': false,
                    'subjectName': '운영체제 - 박교수',
                  },
                ],
              });
            case '/api/v1/session/info':
              return _jsonResponse({'authenticated': true, 'userId': 'u1'});
            case '/std/lis/evltn/TaskStdList.do':
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              receivedSubj.add(body['selectSubj'] as String);
              return _jsonResponse([]);
            default:
              return http.Response('Not Found', 404);
          }
        });

        final client = KlasClient(
          config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
          httpClient: mock,
        );
        addTearDown(client.close);

        final user = await client.login('test-user', 'test-password');
        final courses = await user.courses(refresh: true);
        expect(courses, hasLength(2));

        await courses[1].listTasks(page: 0);
        await courses[0].listTasks(page: 0);

        expect(receivedSubj, equals(['CSE102', 'CSE101']));
      },
    );

    test('noticeBoard list is parsed into high-level board model', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardStdList.do':
            return _jsonResponse({
              'list': [
                {
                  'boardNo': 123,
                  'title': '중간고사 공지',
                  'userNm': '김교수',
                  'registDt': '2024-06-20T13:30:20.000+00:00',
                  'atchFileId': 'attach-123',
                  'fileCnt': 1,
                },
              ],
              'page': {
                'totalPages': 2,
                'totalElements': 19,
                'currentPage': 0,
                'pageSize': 10,
              },
            });
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final course = (await user.defaultCourse())!;
      final board = await course.noticeBoard.listPosts(page: 0);

      expect(board.posts, hasLength(1));
      expect(board.posts.first.boardNo, equals(123));
      expect(board.posts.first.title, equals('중간고사 공지'));
      expect(board.posts.first.attachId, equals('attach-123'));
      expect(board.posts.first.hasAttachments, isTrue);
      expect(board.page?.totalPages, equals(2));
    });

    test('attached file can download itself after listByAttachId', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true, 'userId': 'u1'});
          case '/common/file/UploadFileList.do':
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['attachId'] ?? body['atchFileId'], equals('attach-1'));
            return _jsonResponse([
              {'fileSn': '1', 'orignlFileNm': 'demo.pdf'},
            ]);
          case '/common/file/DownloadFile/attach-1/1':
            return http.Response.bytes(
              <int>[1, 2, 3],
              200,
              headers: {
                'content-type': 'application/octet-stream',
                'content-disposition': 'attachment; filename="demo.pdf"',
              },
            );
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final files = await user.files.listByAttachId(attachId: 'attach-1');
      expect(files, hasLength(1));
      expect(files.first.attachId, isNull);

      final payload = await files.first.download();
      expect(payload.bytes, equals(<int>[1, 2, 3]));
    });

    test('post summary can load detail directly with auto searchMasterNo', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/usr/cmn/login/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
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
            return _jsonResponse({'authenticated': true});
          case '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardStdList.do':
            return _jsonResponse({
              'list': [
                {'boardNo': 123, 'masterNo': 7, 'title': '중간고사 공지'},
              ],
            });
          case '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardViewStdPage.do':
            final body = request.bodyFields;
            expect(body['boardNo'], equals('123'));
            expect(body['searchMasterNo'], equals('7'));
            expect(body['masterNo'], equals('7'));
            return _utf8TextResponse(
              '<html><body>ok</body></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          case '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardStdView.do':
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['boardNo'], equals('123'));
            expect(body['searchMasterNo'], equals('7'));
            expect(body['masterNo'], equals('7'));
            return _jsonResponse({
              'data': {
                'detail': {'boardNo': 123, 'content': '<p>본문 테스트</p>'},
                'comments': [],
              },
            });
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      final user = await client.login('test-user', 'test-password');
      final course = (await user.defaultCourse())!;
      final board = await course.noticeBoard.listPosts(page: 0);
      final detail = await board.posts.first.getPost();

      expect(detail.board?.raw['boardNo'], equals(123));
      expect(detail.board?.raw['content'], equals('<p>본문 테스트</p>'));
    });

    test(
      'noticeBoard getPost preloads page and parses wrapped detail payload',
      () async {
        var pageOpened = false;

        final mock = MockClient((request) async {
          switch (request.url.path) {
            case '/usr/cmn/login/LoginSecurity.do':
              return _jsonResponse({
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-1',
                },
              });
            case '/usr/cmn/login/LoginCaptcha.do':
              return http.Response('OK', 200);
            case '/usr/cmn/login/LoginConfirm.do':
              return _jsonResponse({'success': true});
            case '/std/cmn/frame/KlasStop.do':
              return _utf8TextResponse(
                '<html><head><title>KLAS</title></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
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
              return _jsonResponse({'authenticated': true});
            case '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardViewStdPage.do':
              final body = request.bodyFields;
              expect(body['cmd'], equals('select'));
              expect(body['boardNo'], equals('1'));
              expect(body['selectYearhakgi'], equals('20261'));
              expect(body['selectSubj'], equals('CSE101'));
              pageOpened = true;
              return _utf8TextResponse(
                '<html><body>ok</body></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
              );
            case '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardStdView.do':
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body['cmd'], equals('select'));
              expect(body['boardNo'], equals('1'));
              expect(body['searchMasterNo'], equals('1'));
              expect(body['masterNo'], equals('1'));
              expect(body['searchCondition'], equals('ALL'));
              expect(body['searchKeyword'], equals(''));
              expect(body['currentPage'], equals('1'));
              expect(body['selectYearhakgi'], equals('20261'));
              expect(body['selectSubj'], equals('CSE101'));
              expect(body['selectChangeYn'], equals('Y'));
              expect(pageOpened, isTrue);
              return _jsonResponse({
                'data': {
                  'detail': {
                    'boardNo': 1,
                    'content': '<p>본문 테스트</p>',
                    'userNm': '김교수',
                  },
                  'previous': {'boardNo': 0},
                  'next': {'boardNo': 2},
                  'comments': [
                    {'cn': '댓글 테스트'},
                  ],
                },
              });
            default:
              return http.Response('Not Found', 404);
          }
        });

        final client = KlasClient(
          config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
          httpClient: mock,
        );
        addTearDown(client.close);

        final user = await client.login('test-user', 'test-password');
        final course = (await user.defaultCourse())!;
        final detail = await course.noticeBoard.getPost(boardNo: 1);

        expect(pageOpened, isTrue);
        expect(detail.board?.raw['boardNo'], equals(1));
        expect(detail.board?.raw['content'], equals('<p>본문 테스트</p>'));
        expect(detail.previous?.raw['boardNo'], equals(0));
        expect(detail.next?.raw['boardNo'], equals(2));
        expect(detail.comments, hasLength(1));
      },
    );
  });
}

http.Response _jsonResponse(Object payload, {Map<String, String>? headers}) {
  return http.Response(
    jsonEncode(payload),
    200,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      if (headers != null) ...headers,
    },
  );
}

http.Response _utf8TextResponse(
  String body,
  int statusCode, {
  Map<String, String>? headers,
}) {
  return http.Response.bytes(
    utf8.encode(body),
    statusCode,
    headers: {
      'content-type': 'text/plain; charset=utf-8',
      if (headers != null) ...headers,
    },
  );
}

const String _modulus =
    'd3b0a5d2e6f8c1b4998e77aa31bc4d2f3a7cb9e1ffacde099812f3aa1c8d9e07'
    '84a79b7654f0cc22a1346d8eaf3b70c9d11be9ee02baf7a90876efbda12340fd'
    'c7a8f9d01234abcdeffedcba98765432100112233445566778899aabbccddeeff';
