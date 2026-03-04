import 'package:flutter/material.dart';

import '../klasflow_demo_controller.dart';

/// 액션별 payload를 실제 화면형 UI로 보여준다.
///
/// raw JSON을 직접 읽지 않아도 결과를 이해할 수 있도록
/// 액션 ID마다 요약 레이아웃을 분기한다.
class ActionResultVisualContent extends StatelessWidget {
  final DemoActionResult result;

  const ActionResultVisualContent({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final payload = result.payload;
    if (payload == null) {
      return const Text('표시할 결과 데이터가 없습니다.');
    }

    final id = result.id;
    final map = _asMap(payload);

    switch (id) {
      case 'auth.login':
        return _buildLoginSummary(map);
      case 'user.profile':
        return _buildUserProfile(map);
      case 'user.personalInfo':
        return _buildPersonalInfo(map);
      case 'user.sessionStatus':
        return _buildSessionPanel(map, title: '세션 상태');
      case 'user.keepAlive':
        return _buildKeepAlive(map);
      case 'user.frame.homeOverview':
        return _buildRecordSummary(
          map,
          title: '홈 개요',
          icon: Icons.home_outlined,
        );
      case 'user.frame.scheduleSummary':
        return _buildRecordSummary(
          map,
          title: '일정 요약',
          icon: Icons.calendar_month_outlined,
        );
      case 'course.overview':
        return _buildRecordSummary(
          map,
          title: '강의 개요',
          icon: Icons.menu_book_outlined,
        );
      case 'course.change':
        return _buildCourseChange(map);
      case 'course.scheduleText':
        return _buildScheduleText(map);
      case 'course.tasks':
        return _buildTaskList(map);
      case 'course.noticeBoard.listPosts':
        return _buildBoardList(map, title: '공지사항');
      case 'course.materialBoard.listPosts':
        return _buildBoardList(map, title: '강의자료실');
      case 'course.learning.anytimeQuizzes':
        return _buildLearningList(map, title: '수시퀴즈');
      case 'course.learning.discussions':
        return _buildLearningList(map, title: '토론');
      case 'course.learning.onlineContents':
        return _buildLearningList(map, title: '온라인 콘텐츠');
      case 'course.learning.onlineTests':
        return _buildLearningList(map, title: '온라인 시험');
      case 'course.surveys.list':
        return _buildLearningList(map, title: '설문');
      case 'course.eclass.listItems':
        return _buildLearningList(map, title: 'e-Class');
      case 'user.attendance.listSubjects':
        return _buildAttendanceList(map, title: '출석 과목');
      case 'user.attendance.monthList':
        return _buildAttendanceList(map, title: '월간 일정');
      case 'user.attendance.monthTable':
        return _buildAttendanceList(map, title: '월간 일정 테이블');
      case 'client.healthCheck':
        return _buildHealthCheck(map);
      default:
        return _buildFallback(payload);
    }
  }

  Widget _buildLoginSummary(Map<String, Object?> payload) {
    final profile = _asMap(payload['profile']);
    final personal = _asMap(payload['personalInfo']);
    final session = _asMap(payload['sessionStatus']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(icon: Icons.login, text: '로그인 상태'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _ChipBadge(
              label: '로그인',
              value: profile['authenticated'] == true ? '성공' : '미확인',
            ),
            _ChipBadge(label: '강의', value: _toText(payload['courses'])),
            _ChipBadge(label: '과제', value: _toText(payload['tasks'])),
          ],
        ),
        const SizedBox(height: 10),
        _InfoPanel(
          rows: <_InfoRow>[
            _InfoRow('사용자 ID', _dash(profile['userId'])),
            _InfoRow('이름', _dash(profile['userName'])),
            _InfoRow(
              '학번(상세)',
              _dash(_pickString(personal, const ['hakbun', 'userId'])),
            ),
            _InfoRow('이메일', _dash(_buildEmail(personal))),
            _InfoRow('남은 시간(초)', _dash(session['remainingTime'])),
          ],
        ),
      ],
    );
  }

  Widget _buildUserProfile(Map<String, Object?> payload) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(icon: Icons.badge_outlined, text: '사용자 프로필'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _ChipBadge(
              label: '인증',
              value: payload['authenticated'] == true ? '로그인됨' : '미인증',
            ),
            _ChipBadge(label: 'ID', value: _dash(payload['userId'])),
            _ChipBadge(label: '이름', value: _dash(payload['userName'])),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(Map<String, Object?> payload) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(icon: Icons.person_outline, text: '개인정보'),
        const SizedBox(height: 8),
        _InfoPanel(
          rows: <_InfoRow>[
            _InfoRow(
              '학번',
              _dash(
                _pickString(payload, const ['hakbun', 'userId', 'studentNo']),
              ),
            ),
            _InfoRow(
              '이름',
              _dash(_pickString(payload, const ['kname', 'userName', 'name'])),
            ),
            _InfoRow('영문 이름', _dash(_pickString(payload, const ['ename']))),
            _InfoRow('이메일', _dash(_buildEmail(payload))),
            _InfoRow(
              '휴대폰',
              _dash(_pickString(payload, const ['handPhoneno', 'mobilePhone'])),
            ),
            _InfoRow(
              '집전화',
              _dash(_pickString(payload, const ['homePhoneno', 'homePhone'])),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionPanel(
    Map<String, Object?> payload, {
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(icon: Icons.timer_outlined, text: title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _ChipBadge(
              label: '인증',
              value: payload['authenticated'] == true ? '로그인됨' : '미인증',
            ),
            _ChipBadge(
              label: '남은 시간',
              value: '${_dash(payload['remainingTime'])}초',
            ),
            _ChipBadge(
              label: '자동 로그아웃',
              value: '${_dash(payload['logoutCountDownSec'])}초',
            ),
            _ChipBadge(
              label: '알림 시점',
              value: '${_dash(payload['sessionNotiSec'])}초',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeepAlive(Map<String, Object?> payload) {
    final session = _asMap(payload['session']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(icon: Icons.autorenew, text: '세션 연장'),
        const SizedBox(height: 8),
        Text(
          _dash(payload['message']),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (session.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _buildSessionPanel(session, title: '갱신 후 세션'),
        ],
      ],
    );
  }

  Widget _buildRecordSummary(
    Map<String, Object?> payload, {
    required String title,
    required IconData icon,
  }) {
    final primitiveEntries = payload.entries
        .where((entry) => _isPrimitive(entry.value))
        .take(10)
        .toList(growable: false);
    final listCount = payload.entries
        .where((entry) => entry.value is List)
        .length;
    final objectCount = payload.entries
        .where((entry) => entry.value is Map)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(icon: icon, text: title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _ChipBadge(label: '필드', value: '${payload.length}개'),
            _ChipBadge(label: '기본값', value: '${primitiveEntries.length}개'),
            _ChipBadge(label: '목록', value: '$listCount개'),
            _ChipBadge(label: '객체', value: '$objectCount개'),
          ],
        ),
        const SizedBox(height: 10),
        if (primitiveEntries.isEmpty)
          const Text('표시할 기본 필드가 없습니다.')
        else
          _InfoPanel(
            rows: primitiveEntries
                .map(
                  (entry) =>
                      _InfoRow(_prettyKey(entry.key), _toText(entry.value)),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildCourseChange(Map<String, Object?> payload) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(icon: Icons.swap_horiz, text: '현재 과목 변경'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _ChipBadge(label: '과목 ID', value: _dash(payload['courseId'])),
            _ChipBadge(label: '학기', value: _dash(payload['termId'])),
            _ChipBadge(label: '과제 수', value: _dash(payload['taskCount'])),
          ],
        ),
        const SizedBox(height: 10),
        _InfoPanel(rows: <_InfoRow>[_InfoRow('과목명', _dash(payload['title']))]),
      ],
    );
  }

  Widget _buildScheduleText(Map<String, Object?> payload) {
    final raw = payload['scheduleText']?.toString().trim();
    if (raw == null || raw.isEmpty || raw == '(null)') {
      return const Text('등록된 강의 시간표 문자열이 없습니다.');
    }

    final lines = raw
        .split(RegExp(r'[\n;]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(icon: Icons.schedule_outlined, text: '강의 시간표'),
        const SizedBox(height: 8),
        if (lines.length <= 1)
          _InfoPanel(rows: <_InfoRow>[_InfoRow('시간표', raw)])
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lines
                .map((line) => _ChipBadge(label: '수업', value: line))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTaskList(Map<String, Object?> payload) {
    final items = _toMapList(payload['items']);
    final count = _pickInt(payload, const ['count']) ?? items.length;
    return _buildCountList(
      icon: Icons.assignment_outlined,
      title: '과제 목록',
      count: count,
      items: items,
      tileBuilder: (item) {
        final taskTitle =
            _pickString(item, const ['title', 'taskTitle', 'name']) ??
            '(제목 없음)';
        final taskNo = _pickInt(item, const ['taskNo']);
        final start = _pickString(item, const ['startdate', 'startDate']);
        final end = _pickString(item, const [
          'expiredate',
          'expireDate',
          'dueDate',
        ]);
        final submitted = _pickBool(item, const [
          'submitted',
          'submityn',
          'submitYn',
        ]);
        final subtitle = _join(<String?>[
          if (taskNo != null) '과제번호 $taskNo',
          if (start != null) '시작 ${_friendlyDate(start)}',
          if (end != null) '마감 ${_friendlyDate(end)}',
        ]);
        return _ResultTile(
          icon: submitted == true
              ? Icons.assignment_turned_in
              : Icons.assignment_late,
          title: taskTitle,
          subtitle: subtitle,
          trailing: _StatusBadge(
            text: submitted == true ? '제출완료' : '미제출',
            tone: submitted == true ? _StatusTone.good : _StatusTone.warn,
          ),
        );
      },
    );
  }

  Widget _buildBoardList(
    Map<String, Object?> payload, {
    required String title,
  }) {
    final items = _toMapList(payload['sample']);
    final count = _pickInt(payload, const ['count']) ?? items.length;
    return _buildCountList(
      icon: Icons.campaign_outlined,
      title: '$title 게시글',
      count: count,
      items: items,
      tileBuilder: (item) {
        final postTitle =
            _pickString(item, const ['title', 'bbsTitl']) ?? '(제목 없음)';
        final writer = _pickString(item, const [
          'userNm',
          'writer',
          'authorName',
        ]);
        final date = _pickString(item, const ['registDt', 'registerDate']);
        final boardNo = _pickInt(item, const ['boardNo', 'no']);
        final fileCnt = _pickInt(item, const ['fileCnt', 'attachCount']);
        return _ResultTile(
          icon: Icons.article_outlined,
          title: postTitle,
          subtitle: _join(<String?>[
            if (boardNo != null) '글번호 $boardNo',
            writer,
            if (date != null) _friendlyDate(date),
          ]),
          trailing: fileCnt == null
              ? null
              : _StatusBadge(
                  text: '첨부 $fileCnt',
                  tone: fileCnt > 0 ? _StatusTone.info : _StatusTone.neutral,
                ),
        );
      },
    );
  }

  Widget _buildLearningList(
    Map<String, Object?> payload, {
    required String title,
  }) {
    final items = _toMapList(payload['sample']);
    final count = _pickInt(payload, const ['count']) ?? items.length;
    return _buildCountList(
      icon: Icons.school_outlined,
      title: '$title 목록',
      count: count,
      items: items,
      tileBuilder: (item) {
        final itemTitle =
            _pickString(item, const [
              'title',
              'quizTitle',
              'testTitle',
              'taskTitle',
              'cntntsNm',
              'discussionTitle',
              'surveyTitle',
              'name',
            ]) ??
            '(제목 없음)';
        final start = _pickString(item, const [
          'startDate',
          'startdate',
          'openDate',
        ]);
        final end = _pickString(item, const [
          'expireDate',
          'expiredate',
          'endDate',
          'dueDate',
        ]);
        final status = _pickString(item, const [
          'status',
          'state',
          'submitYn',
          'submityn',
          'completeYn',
          'attendYn',
        ]);
        return _ResultTile(
          icon: _learningIcon(title),
          title: itemTitle,
          subtitle: _join(<String?>[
            if (start != null || end != null)
              '${start == null ? '-' : _friendlyDate(start)} ~ ${end == null ? '-' : _friendlyDate(end)}',
          ]),
          trailing: status == null
              ? null
              : _StatusBadge(text: status, tone: _toneFromStatus(status)),
        );
      },
    );
  }

  Widget _buildAttendanceList(
    Map<String, Object?> payload, {
    required String title,
  }) {
    final items = _toMapList(payload['sample']);
    final count = _pickInt(payload, const ['count']) ?? items.length;
    return _buildCountList(
      icon: Icons.how_to_reg_outlined,
      title: title,
      count: count,
      items: items,
      tileBuilder: (item) {
        final subject =
            _pickString(item, const [
              'subjectName',
              'subjNm',
              'gwamokNm',
              'courseName',
              'title',
            ]) ??
            '(과목명 없음)';
        final day = _pickString(item, const [
          'date',
          'schdulDate',
          'attendDate',
          'startDate',
          'day',
        ]);
        final status = _pickString(item, const [
          'status',
          'state',
          'attendStatus',
          'attendYn',
          'presentYn',
        ]);
        return _ResultTile(
          icon: Icons.event_note_outlined,
          title: subject,
          subtitle: day == null ? null : _friendlyDate(day),
          trailing: status == null
              ? null
              : _StatusBadge(text: status, tone: _toneFromStatus(status)),
        );
      },
    );
  }

  Widget _buildHealthCheck(Map<String, Object?> payload) {
    final items = _toMapList(payload['items']);
    final allPassed = payload['allPassed'] == true;
    final failedCount = _pickInt(payload, const ['failedCount']) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(icon: Icons.monitor_heart_outlined, text: '헬스체크'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _ChipBadge(label: '전체 상태', value: allPassed ? '정상' : '오류 있음'),
            _ChipBadge(label: '실패', value: '$failedCount건'),
            _ChipBadge(label: '항목', value: '${items.length}개'),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Text('점검 결과가 없습니다.')
        else
          ...items.take(8).map((item) {
            final itemId = _pickString(item, const ['id']) ?? '(id 없음)';
            final success = _pickBool(item, const ['success']) == true;
            final detail = _pickString(item, const ['detail']) ?? '-';
            final elapsed = _pickInt(item, const ['elapsedMs']);
            return _ResultTile(
              icon: success ? Icons.check_circle : Icons.error_outline,
              title: itemId,
              subtitle: detail,
              trailing: _StatusBadge(
                text: '${elapsed ?? '-'}ms',
                tone: success ? _StatusTone.good : _StatusTone.warn,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFallback(Object payload) {
    final map = _asMap(payload);
    if (map.isEmpty) {
      final list = _toMapList(payload);
      if (list.isEmpty) {
        return Text(_toText(payload));
      }
      return _buildCountList(
        icon: Icons.dataset_outlined,
        title: '결과 목록',
        count: list.length,
        items: list,
        tileBuilder: (item) => _ResultTile(
          icon: Icons.list_alt_outlined,
          title:
              _pickString(item, const ['title', 'name', 'subjectName']) ??
              '(항목)',
          subtitle: _pickString(item, const ['status', 'state', 'date']),
          trailing: _StatusBadge(text: '${item.length} fields'),
        ),
      );
    }

    final rows = map.entries
        .where((entry) => _isPrimitive(entry.value))
        .take(12)
        .map((entry) => _InfoRow(_prettyKey(entry.key), _toText(entry.value)))
        .toList(growable: false);
    if (rows.isEmpty) {
      return const Text('표시할 기본 필드가 없습니다.');
    }
    return _InfoPanel(rows: rows);
  }

  Widget _buildCountList({
    required IconData icon,
    required String title,
    required int count,
    required List<Map<String, Object?>> items,
    required Widget Function(Map<String, Object?> item) tileBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(icon: icon, text: title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _ChipBadge(label: '조회 건수', value: '$count'),
            _ChipBadge(label: '표시 건수', value: '${items.length}'),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Text('표시할 데이터가 없습니다.')
        else
          ...items.take(8).map(tileBuilder),
      ],
    );
  }

  String? _buildEmail(Map<String, Object?> payload) {
    final id = _pickString(payload, const ['emailId']);
    final host = _pickString(payload, const ['emailHost']);
    if (id == null || host == null) {
      return _pickString(payload, const ['email']);
    }
    return '$id@$host';
  }

  IconData _learningIcon(String label) {
    if (label.contains('퀴즈')) {
      return Icons.quiz_outlined;
    }
    if (label.contains('시험')) {
      return Icons.fact_check_outlined;
    }
    if (label.contains('토론')) {
      return Icons.forum_outlined;
    }
    if (label.contains('설문')) {
      return Icons.poll_outlined;
    }
    return Icons.play_circle_outline;
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final String label;
  final String value;

  const _ChipBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text('$label: $value'),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _ResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing,
      ),
    );
  }
}

enum _StatusTone { good, warn, info, neutral }

class _StatusBadge extends StatelessWidget {
  final String text;
  final _StatusTone tone;

  const _StatusBadge({required this.text, this.tone = _StatusTone.neutral});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      _StatusTone.good => (Colors.green.shade100, Colors.green.shade900),
      _StatusTone.warn => (Colors.orange.shade100, Colors.orange.shade900),
      _StatusTone.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _StatusTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(text, style: TextStyle(color: fg, fontSize: 12)),
      ),
    );
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is! Map) {
    return const <String, Object?>{};
  }
  final mapped = <String, Object?>{};
  value.forEach((key, item) {
    mapped[key.toString()] = item;
  });
  return mapped;
}

List<Map<String, Object?>> _toMapList(Object? value) {
  if (value is! List) {
    return const <Map<String, Object?>>[];
  }
  return value
      .map(_asMap)
      .where((row) => row.isNotEmpty)
      .toList(growable: false);
}

String? _pickString(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final wanted = _norm(key);
    for (final entry in map.entries) {
      if (_norm(entry.key) != wanted) {
        continue;
      }
      final text = entry.value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
  }
  return null;
}

int? _pickInt(Map<String, Object?> map, List<String> keys) {
  final text = _pickString(map, keys);
  if (text == null) {
    return null;
  }
  return int.tryParse(text);
}

bool? _pickBool(Map<String, Object?> map, List<String> keys) {
  final text = _pickString(map, keys);
  if (text == null) {
    return null;
  }
  final normalized = text.toLowerCase();
  if (normalized == 'y' ||
      normalized == 'yes' ||
      normalized == 'true' ||
      normalized == '1') {
    return true;
  }
  if (normalized == 'n' ||
      normalized == 'no' ||
      normalized == 'false' ||
      normalized == '0') {
    return false;
  }
  return null;
}

String _norm(String key) {
  return key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
}

bool _isPrimitive(Object? value) {
  return value == null || value is String || value is num || value is bool;
}

String _toText(Object? value) {
  if (value == null) {
    return '-';
  }
  return value.toString();
}

String _dash(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return '-';
  }
  return text;
}

String _prettyKey(String key) {
  return key.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
}

String? _join(List<String?> values) {
  final filtered = values
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  if (filtered.isEmpty) {
    return null;
  }
  return filtered.join(' · ');
}

String _friendlyDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.year}-$month-$day $hour:$minute';
}

_StatusTone _toneFromStatus(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('완료') ||
      normalized.contains('success') ||
      normalized == 'y' ||
      normalized == 'true') {
    return _StatusTone.good;
  }
  if (normalized.contains('미') ||
      normalized.contains('fail') ||
      normalized == 'n' ||
      normalized == 'false') {
    return _StatusTone.warn;
  }
  if (normalized.contains('진행') || normalized.contains('open')) {
    return _StatusTone.info;
  }
  return _StatusTone.neutral;
}
