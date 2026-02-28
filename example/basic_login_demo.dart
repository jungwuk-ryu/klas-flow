import 'dart:io';

import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final id = const String.fromEnvironment('KLAS_ID');
  final password = const String.fromEnvironment('KLAS_PASSWORD');

  if (id.isEmpty || password.isEmpty) {
    stdout.writeln(
      'Usage: dart run example/basic_login_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
    );
    exitCode = 64;
    return;
  }

  final client = KlasClient();

  try {
    await client.login(id, password);

    final session = await client.getSessionInfo();
    stdout.writeln('Authenticated: ${session.authenticated}');
    stdout.writeln('User ID: ${session.userId ?? '(unknown)'}');
    stdout.writeln('User Name: ${session.userName ?? '(unknown)'}');

    final contexts = client.availableContexts;
    stdout.writeln('Available contexts: ${contexts.length}');
    if (contexts.isNotEmpty) {
      final current = client.currentContext;
      stdout.writeln(
        'Current context: ${current?.selectYearhakgi}/${current?.selectSubj}',
      );
    }
  } on KlasException catch (error) {
    stdout.writeln('KLAS request failed: $error');
    rethrow;
  } finally {
    client.close();
  }
}
