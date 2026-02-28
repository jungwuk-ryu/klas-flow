import 'dart:async';
import 'dart:io';

import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final id = const String.fromEnvironment('KLAS_ID');
  final password = const String.fromEnvironment('KLAS_PASSWORD');

  if (id.isEmpty || password.isEmpty) {
    stdout.writeln(
      'Usage: dart run example/heartbeat_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
    );
    exitCode = 64;
    return;
  }

  final client = KlasClient();

  try {
    await client.login(id, password);
    stdout.writeln('Login complete.');

    client.startSessionHeartbeat(
      interval: const Duration(minutes: 3),
      immediate: false,
      onError: (error, _) {
        stderr.writeln('Heartbeat error: $error');
      },
    );

    stdout.writeln('Heartbeat running: ${client.isSessionHeartbeatRunning}');
    stdout.writeln('Waiting 10 seconds...');
    await Future<void>.delayed(const Duration(seconds: 10));

    client.stopSessionHeartbeat();
    stdout.writeln('Heartbeat stopped.');
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
