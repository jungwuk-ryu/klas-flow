import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final client = KlasClient();

  try {
    await client.login('학번', '비밀번호');
    final session = await client.getSessionInfo();
    print('세션 유효: ${session.authenticated}');
  } on KlasException catch (error) {
    print('요청 실패: $error');
  } finally {
    client.close();
  }
}
