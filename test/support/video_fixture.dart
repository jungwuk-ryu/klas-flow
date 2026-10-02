import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/klasflow.dart';
import 'package:klasflow/src/api/api_paths.dart';
import 'package:klasflow/src/api/auth_api.dart';
import 'package:klasflow/src/api/context_api.dart';
import 'package:klasflow/src/api/frame_api.dart';
import 'package:klasflow/src/api/request_executor.dart';
import 'package:klasflow/src/api/session_api.dart';
import 'package:klasflow/src/api/video_lecture_api.dart';
import 'package:klasflow/src/auth/auth_flow.dart';
import 'package:klasflow/src/auth/credentials_encryptor.dart';
import 'package:klasflow/src/auth/session_coordinator.dart';
import 'package:klasflow/src/context/context_manager.dart';
import 'package:klasflow/src/domain/video_playback.dart';
import 'package:klasflow/src/models/course_context.dart';
import 'package:klasflow/src/parsers/html_parser.dart';
import 'package:klasflow/src/parsers/login_parser.dart';
import 'package:klasflow/src/transport/cookie_jar.dart';
import 'package:klasflow/src/transport/transport.dart';

import 'mobile_qr_fixture.dart';

const videoListPath = '/std/lis/evltn/SelectOnlineCntntsStdList.do';
const videoViewerPath = '/spv/lis/lctre/viewer/LctreCntntsViewSpvPage.do';
const videoSavePath = '/spv/lis/lctre/viewer/UpdateProgress.do';
const videoStatusPath = '/spv/lis/lctre/viewer/ChkLctreCntntsView.do';
const videoCheckPath = '/std/lis/evltn/CertiLctreStdCheck.do';
const videoEmailPath = '/std/lis/evltn/CertiEmailSendStd.do';
const videoCodePath = '/std/lis/evltn/CertiKeyCheckStd.do';
const eclassListPath = '/std/lis/lctre/EClassStdList.do';
const eclassViewerPath = '/std/lis/lctre/EClassViewPage.do';
const eclassLegacyViewerPath = '/spv/lis/lctre/viewer/Default.do';
const eclassLegacyInfoPath = '/spv/lis/lctre/ssplayer/PlayingInfo.do';

Map<String, dynamic> eclassRow({bool legacy = false}) => {
  'contentId': 'synthetic-recording',
  'title': '복습용 녹화 강의',
  'decGb': legacy ? 'N' : 'Y',
  'duration': 1800,
  'registDt': '20261002103000',
  'grcode': 'test-group',
  'subj': qrSubjectId,
  'year': '2026',
  'hakgi': '1',
  'bunban': '01',
};

Map<String, dynamic> videoRow({double percent = 0}) => {
  'grcode': 'test-group',
  'subj': qrSubjectId,
  'year': '2026',
  'hakgi': '1',
  'bunban': '01',
  'module': '02',
  'lesson': '007',
  'oid': 'test-media',
  'weekNo': '2',
  'weeklyseq': '7',
  'sdesc': '테스트 동영상',
  'moduletitle': '연습 단원',
  'evltnSe': 'lesson',
  'isonoff': 'ON',
  'types': 'C',
  'sdate': '202601010000',
  'edate': '202612312359',
  'today': '202610031200',
  'ptime': '20',
  'learnTime': '0',
  'totalTime': '30',
  'prog': percent,
};

const videoXml = '''<?xml version="1.0"?>
<content><content_playing_info><content_duration>1800.25</content_duration>
<main_media><desktop><html5><method>progressive</method>
<media_uri><![CDATA[https://kwcommons.kw.ac.kr/contents/test/movie.mp4?quality=high&token=synthetic]]></media_uri>
</html5></desktop><mobile><html5><method>progressive</method>
<media_uri><![CDATA[https://kwcommons.kw.ac.kr/contents/test/movie.mp4?quality=high&token=synthetic]]></media_uri>
</html5></mobile></main_media></content_playing_info></content>''';

/// Only synthetic lesson data and session keys are used in this fixture.
final class VideoFixture {
  late final MobileQrFixture _login;
  final FutureOr<http.Response?> Function(http.Request)? handle;
  final bool verificationRequired;
  final bool otpAvailable;
  Map<String, dynamic> row;
  final Map<String, dynamic> recording;
  double percent;
  int watchedMinutes = 0;
  int preparations = 0;
  int revision = 1;
  Duration elapsed = Duration.zero;
  late final VideoLectureApi api;
  late final KlasTransport _transport;

