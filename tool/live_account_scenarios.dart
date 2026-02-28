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
  List<CourseContext> contexts = const <CourseContext>[];
  List<dynamic> tasksFromTyped = const <dynamic>[];
  final heartbeatErrors = <Object>[];

  try {
    results.add(
      await _runScenario(
        name: '1) login() succeeds',
        execute: () async {
          await client.login(id, password);
          return 'login completed';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '2) getSessionInfo() returns authenticated=true',
        execute: () async {
          final session = await client.getSessionInfo();
          if (!session.authenticated) {
            throw StateError('authenticated=false');
          }
          final maskedUserId = _mask(session.userId);
          return 'authenticated=true, userId=$maskedUserId';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '3) api.callObject(session.info) returns object',
        execute: () async {
          final response = await client.api.callObject(
            'session.info',
            includeContext: false,
          );
          if (response.isEmpty) {
            throw StateError('session.info returned an empty object');
          }
          return 'keys=${response.keys.take(6).join(', ')}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '4) initializeFrame() parses HTML title',
        execute: () async {
          final page = await client.initializeFrame();
          final title = (page.title ?? '').trim();
          return 'sourceLength=${page.source.length}, '
              'title=${title.isEmpty ? '(empty)' : title}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '5) refreshContexts() loads contexts',
        execute: () async {
          contexts = await client.refreshContexts();
          if (contexts.isEmpty) {
            throw StateError('no available contexts');
          }
          final first = contexts.first;
          return 'count=${contexts.length}, first=${_mask(first.selectSubj)}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '6) setContext() updates currentContext',
        execute: () async {
          final first = contexts.first;
          client.setContext(
            selectYearhakgi: first.selectYearhakgi,
            selectSubj: first.selectSubj,
            selectChangeYn: first.selectChangeYn,
          );
          final current = client.currentContext;
          if (current == null) {
            throw StateError('currentContext is null');
          }
          if (current.selectSubj != first.selectSubj) {
            throw StateError('context mismatch after setContext');
          }
          return 'current=${_mask(current.selectSubj)}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '7) endpoints.learning.taskStdList() works',
        execute: () async {
          tasksFromTyped = await client.endpoints.learning.taskStdList(
            payload: {'currentPage': 0},
          );
          return 'items=${tasksFromTyped.length}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '8) api.callArray(learning.taskStdList) matches typed call',
        execute: () async {
          final tasksFromCatalog = await client.api.callArray(
            'learning.taskStdList',
            payload: {'currentPage': 0},
          );
          if (tasksFromCatalog.length != tasksFromTyped.length) {
            throw StateError(
              'count mismatch: typed=${tasksFromTyped.length}, '
              'catalog=${tasksFromCatalog.length}',
            );
          }
          return 'items=${tasksFromCatalog.length}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '9) updateSession() and typed updateSession() both succeed',
        execute: () async {
          final responseA = await client.updateSession();
          final responseB = await client.endpoints.loginSession.updateSession();
          return 'clientKeys=${responseA.keys.length}, '
              'typedKeys=${responseB.keys.length}';
        },
      ),
    );

    results.add(
      await _runScenario(
        name: '10) heartbeat start/stop + clearLocalState invalidates session',
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
            await client.getSessionInfo();
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
