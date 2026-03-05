import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

import 'app_session.dart';
import 'klas_app_utils.dart';
import 'klas_course_page.dart';
import 'klas_login_page.dart';
import 'klas_timetable_page.dart';

/// 로그인 후 진입하는 홈 화면.
///
/// 핵심 역할:
/// 1) 사용자 요약 정보 표시
/// 2) 수강 과목 목록 표시
/// 3) 과목 선택 시 상세 화면으로 이동
class KlasHomePage extends StatefulWidget {
  final KlasAppSession session;

  const KlasHomePage({super.key, required this.session});

  @override
  State<KlasHomePage> createState() => _KlasHomePageState();
}

class _KlasHomePageState extends State<KlasHomePage> {
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isTimetableLoading = false;
  String? _timetableErrorMessage;
  KlasTimetable? _timetable;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) {
      return;
    }
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      await widget.session.refreshHomeData();
      await _loadTimetable(refresh: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadTimetable({bool refresh = false}) async {
    if (_isTimetableLoading) {
      return;
    }

    setState(() {
      _isTimetableLoading = true;
      _timetableErrorMessage = null;
    });

    try {
      final timetable = await widget.session.loadTimetable(refresh: refresh);
      if (!mounted) {
        return;
      }
      setState(() {
        _timetable = timetable;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _timetableErrorMessage = friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTimetableLoading = false;
        });
      }
    }
  }

  void _openTimetablePage() {
    final timetable = _timetable;
    if (timetable == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<KlasTimetablePage>(
        builder: (_) => KlasTimetablePage(timetable: timetable),
      ),
    );
  }

  void _logout() {
    widget.session.close();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<KlasLoginPage>(builder: (_) => const KlasLoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.session.profile;
    final personalInfo = widget.session.personalInfo;
    final courses = widget.session.courses;

    final userName = profile.userName ?? personalInfo.userName ?? '(이름 없음)';
    final userId = profile.userId ?? personalInfo.userId ?? '(학번 없음)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('KLAS'),
        actions: <Widget>[
          IconButton(
            tooltip: '새로고침',
            onPressed: _isRefreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '로그아웃',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildProfileHeader(context, userName: userName, userId: userId),
            const SizedBox(height: 12),
            _buildQuickInfoCard(
              context,
              personalInfo: personalInfo,
              courseCount: courses.length,
              timetableCount: _timetable?.entries.length,
            ),
            const SizedBox(height: 12),
            _buildTimetableCard(context),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _buildCourseListCard(context, courses),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context, {
    required String userName,
    required String userId,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              child: Text(userName.isNotEmpty ? userName[0] : '?'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(userId, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _isRefreshing ? null : _refresh,
              icon: const Icon(Icons.sync),
              label: const Text('동기화'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard(
    BuildContext context, {
    required KlasPersonalInfo personalInfo,
    required int courseCount,
    required int? timetableCount,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _InfoChip(label: '수강 과목', value: '$courseCount개'),
            _InfoChip(
              label: '시간표',
              value: timetableCount == null ? '로딩 중' : '$timetableCount건',
            ),
            _InfoChip(label: '이메일', value: personalInfo.email ?? '-'),
            _InfoChip(label: '휴대폰', value: personalInfo.mobilePhone ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableCard(BuildContext context) {
    final timetable = _timetable;
    final entries = timetable?.entries ?? const <KlasTimetableEntry>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('학기 시간표', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: '시간표 새로고침',
                  onPressed: _isTimetableLoading
                      ? null
                      : () => _loadTimetable(refresh: true),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_isTimetableLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (_timetableErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  _timetableErrorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!_isTimetableLoading &&
                _timetableErrorMessage == null) ...<Widget>[
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('조회된 시간표가 없습니다.'),
                )
              else
                ...entries.take(5).map((entry) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _join(<String?>[entry.professorName, entry.classroom]) ??
                          '-',
                    ),
                    trailing: Text(
                      entry.scheduleText ?? '-',
                      textAlign: TextAlign.end,
                    ),
                  );
                }),
              if (entries.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '외 ${entries.length - 5}건',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: entries.isEmpty ? null : _openTimetablePage,
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('전체 시간표 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourseListCard(BuildContext context, List<KlasCourse> courses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('수강 과목', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (courses.isEmpty)
              const Text('조회된 과목이 없습니다.')
            else
              ...courses.map((course) {
                final title = course.title ?? '(과목명 없음)';
                final subtitle =
                    _join(<String?>[course.professorName, course.termId]) ??
                    course.termId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(subtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<KlasCoursePage>(
                            builder: (_) => KlasCoursePage(
                              session: widget.session,
                              course: course,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

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
