import 'package:html/parser.dart' as html;

import '../exceptions/klas_exceptions.dart';
import '../models/course_context.dart';
import '../models/eclass_recording.dart';
import '../models/video_lecture.dart';
import 'request_executor.dart';
import 'video_lecture_api.dart';

/// E-class 복습은 별도 뷰어를 사용하며 온라인 강의의 학습 진도를 저장하지 않습니다.
final class EClassVideoApi {
  final RequestExecutor _requests;
  final VideoLectureApi _videos;

  EClassVideoApi(this._requests, this._videos);

  Future<KlasVideoMedia> open(EClassVideoTarget target) async {
    final id = target.value('contentId');
    if (id.isEmpty) {
      throw const VideoLectureUnavailableException(
        'E-class recording is unavailable.',
      );
    }
    if (target.value('decGb') == 'Y') {
      final source = await _requests.postFormTextOnce(
        '/std/lis/lctre/EClassViewPage.do',
        form: {'contentId': id},
      );
      final frame = html.parse(source).querySelector('iframe#LEARN_IFRAME');
      final uri = Uri.tryParse(frame?.attributes['src'] ?? '');
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'kwcommons.kw.ac.kr') {
        throw const VideoLectureUnavailableException(
          'E-class video source is unavailable.',
        );
      }
      return _videos.mediaAtEmbed(uri);
    }
    if (target.value('decGb') != 'N' ||
        [
          'grcode',
          'subj',
          'year',
          'hakgi',
          'bunban',
        ].any((key) => target.value(key).isEmpty)) {
      throw const VideoLectureUnavailableException(
        'E-class recording is unavailable.',
      );
    }
    final source = await _requests.postFormTextOnce(
      '/spv/lis/lctre/viewer/Default.do',
      form: {
        for (final key in [
          'grcode',
          'subj',
          'year',
          'hakgi',
          'bunban',
          'contentId',
        ])
          key: target.value(key),
      },
    );
    final match = RegExp(
      r'''\b(?:var|let|const)\s+contentUri\s*=\s*(['"])([^'"\r\n]+)\1''',
    ).firstMatch(source);
    final baseUri = Uri.parse('https://klas.kw.ac.kr');
    final uri = match == null
        ? null
        : baseUri.resolve(html.parseFragment(match.group(2)!).text ?? '');
    if (uri == null ||
        uri.origin != baseUri.origin ||
        uri.path != '/spv/lis/lctre/ssplayer/PlayingInfo.do' ||
        uri.queryParameters['contentId'] != id ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw const VideoLectureUnavailableException(
        'E-class video description is unavailable.',
      );
    }
    final description = await _requests.getText(
      uri.path,
      query: uri.queryParameters,
    );
    return parseVideoMedia(
      description,
      baseUri,
      fallbackDuration: target.recording.duration,
    );
  }
}

final class EClassVideoTarget {
  final Map<String, dynamic> row;
  final CourseContext context;

  EClassVideoTarget(Map<String, dynamic> row, this.context)
    : row = Map.unmodifiable(row);

  String value(String key) => row[key]?.toString().trim() ?? '';

  KlasEClassRecording get recording {
    final seconds = double.tryParse(value('duration'));
    final date = value('registDt');
    return KlasEClassRecording(
      id: value('contentId'),
      courseId: context.selectSubj,
      termId: context.selectYearhakgi,
      title: value('title').isEmpty ? null : value('title'),
      duration:
          seconds != null && seconds.isFinite && seconds > 0 && seconds < 604800
          ? Duration(
              microseconds: (seconds * Duration.microsecondsPerSecond).round(),
            )
          : null,
      recordedAt: videoDate(date) ?? DateTime.tryParse(date),
    );
  }
}
