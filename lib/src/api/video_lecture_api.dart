import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:xml/xml.dart';

import '../exceptions/klas_exceptions.dart';
import '../models/course_context.dart';
import '../models/video_lecture.dart';
import 'request_executor.dart';

const _viewerRoot = '/spv/lis/lctre/viewer/';

/// 공식 재생 폼과 미디어 설명 문서를 처리합니다. 저장 요청은 재시도하지 않습니다.
final class VideoLectureApi {
  final RequestExecutor _requests;
  int generation = 0;

  VideoLectureApi(this._requests);

  Future<Map<String, dynamic>> checkVerification(VideoLectureTarget target) {
    return _requests
        .postJsonDynamic(
          '/std/lis/evltn/CertiLctreStdCheck.do',
          payload: target.verificationPayload,
          includeContext: false,
        )
        .then(_object);
  }

  Future<void> sendEmail(Map<String, dynamic> payload) async {
    final result = _object(
      await _requests.postJsonDynamicOnce(
        '/std/lis/evltn/CertiEmailSendStd.do',
        payload: payload,
      ),
    );
    if (result['status'] != true) {
      throw const VideoVerificationException(
        'Video email verification was rejected.',
      );
    }
  }

  Future<bool> verifyCode(Map<String, dynamic> payload) async {
    final result = _object(
      await _requests.postJsonDynamicOnce(
        '/std/lis/evltn/CertiKeyCheckStd.do',
        payload: payload,
      ),
    );
    if (result['status'] is! bool) {
      throw const ParsingException('Invalid video verification response.');
    }
    return result['status'] == true;
  }

  Future<VideoPlaybackBootstrap> prepare(
    VideoLectureTarget target, {
    KlasVideoProgress? progress,
  }) async {
    // 이 요청이 실패해도 서버에서 이전 재생 키를 대체했을 수 있습니다.
    final preparedGeneration = ++generation;
    final source = await _requests.postFormTextOnce(
      '${_viewerRoot}LctreCntntsViewSpvPage.do',
      form: {
        ...target.viewerForm,
        if (progress?.percent != null) 'prog': progress!.percent.toString(),
        if (progress?.watchedDuration != null)
          'totalTime':
              (progress!.watchedDuration!.inMicroseconds /
                      Duration.microsecondsPerMinute)
                  .toString(),
      },
    );
    if (preparedGeneration != generation) {
      throw const VideoPlaybackInterruptedException(
        'Another video preparation replaced this session.',
      );
    }
    final parsed = parseVideoBootstrap(source, target);
    return VideoPlaybackBootstrap(
      parsed.embedUri,
      parsed.form,
      parsed.progress,
      generation: preparedGeneration,
    );
  }

  Future<KlasVideoMedia> media(VideoPlaybackBootstrap bootstrap) async {
    return mediaAtEmbed(bootstrap.embedUri);
  }

  Future<KlasVideoMedia> mediaAtEmbed(Uri embedUri) async {
    _validateCommonsUri(embedUri);
    final embed = await _requests.getPublicText(embedUri);
    final match = RegExp(
      r'''\b(?:var|let|const)\s+contentUri\s*=\s*(['"])([^'"\r\n]+)\1''',
    ).firstMatch(embed);
    if (match == null) {
      throw const VideoLectureUnavailableException(
        'Video media description is unavailable.',
      );
    }
    final descriptionUri = embedUri.resolve(
      html.parseFragment(match.group(2)!).text ?? '',
    );
    _validateCommonsUri(descriptionUri);
    final source = await _requests.getPublicText(descriptionUri);
    return parseVideoMedia(source, embedUri, embedUri: embedUri);
  }

  Future<Map<String, dynamic>> save(VideoPlaybackBootstrap bootstrap) {
    return _formObject('UpdateProgress.do', {
      ...bootstrap.form,
      'isendfile': 'Y',
    });
  }

  Future<void> check(VideoPlaybackBootstrap bootstrap) async {
    final response = await _formObject('ChkLctreCntntsView.do', bootstrap.form);
    validateVideoSessionResponse(response);
    if (response['isClose'] is! bool) {
      throw const ParsingException('Invalid video session status.');
    }
  }

