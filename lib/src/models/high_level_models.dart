import 'file_payload.dart';
import 'session_info.dart';

/// 확장 가능한 고수준 레코드 객체입니다.
final class KlasRecord {
  /// 원본 응답 데이터입니다.
  final Map<String, dynamic> raw;

  const KlasRecord(this.raw);

  /// 문자열 필드를 읽습니다.
  String? string(String key) {
    final value = raw[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  /// 정수 필드를 읽습니다.
  int? integer(String key) {
    final value = raw[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  /// 불리언 필드를 읽습니다.
  bool? boolean(String key) {
    final value = raw[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'y' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == 'n' || normalized == 'no') {
        return false;
      }
      final parsed = num.tryParse(normalized);
      if (parsed != null) {
        return parsed != 0;
      }
    }
    return null;
  }
}

/// 페이징 메타데이터입니다.
final class KlasPageInfo {
  final int? totalPages;
  final int? totalElements;
  final int? currentPage;
  final int? pageSize;
  final Map<String, dynamic> raw;

  const KlasPageInfo({
    required this.raw,
    this.totalPages,
    this.totalElements,
    this.currentPage,
    this.pageSize,
  });

  factory KlasPageInfo.fromJson(Map<String, dynamic> json) {
    return KlasPageInfo(
      raw: json,
      totalPages: _toInt(json['totalPages']),
      totalElements: _toInt(json['totalElements']),
      currentPage: _toInt(json['currentPage']),
      pageSize: _toInt(json['pageSize']),
    );
  }
}

/// 사용자 프로필입니다.
final class KlasUserProfile {
  final String? userId;
  final String? userName;
  final bool authenticated;
  final Map<String, dynamic> raw;

  const KlasUserProfile({
    required this.authenticated,
    required this.raw,
    this.userId,
    this.userName,
  });

  factory KlasUserProfile.fromSessionInfo(SessionInfo session) {
    return KlasUserProfile(
      authenticated: session.authenticated,
      userId: session.userId,
      userName: session.userName,
      raw: session.raw,
    );
  }
}

/// 개인정보 수정 화면 기반 사용자 상세 프로필입니다.
final class KlasPersonalInfo {
  final String? userId;
  final String? userName;
  final String? englishName;
  final String? koreanNickname;
  final String? emailId;
  final String? emailHost;
  final String? homePostNo;
  final String? homeAddress1;
  final String? homeAddress2;
  final String? homePhone;
  final String? mobilePhone;
  final String? birthday;
  final bool? bankInfoOpen;
  final bool? birthdayOpen;
  final Map<String, dynamic> raw;

  const KlasPersonalInfo({
    required this.raw,
    this.userId,
    this.userName,
    this.englishName,
    this.koreanNickname,
    this.emailId,
    this.emailHost,
    this.homePostNo,
    this.homeAddress1,
    this.homeAddress2,
    this.homePhone,
    this.mobilePhone,
    this.birthday,
    this.bankInfoOpen,
    this.birthdayOpen,
  });

  factory KlasPersonalInfo.fromJson(Map<String, dynamic> json) {
    return KlasPersonalInfo(
      raw: json,
      userId: _toString(json['hakbun'] ?? json['userId'] ?? json['studentNo']),
      userName: _toString(json['kname'] ?? json['userName'] ?? json['name']),
      englishName: _toString(json['ename']),
      koreanNickname: _toString(json['knickname']),
      emailId: _toString(json['emailId']),
      emailHost: _toString(json['emailHost']),
      homePostNo: _toString(json['homePostno']),
      homeAddress1: _toString(json['homeAddr1']),
      homeAddress2: _toString(json['homeAddr2']),
      homePhone: _toString(json['homePhoneno']),
      mobilePhone: _toString(json['handPhoneno']),
      birthday: _toString(json['birthday']),
      bankInfoOpen: _toBoolYn(json['bankOpt']),
      birthdayOpen: _toBoolYn(json['birthdayOpt']),
    );
  }

  /// 이메일 표시 문자열입니다.
  String? get email {
    final id = emailId;
    final host = emailHost;
    if (id == null || host == null) {
      return null;
    }
    return '$id@$host';
  }
}

/// 세션 상태 정보입니다.
final class KlasSessionStatus {
  final bool authenticated;
  final int? logoutCountDownSec;
  final int? sessionNotiSec;
  final int? remainingTime;
  final Map<String, dynamic> raw;

  const KlasSessionStatus({
    required this.authenticated,
    required this.raw,
    this.logoutCountDownSec,
    this.sessionNotiSec,
    this.remainingTime,
  });

  factory KlasSessionStatus.fromJson(Map<String, dynamic> json) {
    return KlasSessionStatus(
      authenticated: _readBool(json),
      logoutCountDownSec: _toInt(json['logoutCountDownSec']),
      sessionNotiSec: _toInt(json['sessionNotiSec']),
      remainingTime: _toInt(json['remainingTime']),
      raw: json,
    );
  }

  static bool _readBool(Map<String, dynamic> json) {
    final keys = <String>[
      'authenticated',
      'isAuthenticated',
      'isLogin',
      'sessionAlive',
      'remainingTime',
      'logoutCountDownSec',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == 'y' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == 'n' || normalized == 'no') {
          return false;
        }
        final parsed = num.tryParse(normalized);
        if (parsed != null) {
          return parsed != 0;
        }
      }
    }
    return false;
  }
}

/// 강의 개요 정보입니다.
final class KlasCourseOverview {
  final KlasRecord record;

