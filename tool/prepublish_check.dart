import 'dart:convert';
import 'dart:io';

const _privateSpecFiles = <String>[
  'klas-api-spec.md',
  'klasflow_LLM_RFP_with_API_Spec.md',
];

const _ignoredDirs = <String>{
  '.git',
  '.dart_tool',
  '.idea',
  '.tmp',
  'coverage',
  'build',
};

Future<void> main(List<String> args) async {
  var hasFailure = false;
  final blockedLiterals = _loadBlockedLiterals();

  stdout.writeln('[prepublish] Running release safety checks...');

  final gitVersion = await _runGit(['--version']);
  if (gitVersion.exitCode != 0) {
    stderr.writeln('[fail] git is required.');
    exit(1);
  }

  for (final specFile in _privateSpecFiles) {
    final tracked = await _runGit(['ls-files', '--', specFile]);
    if (tracked.stdout.toString().trim().isNotEmpty) {
      stderr.writeln('[fail] Private spec file is tracked: $specFile');
      hasFailure = true;
    } else {
      stdout.writeln('[ok] Private spec file is not tracked: $specFile');
    }

    final committed = await _runGit([
      'log',
      '--all',
      '--oneline',
      '--',
      specFile,
    ]);
    if (committed.stdout.toString().trim().isNotEmpty) {
      stderr.writeln(
        '[fail] Private spec file exists in git history: $specFile',
      );
      hasFailure = true;
    } else {
      stdout.writeln(
        '[ok] Private spec file not found in git history: $specFile',
      );
    }
  }

  if (blockedLiterals.isEmpty) {
    stdout.writeln(
      '[info] KLASFLOW_BLOCKED_LITERALS is empty. Literal checks are skipped.',
    );
  }

  for (final literal in blockedLiterals) {
    hasFailure = await _checkBlockedLiteral(literal: literal) || hasFailure;
  }

  if (hasFailure) {
    stderr.writeln('[prepublish] Failed. Fix issues before publishing.');
    exit(1);
  }

  stdout.writeln('[prepublish] Passed.');
}

Future<ProcessResult> _runGit(List<String> args) {
  return Process.run('git', args, runInShell: true);
}

List<String> _loadBlockedLiterals() {
  final raw = Platform.environment['KLASFLOW_BLOCKED_LITERALS'];
  if (raw == null || raw.trim().isEmpty) {
    return const <String>[];
  }

  return raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

Future<bool> _checkBlockedLiteral({required String literal}) async {
  var hasFailure = false;

  final headMatches = await _runGit(['grep', '-n', '--', literal]);
  if (headMatches.exitCode == 0) {
    stderr.writeln('[fail] Found blocked literal in tracked files: "$literal"');
    stderr.writeln(headMatches.stdout.toString().trim());
    hasFailure = true;
  } else if (headMatches.exitCode == 1) {
    stdout.writeln(
      '[ok] Blocked literal not found in tracked files: "$literal"',
    );
  } else {
    stderr.writeln('[warn] git grep failed for "$literal"');
    stderr.writeln(headMatches.stderr.toString().trim());
    hasFailure = true;
  }

  final historyMatches = await _runGit([
    'log',
    '--all',
    '-S',
    literal,
    '--oneline',
  ]);
  if (historyMatches.stdout.toString().trim().isNotEmpty) {
    stderr.writeln('[fail] Blocked literal found in git history: "$literal"');
    stderr.writeln(historyMatches.stdout.toString().trim());
    hasFailure = true;
  } else {
    stdout.writeln('[ok] Blocked literal not found in git history: "$literal"');
  }

  final treeMatches = await _scanWorkingTreeForLiteral(literal);
  if (treeMatches.isNotEmpty) {
    stderr.writeln(
      '[fail] Blocked literal found in working tree files: "$literal"',
    );
    for (final path in treeMatches) {
      stderr.writeln('  - $path');
    }
    hasFailure = true;
  } else {
    stdout.writeln(
      '[ok] Blocked literal not found in working tree files: "$literal"',
    );
  }

  return hasFailure;
}

Future<List<String>> _scanWorkingTreeForLiteral(String literal) async {
  final matches = <String>[];
  final root = Directory.current;

  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }

    final relativePath = _toRelativePath(root.path, entity.path);
    if (_shouldIgnorePath(relativePath)) {
      continue;
    }

    final bytes = await entity.readAsBytes();
    if (_looksBinary(bytes)) {
      continue;
    }

    final content = utf8.decode(bytes, allowMalformed: true);
    if (content.contains(literal)) {
      matches.add(relativePath);
    }
  }

  return matches;
}

String _toRelativePath(String root, String absolutePath) {
  final rootWithSlash = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  if (absolutePath.startsWith(rootWithSlash)) {
    return absolutePath.substring(rootWithSlash.length).replaceAll('\\', '/');
  }
  return absolutePath.replaceAll('\\', '/');
}

bool _shouldIgnorePath(String relativePath) {
  final parts = relativePath.split('/');
  for (final part in parts) {
    if (_ignoredDirs.contains(part)) {
      return true;
    }
  }
  return false;
}

bool _looksBinary(List<int> bytes) {
  final sampleLength = bytes.length < 1024 ? bytes.length : 1024;
  for (var i = 0; i < sampleLength; i++) {
    if (bytes[i] == 0) {
      return true;
    }
  }
  return false;
}
