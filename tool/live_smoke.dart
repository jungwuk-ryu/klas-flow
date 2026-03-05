import 'dart:io';

import 'package:klasflow/klasflow.dart';

/// 실계정 읽기 전용 smoke 테스트.
///
/// 사용법(Windows PowerShell):
///   $env:KLAS_ID="2023xxxxxx"
///   $env:KLAS_PASSWORD="your-password"
///   dart run tool/live_smoke.dart
///
/// 선택 환경 변수:
/// - KLAS_BASE_URI: 기본값 https://klas.kw.ac.kr
/// - KLAS_MAX_POSTS: 게시판별 상세 검증 개수(기본 3)
Future<void> main() async {
  final id = Platform.environment['KLAS_ID']?.trim() ?? '';
  final password = Platform.environment['KLAS_PASSWORD'] ?? '';
  final baseUri = _resolveBaseUri();
  final maxPosts = _resolveMaxPosts();

  if (id.isEmpty || password.isEmpty) {
    stderr.writeln('Missing credentials.');
    stderr.writeln('Set KLAS_ID and KLAS_PASSWORD environment variables.');
    exitCode = 64;
    return;
  }

  final client = KlasClient(config: KlasClientConfig(baseUri: baseUri));
  final failures = <String>[];

  stdout.writeln('Smoke start: $baseUri');
  try {
    final user = await client.login(id, password);
    final profile = await user.profile(refresh: true);
    final personalInfo = await user.personalInfo(refresh: true);
    final courses = await user.courses(refresh: true);

    stdout.writeln(
      'Login OK: userId=${profile.userId ?? personalInfo.userId ?? '-'} '
      'userName=${profile.userName ?? personalInfo.userName ?? '-'} '
      'courses=${courses.length}',
    );

    final course = await user.defaultCourse();
    if (course == null) {
      failures.add('No default course found.');
      _printResultAndExit(failures);
      return;
    }

    stdout.writeln(
      'Default course: ${course.title ?? '-'} '
      '(courseId=${course.courseId}, termId=${course.termId})',
    );

    await course.overview();
    await course.listTasks(page: 0);

    final noticeList = await course.noticeBoard.listPosts(page: 0);
    final materialList = await course.materialBoard.listPosts(page: 0);

    stdout.writeln(
      'Board list: notices=${noticeList.posts.length}, '
      'materials=${materialList.posts.length}',
    );

    await _verifyBoard(
      boardName: '공지사항',
      posts: noticeList.posts,
      maxPosts: maxPosts,
      getPost: (post) {
        final masterNo = post.masterNo?.toString();
        return course.noticeBoard.getPost(
          boardNo: post.boardNo!,
          query: masterNo == null
              ? null
              : <String, dynamic>{'searchMasterNo': masterNo},
        );
      },
      openPostPage: (post) {
        final masterNo = post.masterNo?.toString();
        return course.noticeBoard.openPostPage(
          boardNo: post.boardNo!,
          query: masterNo == null
              ? null
              : <String, dynamic>{'searchMasterNo': masterNo},
        );
      },
      failures: failures,
    );

    await _verifyBoard(
      boardName: '강의자료실',
      posts: materialList.posts,
      maxPosts: maxPosts,
      getPost: (post) {
        final masterNo = post.masterNo?.toString();
        return course.materialBoard.getPost(
          boardNo: post.boardNo!,
          query: masterNo == null
              ? null
              : <String, dynamic>{'searchMasterNo': masterNo},
        );
      },
      openPostPage: (post) {
        final masterNo = post.masterNo?.toString();
        return course.materialBoard.openPostPage(
          boardNo: post.boardNo!,
          query: masterNo == null
              ? null
              : <String, dynamic>{'searchMasterNo': masterNo},
        );
      },
      failures: failures,
    );
  } on KlasException catch (error) {
    failures.add('KLAS error: ${error.message}');
  } catch (error) {
    failures.add('Unexpected error: $error');
  } finally {
    client.close();
  }

  _printResultAndExit(failures);
}