  Future<Map<String, dynamic>> _formObject(
    String file,
    Map<String, String> form,
  ) async {
    final source = await _requests.postFormTextOnce(
      '$_viewerRoot$file',
      form: form,
    );
    try {
      return _object(jsonDecode(source));
    } on KlasException {
      rethrow;
    } catch (_) {
      throw const ParsingException('Invalid video playback response.');
    }
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const ParsingException('Video API expected an object response.');
  }
}

/// 강의 목록에서 얻은 내부 식별자를 공개 모델과 분리합니다.
final class VideoLectureTarget {
  final Map<String, dynamic> row;
  final CourseContext context;

  VideoLectureTarget(Map<String, dynamic> row, this.context)
    : row = Map.unmodifiable(row);

  String value(String key) => row[key]?.toString().trim() ?? '';

  String get id =>
      '${value('weekNo')}/${value('module')}/${value('lesson')}/${value('weeklyseq')}';

  bool get isVideo => value('evltnSe') == 'lesson' && value('isonoff') == 'ON';

  bool get isWithinPeriod =>
      value('today').isNotEmpty &&
      value('sdate').isNotEmpty &&
      value('edate').isNotEmpty &&
      value('today').compareTo(value('sdate')) >= 0 &&
      value('today').compareTo(value('edate')) <= 0;

  bool get hasNotStarted =>
      value('today').isNotEmpty &&
      value('sdate').isNotEmpty &&
      value('today').compareTo(value('sdate')) < 0;

  KlasVideoLecture get lecture => KlasVideoLecture(
    id: id,
    courseId: context.selectSubj,
    termId: context.selectYearhakgi,
    title: value('sdesc').isEmpty ? null : value('sdesc'),
    unitTitle: value('moduletitle').isEmpty ? null : value('moduletitle'),
    week: int.tryParse(value('weekNo')),
    availableFrom: videoDate(value('sdate')),
    availableUntil: videoDate(value('edate')),
    estimatedDuration: videoMinutes(row['totalTime']),
    isAvailable: isVideo && value('oid').isNotEmpty && !hasNotStarted,
    isWithinLearningPeriod: isWithinPeriod,
    progress: KlasVideoProgress(
      percent: videoPercent(row['prog']),
      watchedDuration: videoMinutes(row['learnTime']),
      requiredDuration: videoMinutes(row['ptime']),
    ),
  );

  Map<String, String> get viewerForm => {
    for (final key in [
      'grcode',
      'subj',
      'year',
      'hakgi',
      'bunban',
      'module',
      'lesson',
      'oid',
    ])
      key: value(key),
    // 공식 화면은 주차와 학습 항목 순번을 각각 전달합니다.
    'weeklyseq': value('weekNo'),
    'weeklysubseq': value('weeklyseq'),
    'ptime': value('ptime'),
    'totalTime': value('learnTime'),
    'prog': value('prog'),
    'profYN': 'N',
    'previewYN': 'N',
    'late': 'N',
  };

  Map<String, dynamic> get verificationPayload => {
    'selectYearhakgi': context.selectYearhakgi,
    'selectSubj': context.selectSubj,
    for (final key in ['grcode', 'subj', 'year', 'hakgi']) key: value(key),
    'weeklyseq': value('weekNo'),
    'gubun': 'C',
    'certiGubun': '',
  };

  void validate() {
    if (!isVideo ||
        hasNotStarted ||
        [
          'grcode',
          'subj',
          'year',
          'hakgi',
          'bunban',
          'module',
          'lesson',
          'oid',
          'weekNo',
          'weeklyseq',
        ].any((key) => value(key).isEmpty)) {
      throw const VideoLectureUnavailableException(
        'Video lecture is not available for playback.',
      );
    }
  }
}

final class VideoPlaybackBootstrap {
  final Uri embedUri;
  final Map<String, String> form;
  final KlasVideoProgress progress;
  final int generation;

  VideoPlaybackBootstrap(
    this.embedUri,
    Map<String, String> form,
    this.progress, {
    this.generation = 0,
  }) : form = Map.unmodifiable(form);
}

