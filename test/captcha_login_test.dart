import 'package:http/http.dart' as http;
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

import 'support/captcha_login_mock.dart';

void main() {
  for (final pem in [true, false]) {
    test(
      'captcha count resumes ${pem ? 'PEM' : 'legacy'} login with answer and cookies',
      () async {
        var confirmations = 0;
        final checks = <String>[];
        final client = captchaTestClient(
          pem: pem,
          respond: (request) async {
            if (request.url.path.endsWith('/LoginCaptcha.do')) {
              checks.add(
                captchaLoginFields(request)['captcha']?.toString() ?? '',
              );
              return captchaJson(3);
            }
            if (request.url.path.endsWith('/captchaImg.do')) {
              expect(request.url.queryParameters['ran'], isNotEmpty);
            }
            if (request.url.path.endsWith('/LoginConfirm.do')) {
              confirmations++;
              expect(captchaLoginFields(request)['captcha'], '007123');
              expect(request.headers['cookie'], contains('challenge=fixture'));
            }
            return null;
          },
        );
        addTearDown(client.close);
        final user = await client.login(
          'test-user',
          'test-password',
          onCaptcha: (challenge) {
            expect(challenge.image.bytes, [1, 2, 3]);
            expect(challenge.attempt, 1);
            expect(challenge.maxAttempts, 3);
            return '007123';
          },
        );
        expect(user.id, 'test-user');
        expect(checks, ['', '007123']);
        expect(confirmations, 1);
      },
    );
  }

  test(
    'confirmation challenges refresh the image after a wrong answer',
    () async {
      var images = 0;
      final answers = <String>[];
      final client = captchaTestClient(
        respond: (request) async {
          if (request.url.path.endsWith('/captchaImg.do')) {
            images++;
            return http.Response.bytes(
              [images],
              200,
              headers: {'content-type': 'image/png'},
            );
          }
          if (request.url.path.endsWith('/LoginConfirm.do')) {
            final answer = captchaLoginFields(request)['captcha'] as String;
            answers.add(answer);
            if (answer != '002222') {
              return captchaJson({
                'errorCount': 1,
                'message': '자동 입력 방지 숫자를 확인하세요.',
              });
            }
          }
          return null;
        },
      );
      addTearDown(client.close);
      await client.login(
        'test-user',
        'test-password',
        onCaptcha: (challenge) {
          expect(challenge.image.bytes.single, challenge.attempt);
          return challenge.attempt == 1 ? '111111' : '002222';
        },
      );
      expect(answers, ['', '111111', '002222']);
      expect(images, 2);
    },
  );

  test(
    'missing handler reports captcha and stops before password confirmation',
    () async {
      final paths = <String>[];
      final client = captchaTestClient(
        respond: (request) async {
          paths.add(request.url.path);
          return request.url.path.endsWith('/LoginCaptcha.do')
              ? captchaJson(3)
              : null;
        },
      );
      addTearDown(client.close);
      await expectLater(
        client.login('test-user', 'test-password'),
        throwsA(isA<CaptchaRequiredException>()),
      );
      expect(paths.any((path) => path.endsWith('/LoginConfirm.do')), isFalse);
      expect(paths.any((path) => path.endsWith('/captchaImg.do')), isFalse);
    },
  );

  test('rejected captcha answers stop at the configured bound', () async {
    var prompts = 0;
    var confirmations = 0;
    final client = captchaTestClient(
      respond: (request) async {
        if (request.url.path.endsWith('/LoginConfirm.do')) {
          confirmations++;
          return captchaJson({'errorCount': 1, 'captchaRequired': true});
        }
        return null;
      },
    );
    addTearDown(client.close);
    await expectLater(
      client.login(
        'test-user',
        'test-password',
        maxCaptchaAttempts: 2,
        onCaptcha: (challenge) {
          prompts++;
          return '1234';
        },
      ),
      throwsA(isA<CaptchaRequiredException>()),
    );
    expect(prompts, 2);
    expect(confirmations, 3);
  });

  for (final answer in <String?>[null, '', '   ']) {
    test('cancelled captcha input does not submit another login', () async {
      var checks = 0;
      final client = captchaTestClient(
        respond: (request) async {
          if (request.url.path.endsWith('/LoginCaptcha.do')) {
            checks++;
            return captchaJson(3);
          }
          return null;
        },
      );
      addTearDown(client.close);
      await expectLater(
        client.login('test-user', 'test-password', onCaptcha: (_) => answer),
        throwsA(isA<CaptchaRequiredException>()),
      );
      expect(checks, 1);
    });
  }

  test('non-numeric answers fail locally without sending them', () async {
    var checks = 0;
    final client = captchaTestClient(
      respond: (request) async {
        if (request.url.path.endsWith('/LoginCaptcha.do')) {
          checks++;
          return captchaJson(3);
        }
        return null;
      },
    );
    addTearDown(client.close);
    await expectLater(
      client.login('test-user', 'test-password', onCaptcha: (_) => '12a3'),
      throwsA(isA<FormatException>()),
    );
    expect(checks, 1);
  });

  test('invalid retry limits fail before network access', () async {
    var calls = 0;
    final client = captchaTestClient(
      respond: (request) async {
        calls++;
        return null;
      },
    );
    addTearDown(client.close);
    await expectLater(
      client.login('test-user', 'test-password', maxCaptchaAttempts: 0),
      throwsRangeError,
    );
    expect(calls, 0);
  });

  test(
    'invalid credentials remain credential failures without captcha prompts',
    () async {
      final client = captchaTestClient(
        respond: (request) async =>
            request.url.path.endsWith('/LoginConfirm.do')
            ? captchaJson({'errorCount': 1, 'message': '비밀번호를 확인하세요.'})
            : null,
      );
      addTearDown(client.close);
      await expectLater(
        client.login(
          'test-user',
          'test-password',
          onCaptcha: (_) => fail('must not prompt'),
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
    },
  );

  test(
    'image service failures propagate without calling the handler',
    () async {
      final client = captchaTestClient(
        respond: (request) async {
          if (request.url.path.endsWith('/LoginCaptcha.do')) {
            return captchaJson(3);
          }
          if (request.url.path.endsWith('/captchaImg.do')) {
            return http.Response('unavailable', 503);
          }
          return null;
        },
      );
      addTearDown(client.close);
      await expectLater(
        client.login(
          'test-user',
          'test-password',
          onCaptcha: (_) => fail('must not prompt'),
        ),
        throwsA(isA<ServiceUnavailableException>()),
      );
    },
  );

  test('empty images fail before asking for an unreadable captcha', () async {
    final client = captchaTestClient(
      respond: (request) async {
        if (request.url.path.endsWith('/LoginCaptcha.do')) {
          return captchaJson(3);
        }
        if (request.url.path.endsWith('/captchaImg.do')) {
          return http.Response.bytes(
            [],
            200,
            headers: {'content-type': 'image/png'},
          );
        }
        return null;
      },
    );
    addTearDown(client.close);
    await expectLater(
      client.login(
        'test-user',
        'test-password',
        onCaptcha: (_) => fail('must not prompt'),
      ),
      throwsA(isA<ParsingException>()),
    );
  });

  test(
    'session renewal can request captcha and preserves the selected course',
    () async {
      var confirmations = 0;
      var taskCalls = 0;
      var prompts = 0;
      final client = captchaTestClient(
        respond: (request) async {
          if (request.url.path.endsWith('/LoginCaptcha.do')) {
            return captchaJson(confirmations == 0 ? 0 : 3);
          }
          if (request.url.path.endsWith('/LoginConfirm.do')) confirmations++;
          if (request.url.path.endsWith('/TaskStdList.do')) {
            taskCalls++;
            if (taskCalls == 1) return http.Response('', 419);
            expect(captchaLoginFields(request)['selectSubj'], 'CSE102');
          }
          return null;
        },
      );
      addTearDown(client.close);
      final user = await client.login(
        'test-user',
        'test-password',
        onCaptcha: (_) {
          prompts++;
          return '1234';
        },
      );
      final course = (await user.courses()).last;
      await course.listTasks();
      expect(prompts, 1);
      expect(confirmations, 2);
      expect(taskCalls, 2);
    },
  );
}