  const KlasCourseOverview(this.record);
}

/// 과제 항목입니다.
final class KlasTask {
  final int? taskNo;
  final String? title;
  final String? startDate;
  final String? expireDate;
  final bool? submitted;
  final Map<String, dynamic> raw;

  const KlasTask({
    required this.raw,
    this.taskNo,
    this.title,
    this.startDate,
    this.expireDate,
    this.submitted,
  });

  factory KlasTask.fromJson(Map<String, dynamic> json) {
    return KlasTask(
      raw: json,
      taskNo: _toInt(json['taskNo']),
      title: _toString(json['title']),
      startDate: _toString(json['startdate']),
      expireDate: _toString(json['expiredate']),
      submitted: _toBoolYn(json['submityn']),
    );
  }
}

/// 학기 시간표의 단일 수업 항목입니다.
final class KlasTimetableEntry {
  final String? subjectName;
  final String? professorName;
  final String? classroom;
  final String? dayOfWeek;
  final String? periodText;
  final String? startTime;
  final String? endTime;
  final Map<String, dynamic> raw;

  const KlasTimetableEntry({
    required this.raw,
    this.subjectName,
    this.professorName,
    this.classroom,
    this.dayOfWeek,
    this.periodText,
    this.startTime,
    this.endTime,
  });

  factory KlasTimetableEntry.fromJson(Map<String, dynamic> json) {
    final periodText = _readNormalizedString(json, const <String>[
      'lctreTime',
      'classTime',
      'periodText',
      'period',
      'timeText',
      'time',
    ]);
    final extractedDay = _extractWeekdayFromText(periodText);
    final extractedRange = _extractTimeRange(periodText);

    final rawDay = _readNormalizedString(json, const <String>[
      'dayNm',
      'weekDay',
      'yoilNm',
      'yoil',
      'day',
    ]);

    return KlasTimetableEntry(
      raw: json,
      subjectName: _readNormalizedString(json, const <String>[
        'subjNm',
        'subjectName',
        'gwamokNm',
        'courseName',
        'title',
        'lctreNm',
        'sbjt',
      ]),
      professorName: _readNormalizedString(json, const <String>[
        'professorName',
        'prfsrNm',
        'teacherName',
        'userNm',
        'staffNm',
      ]),
      classroom: _readNormalizedString(json, const <String>[
        'room',
        'classroom',
        'lecRoom',
        'lctreRoom',
        'ganguiSil',
        'loc',
      ]),
      dayOfWeek: _toWeekdayLabel(rawDay ?? extractedDay),
      periodText: periodText,
      startTime:
          _readNormalizedString(json, const <String>[
            'startTime',
            'beginTime',
            'stTime',
            'startTm',
            'frTm',
          ]) ??
          extractedRange.$1,
      endTime:
          _readNormalizedString(json, const <String>[
            'endTime',
            'finishTime',
            'edTime',
            'endTm',
            'toTm',
          ]) ??
          extractedRange.$2,
    );
  }

