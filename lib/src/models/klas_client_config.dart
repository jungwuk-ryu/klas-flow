import 'dart:core';

import '../api/api_paths.dart';

/// KlasClient 동작 옵션이다.
final class KlasClientConfig {
  /// KLAS 베이스 URL이다.
  final Uri baseUri;

  /// HTTP 타임아웃이다.
  final Duration timeout;

  /// 엔드포인트 경로 설정이다.
  final ApiPaths apiPaths;

  KlasClientConfig({
    Uri? baseUri,
    this.timeout = const Duration(seconds: 15),
    this.apiPaths = const ApiPaths(),
  }) : baseUri = baseUri ?? Uri(scheme: 'https', host: 'klas.kw.ac.kr');
}