  VideoFixture({
    this.handle,
    this.verificationRequired = false,
    this.otpAvailable = true,
    Map<String, dynamic>? row,
    Map<String, dynamic>? recording,
  }) : row = row ?? videoRow(),
       recording = recording ?? eclassRow(),
       percent = double.tryParse(row?['prog']?.toString() ?? '') ?? 0 {
    _login = MobileQrFixture(handle: _respond);
    final mock = MockClient((request) async {
      requests.add(request);
      return await _respond(request) ?? http.Response('not found', 404);
    });
    final cookies = CookieJar()
      ..absorb(
        http.Response(
          '',
          200,
          headers: {
            'set-cookie': 'JSESSIONID=synthetic-video-session; Path=/; Secure',
          },
        ),
      );
    final transport = _transport = KlasTransport(
      baseUri: Uri.parse('https://klas.kw.ac.kr'),
      timeout: const Duration(seconds: 10),
      httpClient: mock,
      ownsHttpClient: true,
      cookieJar: cookies,
    );
    const paths = ApiPaths();
    final contexts = ContextManager();
    final contextApi = ContextApi(transport, paths);
    final frameApi = FrameApi(transport, paths, HtmlPageParser());
    final coordinator = SessionCoordinator(
      authFlow: AuthFlow(
        authApi: AuthApi(transport, paths, LoginParser()),
        frameApi: frameApi,
        sessionApi: SessionApi(transport, paths),
        encryptor: CredentialsEncryptor(),
      ),
      contextApi: contextApi,
      contextManager: contexts,
      maxSessionRenewRetries: 1,
      cacheCredentialsForAutoRenewal: true,
    );
    api = VideoLectureApi(
      RequestExecutor(
        transport: transport,
        contextManager: contexts,
        sessionCoordinator: coordinator,
      ),
    );
  }

  KlasClient get client => _login.client;
  List<http.Request> get requests => _login.requests;
  List<http.Request> calls(String path) => _login.calls(path);
  Future<KlasUser> login() => _login.login();
  void close() {
    client.close();
    _transport.close();
  }

  VideoLectureTarget get target => VideoLectureTarget(
    row,
    const CourseContext(
      selectYearhakgi: '20261',
      selectSubj: qrSubjectId,
      selectChangeYn: 'Y',
      isDefault: true,
    ),
  );

  Future<VideoPlaybackSession> session() async {
    final bootstrap = await api.prepare(target);
    final media = await api.media(bootstrap);
    return VideoPlaybackSession(
      api: api,
      target: target,
      bootstrap: bootstrap,
      media: media,
      sessionRevision: () => revision,
      elapsed: () => elapsed,
    );
  }

  Future<http.Response?> _respond(http.Request request) async {
    final overridden = await handle?.call(request);
    if (overridden != null) return overridden;
    switch (request.url.path) {
      case eclassListPath:
        return qrJson([recording]);
      case eclassViewerPath:
        return http.Response(
          '<iframe id="LEARN_IFRAME" src="https://kwcommons.kw.ac.kr/em/synthetic"></iframe>',
          200,
        );
      case eclassLegacyViewerPath:
        return http.Response(
          "<script>var contentUri = '$eclassLegacyInfoPath?contentId=synthetic-recording&duration=';</script>",
          200,
        );
      case eclassLegacyInfoPath:
        return http.Response(
          videoXml
              .replaceAll('kwcommons.kw.ac.kr', 'stream.kw.ac.kr')
              .replaceAll(
                '<content_duration>1800.25</content_duration>',
                '<content_duration></content_duration>',
              ),
          200,
        );
      case videoListPath:
        return qrJson([
          row,
          {...row, 'evltnSe': 'proj', 'isonoff': '', 'sdesc': '과제'},
        ]);
      case videoCheckPath:
        return qrJson({
          'status': !verificationRequired,
          'curEmail': 'video-test@example.com',
          'otpIssue': otpAvailable ? 'Y' : 'N',
        });
      case videoEmailPath:
      case videoCodePath:
        return qrJson({'status': true});
      case videoViewerPath:
        preparations++;
        final form = request.bodyFields;
        final properties = {
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
          ])
            key: form[key] ?? '',
          'lecKey': 'synthetic-lecture-key-$preparations',
        }.entries.map((e) => '"${e.key}": "${e.value}"').join(',');
        return http.Response(
          '''<html><script>
var __lecParam = {$properties};
function whenUpdate(isendfile) { /* synthetic player protocol */ }
window.frames["LEARN_IFRAME"].location.href = "https://kwcommons.kw.ac.kr/em/synthetic";
</script><span id="lrnPer">$percent%</span><span id="lrnmin">$watchedMinutes분</span>
<iframe id="LEARN_IFRAME"></iframe></html>''',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      case '/em/synthetic':
        return http.Response(
          "<script>var contentUri = '/viewer/ssplayer/uniplayer_support/content.php?content_id=synthetic';</script>",
          200,
        );
      case '/viewer/ssplayer/uniplayer_support/content.php':
        return http.Response(videoXml, 200);
      case videoStatusPath:
        return qrJson({'isClose': false, 'redirect': false});
      case videoSavePath:
        watchedMinutes++;
        percent = watchedMinutes * 5;
        return qrJson({
          'prog': percent,
          'totalTime': watchedMinutes,
          'isClose': false,
          'redirect': false,
        });
      default:
        return null;
    }
  }
}