  /// 표시용 과목명입니다.
  String get title => subjectName ?? '(과목명 없음)';

  /// 표시용 시간 문자열입니다.
  String? get scheduleText {
    final range = _joinScheduleRange(startTime, endTime);
    final parts = <String?>[
      if (dayOfWeek?.isNotEmpty == true) dayOfWeek,
      range,
      if (range == null && periodText?.isNotEmpty == true) periodText,
    ].whereType<String>().toList(growable: false);
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' ');
  }
}

/// 학기 시간표 묶음입니다.
final class KlasTimetable {
  final List<KlasTimetableEntry> entries;
  final List<Map<String, dynamic>> rawRows;

  const KlasTimetable({required this.entries, required this.rawRows});

  factory KlasTimetable.fromRows(Iterable<Map<String, dynamic>> rows) {
    final copiedRows = rows.map(_copyMap).toList(growable: false);
    final parsedEntries = copiedRows
        .map(KlasTimetableEntry.fromJson)
        .toList(growable: false);
    return KlasTimetable(
      entries: List<KlasTimetableEntry>.unmodifiable(parsedEntries),
      rawRows: List<Map<String, dynamic>>.unmodifiable(copiedRows),
    );
  }

  /// 시간표가 비어있는지 여부입니다.
  bool get isEmpty => entries.isEmpty;

  /// 요일 기준으로 시간표를 그룹화합니다.
  Map<String, List<KlasTimetableEntry>> get groupedByWeekday {
    final grouped = <String, List<KlasTimetableEntry>>{};
    for (final entry in entries) {
      final day = entry.dayOfWeek ?? '기타';
      grouped.putIfAbsent(day, () => <KlasTimetableEntry>[]).add(entry);
    }

    final sortedKeys = grouped.keys.toList(growable: false)
      ..sort(_compareWeekdayLabels);

    final result = <String, List<KlasTimetableEntry>>{};
    for (final key in sortedKeys) {
      final dayEntries = grouped[key]!..sort(_compareTimetableEntry);
      result[key] = List<KlasTimetableEntry>.unmodifiable(dayEntries);
    }
    return Map<String, List<KlasTimetableEntry>>.unmodifiable(result);
  }
}

typedef KlasBoardPostDetailResolver =
    Future<KlasBoardPostDetail> Function({
      required int boardNo,
      required String cmd,
      Map<String, dynamic>? query,
    });

typedef KlasAttachedFileDownloadResolver =
    Future<FilePayload> Function({
      required String attachId,
      required String fileSn,
    });

/// 게시글 목록 요약 항목입니다.
final class KlasBoardPostSummary {
  final int? boardNo;
  final int? masterNo;
  final String? title;
  final String? authorName;
  final String? registeredAt;
  final String? attachId;
  final int? fileCount;
  final Map<String, dynamic> raw;
  final KlasBoardPostDetailResolver? _detailResolver;

  const KlasBoardPostSummary({
    required this.raw,
    this.boardNo,
    this.masterNo,
    this.title,
    this.authorName,
    this.registeredAt,
    this.attachId,
    this.fileCount,
    KlasBoardPostDetailResolver? detailResolver,
  }) : _detailResolver = detailResolver;

