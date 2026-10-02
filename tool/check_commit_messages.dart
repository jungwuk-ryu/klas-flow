import 'dart:io';

final _conventionalSubject = RegExp(
  r'^(feat|fix|refactor|docs|test|chore|ci|build|perf|revert)(\([a-z0-9._/-]+\))?!?: .+',
);
final _generatedSubject = RegExp(r'^(Merge |Revert "|fixup!|squash!)');
final _commitId = RegExp(r'^[0-9a-fA-F]{40,64}$');

Future<void> main() async {
  final base = Platform.environment['CI_COMMIT_BASE'];
  final head = Platform.environment['CI_COMMIT_HEAD'] ?? 'HEAD';
  if ((base != null && base.isNotEmpty && !_commitId.hasMatch(base)) ||
      (head != 'HEAD' && !_commitId.hasMatch(head))) {
    stderr.writeln('Commit range must use Git commit IDs.');
    exitCode = 1;
    return;
  }

  final hasBase =
      base != null && base.isNotEmpty && !RegExp(r'^0+$').hasMatch(base);
  final result = await Process.run('git', [
    'log',
    '--format=%s',
    if (!hasBase) '--max-count=1',
    hasBase ? '$base..$head' : head,
    '--',
  ]);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exitCode = result.exitCode;
    return;
  }

  var invalid = false;
  var count = 0;
  for (final subject in result.stdout.toString().split(RegExp(r'\r?\n'))) {
    if (subject.isEmpty) continue;
    count++;
    if (!_generatedSubject.hasMatch(subject) &&
        !_conventionalSubject.hasMatch(subject)) {
      stderr.writeln('Invalid commit message: $subject');
      invalid = true;
    }
  }
  if (invalid) {
    stderr.writeln('Commit message convention check failed.');
    exitCode = 1;
    return;
  }
  stdout.writeln('Commit message check passed ($count commits).');
}
