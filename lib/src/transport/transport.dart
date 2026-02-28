import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../exceptions/klas_exceptions.dart';
import '../models/file_payload.dart';
import 'cookie_jar.dart';
import 'transport_response.dart';

/// 쿠키 세션을 유지하며 JSON/HTML/파일 응답을 분리 처리한다.
final class KlasTransport {
  final Uri _baseUri;
  final Duration _timeout;
  final CookieJar _cookieJar;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  KlasTransport({
    required Uri baseUri,
    required Duration timeout,
    required http.Client httpClient,
    required bool ownsHttpClient,
    CookieJar? cookieJar,
  }) : _baseUri = baseUri,
       _timeout = timeout,
       _httpClient = httpClient,
       _ownsHttpClient = ownsHttpClient,
       _cookieJar = cookieJar ?? CookieJar();

  /// JSON GET 요청을 수행한다.
  Future<TransportResponse<Map<String, dynamic>>> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _request(
      method: 'GET',
      path: path,
      query: query,
      headers: headers,
    );
    return TransportResponse<Map<String, dynamic>>(
      statusCode: response.statusCode,
      headers: response.headers,
      body: _decodeJson(response),
    );
  }

  /// JSON 폼 POST 요청을 수행한다.
  Future<TransportResponse<Map<String, dynamic>>> postFormJson(
    String path, {
    Map<String, String>? form,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _request(
      method: 'POST',
      path: path,
      query: query,
      form: form,
      headers: headers,
    );
    return TransportResponse<Map<String, dynamic>>(
      statusCode: response.statusCode,
      headers: response.headers,
      body: _decodeJson(response),
    );
  }

  /// 문자열 응답 GET 요청을 수행한다.
  Future<TransportResponse<String>> getText(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _request(
      method: 'GET',
      path: path,
      query: query,
      headers: headers,
    );
    return TransportResponse<String>(
      statusCode: response.statusCode,
      headers: response.headers,
      body: _decodeText(response),
    );
  }

  /// 문자열 응답 폼 POST 요청을 수행한다.
  Future<TransportResponse<String>> postFormText(
    String path, {
    Map<String, String>? form,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _request(
      method: 'POST',
      path: path,
      query: query,
      form: form,
      headers: headers,
    );
    return TransportResponse<String>(
      statusCode: response.statusCode,
      headers: response.headers,
      body: _decodeText(response),
    );
  }

  /// 바이너리 파일을 다운로드한다.
  Future<TransportResponse<FilePayload>> download(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _request(
      method: 'GET',
      path: path,
      query: query,
      headers: headers,
    );
    final bytes = Uint8List.fromList(response.bodyBytes);

    return TransportResponse<FilePayload>(
      statusCode: response.statusCode,
      headers: response.headers,
      body: FilePayload(
        bytes: bytes,
        contentType: response.headers['content-type'],
        fileName: _readFileName(response.headers['content-disposition']),
      ),
    );
  }

  /// 세션 쿠키를 제거한다.
  void clearSession() => _cookieJar.clear();

  /// 내부 HTTP 클라이언트를 정리한다.
  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    Map<String, String>? query,
    Map<String, String>? form,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, query);

    final mergedHeaders = <String, String>{
      'Accept': 'application/json, text/html;q=0.9, */*;q=0.8',
      if (headers != null) ...headers,
    };

    final cookieHeader = _cookieJar.cookieHeader;
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      mergedHeaders['Cookie'] = cookieHeader;
    }

    if (method == 'POST') {
      mergedHeaders.putIfAbsent(
        'Content-Type',
        () => 'application/x-www-form-urlencoded; charset=utf-8',
      );
    }

    try {
      final response = switch (method) {
        'GET' =>
          await _httpClient.get(uri, headers: mergedHeaders).timeout(_timeout),
        'POST' =>
          await _httpClient
              .post(
                uri,
                headers: mergedHeaders,
                body: form ?? const <String, String>{},
              )
              .timeout(_timeout),
        _ => throw ArgumentError('Unsupported HTTP method: $method'),
      };

      _cookieJar.absorb(response);
      _validateStatus(response);

      if (_looksLikeSessionExpired(response)) {
        throw const SessionExpiredException(
          'Session expired or authentication is no longer valid.',
        );
      }

      return response;
    } on KlasException {
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      throw NetworkException(
        'Request timed out: $uri',
        cause: error,
        stackTrace: stackTrace,
      );
    } on SocketException catch (error, stackTrace) {
      throw NetworkException(
        'Network connection failed: $uri',
        cause: error,
        stackTrace: stackTrace,
      );
    } on http.ClientException catch (error, stackTrace) {
      throw NetworkException(
        'HTTP client exception occurred: $uri',
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw NetworkException(
        'Unknown network error occurred: $uri',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final resolved = _baseUri.resolve(path);
    if (query == null || query.isEmpty) {
      return resolved;
    }
    return resolved.replace(
      queryParameters: {...resolved.queryParameters, ...query},
    );
  }

  void _validateStatus(http.Response response) {
    if (response.statusCode == 401 ||
        response.statusCode == 419 ||
        response.statusCode == 440) {
      throw const SessionExpiredException(
        'Authentication required or session expired.',
      );
    }

    if (response.statusCode >= 500) {
      throw ServiceUnavailableException(
        'Service unavailable: HTTP ${response.statusCode}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NetworkException('Request failed: HTTP ${response.statusCode}');
    }
  }

  bool _looksLikeSessionExpired(http.Response response) {
    final lowerBody = _decodeText(response).toLowerCase();
    return lowerBody.contains('session expired') ||
        lowerBody.contains('세션이 만료') ||
        lowerBody.contains('re-login');
  }

  String _decodeText(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } catch (_) {
      return response.body;
    }
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    try {
      final decoded = jsonDecode(_decodeText(response));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const ParsingException('Top-level JSON value must be an object.');
    } on KlasException {
      rethrow;
    } catch (error, stackTrace) {
      throw ParsingException(
        'Failed to parse JSON response.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? _readFileName(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) {
      return null;
    }

    final filenameStar = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (filenameStar != null) {
      return Uri.decodeComponent(filenameStar.group(1)!);
    }

    final filename = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (filename != null) {
      return filename.group(1);
    }
    return null;
  }
}