VideoPlaybackBootstrap parseVideoBootstrap(
  String source,
  VideoLectureTarget target,
) {
  final document = html.parse(source);
  if (document.querySelector('#LEARN_IFRAME, #learnEmbed') == null ||
      !source.contains('function whenUpdate(')) {
    throw const VideoLectureUnavailableException(
      'Video playback is unavailable.',
    );
  }
  final parameters = RegExp(
    r'\b(?:var|let|const)\s+__lecParam\s*=\s*\{([\s\S]*?)\}',
  ).firstMatch(source);
  final form = <String, String>{};
  if (parameters != null) {
    final properties = RegExp(
      r'''["'](\w+)["']\s*:\s*(['"])((?:\\.|[^\\])*?)\2\s*[,}]?''',
    );
    for (final match in properties.allMatches(parameters.group(1)!)) {
      form[match.group(1)!] = _jsString(match.group(3)!);
    }
  }
  for (final key in [
    'grcode',
    'subj',
    'year',
    'hakgi',
    'bunban',
    'module',
    'lesson',
    'oid',
    'weeklyseq',
    'weeklysubseq',
  ]) {
    if (form[key] != target.viewerForm[key]) {
      throw const ParsingException(
        'Video playback context does not match the lecture.',
      );
    }
  }
  if (form['lecKey']?.isNotEmpty != true) {
    throw const ParsingException('Video playback session is missing.');
  }
  final media = RegExp(
    r'''window\.frames\[\s*['"]LEARN_IFRAME['"]\s*\]\.location\.href\s*=\s*(['"])((?:\\.|[^\\])*?)\1''',
  ).firstMatch(source);
  final uri = Uri.tryParse(media == null ? '' : _jsString(media.group(2)!));
  if (uri == null) {
    throw const VideoLectureUnavailableException('Video source is missing.');
  }
  _validateCommonsUri(uri);
  return VideoPlaybackBootstrap(
    uri,
    form,
    KlasVideoProgress(
      percent: videoPercent(
        document.querySelector('#lrnPer')?.text.replaceAll('%', ''),
      ),
      watchedDuration: videoMinutes(
        document.querySelector('#lrnmin')?.text.replaceAll('분', ''),
      ),
      requiredDuration: target.lecture.progress.requiredDuration,
    ),
  );
}

KlasVideoMedia parseVideoMedia(
  String source,
  Uri baseUri, {
  Uri? embedUri,
  Duration? fallbackDuration,
}) {
  try {
    if (source.toUpperCase().contains('<!DOCTYPE')) {
      throw const FormatException();
    }
    final document = XmlDocument.parse(source);
    final info = document.rootElement.getElement('content_playing_info');
    final seconds = double.tryParse(
      info?.getElement('content_duration')?.innerText ?? '',
    );
    final duration =
        seconds != null && seconds.isFinite && seconds > 0 && seconds < 604800
        ? Duration(
            microseconds: (seconds * Duration.microsecondsPerSecond).round(),
          )
        : fallbackDuration;
    if (duration == null || duration <= Duration.zero) {
      throw const FormatException();
    }
    final sources = <KlasVideoSource>[];
    void addSource(Uri uri) {
      validateVideoSourceUri(uri);
      final path = uri.path.toLowerCase();
      final format = path.endsWith('.mp4')
          ? KlasVideoSourceFormat.mp4
          : path.endsWith('.m3u8')
          ? KlasVideoSourceFormat.hls
          : null;
      if (format != null && !sources.any((source) => source.uri == uri)) {
        sources.add(KlasVideoSource(uri: uri, format: format));
      }
    }

    for (final device in ['desktop', 'mobile']) {
      final node = info
          ?.getElement('main_media')
          ?.getElement(device)
          ?.getElement('html5');
      final text = node?.getElement('media_uri')?.innerText.trim();
      if (text == null || text.isEmpty) continue;
      final uri = baseUri.resolve(text);
      validateVideoSourceUri(uri);
      final method = node?.getElement('method')?.innerText.trim();
      if (method == 'progressive' || uri.path.toLowerCase().endsWith('.m3u8')) {
        addSource(uri);
      }
    }
    // 다른 공식 미디어 형식은 상대 영상 경로와 미디어 서비스 루트를 분리합니다.
    final stories =
        info?.getElement('story_list')?.findElements('story').toList() ?? [];
    if (stories.length == 1) {
      final list = stories.single.getElement('main_media_list');
      final media = list?.findElements('main_media').toList() ?? [];
      final defaultId = list?.getAttribute('default_media_id');
      media.sort(
        (a, b) => (b.getAttribute('media_id') == defaultId ? 1 : 0).compareTo(
          a.getAttribute('media_id') == defaultId ? 1 : 0,
        ),
      );
      final services =
          document.rootElement
              .getElement('service_root')
              ?.findElements('media')
              .where(
                (service) => const {
                  'video',
                  'default',
                  '',
                }.contains(service.getAttribute('type')?.toLowerCase() ?? ''),
              )
              .toList() ??
          [];
      services.sort(
        (a, b) => (b.getAttribute('type') == 'video' ? 1 : 0).compareTo(
          a.getAttribute('type') == 'video' ? 1 : 0,
        ),
      );
      for (final service in services) {
        for (final base in service.findElements('media_uri')) {
          if (base.getAttribute('method')?.toLowerCase() != 'progressive') {
            continue;
          }
          final template = base.innerText.trim();
          if (!template.contains('[MEDIA_FILE]')) continue;
          final contentId =
              info?.getElement('content_id')?.innerText.trim() ?? '';
          if (template.contains('[CONTENT_ID]') && contentId.isEmpty) {
            throw const FormatException();
          }
          for (final node in media) {
            final reference = node.innerText.trim();
            if (reference.isEmpty) continue;
            final resolved = template
                .replaceAll('[CONTENT_ID]', contentId)
                .replaceAll('[MEDIA_FILE]', reference);
            addSource(baseUri.resolve(resolved));
          }
        }
      }
    }
    if (sources.isEmpty) {
      throw const VideoLectureUnavailableException(
        'No supported video media sources were returned.',
      );
    }
    return KlasVideoMedia(
      embedUri: embedUri,
      duration: duration,
      sources: sources,
    );
  } on KlasException {
    rethrow;
  } catch (_) {
    throw const ParsingException('Invalid video media description.');
  }
}