  /// 요약 객체에서 바로 게시글 상세를 조회합니다.
  Future<KlasBoardPostDetail> getPost({
    String cmd = 'select',
    Map<String, dynamic>? query,
  }) {
    final targetBoardNo = boardNo;
    if (targetBoardNo == null) {
      throw StateError('Cannot load post detail because boardNo is null.');
    }

    final resolver = _detailResolver;
    if (resolver == null) {
      throw StateError(
        'This post summary is not bound to a board feature. '
        'Load it via noticeBoard/materialBoard.listPosts().',
      );
    }

    final resolvedQuery = <String, dynamic>{
      if (masterNo != null) 'searchMasterNo': masterNo.toString(),
      if (query != null) ...query,
    };
    return resolver(
      boardNo: targetBoardNo,
      cmd: cmd,
      query: resolvedQuery.isEmpty ? null : resolvedQuery,
    );
  }

  /// 첨부파일 존재 여부입니다.
  bool get hasAttachments => (fileCount ?? 0) > 0 || attachId != null;

  factory KlasBoardPostSummary.fromJson(
    Map<String, dynamic> json, {
    KlasBoardPostDetailResolver? detailResolver,
  }) {
    return KlasBoardPostSummary(
      raw: json,
      boardNo: _toInt(json['boardNo']),
      masterNo: _toInt(json['masterNo']),
      title: _toString(json['title']),
      authorName: _toString(json['userNm']),
      registeredAt: _toString(json['registDt']),
      attachId: _toString(
        json['atchFileId'] ?? json['attachId'] ?? json['fileGroupId'],
      ),
      fileCount: _toInt(json['fileCnt']),
      detailResolver: detailResolver,
    );
  }
}

/// 게시판 목록 결과입니다.
final class KlasBoardList {
  final List<KlasBoardPostSummary> posts;
  final KlasPageInfo? page;
  final Map<String, dynamic> raw;

  const KlasBoardList({required this.posts, required this.raw, this.page});

  factory KlasBoardList.fromJson(
    Map<String, dynamic> json, {
    KlasBoardPostDetailResolver? detailResolver,
  }) {
    final list = json['list'];
    final postItems = <KlasBoardPostSummary>[];
    if (list is List) {
      for (final item in list) {
        final mapped = _asMap(item);
        if (mapped != null) {
          postItems.add(
            KlasBoardPostSummary.fromJson(
              mapped,
              detailResolver: detailResolver,
            ),
          );
        }
      }
    }

    KlasPageInfo? pageInfo;
    final page = _asMap(json['page']);
    if (page != null) {
      pageInfo = KlasPageInfo.fromJson(page);
    }

    return KlasBoardList(posts: postItems, page: pageInfo, raw: json);
  }
}

/// 게시글 상세 결과입니다.
final class KlasBoardPostDetail {
  final KlasRecord? board;
  final KlasRecord? previous;
  final KlasRecord? next;
  final List<KlasRecord> comments;
  final Map<String, dynamic> raw;

  const KlasBoardPostDetail({
    required this.comments,
    required this.raw,
    this.board,
    this.previous,
    this.next,
  });

  factory KlasBoardPostDetail.fromJson(Map<String, dynamic> json) {
    final envelope = _unwrapBoardDetailEnvelope(json);

    final commentItems = <KlasRecord>[];
    final comments =
        envelope['comment'] ??
        envelope['comments'] ??
        envelope['reply'] ??
        envelope['replyList'];
    if (comments is List) {
      for (final item in comments) {
        final mapped = _asMap(item);
        if (mapped != null) {
          commentItems.add(KlasRecord(mapped));
        }
      }
    }

    return KlasBoardPostDetail(
      comments: commentItems,
      board: _pickBoardMap(envelope) == null
          ? null
          : KlasRecord(_pickBoardMap(envelope)!),
      previous: _pickPreviousMap(envelope) == null
          ? null
          : KlasRecord(_pickPreviousMap(envelope)!),
      next: _pickNextMap(envelope) == null
          ? null
          : KlasRecord(_pickNextMap(envelope)!),
      raw: json,
    );
  }
}

/// 파일 메타데이터 항목입니다.
final class KlasAttachedFile {
  final String? attachId;
  final String? fileSn;
  final String? fileName;
  final int? size;
  final Map<String, dynamic> raw;
  final KlasAttachedFileDownloadResolver? _downloadResolver;
  final String? _defaultAttachId;

