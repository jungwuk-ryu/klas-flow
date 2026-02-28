import 'package:http/http.dart' as http;
import 'package:klasflow/src/transport/cookie_jar.dart';
import 'package:test/test.dart';

void main() {
  group('CookieJar', () {
    test('Set-Cookie를 흡수해 Cookie 헤더를 만든다', () {
      final jar = CookieJar();
      final response = http.Response(
        'ok',
        200,
        headers: {
          'set-cookie': 'JSESSIONID=abc; Path=/; HttpOnly, LANG=ko; Path=/',
        },
      );

      jar.absorb(response);

      final header = jar.cookieHeader;
      expect(header, contains('JSESSIONID=abc'));
      expect(header, contains('LANG=ko'));
    });

    test('빈 값 쿠키는 삭제 처리한다', () {
      final jar = CookieJar();
      jar.absorb(
        http.Response('ok', 200, headers: {'set-cookie': 'A=1; Path=/'}),
      );
      jar.absorb(
        http.Response(
          'ok',
          200,
          headers: {'set-cookie': 'A=; Max-Age=0; Path=/'},
        ),
      );

      expect(jar.cookieHeader, isNull);
    });
  });
}
