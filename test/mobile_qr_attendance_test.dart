import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

import 'support/mobile_qr_fixture.dart';

void main() {
  group('Mobile QR attendance', () {
    test(
      'mobile subject selection works without presentation metadata',
      () async {
        final fixture = MobileQrFixture(
          verificationRequired: false,
          handle: (request) =>
              request.url.path == '/std/ads/admst/KwAttendStdGwakmokList.do'
              ? qrJson([
                  {
                    'selectYear': '2026',
                    'selectHakgi': '1',
                    'openMajorCode': 'CSE',
                    'openGrade': '3',
                    'openGwamokNo': '101',
                    'bunbanNo': '01',
                  },
                ])
              : null,
        );
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final result = await course.qrCheckIn('qr');
        expect(result.accepted, isTrue);
        expect(qrBody(fixture.calls(qrSubmitPath).single)['subj'], qrSubjectId);
      },
    );

    test(
      'registered OTP needs no email and preserves leading zeroes',
      () async {
        final fixture = MobileQrFixture();
        addTearDown(fixture.client.close);
        final user = await fixture.login();
        final subject = (await user.attendance.listSubjectItems()).single;
        expect(subject.subjectId, qrSubjectId);
        final result = await user.attendance.qrCheckIn(
          subject: subject,
          qrCode: 'opaque-scan',
          onVerification: (challenge) {
            expect(challenge.otpAvailable, isTrue);
            return const KlasQrVerificationAnswer(
              method: KlasQrVerificationMethod.otp,
              code: '012345',
            );
          },
        );
        expect(result.accepted, isTrue);
        expect(qrBody(fixture.calls(qrCodePath).single)['inputKey'], '012345');
        expect(qrBody(fixture.calls(qrCodePath).single)['certiGubun'], 'otp');
        expect(fixture.calls(qrEmailPath), isEmpty);
        expect(fixture.calls(qrAppKeyPath), isEmpty);
      },
    );

    test('missing handler prevents preparing unverified attendance', () async {
      final fixture = MobileQrFixture();
      addTearDown(fixture.client.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      await expectLater(
        course.prepareQrCheckIn(),
        throwsA(isA<QrAttendanceVerificationRequiredException>()),
      );
      expect(fixture.calls(qrAppKeyPath), isEmpty);
      expect(fixture.calls(qrSubmitPath), isEmpty);
    });

    test(
      'verification cancellation and stale email request cannot submit',
      () async {
        final fixture = MobileQrFixture();
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        late KlasQrVerificationChallenge saved;
        await expectLater(
          course.qrCheckIn(
            'qr',
            onVerification: (challenge) {
              saved = challenge;
              return null;
            },
          ),
          throwsA(isA<QrAttendanceCancelledException>()),
        );
        expect(
          () => saved.requestEmailCode(),
          throwsA(isA<QrAttendanceVerificationException>()),
        );
        expect(fixture.calls(qrEmailPath), isEmpty);
        expect(fixture.calls(qrCodePath), isEmpty);
        expect(fixture.calls(qrSubmitPath), isEmpty);
      },
    );

    test('cancelled preparation cannot submit', () async {
      final fixture = MobileQrFixture(verificationRequired: false);
      addTearDown(fixture.client.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      final prepared = await course.prepareQrCheckIn();
      expect(prepared.isPending, isTrue);
      expect(fixture.calls(qrSubmitPath), isEmpty);
      prepared.cancel();
      prepared.cancel();
      expect(prepared.isPending, isFalse);
      await expectLater(prepared.submit('qr'), throwsStateError);
      expect(fixture.calls(qrSubmitPath), isEmpty);
    });

    test('closed course cannot prepare attendance', () async {
      final fixture = MobileQrFixture(
        handle: (request) =>
            request.url.path == qrFinishPath ? qrJson('Y') : null,
      );
      addTearDown(fixture.client.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      await expectLater(
        course.prepareQrCheckIn(),
        throwsA(isA<QrAttendanceUnavailableException>()),
      );
      expect(fixture.calls(qrCheckPath), isEmpty);
      expect(fixture.calls(qrSubmitPath), isEmpty);
    });

    test('code retries are bounded and report previous rejection', () async {
      final fixture = MobileQrFixture(
        handle: (request) =>
            request.url.path == qrCodePath ? qrJson({'status': false}) : null,
      );
      addTearDown(fixture.client.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      final attempts = <int>[];
      await expectLater(
        course.qrCheckIn(
          'qr',
          maxVerificationAttempts: 2,
          onVerification: (challenge) {
            attempts.add(challenge.attempt);
            expect(challenge.maxAttempts, 2);
            expect(challenge.previousAttemptRejected, challenge.attempt > 1);
            return const KlasQrVerificationAnswer(
              method: KlasQrVerificationMethod.otp,
              code: '012345',
            );
          },
        ),
        throwsA(isA<QrAttendanceVerificationException>()),
      );
      expect(attempts, [1, 2]);
      expect(fixture.calls(qrCodePath), hasLength(2));
      expect(fixture.calls(qrSubmitPath), isEmpty);
    });

    test(
      'rejected code can be followed by a fresh successful answer',
      () async {
        var checks = 0;
        final fixture = MobileQrFixture(
          handle: (request) {
            if (request.url.path == qrCodePath && ++checks == 1) {
              return qrJson({'status': false});
            }
            return null;
          },
        );
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final result = await course.qrCheckIn(
          'qr',
          onVerification: (challenge) => KlasQrVerificationAnswer(
            method: KlasQrVerificationMethod.otp,
            code: challenge.attempt == 1 ? '000000' : '012345',
          ),
        );
        expect(result.accepted, isTrue);
        expect(fixture.calls(qrSubmitPath), hasLength(1));
      },
    );

    test('unregistered OTP is rejected without device registration', () async {
      final fixture = MobileQrFixture(otpAvailable: false);
      addTearDown(fixture.client.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      await expectLater(
        course.qrCheckIn(
          'qr',
          onVerification: (_) => const KlasQrVerificationAnswer(
            method: KlasQrVerificationMethod.otp,
            code: '012345',
          ),
        ),
        throwsA(isA<QrAttendanceVerificationException>()),
      );
      expect(fixture.calls(qrCodePath), isEmpty);
      expect(fixture.calls(qrSubmitPath), isEmpty);
    });

    test('email delivery failure stops before code check', () async {
      final fixture = MobileQrFixture(
        handle: (request) =>
            request.url.path == qrEmailPath ? qrJson({'status': false}) : null,
      );
      addTearDown(fixture.client.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      await expectLater(
        course.qrCheckIn(
          'qr',
          onVerification: (challenge) async {
            await challenge.requestEmailCode();
            return const KlasQrVerificationAnswer(
              method: KlasQrVerificationMethod.email,
              code: '012345',
            );
          },
        ),
        throwsA(isA<QrAttendanceVerificationException>()),
      );
      expect(fixture.calls(qrCodePath), isEmpty);
      expect(fixture.calls(qrSubmitPath), isEmpty);
    });

    for (final value in [false, true]) {
      test(
        'missing one-time key after ${value ? 'app' : 'code'} authentication stops',
        () async {
          final fixture = MobileQrFixture(
            verificationRequired: !value,
            handle: (request) =>
                request.url.path == (value ? qrAppKeyPath : qrCodePath)
                ? qrJson({'status': true})
                : null,
          );
          addTearDown(fixture.client.close);
          final course = (await (await fixture.login()).defaultCourse())!;
          await expectLater(
            course.qrCheckIn(
              'qr',
              onVerification: (_) => const KlasQrVerificationAnswer(
                method: KlasQrVerificationMethod.otp,
                code: '012345',
              ),
            ),
            throwsA(isA<ParsingException>()),
          );
          expect(fixture.calls(qrSubmitPath), isEmpty);
        },
      );
    }

    for (final path in [qrEmailPath, qrCodePath, qrAppKeyPath, qrSubmitPath]) {
      test('expired session at $path is never renewed or replayed', () async {
        final fixture = MobileQrFixture(
          verificationRequired: path == qrEmailPath || path == qrCodePath,
          handle: (request) => request.url.path == path
              ? http.Response('Session expired', 401)
              : null,
        );
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        await expectLater(
          course.qrCheckIn(
            'qr',
            onVerification: (challenge) async {
              if (path == qrEmailPath) await challenge.requestEmailCode();
              return const KlasQrVerificationAnswer(
                method: KlasQrVerificationMethod.otp,
                code: '012345',
              );
            },
          ),
          throwsA(isA<SessionExpiredException>()),
        );
        expect(fixture.calls(path), hasLength(1));
        expect(fixture.calls('/usr/cmn/login/LoginConfirm.do'), hasLength(1));
        if (path != qrSubmitPath) expect(fixture.calls(qrSubmitPath), isEmpty);
      });
    }

    test(
      'unknown network outcome is never automatically resubmitted',
      () async {
        final fixture = MobileQrFixture(
          verificationRequired: false,
          handle: (request) {
            if (request.url.path == qrSubmitPath) {
              throw TimeoutException('Synthetic timeout');
            }
            return null;
          },
        );
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        await expectLater(
          course.qrCheckIn('qr'),
          throwsA(isA<NetworkException>()),
        );
        expect(fixture.calls(qrSubmitPath), hasLength(1));
        expect(fixture.calls('/usr/cmn/login/LoginConfirm.do'), hasLength(1));
      },
    );

    test(
      'read renewal reapplies app identity to attendance requests',
      () async {
        var reads = 0;
        final fixture = MobileQrFixture(
          verificationRequired: false,
          handle: (request) => request.url.path == qrFinishPath && ++reads == 1
              ? http.Response('Session expired', 401)
              : null,
        );
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        expect((await course.qrCheckIn('qr')).accepted, isTrue);
        expect(fixture.calls('/usr/cmn/login/LoginConfirm.do'), hasLength(2));
        expectAutomaticAttendanceHeaders(fixture.requests);
      },
    );

    test(
      'blank QR and invalid attempt limit fail before attendance calls',
      () async {
        final fixture = MobileQrFixture(verificationRequired: false);
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        await expectLater(course.qrCheckIn('  '), throwsArgumentError);
        await expectLater(
          course.qrCheckIn('qr', maxVerificationAttempts: 0),
          throwsArgumentError,
        );
        await expectLater(
          course.prepareQrCheckIn(maxVerificationAttempts: 11),
          throwsArgumentError,
        );
        expect(fixture.calls(qrFinishPath), isEmpty);
        expect(fixture.calls(qrSubmitPath), isEmpty);
      },
    );
  });

  group('QR preparation lifecycle', () {
    test(
      'blank input leaves preparation available for a valid string',
      () async {
        final fixture = MobileQrFixture(verificationRequired: false);
        addTearDown(fixture.client.close);
        final user = await fixture.login();
        final subject = (await user.attendance.listSubjectItems()).single;
        final prepared = await user.attendance.prepareQrCheckIn(
          subject: subject,
        );
        expect(fixture.calls(qrSubmitPath), isEmpty);
        await expectLater(prepared.submit('  '), throwsArgumentError);
        expect(prepared.isPending, isTrue);
        expect(fixture.calls(qrSubmitPath), isEmpty);
        expect(
          (await prepared.submit('externally-decoded-qr')).accepted,
          isTrue,
        );
        expect(prepared.isPending, isFalse);
        await expectLater(prepared.submit('another-qr'), throwsStateError);
        expect(fixture.calls(qrSubmitPath), hasLength(1));
      },
    );

    test('concurrent submissions consume preparation once', () async {
      final awaitingResponse = Completer<void>();
      final response = Completer<http.Response>();
      final fixture = MobileQrFixture(
        verificationRequired: false,
        handle: (request) {
          if (request.url.path != qrSubmitPath) return null;
          awaitingResponse.complete();
          return response.future;
        },
      );
      addTearDown(fixture.client.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      final prepared = await course.prepareQrCheckIn();
      final first = prepared.submit('first-qr');
      await awaitingResponse.future;
      try {
        expect(prepared.isPending, isFalse);
        await expectLater(prepared.submit('second-qr'), throwsStateError);
        prepared.cancel();
      } finally {
        response.complete(qrJson({'errorCount': 0}));
      }
      expect((await first).accepted, isTrue);
      expect(fixture.calls(qrSubmitPath), hasLength(1));
      expect(qrBody(fixture.calls(qrSubmitPath).single)['encrypt'], 'first-qr');
    });

    for (final outcome in ['rejected', 'malformed', 'timeout', 'expired']) {
      test(
        '$outcome submission cannot reuse prepared authentication',
        () async {
          final fixture = MobileQrFixture(
            verificationRequired: false,
            handle: (request) {
              if (request.url.path != qrSubmitPath) return null;
              return switch (outcome) {
                'rejected' => qrJson({'errorCount': 1}),
                'malformed' => qrJson({'message': 'unknown'}),
                'timeout' => throw TimeoutException('Synthetic timeout'),
                _ => http.Response('Session expired', 401),
              };
            },
          );
          addTearDown(fixture.client.close);
          final course = (await (await fixture.login()).defaultCourse())!;
          final prepared = await course.prepareQrCheckIn();
          if (outcome == 'rejected') {
            expect((await prepared.submit('qr')).accepted, isFalse);
          } else {
            await expectLater(
              prepared.submit('qr'),
              throwsA(switch (outcome) {
                'malformed' => isA<ParsingException>(),
                'timeout' => isA<NetworkException>(),
                _ => isA<SessionExpiredException>(),
              }),
            );
          }
          expect(prepared.isPending, isFalse);
          await expectLater(prepared.submit('qr'), throwsStateError);
          expect(fixture.calls(qrSubmitPath), hasLength(1));
          expect(fixture.calls('/usr/cmn/login/LoginConfirm.do'), hasLength(1));
        },
      );
    }

    for (final change in ['login', 'reset', 'renewal']) {
      test('$change invalidates previously prepared attendance', () async {
        var taskReads = 0;
        final fixture = MobileQrFixture(
          verificationRequired: false,
          handle: (request) {
            if (request.url.path != '/std/lis/evltn/TaskStdList.do') {
              return null;
            }
            if (++taskReads == 1) return http.Response('Session expired', 401);
            return qrJson([]);
          },
        );
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        final prepared = await course.prepareQrCheckIn();
        if (change == 'login') {
          await fixture.client.login('other-user', 'test-password');
        } else if (change == 'reset') {
          fixture.client.clearLocalState();
        } else {
          await course.listTasks();
        }
        expect(prepared.isPending, isFalse);
        await expectLater(
          prepared.submit('qr'),
          throwsA(isA<SessionExpiredException>()),
        );
        await expectLater(prepared.submit('qr'), throwsStateError);
        expect(fixture.calls(qrSubmitPath), isEmpty);
      });
    }

    test(
      'session change during code input stops further verification',
      () async {
        final fixture = MobileQrFixture();
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        await expectLater(
          course.prepareQrCheckIn(
            onVerification: (_) async {
              await fixture.login();
              return const KlasQrVerificationAnswer(
                method: KlasQrVerificationMethod.otp,
                code: '012345',
              );
            },
          ),
          throwsA(isA<SessionExpiredException>()),
        );
        expect(fixture.calls(qrCodePath), isEmpty);
        expect(fixture.calls(qrSubmitPath), isEmpty);
      },
    );

    test(
      'session change blocks email delivery from a pending challenge',
      () async {
        final fixture = MobileQrFixture();
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        await expectLater(
          course.prepareQrCheckIn(
            onVerification: (challenge) async {
              fixture.client.clearLocalState();
              await challenge.requestEmailCode();
              return null;
            },
          ),
          throwsA(isA<SessionExpiredException>()),
        );
        expect(fixture.calls(qrEmailPath), isEmpty);
        expect(fixture.calls(qrCodePath), isEmpty);
        expect(fixture.calls(qrSubmitPath), isEmpty);
      },
    );
  });

  group('QR result parsing', () {
    test(
      'official error count and responseText drive success or rejection',
      () {
        expect(
          KlasQrAttendanceResult.fromJson({
            'errorCount': 0,
            'responseText': '출석 완료',
          }).accepted,
          isTrue,
        );
        final rejected = KlasQrAttendanceResult.fromJson({
          'errorCount': '1',
          'responseText': '유효하지 않은 QR코드입니다.',
        });
        expect(rejected.accepted, isFalse);
        expect(rejected.message, '유효하지 않은 QR코드입니다.');
        expect(
          KlasQrAttendanceResult.fromJson({
            'errorCount': 1,
            'status': 'ok',
          }).accepted,
          isFalse,
        );
        expect(
          KlasQrAttendanceResult.fromJson({
            'errorCount': 0,
            'success': false,
          }).accepted,
          isFalse,
        );
        expect(
          KlasQrAttendanceResult.fromJson({
            'fieldErrors': [{}],
            'status': 'ok',
          }).accepted,
          isFalse,
        );
      },
    );
    test('unknown and empty responses cannot imply success', () {
      for (final response in <Map<String, dynamic>>[
        {},
        {'message': 'unknown'},
        {'errorCount': null},
        {'errorCount': 'invalid'},
        {'errorCount': -1},
      ]) {
        expect(
          () => KlasQrAttendanceResult.fromJson(response),
          throwsA(isA<ParsingException>()),
        );
      }
    });
  });

  group('Automatic attendance User-Agent', () {
    test(
      'ordinary client handles app verification without mobile configuration',
      () async {
        final fixture = MobileQrFixture(verificationRequired: false);
        addTearDown(fixture.client.close);
        final course = (await (await fixture.login()).defaultCourse())!;
        expect((await course.qrCheckIn('qr')).accepted, isTrue);
        await fixture.client.requestCaptchaImage();
        expectAutomaticAttendanceHeaders(fixture.requests);
      },
    );
    test('headers remain isolated while QR verification is pending', () async {
      final fixture = MobileQrFixture(
        handle: (request) => request.url.path == '/std/lis/evltn/TaskStdList.do'
            ? qrJson([])
            : null,
      );
      addTearDown(fixture.client.close);
      final course = (await (await fixture.login()).defaultCourse())!;
      final awaitingInput = Completer<void>();
      final answer = Completer<KlasQrVerificationAnswer?>();
      final checkIn = course.qrCheckIn(
        'qr',
        onVerification: (_) {
          awaitingInput.complete();
          return answer.future;
        },
      );
      await awaitingInput.future;
      try {
        expect(await course.listTasks(), isEmpty);
        await fixture.client.requestCaptchaImage();
        expect(fixture.calls(qrSubmitPath), isEmpty);
        expectAutomaticAttendanceHeaders(fixture.requests);
      } finally {
        answer.complete(
          const KlasQrVerificationAnswer(
            method: KlasQrVerificationMethod.otp,
            code: '012345',
          ),
        );
      }
      expect((await checkIn).accepted, isTrue);
      await course.listTasks();
      expectAutomaticAttendanceHeaders(fixture.requests);
    });
  });
}
