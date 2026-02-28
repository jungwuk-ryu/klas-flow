import 'dart:io';

import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final id = const String.fromEnvironment('KLAS_ID');
  final password = const String.fromEnvironment('KLAS_PASSWORD');

  if (id.isEmpty || password.isEmpty) {
    stdout.writeln(
      'Usage: dart run example/api_catalog_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
    );
    exitCode = 64;
    return;
  }

  final client = KlasClient();

  try {
    await client.login(id, password);

    final endpointIds = client.api.endpointIds;
    stdout.writeln('Catalog endpoints: ${endpointIds.length}');
    for (final endpointId in endpointIds.take(10)) {
      final spec = client.api.spec(endpointId)!;
      stdout.writeln(
        '- $endpointId (${spec.method.name} ${spec.path} / ${spec.responseType.name})',
      );
    }

    final session = await client.api.callObject('session.info');
    stdout.writeln('Session keys: ${session.keys.join(', ')}');

    final subjects = await client.api.callArray(
      'frame.yearhakgiAtnlcSbjectList',
      includeContext: false,
    );
    stdout.writeln('Subject context count: ${subjects.length}');

    final tasks = await client.endpoints.learning.taskStdList(
      payload: {'currentPage': 0},
    );
    stdout.writeln('Task list count: ${tasks.length}');
  } on KlasException catch (error) {
    stdout.writeln('KLAS request failed: $error');
    rethrow;
  } finally {
    client.close();
  }
}
