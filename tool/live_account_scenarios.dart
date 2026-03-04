import 'dart:async';
import 'dart:io';

import 'package:klasflow/klasflow.dart';

final class ScenarioResult {
  final String name;
  final bool success;
  final Duration elapsed;
  final String detail;

  const ScenarioResult({
    required this.name,
    required this.success,
    required this.elapsed,
    required this.detail,
  });
}

Future<void> main() async {
  final id = Platform.environment['KLAS_ID'] ?? '';
  final password = Platform.environment['KLAS_PASSWORD'] ?? '';

  if (id.isEmpty || password.isEmpty) {
    stderr.writeln('Missing KLAS_ID or KLAS_PASSWORD environment variables.');
    stderr.writeln(
      'PowerShell example: '
      r'$env:KLAS_ID="id"; $env:KLAS_PASSWORD="password"; '
      'dart run tool/live_account_scenarios.dart',
    );
    exit(64);
  }

  final client = KlasClient(
    config: KlasClientConfig(
      maxSessionRenewRetries: 1,
      timeout: const Duration(seconds: 20),
    ),
  );

  final results = <ScenarioResult>[];
  KlasUser? user;
  KlasCourse? course;
  final heartbeatErrors = <Object>[];

  try {
    results.add(
      await _runScenario(
        name: '1) login() returns KlasUser',
        execute: () async {
          user = await client.login(id, password);
          return 'userId=${_mask(user?.id)}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '2) user.profile(refresh:true)',
        execute: () async {
          final profile = await user!.profile(refresh: true);
          if (!profile.authenticated) {
            throw StateError('authenticated=false');
          }
          return 'authenticated=true, userId=${_mask(profile.userId)}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '3) user.sessionStatus()',
        execute: () async {
          final status = await user!.sessionStatus();
          return 'remainingTime=${status.remainingTime ?? -1}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '4) user.courses() loads contexts',
        execute: () async {
          final courses = await user!.courses(refresh: true);
          if (courses.isEmpty) {
            throw StateError('no available courses');
          }
          return 'count=${courses.length}, first=${_mask(courses.first.courseId)}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '5) user.defaultCourse()',
        execute: () async {
          course = await user!.defaultCourse(refresh: true);
          if (course == null) {
            throw StateError('default course is null');
          }
          return 'course=${_mask(course!.courseId)}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '6) course.overview()',
        execute: () async {
          final overview = await course!.overview();
          return 'keys=${overview.record.raw.keys.length}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '7) course.listTasks(page:0)',
        execute: () async {
          final tasks = await course!.listTasks(page: 0);
          return 'items=${tasks.length}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '8) course.noticeBoard.listPosts(page:0)',
        execute: () async {
          final board = await course!.noticeBoard.listPosts(page: 0);
          return 'posts=${board.posts.length}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '9) user.keepAlive()',
        execute: () async {
          await user!.keepAlive();
          return 'ok';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '10) heartbeat start/stop + clearLocalState',
        execute: () async {
          client.startSessionHeartbeat(
            interval: const Duration(seconds: 2),
            immediate: true,
            onError: (error, _) => heartbeatErrors.add(error),
          );
          await Future<void>.delayed(const Duration(seconds: 3));
          if (!client.isSessionHeartbeatRunning) {
            throw StateError('heartbeat did not start');
          }
          client.stopSessionHeartbeat();
          if (client.isSessionHeartbeatRunning) {
            throw StateError('heartbeat did not stop');
          }
          if (heartbeatErrors.isNotEmpty) {
            throw StateError(
              'heartbeat reported error: ${heartbeatErrors.first}',
            );
          }

          client.clearLocalState();
          try {
            await user!.sessionStatus();
            throw StateError('expected SessionExpiredException');
          } on SessionExpiredException {
            return 'heartbeat ok, clearLocalState verified';
          }
        },
      ),
    );
  } finally {
    client.close();
  }

  _printReport(results);

  final failed = results.where((result) => !result.success).toList();
  if (failed.isNotEmpty) {
    exitCode = 1;
  }
}

Future<ScenarioResult> _runScenario({
  required String name,
  required Future<String> Function() execute,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final detail = await execute();
    stopwatch.stop();
    return ScenarioResult(
      name: name,
      success: true,
      elapsed: stopwatch.elapsed,
      detail: detail,
    );
  } catch (error) {
    stopwatch.stop();
    return ScenarioResult(
      name: name,
      success: false,
      elapsed: stopwatch.elapsed,
      detail: '$error',
    );
  }
}

void _printReport(List<ScenarioResult> results) {
  stdout.writeln('Live KlasClient scenario report');
  stdout.writeln('----------------------------------------');
  for (final result in results) {
    final status = result.success ? 'PASS' : 'FAIL';
    stdout.writeln(
      '[$status] ${result.name} '
      '(${result.elapsed.inMilliseconds} ms)',
    );
    stdout.writeln('       ${result.detail}');
  }

  final passCount = results.where((result) => result.success).length;
  final failCount = results.length - passCount;
  stdout.writeln('----------------------------------------');
  stdout.writeln(
    'Summary: $passCount/${results.length} passed, $failCount failed',
  );
}

String _mask(String? value) {
  if (value == null || value.isEmpty) {
    return '(null)';
  }
  if (value.length <= 4) {
    return '****';
  }
  final tail = value.substring(value.length - 4);
  return '***$tail';
}
