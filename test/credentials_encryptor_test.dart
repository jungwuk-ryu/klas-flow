import 'dart:convert';

import 'package:klasflow/src/auth/credentials_encryptor.dart';
import 'package:klasflow/src/models/login_security.dart';
import 'package:test/test.dart';

void main() {
  group('CredentialsEncryptor', () {
    final encryptor = CredentialsEncryptor();

    test('base64 publicKey(PEM 헤더 없음)도 암호화할 수 있다', () {
      final security = LoginSecurity(publicKey: _rawPublicKey, raw: const {});
      final token = encryptor.encryptLoginToken(
        id: 'student',
        password: 'password',
        security: security,
      );

      expect(token, isNotEmpty);
      expect(() => base64Decode(token), returnsNormally);
    });

    test('PEM publicKey도 암호화할 수 있다', () {
      final security = LoginSecurity(publicKey: _pemPublicKey, raw: const {});
      final token = encryptor.encryptLoginToken(
        id: 'student',
        password: 'password',
        security: security,
      );

      expect(token, isNotEmpty);
      expect(() => base64Decode(token), returnsNormally);
    });
  });
}

const String _rawPublicKey =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjH3ldRppQsQ2ESqF4utV2mH5'
    'A9j+KqWI8BDLwSLUJR7tJCQ8dpYnmqE1FyiHMC0MGci4rPfwGCTyJISPXh0d48x+ytle'
    'xaZQJy6u9xs5w6u298o1GEBgOMjDbeE6RlGHH+I6k2cbewn8LLL4eAH7sLBY9eBgFdu+'
    'uTkO1vKjeh0SuneHoL0OfKBZNi5uo1yCT6oUj03P0yOw/dY/ptRd43LSYBb5t9WlVIEz'
    'DXekhp3lYj7GqhvJl2WUkwWhT1WA1h1Sc/T6H2nQPQ/NrxWhcE3m6vG1IFHD4oiDRfPS'
    'jgW65k+D9es/zBL7uP564bI+f1lUE6U2LnL5CtLCd8hIqQIDAQAB';

const String _pemPublicKey = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjH3ldRppQsQ2ESqF4utV
2mH5A9j+KqWI8BDLwSLUJR7tJCQ8dpYnmqE1FyiHMC0MGci4rPfwGCTyJISPXh0d
48x+ytlexaZQJy6u9xs5w6u298o1GEBgOMjDbeE6RlGHH+I6k2cbewn8LLL4eAH7
sLBY9eBgFdu+uTkO1vKjeh0SuneHoL0OfKBZNi5uo1yCT6oUj03P0yOw/dY/ptRd
43LSYBb5t9WlVIEzDXekhp3lYj7GqhvJl2WUkwWhT1WA1h1Sc/T6H2nQPQ/NrxWh
cE3m6vG1IFHD4oiDRfPSjgW65k+D9es/zBL7uP564bI+f1lUE6U2LnL5CtLCd8hI
qQIDAQAB
-----END PUBLIC KEY-----
''';
