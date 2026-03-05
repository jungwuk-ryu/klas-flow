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
      expect(board.page?.totalPages, equals(2));
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
