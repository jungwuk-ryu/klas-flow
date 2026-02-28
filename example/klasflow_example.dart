import 'dart:io';

void main() {
  stdout.writeln('klasflow demos');
  stdout.writeln('');
  stdout.writeln('Run one of the examples:');
  stdout.writeln(
    '  dart run example/basic_login_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
  );
  stdout.writeln(
    '  dart run example/error_handling_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
  );
  stdout.writeln(
    '  dart run example/context_workflow_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
  );
  stdout.writeln(
    '  dart run example/file_download_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
  );
  stdout.writeln(
    '  dart run example/auto_session_renewal_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
  );
  stdout.writeln(
    '  dart run example/api_catalog_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
  );
  stdout.writeln('');
  stdout.writeln(
    'Use read-only endpoints only when running against a real account.',
  );
}
