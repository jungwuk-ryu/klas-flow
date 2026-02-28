import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

void main() {
  group('KlasReadOnlyApi', () {
    test('카탈로그 엔드포인트 수는 65개다', () {
      expect(KlasEndpointCatalog.byId.length, equals(65));
    });

    test('json-array endpoint 호출 시 컨텍스트를 자동 주입한다', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/std/lis/evltn/AnytmQuizStdList.do') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(request.headers['content-type'], contains('application/json'));
          expect(body['selectYearhakgi'], equals('20261'));
          expect(body['selectSubj'], equals('CSE101'));
          expect(body['selectChangeYn'], equals('Y'));
          expect(body['currentPage'], equals(0));
          return _jsonResponse([]);
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

      final result = await client.api.callArray(
        'learning.anytmQuizStdList',
        payload: {'currentPage': 0},
      );

      expect(result, isEmpty);
    });

    test('form-text endpoint 호출 시 form 본문으로 전송한다', () async {
      final mock = MockClient((request) async {
        if (request.url.path ==
            '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardViewStdPage.do') {
          final fields = request.bodyFields;
          expect(
            request.headers['content-type'],
            contains('application/x-www-form-urlencoded'),
          );
          expect(fields['boardNo'], equals('101'));
          expect(fields['selectYearhakgi'], equals('20261'));
          expect(fields['selectSubj'], equals('CSE101'));
          expect(fields['selectChangeYn'], equals('Y'));
          return _utf8TextResponse('<html><body>ok</body></html>', 200);
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

      final html = await client.api.callText(
        'boardSurvey.boardViewStdPage_d052b8f8',
        payload: {'boardNo': 101},
      );

      expect(html, contains('<html>'));
    });

    test('binary endpoint 호출 시 path 파라미터를 치환한다', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final mock = MockClient((request) async {
        if (request.url.path == '/common/file/DownloadFile/attach123/1') {
          return http.Response.bytes(
            bytes,
            200,
            headers: {
              'content-type': 'application/octet-stream',
              'content-disposition': 'attachment; filename="demo.bin"',
            },
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = KlasClient(
        config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
        httpClient: mock,
      );

      final file = await client.api.callBinary(
        'file.downloadFile',
        pathParams: {'attachId': 'attach123', 'fileSn': '1'},
      );

      expect(file.fileName, equals('demo.bin'));
      expect(file.bytes, equals(bytes));
    });

    test('세션 만료 시 api.call도 자동 재로그인 후 1회 재시도한다', () async {
      var loginSecurityCalls = 0;
      var protectedCalls = 0;

      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/usr/cmn/login/LoginSecurity.do':
            loginSecurityCalls++;
            return _jsonResponse(
              {
                'data': {
                  'publicKeyModulus': _modulus,
                  'publicKeyExponent': '10001',
                  'loginToken': 'nonce-$loginSecurityCalls',
                },
              },
              headers: {
                'set-cookie':
                    'JSESSIONID=session$loginSecurityCalls; Path=/; HttpOnly',
              },
            );
          case '/usr/cmn/login/LoginCaptcha.do':
            return _utf8TextResponse('1', 200);
          case '/usr/cmn/login/LoginConfirm.do':
            return _jsonResponse({'success': true});
          case '/std/cmn/frame/KlasStop.do':
            return _utf8TextResponse(
              '<html><head><title>KLAS</title></head></html>',
              200,
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
                  'selectChangeYn': 'N',
                  'isDefault': true,
                },
              ],
            });
          case '/std/lis/evltn/TaskStdList.do':
            protectedCalls++;
            if (protectedCalls == 1) {
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

      await client.login('test-user', 'test-password');
      final result = await client.api.callArray(
        'learning.taskStdList',
        payload: {'currentPage': 0},
      );

      expect(result, isEmpty);
      expect(protectedCalls, equals(2));
      expect(loginSecurityCalls, equals(2));
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
