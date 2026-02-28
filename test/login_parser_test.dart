import 'package:klasflow/src/exceptions/klas_exceptions.dart';
import 'package:klasflow/src/parsers/login_parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = LoginParser();

  group('LoginParser', () {
    test('보안키 응답을 정상 파싱한다', () {
      final result = parser.parseSecurity({
        'data': {
          'publicKeyModulus': 'ab',
          'publicKeyExponent': '10001',
          'loginToken': 'token',
        },
      });

      expect(result.publicKeyModulus, equals('ab'));
      expect(result.publicKeyExponent, equals('10001'));
      expect(result.loginToken, equals('token'));
    });

    test('필수 보안키 필드 누락 시 ParsingException을 던진다', () {
      expect(
        () => parser.parseSecurity({
          'data': {'publicKeyModulus': 'ab'},
        }),
        throwsA(isA<ParsingException>()),
      );
    });

    test('로그인 결과에서 OTP 필요 여부를 추론한다', () {
      final result = parser.parseLoginResult({
        'result': 'fail',
        'message': 'OTP 인증 필요',
      });

      expect(result.success, isFalse);
      expect(result.otpRequired, isTrue);
    });
  });
}
