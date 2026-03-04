import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

void main() {
  group('KlasClient', () {
    test('login creates currentUser and loads profile', () async {
      final requestOrder = <String>[];
      final mock = MockClient((request) async {
        requestOrder.add(request.url.path);
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
            return _jsonResponse(0);
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
                },
              ],
            });
          case '/api/v1/session/info':
            return _jsonResponse({
              'authenticated': true,
              'userId': 'test-user',
              'userName': '테스터',
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
      expect(client.currentUser, isNotNull);
      expect(user.id, equals('test-user'));
      expect(
        requestOrder,
        containsAllInOrder([
          '/usr/cmn/login/LoginSecurity.do',
          '/usr/cmn/login/LoginCaptcha.do',
          '/usr/cmn/login/LoginConfirm.do',
          '/std/cmn/frame/KlasStop.do',
          '/std/cmn/frame/YearhakgiAtnlcSbjectList.do',
          '/api/v1/session/info',
        ]),
      );
    });

    test(
      'login resolves profile from fallback endpoints when session lacks id/name',
      () async {
        final calledPaths = <String>[];
        final mock = MockClient((request) async {
          calledPaths.add(request.url.path);
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
              return _jsonResponse(0);
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
                  },
                ],
              });
            case '/api/v1/session/info':
              return _jsonResponse({
                'logoutCountDownSec': 300,
                'sessionNotiSec': 6870,
                'remainingTime': 7170,
              });
            case '/std/cmn/frame/StdHome.do':
              return _jsonResponse({
                'data': {'userNm': '테스터'},
              });
            case '/std/cps/inqire/AtnlcScreHakjukInfo.do':
              return _jsonResponse({
                'data': {'studentNo': '2023000001'},
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

        expect(user.id, equals('2023000001'));
        expect(user.name, equals('테스터'));
        expect(calledPaths, contains('/std/cmn/frame/StdHome.do'));
        expect(calledPaths, contains('/std/cps/inqire/AtnlcScreHakjukInfo.do'));
      },
    );

    test(
      'login resolves profile name/id from frame html when json fallbacks miss',
      () async {
        final calledPaths = <String>[];
        final mock = MockClient((request) async {
          calledPaths.add(request.url.path);
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
              return _jsonResponse(0);
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
                  },
                ],
              });
            case '/api/v1/session/info':
              return _jsonResponse({
                'logoutCountDownSec': 300,
                'sessionNotiSec': 6870,
                'remainingTime': 7170,
              });
            case '/std/cmn/frame/StdHome.do':
            case '/std/cps/inqire/AtnlcScreHakjukInfo.do':
            case '/std/hak/hakjuk/TmpabssklGetHakjuk.do':
              return _jsonResponse({'data': {}});
            case '/std/cmn/frame/Frame.do':
              return _utf8TextResponse(
                '''
<!doctype html>
<html>
  <body>
    <a href="/std/ads/admst/MyInfoStdPage.do"><i class="fas fa-cog"></i>테스트사용자(2023000001)</a>
  </body>
</html>
''',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
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

        expect(user.id, equals('2023000001'));
        expect(user.name, equals('테스트사용자'));
        expect(calledPaths, contains('/std/cmn/frame/Frame.do'));
      },
    );

    test('startSessionHeartbeat reports failure through callback', () async {
      var heartbeatCalls = 0;
      final capturedErrors = <Object>[];

      final mock = MockClient((request) async {
        if (request.url.path == '/usr/cmn/login/UpdateSession.do') {
          heartbeatCalls++;
          return http.Response('server error', 500);
        }
        return http.Response('Not Found', 404);
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      client.startSessionHeartbeat(
        interval: const Duration(milliseconds: 30),
        onError: (error, _) => capturedErrors.add(error),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(client.isSessionHeartbeatRunning, isTrue);
      expect(heartbeatCalls, greaterThanOrEqualTo(1));
      expect(capturedErrors, isNotEmpty);
    });

    test(
      'course.listTasks retries after session expiration when credentials are cached',
      () async {
        final requestOrder = <String>[];
        var loginSecurityCalls = 0;
        var taskCalls = 0;

        final mock = MockClient((request) async {
          requestOrder.add(request.url.path);
          switch (request.url.path) {
            case '/usr/cmn/login/LoginSecurity.do':
              loginSecurityCalls++;
              return _jsonResponse({
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-$loginSecurityCalls',
                },
              });
            case '/usr/cmn/login/LoginCaptcha.do':
              return _jsonResponse(0);
            case '/usr/cmn/login/LoginConfirm.do':
              return _jsonResponse({'success': true});
            case '/std/cmn/frame/KlasStop.do':
              return _utf8TextResponse(
                '<html><head><title>KLAS</title></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
              );
            case '/api/v1/session/info':
              return _jsonResponse({
                'authenticated': true,
                'userId': 'test-user',
              });
            case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
              return _jsonResponse({
                'data': [
                  {
                    'selectYearhakgi': '20261',
                    'selectSubj': 'CSE101',
                    'selectChangeYn': 'Y',
                    'isDefault': true,
                  },
                ],
              });
            case '/std/lis/evltn/TaskStdList.do':
              taskCalls++;
              if (taskCalls == 1) {
                return _utf8TextResponse('세션이 만료되었습니다.', 401);
              }
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
        final course = (await user.defaultCourse())!;
        final tasks = await course.listTasks(page: 0);

        expect(tasks, isEmpty);
        expect(taskCalls, equals(2));
        expect(loginSecurityCalls, equals(2));
        expect(
          requestOrder
              .where((path) => path == '/usr/cmn/login/LoginSecurity.do')
              .length,
          equals(2),
        );
      },
    );

    test(
      'maxSessionRenewRetries=0 does not retry on session expiration',
      () async {
        var loginSecurityCalls = 0;
        var taskCalls = 0;

        final mock = MockClient((request) async {
          switch (request.url.path) {
            case '/usr/cmn/login/LoginSecurity.do':
              loginSecurityCalls++;
              return _jsonResponse({
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-$loginSecurityCalls',
                },
              });
            case '/usr/cmn/login/LoginCaptcha.do':
              return _jsonResponse(0);
            case '/usr/cmn/login/LoginConfirm.do':
              return _jsonResponse({'success': true});
            case '/std/cmn/frame/KlasStop.do':
              return _utf8TextResponse(
                '<html><head><title>KLAS</title></head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'},
              );
            case '/api/v1/session/info':
              return _jsonResponse({
                'authenticated': true,
                'userId': 'test-user',
              });
            case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
              return _jsonResponse({
                'data': [
                  {
                    'selectYearhakgi': '20261',
                    'selectSubj': 'CSE101',
                    'selectChangeYn': 'Y',
                    'isDefault': true,
                  },
                ],
              });
            case '/std/lis/evltn/TaskStdList.do':
              taskCalls++;
              return _utf8TextResponse('세션이 만료되었습니다.', 401);
            default:
              return http.Response('Not Found', 404);
          }
        });

        final client = KlasClient(
          config: KlasClientConfig(
            baseUri: Uri.parse('https://example.com'),
            maxSessionRenewRetries: 0,
          ),
          httpClient: mock,
        );
        addTearDown(client.close);

        final user = await client.login('test-user', 'test-password');
        final course = (await user.defaultCourse())!;

        await expectLater(
          course.listTasks(page: 0),
          throwsA(isA<SessionExpiredException>()),
        );

        expect(taskCalls, equals(1));
        expect(loginSecurityCalls, equals(1));
      },
    );

    test('runHealthCheck reports course task failure', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/api/v1/session/info':
            return _jsonResponse({'authenticated': true});
          case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
            return _jsonResponse({
              'data': [
                {
                  'selectYearhakgi': '20261',
                  'selectSubj': 'CSE101',
                  'selectChangeYn': 'Y',
                  'isDefault': true,
                },
              ],
            });
          case '/usr/cmn/login/UpdateSession.do':
            return _jsonResponse({});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          case '/std/lis/evltn/TaskStdList.do':
            return http.Response('server error', 500);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      addTearDown(client.close);

      // user가 없는 경우 course probe는 skipped 상태로 성공 처리된다.
      final reportBeforeLogin = await client.runHealthCheck();
      expect(
        reportBeforeLogin.items.any((item) => item.id == 'user.session'),
        isTrue,
      );

      // 로그인 후에는 course.tasks를 실제로 검사한다.
      final loginMock = MockClient((request) async {
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
            return _jsonResponse(0);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          case '/api/v1/session/info':
            return _jsonResponse({
              'authenticated': true,
              'userId': 'test-user',
            });
          case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
            return _jsonResponse({
              'data': [
                {
                  'selectYearhakgi': '20261',
                  'selectSubj': 'CSE101',
                  'selectChangeYn': 'Y',
                  'isDefault': true,
                },
              ],
            });
          case '/usr/cmn/login/UpdateSession.do':
            return _jsonResponse({});
          case '/std/lis/evltn/TaskStdList.do':
            return http.Response('server error', 500);
          default:
            return http.Response('Not Found', 404);
        }
      });

      final loggedInClient = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: loginMock,
      );
      addTearDown(loggedInClient.close);
      await loggedInClient.login('test-user', 'test-password');

      final report = await loggedInClient.runHealthCheck();
      expect(report.items.any((item) => item.id == 'course.tasks'), isTrue);
      expect(
        report.items.any((item) => item.id == 'course.tasks' && !item.success),
        isTrue,
      );
      expect(report.allPassed, isFalse);
    });
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
