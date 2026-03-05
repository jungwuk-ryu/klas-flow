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

/// 게시글 목록 요약 항목입니다.
final class KlasBoardPostSummary {
  final int? boardNo;
  final int? masterNo;
  final String? title;
  final String? authorName;
  final String? registeredAt;
  final int? fileCount;
  final Map<String, dynamic> raw;

  const KlasBoardPostSummary({
    required this.raw,
    this.boardNo,
    this.masterNo,
    this.title,
    this.authorName,
    this.registeredAt,
    this.fileCount,
  });

  factory KlasBoardPostSummary.fromJson(Map<String, dynamic> json) {
    return KlasBoardPostSummary(
      raw: json,
      boardNo: _toInt(json['boardNo']),
      masterNo: _toInt(json['masterNo']),
      title: _toString(json['title']),
      authorName: _toString(json['userNm']),
      registeredAt: _toString(json['registDt']),
      fileCount: _toInt(json['fileCnt']),
    );
  }
}

/// 게시판 목록 결과입니다.
final class KlasBoardList {
  final List<KlasBoardPostSummary> posts;
  final KlasPageInfo? page;
  final Map<String, dynamic> raw;

  const KlasBoardList({required this.posts, required this.raw, this.page});

  factory KlasBoardList.fromJson(Map<String, dynamic> json) {
    final list = json['list'];
    final postItems = <KlasBoardPostSummary>[];
    if (list is List) {
      for (final item in list) {
        final mapped = _asMap(item);
        if (mapped != null) {
          postItems.add(KlasBoardPostSummary.fromJson(mapped));
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

  const KlasAttachedFile({
    required this.raw,
    this.attachId,
    this.fileSn,
    this.fileName,
    this.size,
  });

  factory KlasAttachedFile.fromJson(Map<String, dynamic> json) {
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
