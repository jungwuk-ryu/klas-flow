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
  final Future<String> Function(int boardNo)? pageLoader;
  final Future<List<KlasAttachedFile>> Function(String attachId)?
  attachmentsLoader;

  const KlasPostDetailPage({
    super.key,
    required this.boardTitle,
    required this.summary,
    required this.loader,
    this.pageLoader,
    this.attachmentsLoader,
  });

  @override
  State<KlasPostDetailPage> createState() => _KlasPostDetailPageState();
}

class _KlasPostDetailPageState extends State<KlasPostDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  KlasBoardPostDetail? _detail;
  String? _htmlFallbackBody;
  List<KlasAttachedFile> _attachedFiles = const <KlasAttachedFile>[];

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
      String? fallbackBody;
      final boardRaw = _extractBoardRaw(detail);
      final extracted = _pickBodyText(boardRaw);
      if ((extracted == null || extracted.trim().isEmpty) &&
          widget.pageLoader != null) {
        final pageSource = await widget.pageLoader!(boardNo);
        fallbackBody = _extractBodyFromHtml(pageSource);
      }

      var attachedFiles = const <KlasAttachedFile>[];
      final attachId = _pickAttachId(<Map<String, dynamic>>[
        boardRaw,
        detail.raw,
        widget.summary.raw,
      ]);
      if (attachId != null && widget.attachmentsLoader != null) {
        try {
          attachedFiles = await widget.attachmentsLoader!(attachId);
        } catch (_) {
          attachedFiles = const <KlasAttachedFile>[];
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _htmlFallbackBody = fallbackBody;
        _attachedFiles = List<KlasAttachedFile>.unmodifiable(attachedFiles);
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
          : _DetailView(
              summary: widget.summary,
              detail: _detail,
              title: title,
              htmlFallbackBody: _htmlFallbackBody,
              attachedFiles: _attachedFiles,
            ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final KlasBoardPostSummary summary;
  final KlasBoardPostDetail? detail;
  final String title;
  final String? htmlFallbackBody;
  final List<KlasAttachedFile> attachedFiles;

  const _DetailView({
    required this.summary,
    required this.detail,
    required this.title,
    required this.htmlFallbackBody,
    required this.attachedFiles,
  });

  @override
  Widget build(BuildContext context) {
    final rawBoard = detail?.board?.raw ?? const <String, dynamic>{};
    final bodyText =
        _pickBodyText(rawBoard) ??
        _pickBodyText(_extractBoardRaw(detail)) ??
        htmlFallbackBody;
    final hasBody = bodyText != null && bodyText.trim().isNotEmpty;

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
            child: hasBody
                ? SelectableText(bodyText, style: const TextStyle(height: 1.5))
                : Text(
                    attachedFiles.isNotEmpty
                        ? '본문 텍스트가 없는 게시글입니다. 아래 첨부파일을 확인해 주세요.'
                        : '본문 정보가 없습니다.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        if (attachedFiles.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('첨부파일', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...attachedFiles.map((file) {
                    final sizeText = file.size == null
                        ? '-'
                        : '${file.size} bytes';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.attach_file),
                      title: Text(file.fileName ?? '(파일명 없음)'),
                      subtitle: Text('파일 번호: ${file.fileSn ?? '-'}'),
                      trailing: Text(sizeText),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
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
                    final text = _pickBodyText(comment.raw) ?? '댓글 본문이 없습니다.';
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

String? _pickBodyText(Map<String, dynamic> source) {
  final raw = _pickFirst(source, const <String>[
    'content',
    'contents',
    'cont',
    'ctt',
    'cn',
    'bbsCn',
    'boardCn',
    'boardContents',
    'boardContent',
    'boardHtml',
    'htmlData',
    'editorData',
    'memoCn',
    'memo',
    'body',
    'text',
    'html',
  ]);

  if (raw != null && raw.trim().isNotEmpty) {
    final cleaned = _stripHtml(raw);
    if (!_looksLikeTemplateText(cleaned)) {
      return cleaned;
    }
  }

  // 필드명이 계속 바뀌는 응답을 대비해 "가장 긴 문자열 필드"를 최후 보루로 사용한다.
  String? longest;
  source.forEach((_, value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return;
    }
    if (longest == null || text.length > longest!.length) {
      longest = text;
    }
  });

  if (longest != null && longest!.length >= 20) {
    final cleaned = _stripHtml(longest!);
    if (!_looksLikeTemplateText(cleaned)) {
      return cleaned;
    }
  }
  return null;
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

Map<String, dynamic> _extractBoardRaw(KlasBoardPostDetail? detail) {
  if (detail == null) {
    return const <String, dynamic>{};
  }

  if (detail.board != null) {
    return detail.board!.raw;
  }

  final raw = detail.raw;
  final board = _asMapByKeys(raw, const <String>[
    'board',
    'post',
    'article',
    'detail',
    'detailInfo',
    'boardInfo',
  ]);
  if (board != null) {
    return board;
  }

  final wrapped = _asMapByKeys(raw, const <String>[
    'data',
    'result',
    'payload',
  ]);
  if (wrapped != null) {
    final wrappedBoard = _asMapByKeys(wrapped, const <String>[
      'board',
      'post',
      'article',
      'detail',
      'detailInfo',
      'boardInfo',
    ]);
    if (wrappedBoard != null) {
      return wrappedBoard;
    }
    return wrapped;
  }

  return raw;
}

Map<String, dynamic>? _asMapByKeys(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    for (final entry in source.entries) {
      if (_norm(entry.key) != _norm(key)) {
        continue;
      }
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, dynamic>();
      }
    }
  }
  return null;
}

String? _extractBodyFromHtml(String html) {
  if (html.trim().isEmpty) {
    return null;
  }

  final candidates = <RegExp>[
    RegExp(
      r'<(?:div|td|section)[^>]*class="[^"]*(?:board|bbs)[^"]*(?:content|cn|view)[^"]*"[^>]*>(.*?)</(?:div|td|section)>',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'<(?:div|td|section)[^>]*id="[^"]*(?:board|bbs)[^"]*(?:content|cn|view)[^"]*"[^>]*>(.*?)</(?:div|td|section)>',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'<textarea[^>]*name="[^"]*(?:content|cn|bbsCn|boardCn)[^"]*"[^>]*>(.*?)</textarea>',
      caseSensitive: false,
      dotAll: true,
    ),
  ];

  for (final pattern in candidates) {
    final match = pattern.firstMatch(html);
    if (match == null) {
      continue;
    }
    final body = match.group(1);
    if (body == null || body.trim().isEmpty) {
      continue;
    }
    final cleaned = _stripHtml(body);
    if (!_looksLikeTemplateText(cleaned)) {
      return cleaned;
    }
  }
  return null;
}

bool _looksLikeTemplateText(String text) {
  if (!text.contains('{{') || !text.contains('}}')) {
    return false;
  }

  // Vue/템플릿 플레이스홀더가 본문 대부분을 차지하면 유효 본문으로 보지 않는다.
  final withoutWhitespace = text.replaceAll(RegExp(r'\s+'), '');
  final placeholderRemoved = withoutWhitespace.replaceAll(
    RegExp(r'\{\{.*?\}\}'),
    '',
  );
  return placeholderRemoved.length <= 12;
}

String? _pickAttachId(List<Map<String, dynamic>> sources) {
  const keys = <String>['atchFileId', 'attachId', 'fileGroupId'];
  for (final source in sources) {
    final value = _pickFirst(source, keys);
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
