import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

import 'app_session.dart';
import 'klas_app_utils.dart';

/// 과제 상세(본문/내 제출/첨부파일) 화면.
class KlasTaskDetailPage extends StatefulWidget {
  final KlasAppSession session;
  final KlasCourse course;
  final KlasTask task;

  const KlasTaskDetailPage({
    super.key,
    required this.session,
    required this.course,
    required this.task,
  });

  @override
  State<KlasTaskDetailPage> createState() => _KlasTaskDetailPageState();
}

class _KlasTaskDetailPageState extends State<KlasTaskDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  KlasTaskDetail? _detail;
  List<KlasAttachedFile> _reportFiles = const <KlasAttachedFile>[];
  List<KlasAttachedFile> _submissionFiles = const <KlasAttachedFile>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ordseq = _pickInt(widget.task.raw, const <String>['ordseq']);
    if (ordseq == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '과제 상세 조회에 필요한 ordseq 값이 없습니다.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget.course.learning.getTaskDetail(ordseq: ordseq);

      final reportFiles = await _loadFiles(detail.reportAttachId);
      final submissionFiles = await _loadFiles(detail.submissionAttachId);

      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _reportFiles = List<KlasAttachedFile>.unmodifiable(reportFiles);
        _submissionFiles = List<KlasAttachedFile>.unmodifiable(submissionFiles);
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

  Future<List<KlasAttachedFile>> _loadFiles(String? attachId) async {
    final resolved = attachId?.trim();
    if (resolved == null || resolved.isEmpty) {
      return const <KlasAttachedFile>[];
    }
    try {
      return await widget.session.user.files.listByAttachId(attachId: resolved);
    } catch (_) {
      return const <KlasAttachedFile>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _detail?.reportTitle ?? widget.task.title ?? '(제목 없음)';

    return Scaffold(
      appBar: AppBar(title: const Text('과제 상세')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _ErrorView(message: _errorMessage!, onRetry: _load)
          : _TaskDetailView(
              title: title,
              task: widget.task,
              detail: _detail,
              reportFiles: _reportFiles,
              submissionFiles: _submissionFiles,
            ),
    );
  }
}

class _TaskDetailView extends StatelessWidget {
  final String title;
  final KlasTask task;
  final KlasTaskDetail? detail;
  final List<KlasAttachedFile> reportFiles;
  final List<KlasAttachedFile> submissionFiles;

  const _TaskDetailView({
    required this.title,
    required this.task,
    required this.detail,
    required this.reportFiles,
    required this.submissionFiles,
  });

  @override
  Widget build(BuildContext context) {
    final reportRaw = detail?.report?.raw ?? const <String, dynamic>{};
    final submissionRaw = detail?.submission?.raw ?? const <String, dynamic>{};
    final reportBody = _stripHtml(detail?.reportHtml ?? '');
    final submissionBody = _stripHtml(detail?.submissionText ?? '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '과제번호: ${_pickText(task.raw, const <String>['taskNo']) ?? '-'}',
                ),
                Text('제출여부: ${task.submitted == true ? '제출완료' : '미제출'}'),
                Text(
                  '제출기한: ${detail?.reportStartDate ?? task.startDate ?? '-'} ~ ${detail?.reportExpireDate ?? task.expireDate ?? '-'}',
                ),
                Text(
                  '제출양식: ${_pickText(reportRaw, const <String>['submitfiletype']) ?? '-'}',
                ),
                Text(
                  '용량제한: ${_pickText(reportRaw, const <String>['filelimit']) ?? '-'} MB',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('출제 내용', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(
                  reportBody.isEmpty ? '본문 정보가 없습니다.' : reportBody,
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('내 제출', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '제목: ${detail?.submissionTitle ?? _pickText(submissionRaw, const <String>['title']) ?? '-'}',
                ),
                const SizedBox(height: 6),
                SelectableText(
                  submissionBody.isEmpty ? '제출 내용이 없습니다.' : submissionBody,
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        if (reportFiles.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _AttachmentSection(title: '출제 첨부파일', files: reportFiles),
        ],
        if (submissionFiles.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _AttachmentSection(title: '제출 첨부파일', files: submissionFiles),
        ],
      ],
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  final String title;
  final List<KlasAttachedFile> files;

  const _AttachmentSection({required this.title, required this.files});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...files.map((file) {
              final fileSize = file.size == null ? '-' : '${file.size} bytes';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file),
                title: Text(file.fileName ?? '(파일명 없음)'),
                subtitle: Text('파일번호: ${file.fileSn ?? '-'}'),
                trailing: Text(fileSize),
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

int? _pickInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    for (final entry in source.entries) {
      if (_normalizeKey(entry.key) != _normalizeKey(key)) {
        continue;
      }
      final value = entry.value;
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
  }
  return null;
}

String? _pickText(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    for (final entry in source.entries) {
      if (_normalizeKey(entry.key) != _normalizeKey(key)) {
        continue;
      }
      final value = entry.value?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

String _normalizeKey(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
}

String _stripHtml(String input) {
  if (input.trim().isEmpty) {
    return '';
  }

  final withLineBreaks = input
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
  final plain = withLineBreaks.replaceAll(RegExp(r'<[^>]*>'), '');
  return plain
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .trim();
}
