import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

import 'app_session.dart';
import 'klas_app_utils.dart';
import 'klas_post_detail_page.dart';
import 'klas_task_detail_page.dart';

/// 단일 강의 상세 화면.
///
/// 공지/자료/과제/학습 정보를 한 화면에서 탭으로 탐색하도록 구성한다.
class KlasCoursePage extends StatefulWidget {
  final KlasAppSession session;
  final KlasCourse course;

  const KlasCoursePage({
    super.key,
    required this.session,
    required this.course,
  });

  @override
  State<KlasCoursePage> createState() => _KlasCoursePageState();
}

class _KlasCoursePageState extends State<KlasCoursePage> {
  bool _isLoading = true;
  String? _errorMessage;

  KlasCourseOverview? _overview;
  String? _scheduleText;
  List<KlasTask> _tasks = const <KlasTask>[];
  KlasBoardList? _noticeBoard;
  KlasBoardList? _materialBoard;
  List<KlasRecord> _onlineContents = const <KlasRecord>[];
  List<KlasRecord> _onlineTests = const <KlasRecord>[];
  List<KlasRecord> _quizzes = const <KlasRecord>[];
  List<KlasRecord> _discussions = const <KlasRecord>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<Object?>(<Future<Object?>>[
        widget.course.overview(),
        widget.course.scheduleText(),
        widget.course.listTasks(page: 0),
        widget.course.noticeBoard.listPosts(page: 0),
        widget.course.materialBoard.listPosts(page: 0),
        widget.course.learning.onlineContents(page: 0),
        widget.course.learning.onlineTests(page: 0),
        widget.course.learning.listAnytimeQuizzes(page: 0),
        widget.course.learning.listDiscussions(page: 0),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _overview = results[0] as KlasCourseOverview;
        _scheduleText = results[1] as String?;
        _tasks = List<KlasTask>.unmodifiable(results[2] as List<KlasTask>);
        _noticeBoard = results[3] as KlasBoardList;
        _materialBoard = results[4] as KlasBoardList;
        _onlineContents = List<KlasRecord>.unmodifiable(
          results[5] as List<KlasRecord>,
        );
        _onlineTests = List<KlasRecord>.unmodifiable(
          results[6] as List<KlasRecord>,
        );
        _quizzes = List<KlasRecord>.unmodifiable(
          results[7] as List<KlasRecord>,
        );
        _discussions = List<KlasRecord>.unmodifiable(
          results[8] as List<KlasRecord>,
        );
      });
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.course.title ?? '(과목명 없음)';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              tooltip: '새로고침',
              onPressed: _isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Tab>[
              Tab(text: '공지사항'),
              Tab(text: '강의자료실'),
              Tab(text: '과제'),
              Tab(text: '학습'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _ErrorView(message: _errorMessage!, onRetry: _load)
            : Column(
                children: <Widget>[
                  _CourseHeader(
                    overview: _overview,
                    scheduleText: _scheduleText,
                    termId: widget.course.termId,
                    professorName: widget.course.professorName,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        _BoardTab(
                          boardTitle: '공지사항',
                          board: _noticeBoard,
                          onPostTap: (post) {
                            final boardNo = post.boardNo;
                            if (boardNo == null) {
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<KlasPostDetailPage>(
                                builder: (_) => KlasPostDetailPage(
                                  boardTitle: '공지사항',
                                  summary: post,
                                  loader: (no) {
                                    final masterNo = post.masterNo;
                                    return widget.course.noticeBoard.getPost(
                                      boardNo: no,
                                      query: masterNo == null
                                          ? null
                                          : <String, dynamic>{
                                              'searchMasterNo': masterNo
                                                  .toString(),
                                            },
                                    );
                                  },
                                  pageLoader: (no) {
                                    final masterNo = post.masterNo;
                                    return widget.course.noticeBoard
                                        .openPostPage(
                                          boardNo: no,
                                          query: masterNo == null
                                              ? null
                                              : <String, dynamic>{
                                                  'searchMasterNo': masterNo
                                                      .toString(),
                                                },
                                        );
                                  },
                                  attachmentsLoader: (attachId) => widget
                                      .session
                                      .user
                                      .files
                                      .listByAttachId(attachId: attachId),
                                ),
                              ),
                            );
                          },
                        ),
                        _BoardTab(
                          boardTitle: '강의자료실',
                          board: _materialBoard,
                          onPostTap: (post) {
                            final boardNo = post.boardNo;
                            if (boardNo == null) {
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<KlasPostDetailPage>(
                                builder: (_) => KlasPostDetailPage(
                                  boardTitle: '강의자료실',
                                  summary: post,
                                  loader: (no) {
                                    final masterNo = post.masterNo;
                                    return widget.course.materialBoard.getPost(
                                      boardNo: no,
                                      query: masterNo == null
                                          ? null
                                          : <String, dynamic>{
                                              'searchMasterNo': masterNo
                                                  .toString(),
                                            },
                                    );
                                  },
                                  pageLoader: (no) {
                                    final masterNo = post.masterNo;
                                    return widget.course.materialBoard
                                        .openPostPage(
                                          boardNo: no,
                                          query: masterNo == null
                                              ? null
                                              : <String, dynamic>{
                                                  'searchMasterNo': masterNo
                                                      .toString(),
                                                },
                                        );
                                  },
                                  attachmentsLoader: (attachId) => widget
                                      .session
                                      .user
                                      .files
                                      .listByAttachId(attachId: attachId),
                                ),
                              ),
                            );
                          },
                        ),
                        _TaskTab(
                          tasks: _tasks,
                          onTaskTap: (task) {
                            Navigator.of(context).push(
                              MaterialPageRoute<KlasTaskDetailPage>(
                                builder: (_) => KlasTaskDetailPage(
                                  session: widget.session,
                                  course: widget.course,
                                  task: task,
                                ),
                              ),
                            );
                          },
                        ),
                        _LearningTab(
                          onlineContents: _onlineContents,
                          onlineTests: _onlineTests,
                          quizzes: _quizzes,
                          discussions: _discussions,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  final KlasCourseOverview? overview;
  final String? scheduleText;
  final String termId;
  final String? professorName;

  const _CourseHeader({
    required this.overview,
    required this.scheduleText,
    required this.termId,
    required this.professorName,
  });

  @override
  Widget build(BuildContext context) {
    final overviewRaw = overview?.record.raw ?? const <String, dynamic>{};
    final topFields = overviewRaw.entries
        .where((entry) {
          final value = entry.value;
          return value is String || value is num || value is bool;
        })
        .take(4)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetricChip(label: '학기', value: termId),
              _MetricChip(
                label: '담당 교수',
                value: (professorName?.trim().isNotEmpty == true)
                    ? professorName!.trim()
                    : '미지정',
              ),
              if (scheduleText != null && scheduleText!.trim().isNotEmpty)
                _MetricChip(
                  label: '시간표',
                  value: _compactSchedule(scheduleText!),
                ),
            ],
          ),
          if (topFields.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topFields
                  .map(
                    (entry) => _MetricChip(
                      label: _prettyKey(entry.key),
                      value: entry.value.toString(),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _BoardTab extends StatelessWidget {
  final String boardTitle;
  final KlasBoardList? board;
  final void Function(KlasBoardPostSummary post) onPostTap;

  const _BoardTab({
    required this.boardTitle,
    required this.board,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final posts = board?.posts ?? const <KlasBoardPostSummary>[];
    if (posts.isEmpty) {
      return Center(child: Text('$boardTitle 데이터가 없습니다.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final post = posts[index];
        final boardNo = post.boardNo;
        return ListTile(
          leading: const Icon(Icons.article_outlined),
          title: Text(post.title ?? '(제목 없음)'),
          subtitle: Text(
            '${post.authorName ?? '-'} · ${post.registeredAt ?? '-'}',
          ),
          trailing: boardNo == null
              ? const Text('읽기불가')
              : const Icon(Icons.chevron_right),
          onTap: boardNo == null ? null : () => onPostTap(post),
        );
      },
    );
  }
}

class _TaskTab extends StatelessWidget {
  final List<KlasTask> tasks;
  final void Function(KlasTask task) onTaskTap;

  const _TaskTab({required this.tasks, required this.onTaskTap});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('과제 데이터가 없습니다.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final task = tasks[index];
        return ListTile(
          leading: Icon(
            task.submitted == true
                ? Icons.assignment_turned_in
                : Icons.assignment_late,
          ),
          title: Text(task.title ?? '(제목 없음)'),
          subtitle: Text(
            '시작 ${task.startDate ?? '-'} · 마감 ${task.expireDate ?? '-'}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(task.submitted == true ? '제출완료' : '미제출'),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => onTaskTap(task),
        );
      },
    );
  }
}

class _LearningTab extends StatelessWidget {
  final List<KlasRecord> onlineContents;
  final List<KlasRecord> onlineTests;
  final List<KlasRecord> quizzes;
  final List<KlasRecord> discussions;

  const _LearningTab({
    required this.onlineContents,
    required this.onlineTests,
    required this.quizzes,
    required this.discussions,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        _LearningSection(
          title: '온라인 콘텐츠',
          icon: Icons.play_circle_outline,
          rows: onlineContents,
        ),
        const SizedBox(height: 10),
        _LearningSection(
          title: '온라인 시험',
          icon: Icons.fact_check_outlined,
          rows: onlineTests,
        ),
        const SizedBox(height: 10),
        _LearningSection(
          title: '수시퀴즈',
          icon: Icons.quiz_outlined,
          rows: quizzes,
        ),
        const SizedBox(height: 10),
        _LearningSection(
          title: '토론',
          icon: Icons.forum_outlined,
          rows: discussions,
        ),
      ],
    );
  }
}

class _LearningSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<KlasRecord> rows;

  const _LearningSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 8),
                Text('(${rows.length})'),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text('데이터가 없습니다.')
            else
              ...rows.take(6).map((row) {
                // KLAS 응답은 화면/기능마다 제목 키가 달라서 후보 키를 순차 탐색한다.
                final titleText =
                    _pickRecordText(row, const <String>[
                      'title',
                      'sdesc',
                      'sbjt',
                      'moduletitle',
                      'lessontitle',
                      'quizTitle',
                      'testTitle',
                      'papernm',
                      'taskTitle',
                      'cntntsNm',
                      'cntntNm',
                      'dscsnTitle',
                      'discussionTitle',
                      'examTitle',
                      'examtypenm',
                      'name',
                    ]) ??
                    '(제목 없음)';
                // 상태값도 submit/progress/examtype 등 다양한 키로 내려올 수 있다.
                final statusText = _pickRecordText(row, const <String>[
                  'status',
                  'state',
                  'submit',
                  'submitYn',
                  'submityn',
                  'issubmit',
                  'progress',
                  'prog',
                  'examtype',
                  'examtypenm',
                  'completeYn',
                  'attendYn',
                ]);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: statusText == null ? null : Text(statusText),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

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

String _compactSchedule(String value) {
  final compact = value
      .replaceAll('\n', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (compact.length <= 32) {
    return compact;
  }
  return '${compact.substring(0, 32)}...';
}

String _prettyKey(String key) {
  return key.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
}

String? _pickRecordText(KlasRecord record, List<String> keys) {
  for (final key in keys) {
    final value = _pickByNormalizedKey(record.raw, key);
    if (value != null) {
      return value;
    }
  }
  return null;
}

String? _pickByNormalizedKey(Map<String, dynamic> source, String targetKey) {
  final normalizedTarget = _normalizeKey(targetKey);
  for (final entry in source.entries) {
    if (_normalizeKey(entry.key) != normalizedTarget) {
      continue;
    }
    final value = entry.value?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String _normalizeKey(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
}
