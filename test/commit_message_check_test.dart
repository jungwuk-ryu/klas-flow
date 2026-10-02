import 'dart:io';

import 'package:test/test.dart';

void main() {
  final script = File('tool/check_commit_messages.dart').absolute.path;
  late Directory repository;
  late String base;

  Future<ProcessResult> git(List<String> args) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: repository.path,
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return result;
  }

  Future<void> commit(String subject) async {
    await git([
      '-c',
      'commit.gpgsign=false',
      'commit',
      '--allow-empty',
      '-m',
      subject,
    ]);
  }

  Future<ProcessResult> validate({String? rangeBase}) async {
    final head = (await git(['rev-parse', 'HEAD'])).stdout.toString().trim();
    return Process.run(
      Platform.resolvedExecutable,
      [script],
      workingDirectory: repository.path,
      environment: {
        'CI_COMMIT_BASE': rangeBase ?? base,
        'CI_COMMIT_HEAD': head,
      },
    );
  }

  setUp(() async {
    repository = await Directory.systemTemp.createTemp('klas_commit_range_');
    await git(['init']);
    await git(['config', 'user.name', 'Commit fixture']);
    await git(['config', 'user.email', 'fixture@example.com']);
    await commit('Legacy subject without a convention');
    base = (await git(['rev-parse', 'HEAD'])).stdout.toString().trim();
  });
  tearDown(() => repository.delete(recursive: true));

  test(
    'legacy history outside the PR range does not reject new commits',
    () async {
      await commit('feat(auth): continue captcha login');
      await commit('fix(attendance): handle verification');
      final result = await validate();
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('(2 commits)'));
    },
  );

  test('a newly introduced invalid commit is rejected', () async {
    await commit('feat(auth): continue captcha login');
    await commit('Invalid new subject');
    final result = await validate();
    expect(result.exitCode, 1);
    expect(
      result.stderr,
      contains('Invalid commit message: Invalid new subject'),
    );
  });

  test(
    'an initial push checks its tip without auditing legacy history',
    () async {
      await commit('ci: validate newly pushed commits');
      final result = await validate(rangeBase: '0' * 40);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('(1 commits)'));
    },
  );
}
