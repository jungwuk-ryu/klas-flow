import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

import 'klas_app_utils.dart';

/// 게시글 상세 조회 화면.
///
/// 목록에서 선택한 게시글 번호를 받아 `getPost`를 호출하고,
/// 본문/댓글 등 상세 정보를 읽기 쉽게 렌더링한다.
class KlasPostDetailPage extends StatefulWidget {
  final String boardTitle;
  final KlasBoardPostSummary summary;
  final Future<KlasBoardPostDetail> Function(int boardNo) loader;

  const KlasPostDetailPage({
    super.key,
    required this.boardTitle,
    required this.summary,
    required this.loader,
  });

  @override
  State<KlasPostDetailPage> createState() => _KlasPostDetailPageState();
}

class _KlasPostDetailPageState extends State<KlasPostDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  KlasBoardPostDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final boardNo = widget.summary.boardNo;
    if (boardNo == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '게시글 번호가 없어 상세를 조회할 수 없습니다.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget.loader(boardNo);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
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
    final title = widget.summary.title ?? '(제목 없음)';

    return Scaffold(
      appBar: AppBar(title: Text(widget.boardTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _ErrorView(message: _errorMessage!, onRetry: _load)
          : _DetailView(summary: widget.summary, detail: _detail, title: title),
    );
  }
}

class _DetailView extends StatelessWidget {
  final KlasBoardPostSummary summary;
  final KlasBoardPostDetail? detail;
  final String title;

  const _DetailView({
    required this.summary,
    required this.detail,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final rawBoard = detail?.board?.raw ?? const <String, dynamic>{};
    final bodyText = _pickBodyText(rawBoard);

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
                Text('작성자: ${summary.authorName ?? '-'}'),
                Text('등록일: ${summary.registeredAt ?? '-'}'),
                if (summary.fileCount != null)
                  Text('첨부파일: ${summary.fileCount}개'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              bodyText,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ),
        if ((detail?.comments.length ?? 0) > 0) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('댓글', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...detail!.comments.map((comment) {
                    final text = _pickBodyText(comment.raw);
                    final writer = _pickFirst(comment.raw, const <String>[
                      'userNm',
                      'writer',
                      'authorName',
                    ]);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (writer != null)
                              Text(
                                writer,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(text),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
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

String _pickBodyText(Map<String, dynamic> source) {
  final raw = _pickFirst(source, const <String>[
    'content',
    'cn',
    'bbsCn',
    'boardCn',
    'boardContents',
    'memo',
    'body',
    'text',
    'html',
  ]);

  if (raw == null || raw.trim().isEmpty) {
    return '본문 정보가 없습니다.';
  }

  return _stripHtml(raw);
}

String? _pickFirst(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    for (final entry in source.entries) {
      if (_norm(entry.key) != _norm(key)) {
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

String _stripHtml(String input) {
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

String _norm(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
}