  const KlasAttachedFile({
    required this.raw,
    this.attachId,
    this.fileSn,
    this.fileName,
    this.size,
    KlasAttachedFileDownloadResolver? downloadResolver,
    String? defaultAttachId,
  }) : _downloadResolver = downloadResolver,
       _defaultAttachId = defaultAttachId;

  /// 파일 객체에서 바로 다운로드를 수행합니다.
  Future<FilePayload> download({String? attachId}) {
    final resolvedAttachId = (this.attachId ?? attachId ?? _defaultAttachId)
        ?.trim();
    if (resolvedAttachId == null || resolvedAttachId.isEmpty) {
      throw StateError('Cannot download file because attachId is missing.');
    }

    final resolvedFileSn = fileSn?.trim();
    if (resolvedFileSn == null || resolvedFileSn.isEmpty) {
      throw StateError('Cannot download file because fileSn is missing.');
    }

    final resolver = _downloadResolver;
    if (resolver == null) {
      throw StateError(
        'This attached file is not bound to a file feature. '
        'Load it via KlasFileFeature.listByAttachId().',
      );
    }

    return resolver(attachId: resolvedAttachId, fileSn: resolvedFileSn);
  }

  factory KlasAttachedFile.fromJson(
    Map<String, dynamic> json, {
    KlasAttachedFileDownloadResolver? downloadResolver,
    String? defaultAttachId,
  }) {
    return KlasAttachedFile(
      raw: json,
      attachId: _toString(
        json['atchFileId'] ?? json['attachId'] ?? json['fileGroupId'],
      ),
      fileSn: _toString(json['fileSn'] ?? json['sn']),
      fileName: _toString(
        // 파일명 키는 구형/신형 배포가 혼재해서 여러 후보를 함께 본다.
        json['fileName'] ??
            json['orignlFileNm'] ??
            json['originFileNm'] ??
            json['fileNm'],
      ),
      size: _toInt(json['fileMg'] ?? json['fileSize']),
      downloadResolver: downloadResolver,
      defaultAttachId: defaultAttachId,
    );
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return null;
}

int? _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

String? _toString(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}

bool? _toBoolYn(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'y' || normalized == 'yes' || normalized == 'true') {
      return true;
    }
    if (normalized == 'n' || normalized == 'no' || normalized == 'false') {
      return false;
    }
  }
  return null;
}

Map<String, dynamic> _unwrapBoardDetailEnvelope(Map<String, dynamic> json) {
  if (_looksLikeBoardDetailEnvelope(json)) {
    return json;
  }

  final candidates = <Object?>[
    json['data'],
    json['result'],
    json['payload'],
    json['response'],
  ];

  for (final candidate in candidates) {
    final mapped = _asMap(candidate);
    if (mapped == null) {
      continue;
    }
    if (_looksLikeBoardDetailEnvelope(mapped)) {
      return mapped;
    }
  }

  return json;
}

bool _looksLikeBoardDetailEnvelope(Map<String, dynamic> json) {
  return json.containsKey('board') ||
      json.containsKey('boardPre') ||
      json.containsKey('boardNex') ||
      json.containsKey('comment') ||
      json.containsKey('comments') ||
      json.containsKey('replyList');
}

Map<String, dynamic>? _pickBoardMap(Map<String, dynamic> envelope) {
  return _firstMapByKeys(envelope, const <String>[
    'board',
    'post',
    'article',
    'detail',
    'detailInfo',
    'boardInfo',
    'data',
  ]);
}

Map<String, dynamic>? _pickPreviousMap(Map<String, dynamic> envelope) {
  return _firstMapByKeys(envelope, const <String>[
    'boardPre',
    'previous',
    'prev',
    'pre',
  ]);
}

Map<String, dynamic>? _pickNextMap(Map<String, dynamic> envelope) {
  return _firstMapByKeys(envelope, const <String>['boardNex', 'next', 'nex']);
}

