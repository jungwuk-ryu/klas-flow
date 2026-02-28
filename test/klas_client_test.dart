import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

void main() {
  group('KlasClient', () {
    test('login은 인증/프레임/세션/컨텍스트 초기화를 순차 수행한다', () async {
      final requestOrder = <String>[];
      final mock = MockClient((request) async {
        requestOrder.add(request.url.path);

        switch (request.url.path) {
          case '/LoginSecurity.do':
            return _jsonResponse(
              {
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-1',
                },
              },
              headers: {'set-cookie': 'JSESSIONID=abc123; Path=/; HttpOnly'},
            );
          case '/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/LoginConfirm.do':
            final body = request.bodyFields;
            expect(body['id'], equals('test-user'));
            expect(body['loginToken'], isNotEmpty);
            return _jsonResponse({'success': true});
          case '/FrameInit.do':
            return http.Response(
              '<html><head><title>KLAS</title></head></html>',
              200,
            );
          case '/api/v1/session/info':
            final cookie = request.headers['cookie'];
            expect(cookie, contains('JSESSIONID=abc123'));
            return _jsonResponse({
              'authenticated': true,
              'userId': 'test-user',
              'userName': '테스터',
            });
          case '/YearhakgiAtnlcSbjectList.do':
            return _jsonResponse({
              'data': [
                {
                  'selectYearhakgi': '20261',
                  'selectSubj': 'CSE101',
                  'selectChangeYn': 'N',
                  'isDefault': true,
                  'subjectName': '자료구조',
                },
              ],
            });
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );

      await client.login('test-user', 'test-password');

      expect(client.availableContexts, hasLength(1));
      expect(client.currentContext?.selectSubj, equals('CSE101'));
      expect(
        requestOrder,
        equals([
          '/LoginSecurity.do',
          '/LoginCaptcha.do',
          '/LoginConfirm.do',
          '/FrameInit.do',
          '/api/v1/session/info',
          '/YearhakgiAtnlcSbjectList.do',
        ]),
      );
    });

    test('세션 만료 응답은 SessionExpiredException으로 변환된다', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/api/v1/session/info') {
          return _utf8TextResponse('세션이 만료되었습니다.', 401);
        }
        return http.Response('Not Found', 404);
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );

      expect(client.getSessionInfo(), throwsA(isA<SessionExpiredException>()));
    });

    test('postJsonWithContext는 과목 컨텍스트를 자동 주입한다', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/context-required') {
          final body = request.bodyFields;
          return _jsonResponse({'echo': body});
        }
        return http.Response('Not Found', 404);
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );
      client.setContext(
        selectYearhakgi: '20261',
        selectSubj: 'CSE101',
        selectChangeYn: 'Y',
      );

      final response = await client.postJsonWithContext(
        '/context-required',
        form: {'custom': 'value'},
      );

      final echo = (response['echo'] as Map<String, dynamic>);
      expect(echo['custom'], equals('value'));
      expect(echo['selectYearhakgi'], equals('20261'));
      expect(echo['selectSubj'], equals('CSE101'));
      expect(echo['selectChangeYn'], equals('Y'));
    });

    test('initializeFrame은 HTML을 파싱해 제목을 제공한다', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/FrameInit.do') {
          return _utf8TextResponse(
            '<html><head><title>포털 메인</title></head><body>ok</body></html>',
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );

      final page = await client.initializeFrame();
      expect(page.title, equals('포털 메인'));
    });

    test('downloadFile은 바이너리와 파일명을 추출한다', () async {
      final bytes = Uint8List.fromList([0, 1, 2, 3, 4]);
      final mock = MockClient((request) async {
        if (request.url.path == '/files/test.bin') {
          return http.Response.bytes(
            bytes,
            200,
            headers: {
              'content-type': 'application/octet-stream',
              'content-disposition': 'attachment; filename="test.bin"',
            },
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );

      final file = await client.downloadFile('/files/test.bin');
      expect(file.fileName, equals('test.bin'));
      expect(file.contentType, contains('application/octet-stream'));
      expect(file.bytes, equals(bytes));
    });

    test('로그인 실패는 InvalidCredentialsException으로 변환된다', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/LoginConfirm.do':
            return _jsonResponse({'success': false, 'message': '인증 실패'});
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );

      expect(
        client.login('wrong', 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('OTP 요구 응답은 OtpRequiredException으로 변환된다', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/LoginConfirm.do':
            return _jsonResponse({'otpRequired': true, 'message': 'OTP 필요'});
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );

      expect(client.login('id', 'pw'), throwsA(isA<OtpRequiredException>()));
    });

    test('Captcha 요구 응답은 CaptchaRequiredException으로 변환된다', () async {
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/LoginSecurity.do':
            return _jsonResponse({
              'data': {
                'publicKeyModulus': _modulus,
                'publicKeyExponent': '10001',
                'loginToken': 'nonce-1',
              },
            });
          case '/LoginCaptcha.do':
            return http.Response('OK', 200);
          case '/LoginConfirm.do':
            return _jsonResponse({'captchaRequired': true, 'message': '캡차 필요'});
          default:
            return http.Response('Not Found', 404);
        }
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );

      expect(
        client.login('id', 'pw'),
        throwsA(isA<CaptchaRequiredException>()),
      );
    });
  });
}

http.Response _jsonResponse(
  Map<String, dynamic> payload, {
  Map<String, String>? headers,
}) {
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
