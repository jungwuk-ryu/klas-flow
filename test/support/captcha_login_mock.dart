import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/klasflow.dart';

KlasClient captchaTestClient({
  bool pem = true,
  required Future<http.Response?> Function(http.Request request) respond,
}) => KlasClient(
  config: KlasClientConfig(baseUri: Uri.parse('https://example.com')),
  httpClient: MockClient((request) async {
    final response = await respond(request);
    if (response != null) return response;
    switch (request.url.path) {
      case '/usr/cmn/login/LoginSecurity.do':
        return captchaJson(
          pem
              ? {'publicKey': _publicKey}
              : {
                  'data': {
                    'publicKeyModulus': _modulus,
                    'publicKeyExponent': '10001',
                    'loginToken': 'fixture-nonce',
                  },
                },
        );
      case '/usr/cmn/login/LoginCaptcha.do':
        return captchaJson(0);
      case '/usr/cmn/login/LoginConfirm.do':
        return captchaJson({'errorCount': 0});
      case '/usr/cmn/login/captchaImg.do':
        return http.Response.bytes(
          [1, 2, 3],
          200,
          headers: {
            'content-type': 'image/png',
            'set-cookie': 'challenge=fixture; Path=/',
          },
        );
      case '/std/cmn/frame/KlasStop.do':
        return http.Response('<html>KLAS</html>', 200);
      case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
        return captchaJson({
          'data': [
            {
              'selectYearhakgi': '20261',
              'selectSubj': 'CSE101',
              'selectChangeYn': 'N',
              'isDefault': true,
            },
            {
              'selectYearhakgi': '20261',
              'selectSubj': 'CSE102',
              'selectChangeYn': 'N',
              'isDefault': false,
            },
          ],
        });
      case '/api/v1/session/info':
        return captchaJson({
          'authenticated': true,
          'userId': 'test-user',
          'userName': 'Tester',
        });
      case '/std/lis/evltn/TaskStdList.do':
        return captchaJson([]);
      default:
        return http.Response('Not Found', 404);
    }
  }),
);

http.Response captchaJson(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> captchaLoginFields(http.Request request) =>
    (request.headers['content-type'] ?? '').contains('application/json')
    ? jsonDecode(request.body) as Map<String, dynamic>
    : request.bodyFields;

const _modulus =
    'd3b0a5d2e6f8c1b4998e77aa31bc4d2f3a7cb9e1ffacde099812f3aa1c8d9e07'
    '84a79b7654f0cc22a1346d8eaf3b70c9d11be9ee02baf7a90876efbda12340fd'
    'c7a8f9d01234abcdeffedcba98765432100112233445566778899aabbccddeeff';
const _publicKey =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjH3ldRppQsQ2ESqF4utV2mH5'
    'A9j+KqWI8BDLwSLUJR7tJCQ8dpYnmqE1FyiHMC0MGci4rPfwGCTyJISPXh0d48x+ytle'
    'xaZQJy6u9xs5w6u298o1GEBgOMjDbeE6RlGHH+I6k2cbewn8LLL4eAH7sLBY9eBgFdu+'
    'uTkO1vKjeh0SuneHoL0OfKBZNi5uo1yCT6oUj03P0yOw/dY/ptRd43LSYBb5t9WlVIEz'
    'DXekhp3lYj7GqhvJl2WUkwWhT1WA1h1Sc/T6H2nQPQ/NrxWhcE3m6vG1IFHD4oiDRfPS'
    'jgW65k+D9es/zBL7uP564bI+f1lUE6U2LnL5CtLCd8hIqQIDAQAB';