Map<String, dynamic>? _firstMapByKeys(
  Map<String, dynamic> source,
  List<String> keys,
) {
  final normalizedMap = <String, Map<String, dynamic>>{};
  source.forEach((key, value) {
    final mapped = _asMap(value);
    if (mapped != null) {
      normalizedMap[_normalizeFieldKey(key)] = mapped;
    }
  });

  for (final key in keys) {
    final matched = normalizedMap[_normalizeFieldKey(key)];
    if (matched != null) {
      return matched;
    }
  }
  return null;
}

String _normalizeFieldKey(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
}

Map<String, dynamic> _copyMap(Map<String, dynamic> source) {
  return Map<String, dynamic>.from(source);
}

String? _readNormalizedString(Map<String, dynamic> source, List<String> keys) {
  final normalizedSource = <String, Object?>{};
  source.forEach((key, value) {
    normalizedSource[_normalizeFieldKey(key)] = value;
  });

  for (final key in keys) {
    final normalizedKey = _normalizeFieldKey(key);
    final value = normalizedSource[normalizedKey];
    final text = _toString(value);
    if (text != null) {
      return text;
    }
  }
  return null;
}

String? _extractWeekdayFromText(String? text) {
  if (text == null) {
    return null;
  }

  const weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  for (final day in weekdays) {
    if (text.contains(day)) {
      return day;
    }
  }
  return null;
}

(String?, String?) _extractTimeRange(String? text) {
  if (text == null) {
    return (null, null);
  }

  final pattern = RegExp(r'(\d{1,2}:\d{2})\s*[~-]\s*(\d{1,2}:\d{2})');
  final match = pattern.firstMatch(text);
  if (match == null) {
    return (null, null);
  }
  return (match.group(1), match.group(2));
}

String? _toWeekdayLabel(String? source) {
  if (source == null) {
    return null;
  }

  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final lowered = trimmed.toLowerCase();
  if (lowered.contains('월') || lowered.contains('mon')) {
    return '월';
  }
  if (lowered.contains('화') || lowered.contains('tue')) {
    return '화';
  }
  if (lowered.contains('수') || lowered.contains('wed')) {
    return '수';
  }
  if (lowered.contains('목') || lowered.contains('thu')) {
    return '목';
  }
  if (lowered.contains('금') || lowered.contains('fri')) {
    return '금';
  }
  if (lowered.contains('토') || lowered.contains('sat')) {
    return '토';
  }
  if (lowered.contains('일') || lowered.contains('sun')) {
    return '일';
  }

  final number = int.tryParse(trimmed);
  if (number != null) {
    return switch (number) {
      1 => '월',
      2 => '화',
      3 => '수',
      4 => '목',
      5 => '금',
      6 => '토',
      7 => '일',
      _ => trimmed,
    };
  }

  return trimmed;
}

String? _joinScheduleRange(String? startTime, String? endTime) {
  final start = startTime?.trim();
  final end = endTime?.trim();
  if (start == null || start.isEmpty || end == null || end.isEmpty) {
    return null;
  }
  return '$start-$end';
}

int _compareWeekdayLabels(String a, String b) {
  final orderA = _weekdayOrder(a);
  final orderB = _weekdayOrder(b);
  if (orderA != orderB) {
    return orderA.compareTo(orderB);
  }
  return a.compareTo(b);
}

int _weekdayOrder(String day) {
  return switch (day) {
    '월' => 1,
    '화' => 2,
    '수' => 3,
    '목' => 4,
    '금' => 5,
    '토' => 6,
    '일' => 7,
    _ => 99,
  };
}

int _compareTimetableEntry(KlasTimetableEntry a, KlasTimetableEntry b) {
  final startA = a.startTime ?? '';
  final startB = b.startTime ?? '';
  if (startA != startB) {
    return startA.compareTo(startB);
  }

  final periodA = a.periodText ?? '';
  final periodB = b.periodText ?? '';
  if (periodA != periodB) {
    return periodA.compareTo(periodB);
  }

  return a.title.compareTo(b.title);
}
