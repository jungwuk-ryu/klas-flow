import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:klasflow/klasflow.dart';
import 'package:klasflow/src/api/video_lecture_api.dart';
import 'package:test/test.dart';

import 'support/mobile_qr_fixture.dart';
import 'support/video_fixture.dart';

Future<void> playFor(
  VideoFixture fixture,
  KlasVideoPlaybackSession session,
  int seconds, {
  int from = 0,
}) async {
  for (var second = 1; second <= seconds; second++) {
    fixture.elapsed += const Duration(seconds: 1);
    await session.recordPlayback(
      position: Duration(seconds: from + second),
      state: KlasVideoPlaybackState.playing,
    );
  }
}

void main() {
  group('Playback progress', () {
    test(
      'close saves only the pending observed interval and resume preserves server progress',
      () async {
        final fixture = VideoFixture();
        addTearDown(fixture.close);
        final session = await fixture.session();
        await session.recordPlayback(
          position: Duration.zero,
          state: KlasVideoPlaybackState.playing,
        );
        await playFor(fixture, session, 60);
        await session.recordPlayback(
          position: const Duration(seconds: 60),
          state: KlasVideoPlaybackState.paused,
        );
        fixture.elapsed += const Duration(minutes: 10);
        await session.recordPlayback(
          position: const Duration(seconds: 60),
          state: KlasVideoPlaybackState.playing,
        );
        final form = fixture.calls(videoViewerPath).last.bodyFields;
        expect(double.parse(form['prog']!), 5);
        expect(double.parse(form['totalTime']!), 1);
        await playFor(fixture, session, 59, from: 60);
        fixture.elapsed += const Duration(seconds: 1);
        final progress = await session.close();
        expect(progress.percent, 10);
        expect(progress.isComplete, isFalse);
        expect(fixture.calls(videoSavePath), hasLength(2));
      },
    );

    test(
      'a replaced server player is detected before a progress request',
      () async {
        final fixture = VideoFixture(
          handle: (r) =>
              r.url.path == videoStatusPath ? qrJson({'isClose': true}) : null,
        );
        addTearDown(fixture.close);
        final session = await fixture.session();
        await session.recordPlayback(
          position: Duration.zero,
          state: KlasVideoPlaybackState.playing,
        );
        await playFor(fixture, session, 59);
        fixture.elapsed += const Duration(seconds: 1);
        await expectLater(
          session.recordPlayback(
            position: const Duration(seconds: 60),
            state: KlasVideoPlaybackState.playing,
          ),
          throwsA(isA<VideoPlaybackInterruptedException>()),
        );
        expect(fixture.calls(videoSavePath), isEmpty);
        expect(session.isOpen, isFalse);
      },
    );

    test(
      'only observed playing saves server progress at the official cadence',
      () async {
        final fixture = VideoFixture();
        addTearDown(fixture.close);
        final session = await fixture.session();
        fixture.elapsed = const Duration(minutes: 4);
        expect(fixture.calls(videoSavePath), isEmpty);
        await session.recordPlayback(
          position: Duration.zero,
          state: KlasVideoPlaybackState.playing,
        );
        expect(fixture.preparations, 2);
        await playFor(fixture, session, 59);
        expect(fixture.calls(videoSavePath), isEmpty);
        await playFor(fixture, session, 1, from: 59);
        expect(session.progress.percent, 5);
        expect(session.progress.watchedDuration, const Duration(minutes: 1));
        final save = fixture.calls(videoSavePath).single;
        expect(save.bodyFields['isendfile'], 'Y');
        expect(save.bodyFields.keys, isNot(contains('position')));
        expect(save.bodyFields.keys, isNot(contains('prog')));
        expect(save.bodyFields.keys, isNot(contains('totalTime')));
        expect(save.bodyFields['weeklyseq'], '2');
        expect(save.bodyFields['weeklysubseq'], '7');
        expect(save.headers['cookie'], contains('synthetic-video-session'));
      },
    );

    for (final state in [
      KlasVideoPlaybackState.paused,
      KlasVideoPlaybackState.buffering,
      KlasVideoPlaybackState.seeking,
    ]) {
      test(
        '$state stops credit and resume starts a new playback key',
        () async {
          final fixture = VideoFixture();
          addTearDown(fixture.close);
          final session = await fixture.session();
          await session.recordPlayback(
            position: Duration.zero,
            state: KlasVideoPlaybackState.playing,
          );
          await playFor(fixture, session, 30);
          await session.recordPlayback(
            position: const Duration(seconds: 30),
            state: state,
          );
          fixture.elapsed += const Duration(minutes: 9);
          await session.recordPlayback(
            position: const Duration(seconds: 30),
            state: state,
          );
          expect(fixture.calls(videoSavePath), isEmpty);
          await session.recordPlayback(
            position: const Duration(seconds: 30),
            state: KlasVideoPlaybackState.playing,
          );
          await playFor(fixture, session, 60, from: 30);
          expect(fixture.calls(videoSavePath), hasLength(1));
          expect(
            fixture.calls(videoSavePath).single.bodyFields['lecKey'],
            'synthetic-lecture-key-3',
          );
          expect(session.progress.percent, 5);
        },
      );
    }

    test(
      'missing playback events and delayed close cannot credit an idle gap',
      () async {
        final fixture = VideoFixture();
        addTearDown(fixture.close);
        final session = await fixture.session();
        await session.recordPlayback(
          position: Duration.zero,
          state: KlasVideoPlaybackState.playing,
        );
        await playFor(fixture, session, 20);
        fixture.elapsed += const Duration(minutes: 20);
        await session.recordPlayback(
          position: const Duration(minutes: 20),
          state: KlasVideoPlaybackState.playing,
        );
        expect(fixture.preparations, 3);
        expect(fixture.calls(videoSavePath), isEmpty);
        fixture.elapsed += const Duration(minutes: 20);
        await session.close();
        expect(fixture.calls(videoSavePath), isEmpty);
      },
    );

    test(
      'seek and stalled position never cause completion or instant credit',
      () async {
        final fixture = VideoFixture();
        addTearDown(fixture.close);
        final session = await fixture.session();
        await session.recordPlayback(
          position: Duration.zero,
          state: KlasVideoPlaybackState.playing,
        );
        await playFor(fixture, session, 20);
        fixture.elapsed += const Duration(seconds: 1);
        await session.recordPlayback(
          position: const Duration(minutes: 25),
          state: KlasVideoPlaybackState.playing,
        );
        expect(fixture.preparations, 3);
        fixture.elapsed += const Duration(seconds: 3);
        await session.recordPlayback(
          position: const Duration(minutes: 25),
          state: KlasVideoPlaybackState.playing,
        );
        expect(fixture.preparations, 4);
        await session.recordPlayback(
          position: session.media.duration,
          state: KlasVideoPlaybackState.ended,
        );
        expect(session.progress.isComplete, isFalse);
        expect(fixture.calls(videoSavePath), isEmpty);
        await session.close();
        await session.close();
        expect(session.isOpen, isFalse);
      },
    );

    test(
      'late lecture supports review without sending progress updates',
      () async {
        final fixture = VideoFixture(
          row: {...videoRow(), 'edate': '202601022359'},
        );
        addTearDown(fixture.close);
        final session = await fixture.session();
        expect(session.canRecordProgress, isFalse);
        await session.recordPlayback(
          position: Duration.zero,
          state: KlasVideoPlaybackState.playing,
        );
        await playFor(fixture, session, 70);
        await session.close();
        expect(fixture.calls(videoSavePath), isEmpty);
        expect(fixture.preparations, 1);
      },
    );

    test(
      'invalid position is rejected before HTTP and leaves the session usable',
      () async {
        final fixture = VideoFixture();
        addTearDown(fixture.close);
        final session = await fixture.session();
        final count = fixture.requests.length;
        expect(
          () => session.recordPlayback(
            position: const Duration(seconds: -1),
            state: KlasVideoPlaybackState.playing,
          ),
          throwsArgumentError,
        );
        expect(
          () => session.recordPlayback(
            position: const Duration(hours: 1),
            state: KlasVideoPlaybackState.playing,
          ),
          throwsArgumentError,
        );
        expect(fixture.requests, hasLength(count));
        expect(session.isOpen, isTrue);
      },
    );

    test(
      'login changes and other video sessions invalidate the previous key',
      () async {
        final fixture = VideoFixture();
        addTearDown(fixture.close);
        final session = await fixture.session();
        fixture.revision++;
        expect(session.isOpen, isFalse);
        await expectLater(
          session.checkStatus(),
          throwsA(isA<SessionExpiredException>()),
        );
        final second = await fixture.session();
        await fixture.session();
        expect(second.isOpen, isFalse);
        await expectLater(
          second.checkStatus(),
          throwsA(isA<VideoPlaybackInterruptedException>()),
        );
      },
    );

    for (final rejection in [
      {'isClose': true},
      {'redirect': true},
      {'prog': 105, 'totalTime': 1},
    ]) {
      test(
        'server rejection $rejection closes the session without replay',
        () async {
          final fixture = VideoFixture(
            handle: (r) =>
                r.url.path == videoSavePath ? qrJson(rejection) : null,
          );
          addTearDown(fixture.close);
          final session = await fixture.session();
          await session.recordPlayback(
            position: Duration.zero,
            state: KlasVideoPlaybackState.playing,
          );
          await playFor(fixture, session, 59);
          fixture.elapsed += const Duration(seconds: 1);
          await expectLater(
            session.recordPlayback(
              position: const Duration(seconds: 60),
              state: KlasVideoPlaybackState.playing,
            ),
            throwsA(isA<KlasException>()),
          );
          expect(session.isOpen, isFalse);
          await expectLater(session.checkStatus(), throwsStateError);
          expect(fixture.calls(videoSavePath), hasLength(1));
        },
      );
    }

    test(
      'ambiguous progress failure is sent once with no login renewal',
      () async {
        final fixture = VideoFixture(
          handle: (r) {
            if (r.url.path == videoSavePath) {
              throw http.ClientException('synthetic failure');
            }
            return null;
          },
        );
        addTearDown(fixture.close);
        final session = await fixture.session();
        await session.recordPlayback(
          position: Duration.zero,
          state: KlasVideoPlaybackState.playing,
        );
        await playFor(fixture, session, 59);
        fixture.elapsed += const Duration(seconds: 1);
        await expectLater(
          session.recordPlayback(
            position: const Duration(seconds: 60),
            state: KlasVideoPlaybackState.playing,
          ),
          throwsA(isA<NetworkException>()),
        );
        expect(fixture.calls(videoSavePath), hasLength(1));
        expect(fixture.calls('/usr/cmn/login/LoginConfirm.do'), isEmpty);
        expect(session.isOpen, isFalse);
      },
    );

    test(
      'simultaneous operations are rejected while the first operation completes',
      () async {
        final gate = Completer<http.Response>();
        var hold = false;
        final fixture = VideoFixture(
          handle: (r) =>
              r.url.path == videoStatusPath && hold ? gate.future : null,
        );
        addTearDown(fixture.close);
        final session = await fixture.session();
        hold = true;
        final pending = session.checkStatus();
        await expectLater(session.checkStatus(), throwsStateError);
        expect(() => session.close(), throwsStateError);
        gate.complete(qrJson({'isClose': false}));
        await pending;
        expect(session.isOpen, isTrue);
      },
    );
  });

  group('Video preparation and verification', () {
    test(
      'login changes during authentication invalidate the challenge before any write',
      () async {
        final fixture = VideoFixture(verificationRequired: true);
        addTearDown(fixture.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final lecture = (await course.learning.listVideoLectures()).single;
        await expectLater(
          course.learning.openVideo(
            lecture,
            onVerification: (challenge) async {
              await fixture.login();
              await challenge.requestEmailCode();
              return const KlasVideoVerificationAnswer(
                method: KlasVideoVerificationMethod.email,
                code: '123456',
              );
            },
          ),
          throwsA(isA<SessionExpiredException>()),
        );
        expect(fixture.calls(videoEmailPath), isEmpty);
        expect(fixture.calls(videoCodePath), isEmpty);
        expect(fixture.calls(videoViewerPath), isEmpty);
      },
    );

    test(
      'public lecture selection rejects foreign, unavailable and missing lessons',
      () async {
        final fixture = VideoFixture();
        addTearDown(fixture.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final lecture = (await course.learning.listVideoLectures()).single;
        final foreign = KlasVideoLecture(
          id: lecture.id,
          courseId: 'another',
          termId: lecture.termId,
          isAvailable: true,
          isWithinLearningPeriod: true,
          progress: lecture.progress,
        );
        await expectLater(
          course.learning.openVideo(foreign),
          throwsArgumentError,
        );
        fixture.row = {...fixture.row, 'today': '202501010000'};
        await expectLater(
          course.learning.openVideo(lecture),
          throwsA(isA<VideoLectureUnavailableException>()),
        );
        fixture.row = {...videoRow(), 'oid': null};
        await expectLater(
          course.learning.openVideo(lecture),
          throwsA(isA<VideoLectureUnavailableException>()),
        );
        fixture.row = {...videoRow(), 'weeklyseq': '99'};
        await expectLater(
          course.learning.openVideo(lecture),
          throwsA(isA<VideoLectureUnavailableException>()),
        );
        expect(fixture.calls(videoViewerPath), isEmpty);
      },
    );

    test(
      'email verification is explicit, deduplicated and preserves leading zeros',
      () async {
        final fixture = VideoFixture(verificationRequired: true);
        addTearDown(fixture.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final lecture = (await course.learning.listVideoLectures()).single;
        await expectLater(
          course.learning.openVideo(lecture),
          throwsA(isA<VideoVerificationRequiredException>()),
        );
        KlasVideoVerificationChallenge? captured;
        final session = await course.learning.openVideo(
          lecture,
          onVerification: (challenge) async {
            captured = challenge;
            expect(challenge.emailHint, 'v***@example.com');
            await Future.wait([
              challenge.requestEmailCode(),
              challenge.requestEmailCode(),
            ]);
            return const KlasVideoVerificationAnswer(
              method: KlasVideoVerificationMethod.email,
              code: '001234',
            );
          },
        );
        expect(fixture.calls(videoEmailPath), hasLength(1));
        final code =
            jsonDecode(fixture.calls(videoCodePath).single.body) as Map;
        expect(code['inputKey'], '001234');
        expect(code['weeklyseq'], '2');
        expect(code['gubun'], 'C');
        expect(code['certiGubun'], 'eml');
        expect(() => captured!.requestEmailCode(), throwsStateError);
        await session.close();
        expect(fixture.calls(videoSavePath), isEmpty);
      },
    );

    test('existing OTP can verify without sending email', () async {
      final fixture = VideoFixture(verificationRequired: true);
      addTearDown(fixture.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      final lecture = (await course.learning.listVideoLectures()).single;
      await course.learning.openVideo(
        lecture,
        onVerification: (challenge) {
          expect(challenge.otpAvailable, isTrue);
          return const KlasVideoVerificationAnswer(
            method: KlasVideoVerificationMethod.otp,
            code: '000007',
          );
        },
      );
      expect(fixture.calls(videoEmailPath), isEmpty);
      expect(
        (jsonDecode(fixture.calls(videoCodePath).single.body)
            as Map)['certiGubun'],
        'otp',
      );
    });

    test(
      'cancelled or invalid authentication never prepares or submits progress',
      () async {
        final fixture = VideoFixture(
          verificationRequired: true,
          otpAvailable: false,
        );
        addTearDown(fixture.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final lecture = (await course.learning.listVideoLectures()).single;
        await expectLater(
          course.learning.openVideo(lecture, onVerification: (_) => null),
          throwsA(isA<VideoVerificationException>()),
        );
        await expectLater(
          course.learning.openVideo(
            lecture,
            onVerification: (_) => const KlasVideoVerificationAnswer(
              method: KlasVideoVerificationMethod.email,
              code: 'x',
            ),
          ),
          throwsArgumentError,
        );
        await expectLater(
          course.learning.openVideo(
            lecture,
            onVerification: (_) => const KlasVideoVerificationAnswer(
              method: KlasVideoVerificationMethod.otp,
              code: '123456',
            ),
          ),
          throwsA(isA<VideoVerificationException>()),
        );
        await expectLater(
          course.learning.openVideo(lecture, maxVerificationAttempts: 0),
          throwsArgumentError,
        );
        expect(fixture.calls(videoCodePath), isEmpty);
        expect(fixture.calls(videoViewerPath), isEmpty);
      },
    );

    test(
      'verification attempt limit and failed prepare never retry implicitly',
      () async {
        final fixture = VideoFixture(
          verificationRequired: true,
          handle: (r) =>
              r.url.path == videoCodePath ? qrJson({'status': false}) : null,
        );
        addTearDown(fixture.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final lecture = (await course.learning.listVideoLectures()).single;
        await expectLater(
          course.learning.openVideo(
            lecture,
            maxVerificationAttempts: 2,
            onVerification: (_) => const KlasVideoVerificationAnswer(
              method: KlasVideoVerificationMethod.email,
              code: '123456',
            ),
          ),
          throwsA(isA<VideoVerificationException>()),
        );
        expect(fixture.calls(videoCodePath), hasLength(2));
        expect(fixture.calls(videoViewerPath), isEmpty);
        final failure = VideoFixture(
          handle: (r) => r.url.path == videoViewerPath
              ? http.Response('expired', 401)
              : null,
        );
        addTearDown(failure.close);
        final failureCourse = (await (await failure.login()).defaultCourse())!;
        await expectLater(
          failureCourse.learning.openVideo(
            (await failureCourse.learning.listVideoLectures()).single,
          ),
          throwsA(isA<KlasException>()),
        );
        expect(failure.calls(videoViewerPath), hasLength(1));
        expect(failure.calls('/usr/cmn/login/LoginConfirm.do'), hasLength(1));
      },
    );

    test('complete lectures skip additional verification', () async {
      final fixture = VideoFixture(
        verificationRequired: true,
        row: videoRow(percent: 100),
      );
      addTearDown(fixture.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      await course.learning.openVideo(
        (await course.learning.listVideoLectures()).single,
      );
      expect(fixture.calls(videoCheckPath), isEmpty);
    });
  });

  group('Media and E-class', () {
    test(
      'story-based media resolves official templates and defaults to the requested quality',
      () {
        const source =
            '''<content><content_playing_info><content_id>synthetic</content_id><content_duration>120</content_duration>
<story_list><story><main_media_list default_media_id="primary">
<main_media media_id="alternate">media_files/alternate.mp4</main_media>
<main_media media_id="primary">media_files/main.mp4</main_media>
</main_media_list></story></story_list></content_playing_info>
<service_root><media type="video"><media_uri method="progressive" target="all">https://kwcommons.kw.ac.kr/contents/[CONTENT_ID]/[MEDIA_FILE]</media_uri>
<media_uri method="pseudo" target="flash-fallback">rtmp://example.com/ignored</media_uri>
<media_uri method="progressive" target="mobile">https://kwcommons.kw.ac.kr/contents/[CONTENT_ID]/[MEDIA_FILE]</media_uri>
</media></service_root></content>''';
        final media = parseVideoMedia(
          source,
          Uri.parse('https://kwcommons.kw.ac.kr/em/test'),
        );
        expect(media.sources, hasLength(2));
        expect(
          media.sources.first.uri.path,
          '/contents/synthetic/media_files/main.mp4',
        );
        expect(media.duration, const Duration(minutes: 2));
        expect(
          () => parseVideoMedia(
            source.replaceAll(
              'https://kwcommons.kw.ac.kr/contents/[CONTENT_ID]/[MEDIA_FILE]',
              'https://example.com/private',
            ),
            Uri.parse('https://kwcommons.kw.ac.kr'),
          ),
          throwsA(isA<VideoLectureUnavailableException>()),
        );
      },
    );

    test('media metadata never receives or replaces the KLAS cookie', () async {
      final fixture = VideoFixture(
        handle: (r) =>
            r.url.host == 'kwcommons.kw.ac.kr' && r.url.path.startsWith('/em/')
            ? http.Response(
                "<script>var contentUri = '/viewer/ssplayer/uniplayer_support/content.php?content_id=synthetic';</script>",
                200,
                headers: {'set-cookie': 'JSESSIONID=foreign-cookie; Path=/'},
              )
            : null,
      );
      addTearDown(fixture.close);
      final session = await fixture.session();
      final public = fixture.requests.where(
        (r) => r.url.host == 'kwcommons.kw.ac.kr',
      );
      expect(public, hasLength(2));
      for (final request in public) {
        expect(request.headers['cookie'], isNull);
        expect(request.followRedirects, isFalse);
      }
      await session.checkStatus();
      expect(
        fixture.calls(videoStatusPath).single.headers['cookie'],
        contains('synthetic-video-session'),
      );
      expect(
        fixture.calls(videoStatusPath).single.headers['cookie'],
        isNot(contains('foreign-cookie')),
      );
    });

    test('unexpected redirects and media origins are rejected', () async {
      final fixture = VideoFixture(
        handle: (r) => r.url.path == '/em/synthetic'
            ? http.Response(
                '',
                302,
                headers: {'location': 'https://example.com/video'},
              )
            : null,
      );
      addTearDown(fixture.close);
      await expectLater(fixture.session(), throwsA(isA<KlasException>()));
      expect(fixture.requests.any((r) => r.url.host == 'example.com'), isFalse);
      expect(
        () => parseVideoMedia(
          videoXml.replaceAll('kwcommons.kw.ac.kr', 'example.com'),
          Uri.parse('https://kwcommons.kw.ac.kr'),
        ),
        throwsA(isA<VideoLectureUnavailableException>()),
      );
    });

    test('XML handles CDATA, deduplicates sources and exposes MP4 and HLS', () {
      final media = parseVideoMedia(
        videoXml,
        Uri.parse('https://kwcommons.kw.ac.kr/em/test'),
      );
      expect(media.sources, hasLength(1));
      expect(media.duration, const Duration(milliseconds: 1800250));
      expect(media.sources.single.uri.queryParameters['token'], 'synthetic');
      final hls = parseVideoMedia(
        videoXml.replaceAll('movie.mp4', 'movie.m3u8'),
        Uri.parse('https://kwcommons.kw.ac.kr/em/test'),
      );
      expect(hls.sources.single.format, KlasVideoSourceFormat.hls);
      expect(() => media.sources.clear(), throwsUnsupportedError);
      expect(
        () => parseVideoMedia(
          '<broken>',
          Uri.parse('https://kwcommons.kw.ac.kr'),
        ),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => parseVideoMedia(
          '<!DOCTYPE test>$videoXml',
          Uri.parse('https://kwcommons.kw.ac.kr'),
        ),
        throwsA(isA<ParsingException>()),
      );
    });

    for (final legacy in [false, true]) {
      test(
        'E-class ${legacy ? 'legacy' : 'Commons'} review uses its own API and has no progress writes',
        () async {
          final fixture = VideoFixture(recording: eclassRow(legacy: legacy));
          addTearDown(fixture.close);
          final course = (await (await fixture.login()).defaultCourse())!;
          final recording = (await course.eclass.listRecordings()).single;
          expect(recording.displayTitle, '복습용 녹화 강의');
          expect(recording.recordedAt, DateTime(2026, 10, 2, 10, 30));
          final media = await course.eclass.openVideo(recording);
          expect(media.sources.single.format, KlasVideoSourceFormat.mp4);
          expect(
            media.sources.single.uri.host,
            legacy ? 'stream.kw.ac.kr' : 'kwcommons.kw.ac.kr',
          );
          expect(
            media.duration,
            legacy
                ? const Duration(minutes: 30)
                : const Duration(milliseconds: 1800250),
          );
          expect(media.embedUri == null, legacy);
          expect(
            fixture.calls(legacy ? eclassLegacyViewerPath : eclassViewerPath),
            hasLength(1),
          );
          expect(fixture.calls(videoListPath), isEmpty);
          expect(fixture.calls(videoViewerPath), isEmpty);
          expect(fixture.calls(videoSavePath), isEmpty);
          expect(fixture.calls(videoCheckPath), isEmpty);
          if (legacy) {
            expect(
              fixture.calls(eclassLegacyInfoPath).single.headers['cookie'],
              contains('synthetic-session'),
            );
          }
        },
      );
    }

    test(
      'E-class rejects foreign or removed recordings and mismatched legacy descriptions',
      () async {
        final fixture = VideoFixture(
          recording: eclassRow(legacy: true),
          handle: (r) => r.url.path == eclassLegacyViewerPath
              ? http.Response(
                  "<script>var contentUri = '$eclassLegacyInfoPath?contentId=another';</script>",
                  200,
                )
              : null,
        );
        addTearDown(fixture.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final recording = (await course.eclass.listRecordings()).single;
        await expectLater(
          course.eclass.openVideo(
            KlasEClassRecording(
              id: recording.id,
              courseId: 'foreign',
              termId: recording.termId,
            ),
          ),
          throwsArgumentError,
        );
        await expectLater(
          course.eclass.openVideo(
            KlasEClassRecording(
              id: 'removed',
              courseId: recording.courseId,
              termId: recording.termId,
            ),
          ),
          throwsA(isA<VideoLectureUnavailableException>()),
        );
        await expectLater(
          course.eclass.openVideo(recording),
          throwsA(isA<VideoLectureUnavailableException>()),
        );
        expect(fixture.calls(eclassLegacyInfoPath), isEmpty);
      },
    );
  });
}
