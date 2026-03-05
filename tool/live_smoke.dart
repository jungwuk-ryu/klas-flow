import 'dart:convert';
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
  final maxSamples = _resolveMaxPosts();

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

    var taskCourse = course;
    var tasks = await taskCourse.listTasks(page: 0);

    var onlineContentCourse = course;
    var onlineContents = await onlineContentCourse.learning.onlineContents(
      page: 0,
    );

    var onlineTestCourse = course;
    var onlineTests = await onlineTestCourse.learning.onlineTests(page: 0);

    var quizCourse = course;
    var quizzes = await quizCourse.learning.listAnytimeQuizzes(page: 0);

    var discussionCourse = course;
    var discussions = await discussionCourse.learning.listDiscussions(page: 0);

    // 기본 과목에 데이터가 없을 수 있어, 카테고리별로 데이터가 있는 과목을 다시 찾는다.
    if (tasks.isEmpty) {
      final found = await _findCourseWithItems<KlasTask>(
        courses: courses,
        excludedCourse: course,
        label: '과제',
        loader: (candidate) => candidate.listTasks(page: 0),
      );
      if (found != null) {
        taskCourse = found.key;
        tasks = found.value;
      }
    }

    if (onlineContents.isEmpty) {
      final found = await _findCourseWithItems<KlasRecord>(
        courses: courses,
        excludedCourse: course,
        label: '온라인 콘텐츠',
        loader: (candidate) => candidate.learning.onlineContents(page: 0),
      );
      if (found != null) {
        onlineContentCourse = found.key;
        onlineContents = found.value;
      }
    }

    if (onlineTests.isEmpty) {
      final found = await _findCourseWithItems<KlasRecord>(
        courses: courses,
        excludedCourse: course,
        label: '온라인 시험',
        loader: (candidate) => candidate.learning.onlineTests(page: 0),
      );
      if (found != null) {
        onlineTestCourse = found.key;
        onlineTests = found.value;
      }
    }

    if (quizzes.isEmpty) {
      final found = await _findCourseWithItems<KlasRecord>(
        courses: courses,
        excludedCourse: course,
        label: '수시퀴즈',
        loader: (candidate) => candidate.learning.listAnytimeQuizzes(page: 0),
      );
      if (found != null) {
        quizCourse = found.key;
        quizzes = found.value;
      }
    }

    if (discussions.isEmpty) {
      final found = await _findCourseWithItems<KlasRecord>(
        courses: courses,
        excludedCourse: course,
        label: '토론',
        loader: (candidate) => candidate.learning.listDiscussions(page: 0),
      );
      if (found != null) {
        discussionCourse = found.key;
        discussions = found.value;
      }
    }

    final noticeList = await course.noticeBoard.listPosts(page: 0);
    final materialList = await course.materialBoard.listPosts(page: 0);

    stdout.writeln(
      'Board list: notices=${noticeList.posts.length}, '
      'materials=${materialList.posts.length}',
    );
    stdout.writeln(
      'Learning list: '
      'tasks=${tasks.length} ${_courseTag(taskCourse)}, '
      'contents=${onlineContents.length} ${_courseTag(onlineContentCourse)}, '
      'tests=${onlineTests.length} ${_courseTag(onlineTestCourse)}, '
      'quizzes=${quizzes.length} ${_courseTag(quizCourse)}, '
      'discussions=${discussions.length} ${_courseTag(discussionCourse)}',
    );

    await _verifyBoard(
      boardName: '공지사항',
      posts: noticeList.posts,
      maxPosts: maxSamples,
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
      listAttachments: (attachId) =>
          user.files.listByAttachId(attachId: attachId),
      downloadAttachment: (attachId, fileSn) =>
          user.files.download(attachId: attachId, fileSn: fileSn),
      failures: failures,
    );

    await _verifyBoard(
      boardName: '강의자료실',
      posts: materialList.posts,
      maxPosts: maxSamples,
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
      listAttachments: (attachId) =>
          user.files.listByAttachId(attachId: attachId),
      downloadAttachment: (attachId, fileSn) =>
          user.files.download(attachId: attachId, fileSn: fileSn),
      failures: failures,
    );

    await _verifyLearning(
      taskCourse: taskCourse,
      maxSamples: maxSamples,
      tasks: tasks,
      onlineContentCourse: onlineContentCourse,
      onlineContents: onlineContents,
      onlineTestCourse: onlineTestCourse,
      onlineTests: onlineTests,
      quizCourse: quizCourse,
      quizzes: quizzes,
      discussionCourse: discussionCourse,
      discussions: discussions,
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
  required Future<List<KlasAttachedFile>> Function(String attachId)
  listAttachments,
  required Future<FilePayload> Function(String attachId, String fileSn)
  downloadAttachment,
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
      final attachId =
          _extractAttachId(detail.board?.raw) ?? _extractAttachId(post.raw);
      final hasAttachment = (post.fileCount ?? 0) > 0 || attachId != null;
      var attachmentsVerified = false;

      if (hasAttachment) {
        attachmentsVerified = await _verifyAttachments(
          boardName: boardName,
          boardNo: boardNo,
          attachId: attachId,
          listAttachments: listAttachments,
          downloadAttachment: downloadAttachment,
          failures: failures,
        );
      }

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

      if (attachmentsVerified) {
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

Future<MapEntry<KlasCourse, List<T>>?> _findCourseWithItems<T>({
  required List<KlasCourse> courses,
  required KlasCourse excludedCourse,
  required String label,
  required Future<List<T>> Function(KlasCourse course) loader,
}) async {
  for (final course in courses) {
    if (_sameCourse(course, excludedCourse)) {
      continue;
    }
    try {
      final rows = await loader(course);
      if (rows.isNotEmpty) {
        return MapEntry<KlasCourse, List<T>>(course, rows);
      }
    } catch (error) {
      stdout.writeln('$label scan skipped ${_courseTag(course)}: $error');
    }
  }
  return null;
}

Future<void> _verifyLearning({
  required KlasCourse taskCourse,
  required int maxSamples,
  required List<KlasTask> tasks,
  required KlasCourse onlineContentCourse,
  required List<KlasRecord> onlineContents,
  required KlasCourse onlineTestCourse,
  required List<KlasRecord> onlineTests,
  required KlasCourse quizCourse,
  required List<KlasRecord> quizzes,
  required KlasCourse discussionCourse,
  required List<KlasRecord> discussions,
  required List<String> failures,
}) async {
  final taskSectionName = '과제 ${_courseTag(taskCourse)}';
  final contentSectionName = '온라인 콘텐츠 ${_courseTag(onlineContentCourse)}';
  final onlineTestSectionName = '온라인 시험 ${_courseTag(onlineTestCourse)}';
  final quizSectionName = '수시퀴즈 ${_courseTag(quizCourse)}';
  final discussionSectionName = '토론 ${_courseTag(discussionCourse)}';

  final taskStatus = await _safeRecordList(
    label: '학습현황(taskStatus:${_courseTag(taskCourse)})',
    loader: () => taskCourse.learning.taskStatus(),
    failures: failures,
  );
  late final List<KlasRecord> onlineTestStatus;
  late final List<KlasRecord> quizStatus;
  if (_sameCourse(onlineTestCourse, quizCourse)) {
    // 시험/퀴즈 과목이 같으면 학습현황 API를 한 번만 호출해 재사용한다.
    final shared = await _safeRecordList(
      label: '학습현황(testAndQuizStatus:${_courseTag(onlineTestCourse)})',
      loader: () => onlineTestCourse.learning.testAndQuizStatus(),
      failures: failures,
    );
    onlineTestStatus = shared;
    quizStatus = shared;
  } else {
    onlineTestStatus = await _safeRecordList(
      label: '학습현황(testAndQuizStatus:${_courseTag(onlineTestCourse)})',
      loader: () => onlineTestCourse.learning.testAndQuizStatus(),
      failures: failures,
    );
    quizStatus = await _safeRecordList(
      label: '학습현황(testAndQuizStatus:${_courseTag(quizCourse)})',
      loader: () => quizCourse.learning.testAndQuizStatus(),
      failures: failures,
    );
  }
  final discussionStatus = await _safeRecordList(
    label: '학습현황(discussionStatus:${_courseTag(discussionCourse)})',
    loader: () => discussionCourse.learning.discussionStatus(),
    failures: failures,
  );

  final taskRows = tasks
      .map((task) => KlasRecord(task.raw))
      .toList(growable: false);

  await _verifyRecordDetails(
    sectionName: taskSectionName,
    rows: taskRows,
    maxSamples: maxSamples,
    titleKeys: const <String>['title', 'taskTitle', 'name'],
    detailKeys: const <String>[
      'sedate',
      'startdate',
      'expiredate',
      'submityn',
      'submit',
      'score',
      'weeklyseq',
      'weeklysubseq',
    ],
    statusRows: taskStatus,
    statusTitleKeys: const <String>['title'],
    statusDetailKeys: const <String>[
      'sedate',
      'startdate',
      'expiredate',
      'submit',
      'score',
    ],
    failures: failures,
    minDetailChars: 6,
  );

  await _verifyRecordDetails(
    sectionName: contentSectionName,
    rows: onlineContents,
    maxSamples: maxSamples,
    titleKeys: const <String>[
      'title',
      'sdesc',
      'sbjt',
      'moduletitle',
      'lessontitle',
      'cntntsNm',
      'cntntNm',
      'name',
    ],
    detailKeys: const <String>[
      'lrnPd',
      'startDate',
      'endDate',
      'sdate',
      'edate',
      'weeklyseq',
      'lesson',
      'module',
      'prog',
      'types',
      'isonoff',
    ],
    statusRows: const <KlasRecord>[],
    failures: failures,
    minDetailChars: 8,
    verifyRemotePage: true,
    remotePageUrlKeys: const <String>['starting'],
  );

  await _verifyRecordDetails(
    sectionName: onlineTestSectionName,
    rows: onlineTests,
    maxSamples: maxSamples,
    titleKeys: const <String>[
      'title',
      'papernm',
      'testTitle',
      'examTitle',
      'name',
    ],
    detailKeys: const <String>[
      'sdt',
      'edt',
      'sdate',
      'edate',
      'examtype',
      'examtypenm',
      'issubmit',
      'submit',
      'progress',
    ],
    statusRows: onlineTestStatus,
    statusTitleKeys: const <String>['papernm', 'title'],
    statusDetailKeys: const <String>[
      'sedate',
      'sdate',
      'edate',
      'submit',
      'score',
      'examtype',
    ],
    failures: failures,
    minDetailChars: 6,
  );

  await _verifyRecordDetails(
    sectionName: quizSectionName,
    rows: quizzes,
    maxSamples: maxSamples,
    titleKeys: const <String>['papernm', 'title', 'quizTitle', 'name'],
    detailKeys: const <String>[
      'sdt',
      'edt',
      'sdate',
      'edate',
      'examtype',
      'examtypenm',
      'issubmit',
      'isresubmit',
      'totalscore',
      'sparetime',
    ],
    statusRows: quizStatus,
    statusTitleKeys: const <String>['papernm', 'title'],
    statusDetailKeys: const <String>[
      'sedate',
      'sdate',
      'edate',
      'submit',
      'score',
      'examtype',
    ],
    failures: failures,
    minDetailChars: 6,
  );

  await _verifyRecordDetails(
    sectionName: discussionSectionName,
    rows: discussions,
    maxSamples: maxSamples,
    titleKeys: const <String>[
      'title',
      'dscsnTitle',
      'discussionTitle',
      'topic',
      'subject',
      'name',
    ],
    detailKeys: const <String>[
      'sdt',
      'edt',
      'sdate',
      'edate',
      'status',
      'state',
      'submit',
      'progress',
      'content',
      'cn',
      'bbsCn',
      'boardCn',
    ],
    statusRows: discussionStatus,
    statusTitleKeys: const <String>['title', 'dscsnTitle', 'discussionTitle'],
    statusDetailKeys: const <String>[
      'sedate',
      'sdate',
      'edate',
      'submit',
      'status',
      'state',
    ],
    failures: failures,
    minDetailChars: 6,
  );
}

bool _sameCourse(KlasCourse a, KlasCourse b) {
  return a.termId == b.termId && a.courseId == b.courseId;
}

String _courseTag(KlasCourse course) {
  final title = (course.title ?? '-').trim();
  final resolved = title.isEmpty ? '-' : title;
  return '[$resolved ${course.termId}/${course.courseId}]';
}

Future<List<KlasRecord>> _safeRecordList({
  required String label,
  required Future<List<KlasRecord>> Function() loader,
  required List<String> failures,
}) async {
  try {
    return await loader();
  } catch (error) {
    failures.add('$label fetch failed: $error');
    return const <KlasRecord>[];
  }
}

Future<void> _verifyRecordDetails({
  required String sectionName,
  required List<KlasRecord> rows,
  required int maxSamples,
  required List<String> titleKeys,
  required List<String> detailKeys,
  List<KlasRecord>? statusRows,
  List<String>? statusTitleKeys,
  List<String>? statusDetailKeys,
  required List<String> failures,
  required int minDetailChars,
  bool verifyRemotePage = false,
  List<String> remotePageUrlKeys = const <String>['starting', 'url', 'link'],
}) async {
  final statuses = statusRows ?? const <KlasRecord>[];
  final candidates = rows.take(maxSamples).toList(growable: false);
  if (candidates.isEmpty) {
    stdout.writeln('$sectionName: no items to verify.');
    return;
  }

  var remoteChecked = !verifyRemotePage;
  for (var i = 0; i < candidates.length; i++) {
    final row = candidates[i];
    final raw = row.raw;
    var title = _pickField(raw, titleKeys);
    final status = _matchStatusByIdentity(
      source: raw,
      statuses: statuses,
      titleKeys: titleKeys,
      statusTitleKeys: statusTitleKeys ?? titleKeys,
    );
    if (title == null && status != null) {
      title = _pickField(status.raw, statusTitleKeys ?? titleKeys);
    }

    final detailValues = <String>[
      ..._pickValues(raw, detailKeys),
      if (status != null)
        ..._pickValues(status.raw, statusDetailKeys ?? detailKeys),
    ];
    final deduped = _dedupe(detailValues);
    final displayTitle = title ?? '(제목 없음)';

    stdout.writeln('$sectionName #${i + 1}: $displayTitle');

    if (title == null || title.trim().isEmpty) {
      failures.add('$sectionName item#${i + 1} has no title field.');
      continue;
    }
    if (!_hasMeaningfulDetail(deduped, minChars: minDetailChars)) {
      failures.add('$sectionName "$title" missing detail fields.');
      continue;
    }

    if (!remoteChecked) {
      final url = _pickField(raw, remotePageUrlKeys);
      if (url != null && _looksHttpUrl(url)) {
        try {
          final html = await _fetchUrlText(url);
          final pageTitle = _extractHtmlTitle(html);
          final pageBody = _extractGenericHtmlBody(html);
          final titleUsable = pageTitle != null && pageTitle.trim().length >= 4;
          if (!_looksValidBody(pageBody) && !titleUsable) {
            failures.add(
              '$sectionName "$title" detail page has no usable content.',
            );
          } else {
            stdout.writeln(
              '  remote detail OK '
              '(pageTitle=${pageTitle ?? '-'}, body=${pageBody?.length ?? 0})',
            );
          }
        } catch (error) {
          failures.add(
            '$sectionName "$title" remote detail fetch failed: $error',
          );
        } finally {
          remoteChecked = true;
        }
      }
    }

    stdout.writeln('  detail OK (${deduped.length} fields)');
  }
}

KlasRecord? _matchStatusByIdentity({
  required Map<String, dynamic> source,
  required List<KlasRecord> statuses,
  required List<String> titleKeys,
  required List<String> statusTitleKeys,
}) {
  if (statuses.isEmpty) {
    return null;
  }

  final sourceWeeklySeq = _toIntValue(_pickField(source, const ['weeklyseq']));
  final sourceWeeklySubSeq = _toIntValue(
    _pickField(source, const ['weeklysubseq']),
  );
  final sourceTaskNo = _toIntValue(_pickField(source, const ['taskNo']));
  final sourcePaperNo = _toIntValue(_pickField(source, const ['papernum']));
  final sourceOid = _pickField(source, const ['oid'])?.trim();
  final sourceTitle = _normalizeText(_pickField(source, titleKeys));

  for (final status in statuses) {
    final raw = status.raw;
    final statusTaskNo = _toIntValue(_pickField(raw, const ['taskNo']));
    if (sourceTaskNo != null && statusTaskNo == sourceTaskNo) {
      return status;
    }

    final statusPaperNo = _toIntValue(_pickField(raw, const ['papernum']));
    if (sourcePaperNo != null && statusPaperNo == sourcePaperNo) {
      return status;
    }

    final statusWeeklySeq = _toIntValue(_pickField(raw, const ['weeklyseq']));
    final statusWeeklySubSeq = _toIntValue(
      _pickField(raw, const ['weeklysubseq']),
    );
    if (sourceWeeklySeq != null &&
        statusWeeklySeq == sourceWeeklySeq &&
        (sourceWeeklySubSeq == null ||
            statusWeeklySubSeq == sourceWeeklySubSeq)) {
      return status;
    }

    final statusOid = _pickField(raw, const ['oid'])?.trim();
    if (sourceOid != null &&
        sourceOid.isNotEmpty &&
        statusOid != null &&
        statusOid.isNotEmpty &&
        sourceOid == statusOid) {
      return status;
    }

    final statusTitle = _normalizeText(_pickField(raw, statusTitleKeys));
    if (sourceTitle.isNotEmpty &&
        statusTitle.isNotEmpty &&
        sourceTitle == statusTitle) {
      return status;
    }
  }
  return null;
}

Future<bool> _verifyAttachments({
  required String boardName,
  required int boardNo,
  required String? attachId,
  required Future<List<KlasAttachedFile>> Function(String attachId)
  listAttachments,
  required Future<FilePayload> Function(String attachId, String fileSn)
  downloadAttachment,
  required List<String> failures,
}) async {
  final resolvedAttachId = attachId?.trim();
  if (resolvedAttachId == null || resolvedAttachId.isEmpty) {
    failures.add(
      '$boardName boardNo=$boardNo expected attachId but none found.',
    );
    return false;
  }

  try {
    final files = await listAttachments(resolvedAttachId);
    if (files.isEmpty) {
      failures.add(
        '$boardName boardNo=$boardNo attachment list empty (attachId=$resolvedAttachId).',
      );
      return false;
    }
    stdout.writeln('  attachments list OK (${files.length})');

    KlasAttachedFile? target;
    for (final file in files) {
      final fileSn = file.fileSn?.trim();
      if (fileSn == null || fileSn.isEmpty) {
        continue;
      }
      target = file;
      break;
    }
    if (target == null) {
      failures.add(
        '$boardName boardNo=$boardNo has attachments but no downloadable fileSn.',
      );
      return false;
    }

    final resolvedDownloadAttachId = target.attachId?.trim().isNotEmpty == true
        ? target.attachId!.trim()
        : resolvedAttachId;

    final payload = await downloadAttachment(
      resolvedDownloadAttachId,
      target.fileSn!.trim(),
    );
    if (payload.bytes.isEmpty) {
      failures.add(
        '$boardName boardNo=$boardNo attachment download returned empty bytes.',
      );
      return false;
    }
    stdout.writeln(
      '  attachment download OK (${payload.bytes.length} bytes, '
      'file=${target.fileName ?? '-'})',
    );
    return true;
  } catch (error) {
    failures.add(
      '$boardName boardNo=$boardNo attachment verification failed: $error',
    );
    return false;
  }
}

String? _extractAttachId(Map<String, dynamic>? source) {
  if (source == null || source.isEmpty) {
    return null;
  }
  final value = _pickField(source, const <String>[
    'atchFileId',
    'attachId',
    'fileGroupId',
  ]);
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
    return null;
  }
  return trimmed;
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

String? _extractHtmlTitle(String html) {
  final match = RegExp(
    r'<title[^>]*>(.*?)</title>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);
  if (match == null) {
    return null;
  }
  final value = match.group(1);
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final cleaned = _stripHtml(value);
  return cleaned.isEmpty ? null : cleaned;
}

String? _extractGenericHtmlBody(String html) {
  if (html.trim().isEmpty) {
    return null;
  }
  final match = RegExp(
    r'<body[^>]*>(.*?)</body>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);
  final source = match?.group(1) ?? html;
  if (source.trim().isEmpty) {
    return null;
  }
  final cleaned = _stripHtml(source);
  return _looksValidBody(cleaned) ? cleaned : null;
}

Future<String> _fetchUrlText(String url) async {
  final parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
    throw ArgumentError('Invalid URL: $url');
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  client.autoUncompress = true;

  try {
    final request = await client.getUrl(parsed);
    request.headers.set(
      HttpHeaders.acceptHeader,
      'text/html,application/xhtml+xml',
    );
    request.headers.set(HttpHeaders.userAgentHeader, 'klasflow-live-smoke/1.0');

    final response = await request.close();
    final bytes = await _readResponseBytes(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'HTTP ${response.statusCode} while fetching detail page.',
        uri: parsed,
      );
    }
    return utf8.decode(bytes, allowMalformed: true);
  } finally {
    client.close(force: true);
  }
}

Future<List<int>> _readResponseBytes(HttpClientResponse response) async {
  final chunks = <int>[];
  await for (final part in response) {
    chunks.addAll(part);
  }
  return chunks;
}

bool _looksHttpUrl(String value) {
  final parsed = Uri.tryParse(value);
  if (parsed == null) {
    return false;
  }
  final scheme = parsed.scheme.toLowerCase();
  return (scheme == 'http' || scheme == 'https') && parsed.host.isNotEmpty;
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

List<String> _pickValues(Map<String, dynamic> source, List<String> keys) {
  final values = <String>[];
  for (final key in keys) {
    final value = _pickField(source, <String>[key]);
    if (value == null) {
      continue;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    values.add(trimmed);
  }
  return values;
}

List<String> _dedupe(List<String> values) {
  final seen = <String>{};
  final out = <String>[];
  for (final value in values) {
    if (seen.add(value)) {
      out.add(value);
    }
  }
  return out;
}

bool _hasMeaningfulDetail(List<String> values, {required int minChars}) {
  if (values.isEmpty) {
    return false;
  }
  final merged = values.join(' ').trim();
  if (merged.length < minChars) {
    return false;
  }
  if (merged.contains('{{') && merged.contains('}}')) {
    final withoutWhitespace = merged.replaceAll(RegExp(r'\s+'), '');
    final removed = withoutWhitespace.replaceAll(RegExp(r'\{\{.*?\}\}'), '');
    if (removed.length <= minChars) {
      return false;
    }
  }
  return true;
}

int? _toIntValue(String? value) {
  if (value == null) {
    return null;
  }
  return int.tryParse(value.trim());
}

String _normalizeText(String? value) {
  if (value == null) {
    return '';
  }
  return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
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
  final sanitized = source
      .replaceAll(
        RegExp(
          r'<script[^>]*>.*?</script>',
          caseSensitive: false,
          dotAll: true,
        ),
        ' ',
      )
      .replaceAll(
        RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
        ' ',
      );
  final withBreaks = sanitized
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