Future<void> _verifyBoard({
  required String boardName,
  required List<KlasBoardPostSummary> posts,
  required int maxPosts,
  required Future<KlasBoardPostDetail> Function(KlasBoardPostSummary post)
  getPost,
  required Future<String> Function(KlasBoardPostSummary post) openPostPage,
  required List<String> failures,
}) async {
  final candidates = posts
      .where((post) => post.boardNo != null)
      .take(maxPosts)
      .toList(growable: false);
  if (candidates.isEmpty) {
    stdout.writeln('$boardName: no posts to verify.');
    return;
  }

  for (final post in candidates) {
    final boardNo = post.boardNo!;
    final title = post.title ?? '(title 없음)';
    stdout.writeln('$boardName #$boardNo: $title');
    try {
      final detail = await getPost(post);
      final body = _extractBodyFromRecord(detail.board?.raw);
      if (_looksValidBody(body)) {
        stdout.writeln('  getPost body OK (${body!.length} chars)');
        continue;
      }

      final html = await openPostPage(post);
      final htmlBody = _extractBodyFromHtml(html);
      if (_looksValidBody(htmlBody)) {
        stdout.writeln('  openPostPage body OK (${htmlBody!.length} chars)');
        continue;
      }

      if ((post.fileCount ?? 0) > 0) {
        stdout.writeln(
          '  attachment-only post (fileCount=${post.fileCount}) treated as OK',
        );
        continue;
      }

      failures.add(
        '$boardName boardNo=$boardNo has no usable body '
        '(jsonBody=${body?.length ?? 0}, htmlBody=${htmlBody?.length ?? 0})',
      );
    } catch (error) {
      failures.add('$boardName boardNo=$boardNo failed: $error');
    }
  }
}

Uri _resolveBaseUri() {
  final raw = Platform.environment['KLAS_BASE_URI']?.trim() ?? '';
  if (raw.isEmpty) {
    return Uri(scheme: 'https', host: 'klas.kw.ac.kr');
  }
  final parsed = Uri.tryParse(raw);
  if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
    return Uri(scheme: 'https', host: 'klas.kw.ac.kr');
  }
  return parsed;
}

int _resolveMaxPosts() {
  final raw = Platform.environment['KLAS_MAX_POSTS'];
  final parsed = raw == null ? null : int.tryParse(raw);
  if (parsed == null || parsed <= 0) {
    return 3;
  }
  if (parsed > 10) {
    return 10;
  }
  return parsed;
}

void _printResultAndExit(List<String> failures) {
  if (failures.isEmpty) {
    stdout.writeln('Smoke result: PASS');
    exitCode = 0;
    return;
  }

  stderr.writeln('Smoke result: FAIL (${failures.length})');
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  exitCode = 1;
}

String? _extractBodyFromRecord(Map<String, dynamic>? source) {
  if (source == null || source.isEmpty) {
    return null;
  }
  const keys = <String>[
    'content',
    'contents',
    'cn',
    'bbsCn',
    'boardCn',
    'boardContents',
    'boardContent',
    'memo',
    'body',
    'text',
    'html',
  ];
  final text = _pickField(source, keys);
  if (text != null && text.trim().isNotEmpty) {
    final cleaned = _stripHtml(text);
    if (_looksValidBody(cleaned)) {
      return cleaned;
    }
  }
  return null;
}

String? _extractBodyFromHtml(String html) {
  if (html.trim().isEmpty) {
    return null;
  }

  final patterns = <RegExp>[
    RegExp(
      r'<(?:div|td|section)[^>]*class="[^"]*(?:board|bbs)[^"]*(?:content|cn|view)[^"]*"[^>]*>(.*?)</(?:div|td|section)>',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'<textarea[^>]*name="[^"]*(?:content|cn|bbsCn|boardCn)[^"]*"[^>]*>(.*?)</textarea>',
      caseSensitive: false,
      dotAll: true,
    ),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(html);
    if (match == null) {
      continue;
    }
    final body = match.group(1);
    if (body == null || body.trim().isEmpty) {
      continue;
    }
    final cleaned = _stripHtml(body);
    if (_looksValidBody(cleaned)) {
      return cleaned;
    }
  }
  return null;
}

String? _pickField(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final normalized = _normalize(key);
    for (final entry in source.entries) {
      if (_normalize(entry.key) != normalized) {
        continue;
      }
      final value = entry.value?.toString();
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

bool _looksValidBody(String? text) {
  if (text == null) {
    return false;
  }
  final trimmed = text.trim();
  if (trimmed.length < 8) {
    return false;
  }
  if (trimmed.contains('{{') && trimmed.contains('}}')) {
    final withoutWhitespace = trimmed.replaceAll(RegExp(r'\s+'), '');
    final removed = withoutWhitespace.replaceAll(RegExp(r'\{\{.*?\}\}'), '');
    if (removed.length <= 12) {
      return false;
    }
  }
  return true;
}

String _stripHtml(String source) {
  final withBreaks = source
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
  final plain = withBreaks.replaceAll(RegExp(r'<[^>]*>'), '');
  return plain
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .trim();
}

String _normalize(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
}
