import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

import 'support/mobile_qr_fixture.dart';
import 'support/team_project_fixture.dart';

void main() {
  group('Team project reads', () {
    test(
      'list maps both submission periods, status and course ownership',
      () async {
        final fixture = TeamProjectFixture();
        addTearDown(fixture.close);
        final course = await fixture.course();
        final projects = await course.teamProjects.listProjects();
        final project = projects.single;
        expect(project.id, '11/2');
        expect(project.number, 2);
        expect(project.courseId, course.courseId);
        expect(project.termId, course.termId);
        expect(project.teamNumber, 3);
        expect(project.displayTitle, '팀 프로젝트 연습');
        expect(project.startsAt, DateTime(2026, 10, 1, 9));
        expect(project.dueAt, DateTime(2026, 10, 20, 23, 59));
        expect(project.additionalStartsAt, DateTime(2026, 10, 21));
        expect(project.additionalDueAt, DateTime(2026, 10, 22, 23, 59));
        expect(project.submitted, isTrue);
        expect(project.isWithinSubmissionPeriod, isFalse);
        expect(project.isWithinAdditionalSubmissionPeriod, isTrue);
        expect(
          project.submissionVisibility,
          KlasTeamProjectSubmissionVisibility.private,
        );
        expect(jsonDecode(fixture.calls(projectListPath).single.body), {
          'selectYearhakgi': course.termId,
          'selectSubj': course.courseId,
          'selectChangeYn': 'N',
        });
      },
    );

    test(
      'a course with no projects returns an empty list without other reads',
      () async {
        final fixture = TeamProjectFixture(
          handle: (request) =>
              request.url.path == projectListPath ? qrJson([]) : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        expect(await course.teamProjects.listProjects(), isEmpty);
        expect(fixture.calls(projectDetailPath), isEmpty);
        expect(fixture.calls(projectMembersPath), isEmpty);
        expect(fixture.calls(projectFilesPath), isEmpty);
      },
    );

    test(
      'details preserve instruction HTML, submission text and zero scores',
      () async {
        final fixture = TeamProjectFixture();
        addTearDown(fixture.close);
        final course = await fixture.course();
        final project = (await course.teamProjects.listProjects()).single;
        final detail = await course.teamProjects.getDetail(project);
        expect(detail.project.id, project.id);
        expect(detail.contentHtml, projectDetailRow()['contents']);
        expect(detail.week, 7);
        expect(detail.session, 1);
        expect(detail.basicScore, 0);
        expect(detail.allowedFileTypes, 'PDF, ZIP');
        expect(detail.fileSizeLimitMegabytes, 20);
        expect(detail.isCurrentUserLeader, isTrue);
        expect(detail.submission!.title, '팀 제출물');
        expect(detail.submission!.content, '구현 내용\n\n역할 분담');
        expect(detail.submission!.score, 92.5);
        expect(detail.submission!.isSelectedAsBest, isFalse);
        expect(detail.submission!.instructorFeedback, '검토 의견\n수고했습니다.');
        final body = jsonDecode(fixture.calls(projectDetailPath).single.body);
        expect(body['searchTeamseq'], '11');
        expect(body['searchOrdseq'], '2');
        expect(body['searchTeamno'], '3');
        expect(body['selectSubj'], course.courseId);
        expect(body['selectYearhakgi'], course.termId);
      },
    );

    test(
      'all three attachment groups use their storage and support downloads',
      () async {
        final fixture = TeamProjectFixture();
        addTearDown(fixture.close);
        final course = await fixture.course();
        final detail = await course.teamProjects.getDetail(
          (await course.teamProjects.listProjects()).single,
        );
        final groups = fixture
            .calls(projectFilesPath)
            .map((request) => jsonDecode(request.body))
            .toList();
        expect(groups, [
          {'storageId': 'CLS_PROF_TEAM', 'attachId': 'synthetic-instructions'},
          {'storageId': 'CLS_STU_TEAM', 'attachId': 'synthetic-submission'},
          {'storageId': 'CLS_PROF_TEAM_ADD', 'attachId': 'synthetic-feedback'},
        ]);
        for (final file in [
          detail.files.single,
          detail.submission!.files.single,
          detail.submission!.feedbackFiles.single,
        ]) {
          expect((await file.download()).bytes, [1, 2, 3]);
        }
        expect(
          fixture.requests.where(
            (request) =>
                request.method == 'GET' &&
                request.url.path.startsWith('/common/file/DownloadFile/'),
          ),
          hasLength(3),
        );
      },
    );

    test(
      'includeFiles false reads all text without fetching file metadata',
      () async {
        final fixture = TeamProjectFixture();
        addTearDown(fixture.close);
        final course = await fixture.course();
        final detail = await course.teamProjects.getDetail(
          (await course.teamProjects.listProjects()).single,
          includeFiles: false,
        );
        expect(detail.contentHtml, isNotNull);
        expect(detail.submission!.content, isNotNull);
        expect(detail.files, isEmpty);
        expect(detail.submission!.files, isEmpty);
        expect(detail.submission!.feedbackFiles, isEmpty);
        expect(fixture.calls(projectFilesPath), isEmpty);
      },
    );

    test(
      'missing submitted work and attachment IDs remain empty without file requests',
      () async {
        final fixture = TeamProjectFixture(
          handle: (request) => request.url.path == projectDetailPath
              ? qrJson({
                  'prjctDetail': {
                    ...projectDetailRow(),
                    'submityn': 'N',
                    'atchFileId': null,
                  },
                  'rptDetail': null,
                  'isLeader': 'N',
                })
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        final detail = await course.teamProjects.getDetail(
          (await course.teamProjects.listProjects()).single,
        );
        expect(detail.project.submitted, isFalse);
        expect(detail.submission, isNull);
        expect(detail.isCurrentUserLeader, isFalse);
        expect(detail.files, isEmpty);
        expect(fixture.calls(projectFilesPath), isEmpty);
      },
    );

    test('member roles, contact fields and missing values are typed', () async {
      final fixture = TeamProjectFixture();
      addTearDown(fixture.close);
      final course = await fixture.course();
      final members = await course.teamProjects.listMembers(
        (await course.teamProjects.listProjects()).single,
      );
      expect(members, hasLength(2));
      expect(members.first.name, '팀장 테스트');
      expect(members.first.department, '테스트학과');
      expect(members.first.studentId, 'synthetic-001');
      expect(members.first.email, 'leader@example.com');
      expect(members.first.teamNumber, 3);
      expect(members.first.isLeader, isTrue);
      expect(members.last.isLeader, isFalse);
      expect(members.last.email, isNull);
    });

    test(
      'an unassigned team returns no members without a member request',
      () async {
        final fixture = TeamProjectFixture(
          handle: (request) => request.url.path == projectListPath
              ? qrJson([
                  {...projectRow(), 'teamno': null},
                ])
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        final project = (await course.teamProjects.listProjects()).single;
        expect(project.teamNumber, isNull);
        expect(await course.teamProjects.listMembers(project), isEmpty);
        expect(fixture.calls(projectMembersPath), isEmpty);
      },
    );

    test(
      'detail and member reads reject another course or term before any request',
      () async {
        final fixture = TeamProjectFixture();
        addTearDown(fixture.close);
        final course = await fixture.course();
        final count = fixture.requests.length;
        for (final other in [
          KlasTeamProject(
            id: '11/2',
            courseId: 'OTHER',
            termId: course.termId,
            number: 2,
          ),
          KlasTeamProject(
            id: '11/2',
            courseId: course.courseId,
            termId: '20262',
            number: 2,
          ),
          KlasTeamProject(
            id: '',
            courseId: course.courseId,
            termId: course.termId,
            number: 2,
          ),
        ]) {
          await expectLater(
            course.teamProjects.getDetail(other),
            throwsArgumentError,
          );
          await expectLater(
            course.teamProjects.listMembers(other),
            throwsArgumentError,
          );
        }
        expect(fixture.requests, hasLength(count));
      },
    );

    test(
      'stale caller fields cannot redirect a member read to another team',
      () async {
        final fixture = TeamProjectFixture();
        addTearDown(fixture.close);
        final course = await fixture.course();
        final fabricated = KlasTeamProject(
          id: '11/2',
          courseId: course.courseId,
          termId: course.termId,
          number: 99,
          teamNumber: 999,
        );
        await course.teamProjects.listMembers(fabricated);
        final body = jsonDecode(fixture.calls(projectMembersPath).single.body);
        expect(body['searchOrdseq'], '2');
        expect(body['searchTeamno'], '3');
      },
    );

    test(
      'removed project references fail without detail or member calls',
      () async {
        var available = true;
        final fixture = TeamProjectFixture(
          handle: (request) => request.url.path == projectListPath
              ? qrJson(available ? [projectRow()] : [])
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        final project = (await course.teamProjects.listProjects()).single;
        available = false;
        await expectLater(
          course.teamProjects.getDetail(project),
          throwsA(isA<TeamProjectUnavailableException>()),
        );
        await expectLater(
          course.teamProjects.listMembers(project),
          throwsA(isA<TeamProjectUnavailableException>()),
        );
        expect(fixture.calls(projectDetailPath), isEmpty);
        expect(fixture.calls(projectMembersPath), isEmpty);
      },
    );

    test(
      'duplicate project references are rejected before secondary requests',
      () async {
        final fixture = TeamProjectFixture(
          handle: (request) => request.url.path == projectListPath
              ? qrJson([projectRow(), projectRow()])
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        await expectLater(
          course.teamProjects.listProjects(),
          throwsA(isA<ParsingException>()),
        );
      },
    );

    for (final value in [
      null,
      {},
      'invalid',
      [23],
      [
        {'title': 'No identifier'},
      ],
    ]) {
      test(
        'malformed project list is an error rather than an empty result ($value)',
        () async {
          final fixture = TeamProjectFixture(
            handle: (request) =>
                request.url.path == projectListPath ? qrJson(value) : null,
          );
          addTearDown(fixture.close);
          final course = await fixture.course();
          await expectLater(
            course.teamProjects.listProjects(),
            throwsA(isA<ParsingException>()),
          );
        },
      );
    }

    test(
      'single data wrappers are accepted without accepting error objects',
      () async {
        final fixture = TeamProjectFixture(
          handle: (request) {
            if (request.url.path == projectListPath) {
              return qrJson({
                'data': [projectRow()],
              });
            }
            if (request.url.path == projectDetailPath) {
              return qrJson({
                'data': {
                  'prjctDetail': projectDetailRow(),
                  'rptDetail': null,
                  'isLeader': 'Y',
                },
              });
            }
            if (request.url.path == projectMembersPath) {
              return qrJson({'data': []});
            }
            return null;
          },
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        final project = (await course.teamProjects.listProjects()).single;
        expect(
          (await course.teamProjects.getDetail(
            project,
            includeFiles: false,
          )).contentHtml,
          isNotNull,
        );
        expect(await course.teamProjects.listMembers(project), isEmpty);
      },
    );

    for (final value in [null, {}]) {
      test(
        'missing project detail is reported as unavailable ($value)',
        () async {
          final fixture = TeamProjectFixture(
            handle: (request) => request.url.path == projectDetailPath
                ? qrJson({'prjctDetail': value, 'rptDetail': null})
                : null,
          );
          addTearDown(fixture.close);
          final course = await fixture.course();
          await expectLater(
            course.teamProjects.getDetail(
              (await course.teamProjects.listProjects()).single,
            ),
            throwsA(isA<TeamProjectUnavailableException>()),
          );
          expect(fixture.calls(projectFilesPath), isEmpty);
        },
      );
    }

    for (final response in [
      {'error': 'unavailable'},
      {'prjctDetail': []},
      {'prjctDetail': projectDetailRow(), 'rptDetail': []},
      {
        'prjctDetail': {...projectDetailRow(), 'teamseq': 999},
      },
      {
        'prjctDetail': {...projectDetailRow(), 'ordseq': 999},
      },
      {
        'prjctDetail': {...projectDetailRow(), 'teamno': 999},
      },
      {
        'prjctDetail': {...projectDetailRow(), 'selectSubj': 'OTHER'},
      },
    ]) {
      test(
        'malformed or mismatched details cannot trigger file reads (${response.keys})',
        () async {
          final fixture = TeamProjectFixture(
            handle: (request) =>
                request.url.path == projectDetailPath ? qrJson(response) : null,
          );
          addTearDown(fixture.close);
          final course = await fixture.course();
          await expectLater(
            course.teamProjects.getDetail(
              (await course.teamProjects.listProjects()).single,
            ),
            throwsA(isA<ParsingException>()),
          );
          expect(fixture.calls(projectFilesPath), isEmpty);
        },
      );
    }

    test(
      'numeric identifiers stay stable when list and detail use different padding',
      () async {
        final fixture = TeamProjectFixture(
          handle: (request) => request.url.path == projectListPath
              ? qrJson([
                  {...projectRow(), 'teamseq': '0011', 'ordseq': '02'},
                ])
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        final project = (await course.teamProjects.listProjects()).single;
        expect(project.id, '11/2');
        expect(
          (await course.teamProjects.getDetail(
            project,
            includeFiles: false,
          )).project.id,
          project.id,
        );
      },
    );

    for (final response in [
      null,
      {'error': 'unavailable'},
      [42],
      [
        {'name': 'Other team', 'teamno': 999},
      ],
    ]) {
      test(
        'invalid or mismatched member responses are errors ($response)',
        () async {
          final fixture = TeamProjectFixture(
            handle: (request) => request.url.path == projectMembersPath
                ? qrJson(response)
                : null,
          );
          addTearDown(fixture.close);
          final course = await fixture.course();
          await expectLater(
            course.teamProjects.listMembers(
              (await course.teamProjects.listProjects()).single,
            ),
            throwsA(isA<ParsingException>()),
          );
        },
      );
    }

    test(
      'invalid flags and optional numbers remain unknown; zero is preserved',
      () async {
        final fixture = TeamProjectFixture(
          handle: (request) => request.url.path == projectDetailPath
              ? qrJson({
                  'prjctDetail': {
                    ...projectDetailRow(),
                    'indate': '?',
                    'adddate': null,
                    'submityn': '?',
                    'isopen': 'unexpected',
                    'filelimit': 'NaN',
                    'basicscore': '0',
                  },
                  'rptDetail': {
                    ...projectSubmissionRow(),
                    'finalscore': '0',
                    'isbestreport': '?',
                  },
                  'isLeader': '?',
                })
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        final detail = await course.teamProjects.getDetail(
          (await course.teamProjects.listProjects()).single,
          includeFiles: false,
        );
        expect(detail.project.submitted, isNull);
        expect(detail.project.isWithinSubmissionPeriod, isNull);
        expect(detail.project.isWithinAdditionalSubmissionPeriod, isNull);
        expect(detail.project.submissionVisibility, isNull);
        expect(detail.basicScore, 0);
        expect(detail.fileSizeLimitMegabytes, isNull);
        expect(detail.isCurrentUserLeader, isNull);
        expect(detail.submission!.score, 0);
        expect(detail.submission!.isSelectedAsBest, isNull);
      },
    );

    test(
      'deadlines accept valid leap dates and reject calendar rollover',
      () async {
        final values = [
          '20240229235959',
          '2024-02-29 23:59:59',
          '202602302359',
          '202613012400',
          '',
          null,
        ];
        final fixture = TeamProjectFixture(
          handle: (request) => request.url.path == projectListPath
              ? qrJson([
                  for (var i = 0; i < values.length; i++)
                    {...projectRow(), 'ordseq': i + 1, 'expiredate': values[i]},
                ])
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        final projects = await course.teamProjects.listProjects();
        expect(projects[0].dueAt, DateTime(2024, 2, 29, 23, 59, 59));
        expect(projects[1].dueAt, projects[0].dueAt);
        expect(
          projects.skip(2).map((project) => project.dueAt),
          everyElement(isNull),
        );
      },
    );

    test(
      'ISO deadlines preserve fractional seconds and time zone offsets',
      () async {
        final values = [
          '2026-10-20T23:59:59.123+09:00',
          '2026-10-20T14:59:59.123Z',
          '2026-02-30T23:59:59Z',
          '2026-10-20T23:59:59+24:00',
          '2026-10-20T23:59:59+09:60',
        ];
        final fixture = TeamProjectFixture(
          handle: (request) => request.url.path == projectListPath
              ? qrJson([
                  for (var i = 0; i < values.length; i++)
                    {...projectRow(), 'ordseq': i + 1, 'expiredate': values[i]},
                ])
              : null,
        );
        addTearDown(fixture.close);
        final course = await fixture.course();
        final projects = await course.teamProjects.listProjects();
        expect(projects[0].dueAt, DateTime.utc(2026, 10, 20, 14, 59, 59, 123));
        expect(projects[1].dueAt, projects[0].dueAt);
        expect(projects.skip(2).map((p) => p.dueAt), everyElement(isNull));
      },
    );

    test('server failure is distinct from a course with no projects', () async {
      final fixture = TeamProjectFixture(
        handle: (request) => request.url.path == projectListPath
            ? http.Response('unavailable', 500)
            : null,
      );
      addTearDown(fixture.close);
      final course = await fixture.course();
      await expectLater(
        course.teamProjects.listProjects(),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });

    test(
      'reads use no submission, upload, team-edit or attendance operations',
      () async {
        final fixture = TeamProjectFixture();
        addTearDown(fixture.close);
        final course = await fixture.course();
        final project = (await course.teamProjects.listProjects()).single;
        await course.teamProjects.getDetail(project);
        await course.teamProjects.listMembers(project);
        final allowed = {...projectReadPaths, projectFilesPath};
        final reads = fixture.requests.where(
          (request) => allowed.contains(request.url.path),
        );
        expect(reads, isNotEmpty);
        expect(
          reads.every(
            (request) =>
                request.method == 'POST' &&
                request.headers['content-type']!.contains('application/json') &&
                request.headers['user-agent'] == null,
          ),
          isTrue,
        );
        expect(
          fixture.requests.where(
            (request) =>
                request.url.path.startsWith('/std/lis/evltn/') &&
                !projectReadPaths.contains(request.url.path),
          ),
          isEmpty,
        );
      },
    );
  });
}
