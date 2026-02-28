import 'dart:async';
import 'dart:io';

import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final id = const String.fromEnvironment('KLAS_ID');
  final password = const String.fromEnvironment('KLAS_PASSWORD');

  if (id.isEmpty || password.isEmpty) {
    stdout.writeln(
      'Usage: dart run example/auto_session_renewal_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
    );
    exitCode = 64;
    return;
  }

  final client = KlasClient();

  try {
    await client.login(id, password);
    stdout.writeln('Login succeeded. Polling session info...');

    for (var i = 1; i <= 3; i++) {
      final session = await client.getSessionInfo();
      stdout.writeln(
        '[$i] authenticated=${session.authenticated} userId=${session.userId ?? '-'}',
      );
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    stdout.writeln(
      'Done. If session expired during calls, KlasClient auto-renewed once and retried.',
    );
  } on SessionExpiredException catch (error) {
    stdout.writeln('Auto-renewal failed: $error');
    rethrow;
  } on KlasException catch (error) {
    stdout.writeln('KLAS request failed: $error');
    rethrow;
  } finally {
    client.close();
  }
}
