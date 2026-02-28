import 'dart:io';

import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final id = const String.fromEnvironment('KLAS_ID');
  final password = const String.fromEnvironment('KLAS_PASSWORD');

  if (id.isEmpty || password.isEmpty) {
    stdout.writeln(
      'Usage: dart run example/error_handling_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>',
    );
    exitCode = 64;
    return;
  }

  final client = KlasClient();

  try {
    await client.login(id, password);
    stdout.writeln('Login succeeded.');

    final session = await client.getSessionInfo();
    stdout.writeln('Session check: ${session.authenticated}');
  } on InvalidCredentialsException {
    stdout.writeln('Invalid ID or password.');
  } on OtpRequiredException {
    stdout.writeln('OTP verification is required by the server.');
  } on CaptchaRequiredException {
    stdout.writeln('Captcha verification is required by the server.');
  } on SessionExpiredException {
    stdout.writeln('Session expired and automatic renewal was not possible.');
  } on ServiceUnavailableException {
    stdout.writeln('Service is temporarily unavailable.');
  } on NetworkException {
    stdout.writeln('Network problem occurred while calling KLAS.');
  } on ParsingException {
    stdout.writeln('Response format changed or parsing failed.');
  } on KlasException catch (error) {
    stdout.writeln('Unhandled KLAS exception: $error');
  } finally {
    client.close();
  }
}
