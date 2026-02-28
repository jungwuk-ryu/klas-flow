import 'package:klasflow/src/exceptions/klas_exceptions.dart';
import 'package:klasflow/src/parsers/login_parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = LoginParser();

  group('LoginParser', () {
    test('publicKey 단일 필드 응답을 파싱한다', () {
      final result = parser.parseSecurity({
        'publicKey': 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A',
      });

      expect(result.usesPemPublicKey, isTrue);
      expect(result.publicKey, startsWith('MIIB'));
      expect(result.publicKeyModulus, isNull);
      expect(result.publicKeyExponent, isNull);
      expect(result.loginToken, isNull);
    });

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

    test('errorCount=0 응답을 로그인 성공으로 파싱한다', () {
      final result = parser.parseLoginResult({
        'errorCount': 0,
        'response': {'userId': '2023000001'},
      });

      expect(result.success, isTrue);
      expect(result.otpRequired, isFalse);
      expect(result.captchaRequired, isFalse);
    });

    test('errorCount>0 + captcha 메시지를 captchaRequired로 파싱한다', () {
      final result = parser.parseLoginResult({
        'errorCount': 1,
        'message': 'Captcha required',
      });

      expect(result.success, isFalse);
      expect(result.captchaRequired, isTrue);
    });
  });
}
