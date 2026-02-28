import 'dart:io';

import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final id = const String.fromEnvironment('KLAS_ID');
  final password = const String.fromEnvironment('KLAS_PASSWORD');

  if (id.isEmpty || password.isEmpty) {
    stdout.writeln(
      'Usage: dart run example/context_workflow_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
    );
    exitCode = 64;
    return;
  }

  final client = KlasClient();

  try {
    await client.login(id, password);

    final contexts = await client.refreshContexts();
    stdout.writeln('Contexts loaded: ${contexts.length}');

    for (var index = 0; index < contexts.length; index++) {
      final item = contexts[index];
      stdout.writeln(
        '[$index] ${item.selectYearhakgi} ${item.selectSubj} ${item.subjectName ?? ''}'
            .trim(),
      );
    }

    if (contexts.length > 1) {
      final second = contexts[1];
      client.setContext(
        selectYearhakgi: second.selectYearhakgi,
        selectSubj: second.selectSubj,
        selectChangeYn: second.selectChangeYn,
      );
      stdout.writeln('Switched to second context.');
    }

    // IMPORTANT:
    // Replace this with a read-only endpoint from your private API spec.
    final response = await client.postJsonWithContext(
      '/replace-with-readonly-context-endpoint',
      form: {'page': '1'},
    );

    stdout.writeln('Response keys: ${response.keys.join(', ')}');
  } on KlasException catch (error) {
    stdout.writeln('KLAS request failed: $error');
    rethrow;
  } finally {
    client.close();
  }
}
