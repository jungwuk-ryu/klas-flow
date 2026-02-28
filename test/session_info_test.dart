import 'package:klasflow/src/models/session_info.dart';
import 'package:test/test.dart';

void main() {
  group('SessionInfo', () {
    test('remainingTime 숫자 문자열도 authenticated=true로 해석한다', () {
      final info = SessionInfo.fromJson({
        'remainingTime': '1742',
      });
      expect(info.authenticated, isTrue);
    });

    test('data 래퍼 구조에서도 값을 읽는다', () {
      final info = SessionInfo.fromJson({
        'data': {
          'isAuthenticated': true,
          'userId': '2023000001',
          'userName': '홍길동',
        },
      });
      expect(info.authenticated, isTrue);
      expect(info.userId, equals('2023000001'));
      expect(info.userName, equals('홍길동'));
    });
  });
}
