import 'dart:io';

import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final id = const String.fromEnvironment('KLAS_ID');
  final password = const String.fromEnvironment('KLAS_PASSWORD');

  if (id.isEmpty || password.isEmpty) {
    stdout.writeln(
      'Usage: dart run example/bootstrap_and_health_demo.dart '
      '-DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
    );
    exitCode = 64;
    return;
  }

  final client = KlasClient();

  try {
    final bootstrap = await client.loginAndBootstrap(id, password);
    stdout.writeln('Authenticated: ${bootstrap.session.authenticated}');
    stdout.writeln('Contexts: ${bootstrap.contexts.length}');

    final report = await client.runHealthCheck();
    stdout.writeln('Health all passed: ${report.allPassed}');
    for (final item in report.items) {
      stdout.writeln(
        '- ${item.id}: ${item.success ? 'PASS' : 'FAIL'} (${item.detail})',
      );
    }
  } on KlasException catch (error) {
    stderr.writeln('KlasException: $error');
    exitCode = 1;
  } catch (error) {
    stderr.writeln('Unexpected error: $error');
    exitCode = 1;
  } finally {
    client.close();
  }
}
