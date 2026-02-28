import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/src/api/api_paths.dart';
import 'package:klasflow/src/api/context_api.dart';
import 'package:klasflow/src/transport/transport.dart';
import 'package:test/test.dart';

void main() {
  group('ContextApi', () {
    test('Yearhakgi API(year/subjList 구조)를 CourseContext로 펼친다', () async {
      final mock = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(
          request.url.path,
          equals('/std/cmn/frame/YearhakgiAtnlcSbjectList.do'),
        );
        expect(request.body, equals('{}'));

        return http.Response(
          jsonEncode([
            {
              'value': '2024,1',
              'label': '2024년도 1학기',
              'subjList': [
                {'value': 'SUBJ-001', 'label': '알고리즘'},
                {'value': 'SUBJ-002', 'label': '운영체제'},
              ],
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final transport = KlasTransport(
        baseUri: Uri.parse('https://example.com'),
        timeout: const Duration(seconds: 5),
        httpClient: mock,
        ownsHttpClient: false,
      );
      final api = ContextApi(transport, const ApiPaths());

      final contexts = await api.fetchCourseContexts();
      expect(contexts, hasLength(2));
      expect(contexts.first.selectYearhakgi, equals('2024,1'));
      expect(contexts.first.selectSubj, equals('SUBJ-001'));
      expect(contexts.first.subjectName, contains('알고리즘'));
      expect(contexts.first.selectChangeYn, equals('Y'));
    });

    test('기존 data 배열 구조도 그대로 파싱한다', () async {
      final mock = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'selectYearhakgi': '2026,1',
                'selectSubj': 'SUBJ-100',
                'selectChangeYn': 'N',
                'isDefault': true,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final transport = KlasTransport(
        baseUri: Uri.parse('https://example.com'),
        timeout: const Duration(seconds: 5),
        httpClient: mock,
        ownsHttpClient: false,
      );
      final api = ContextApi(transport, const ApiPaths());

      final contexts = await api.fetchCourseContexts();
      expect(contexts, hasLength(1));
      expect(contexts.first.selectYearhakgi, equals('2026,1'));
      expect(contexts.first.selectSubj, equals('SUBJ-100'));
      expect(contexts.first.selectChangeYn, equals('N'));
    });
  });
}
