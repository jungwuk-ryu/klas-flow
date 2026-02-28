import 'dart:io';

import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final id = const String.fromEnvironment('KLAS_ID');
  final password = const String.fromEnvironment('KLAS_PASSWORD');

  if (id.isEmpty || password.isEmpty) {
    stdout.writeln(
      'Usage: dart run example/file_download_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
    );
    exitCode = 64;
    return;
  }

  final client = KlasClient();

  try {
    await client.login(id, password);

    // IMPORTANT:
    // Replace path/query with a read-only file download endpoint from your private API spec.
    final file = await client.downloadFile(
      '/replace-with-safe-download-endpoint',
      query: {'fileId': 'sample'},
    );

    final fileName = file.fileName ?? 'download.bin';
    final output = File('${Directory.systemTemp.path}\\$fileName');
    await output.writeAsBytes(file.bytes, flush: true);

    stdout.writeln('Saved: ${output.path}');
    stdout.writeln('Size: ${file.bytes.length} bytes');
    stdout.writeln('Content-Type: ${file.contentType ?? '(unknown)'}');
  } on KlasException catch (error) {
    stdout.writeln('KLAS request failed: $error');
    rethrow;
  } finally {
    client.close();
  }
}
