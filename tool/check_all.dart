import 'dart:io';

final class _Step {
  final String name;
  final List<String> command;

  const _Step(this.name, this.command);
}

Future<void> main(List<String> args) async {
  final blockedArgs = args.where((arg) => arg.startsWith('--block=')).toList();

  final steps = <_Step>[
    const _Step('Install dependencies', ['dart', 'pub', 'get']),
    const _Step('Analyze', ['dart', 'analyze']),
    const _Step('Test', ['dart', 'test']),
    const _Step('Generate typed endpoints', [
      'dart',
      'run',
      'tool/generate_typed_endpoints.dart',
    ]),
    const _Step('Verify generated file is clean', [
      'git',
      'diff',
      '--exit-code',
      '--',
      'lib/src/api/typed_endpoints.dart',
    ]),
    _Step('Prepublish check', [
      'dart',
      'run',
      'tool/prepublish_check.dart',
      ...blockedArgs,
    ]),
  ];

  for (final step in steps) {
    stdout.writeln('==> ${step.name}');
    final exitCode = await _run(step.command);
    if (exitCode != 0) {
      stderr.writeln('Step failed: ${step.name}');
      exit(exitCode);
    }
  }

  stdout.writeln('All checks passed.');
}

Future<int> _run(List<String> command) async {
  final process = await Process.start(
    command.first,
    command.skip(1).toList(growable: false),
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  return process.exitCode;
}
