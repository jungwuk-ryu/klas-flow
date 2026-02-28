import 'dart:typed_data';

import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

void main() {
  group('KlasTypedEndpoints', () {
    test('그룹 메서드는 카탈로그 경로로 위임된다', () async {
      String? lastPostPath;
      Map<String, dynamic>? lastPayload;
      String? lastGetPath;
      String? lastBinaryPath;

      final api = KlasReadOnlyApi(
        postJsonDynamic: (path, {payload, includeContext = false}) async {
          lastPostPath = path;
          lastPayload = payload;
          if (path == '/std/lis/evltn/TaskStdList.do') {
            return <dynamic>[];
          }
          return <String, dynamic>{};
        },
        postJsonText: (path, {payload, includeContext = false}) async => 'ok',
        postFormDynamic: (path, {payload, includeContext = false}) async =>
            <String, dynamic>{},
        postFormText: (path, {payload, includeContext = false}) async => 'ok',
        getJsonObject: (path, {query}) async {
          lastGetPath = path;
          return <String, dynamic>{'authenticated': true};
        },
        getText: (path, {query}) async => 'ok',
        getBinary: (path, {query}) async {
          lastBinaryPath = path;
          return FilePayload(bytes: Uint8List.fromList([1, 2, 3]));
        },
      );

      final endpoints = KlasTypedEndpoints(api);

      final tasks = await endpoints.learning.taskStdList(
        payload: {'currentPage': 0},
      );
      expect(tasks, isA<List<dynamic>>());
      expect(lastPostPath, equals('/std/lis/evltn/TaskStdList.do'));
      expect(lastPayload?['currentPage'], equals(0));

      final session = await endpoints.session.info();
      expect(session['authenticated'], isTrue);
      expect(lastGetPath, equals('/api/v1/session/info'));

      final file = await endpoints.file.downloadFile(
        pathParams: {'attachId': 'attach123', 'fileSn': '1'},
      );
      expect(file.bytes.length, equals(3));
      expect(lastBinaryPath, equals('/common/file/DownloadFile/attach123/1'));
    });
  });
}