void validateVideoSessionResponse(Map<String, dynamic> response) {
  for (final key in ['redirect', 'isClose']) {
    if (response[key] != null && response[key] is! bool) {
      throw const ParsingException('Invalid video playback status.');
    }
  }
  if (response['redirect'] == true) {
    throw const SessionExpiredException('Video playback session expired.');
  }
  if (response['isClose'] == true) {
    throw const VideoPlaybackInterruptedException(
      'Another player replaced this video session.',
    );
  }
}

double? videoPercent(Object? value) {
  final number = double.tryParse(value?.toString().trim() ?? '');
  return number != null && number.isFinite && number >= 0 && number <= 100
      ? number
      : null;
}

Duration? videoMinutes(Object? value) {
  final number = double.tryParse(value?.toString().trim() ?? '');
  return number != null && number.isFinite && number >= 0 && number < 10080
      ? Duration(
          microseconds: (number * Duration.microsecondsPerMinute).round(),
        )
      : null;
}

DateTime? videoDate(String value) {
  if (!RegExp(r'^\d{12}(\d{2})?$').hasMatch(value)) return null;
  final text =
      '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}T'
      '${value.substring(8, 10)}:${value.substring(10, 12)}:${value.length == 14 ? value.substring(12) : '00'}';
  final result = DateTime.tryParse(text);
  if (result == null || result.toIso8601String().substring(0, 19) != text) {
    return null;
  }
  return result;
}

void _validateCommonsUri(Uri uri) {
  if (uri.scheme != 'https' ||
      uri.host != 'kwcommons.kw.ac.kr' ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      (uri.hasPort && uri.port != 443)) {
    throw const VideoLectureUnavailableException(
      'Unsupported video media origin.',
    );
  }
}

void validateVideoSourceUri(Uri uri) {
  if (uri.scheme != 'https' ||
      !const {'kwcommons.kw.ac.kr', 'stream.kw.ac.kr'}.contains(uri.host) ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      (uri.hasPort && uri.port != 443)) {
    throw const VideoLectureUnavailableException(
      'Unsupported video media origin.',
    );
  }
}

String _jsString(String source) => source.replaceAllMapped(
  RegExp(r'''\\(?:u([0-9a-fA-F]{4})|([\\/'"bfnrt]))'''),
  (match) => match.group(1) != null
      ? String.fromCharCode(int.parse(match.group(1)!, radix: 16))
      : switch (match.group(2)) {
          'b' => '\b',
          'f' => '\f',
          'n' => '\n',
          'r' => '\r',
          't' => '\t',
          final value => value!,
        },
);
