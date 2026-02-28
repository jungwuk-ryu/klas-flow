import 'dart:core';

import '../api/api_paths.dart';

/// KlasClient 동작 옵션입니다.
final class KlasClientConfig {
  /// KLAS 베이스 URL입니다.
  final Uri baseUri;

  /// HTTP 타임아웃입니다.
  final Duration timeout;

  /// 엔드포인트 경로 설정입니다.
  final ApiPaths apiPaths;

  /// 세션 만료 시 자동 재시도할 최대 횟수입니다.
  final int maxSessionRenewRetries;

  KlasClientConfig({
    Uri? baseUri,
    this.timeout = const Duration(seconds: 15),
    this.apiPaths = const ApiPaths(),
    this.maxSessionRenewRetries = 1,
  }) : baseUri = baseUri ?? Uri(scheme: 'https', host: 'klas.kw.ac.kr');
}
