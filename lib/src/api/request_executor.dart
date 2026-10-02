import 'dart:convert';

import '../context/context_manager.dart';
import '../exceptions/klas_exceptions.dart';
import '../models/file_payload.dart';
import '../auth/session_coordinator.dart';
import '../transport/transport.dart';

/// Transport 호출과 payload/context 병합을 담당합니다.
final class RequestExecutor {
  final KlasTransport _transport;
  final ContextManager _contextManager;
  final SessionCoordinator _sessionCoordinator;

  RequestExecutor({
    required KlasTransport transport,
    required ContextManager contextManager,
    required SessionCoordinator sessionCoordinator,
  }) : _transport = transport,
       _contextManager = contextManager,
       _sessionCoordinator = sessionCoordinator;

  Future<Object?> postJsonDynamic(
    String path, {
    Map<String, dynamic>? payload,
    required bool includeContext,
    Map<String, String>? headers,
  }) {
    return _sessionCoordinator.withAutoRenewal(() async {
      final merged = _mergePayload(payload, includeContext: includeContext);
      final response = await _transport.postJsonDynamic(
        path,
        json: merged,
        headers: headers,
      );
      return response.body;
    });
  }

  /// 일회용 인증 코드나 상태 변경 요청을 세션 갱신으로 재전송하지 않습니다.
  Future<Object?> postJsonDynamicOnce(
    String path, {
    required Map<String, dynamic> payload,
    Map<String, String>? headers,
  }) async {
    final response = await _transport.postJsonDynamic(
      path,
      json: payload,
      headers: headers,
    );
    return response.body;
  }

  Future<String> postJsonText(
    String path, {
    Map<String, dynamic>? payload,
    required bool includeContext,
    Map<String, String>? headers,
  }) {
    return _sessionCoordinator.withAutoRenewal(() async {
      final merged = _mergePayload(payload, includeContext: includeContext);
      final response = await _transport.postJsonText(
        path,
        json: merged,
        headers: headers,
      );
      return response.body;
    });
  }

  Future<Object?> postFormDynamic(
    String path, {
    Map<String, dynamic>? payload,
    required bool includeContext,
  }) {
    return _sessionCoordinator.withAutoRenewal(() async {
      final merged = _mergePayload(payload, includeContext: includeContext);
      final response = await _transport.postFormText(
        path,
        form: _toFormData(merged),
      );
      return _decodeJsonString(response.body);
    });
  }

  Future<String> postFormText(
    String path, {
    Map<String, dynamic>? payload,
    required bool includeContext,
  }) {
    return _sessionCoordinator.withAutoRenewal(() async {
      final merged = _mergePayload(payload, includeContext: includeContext);
      final response = await _transport.postFormText(
        path,
        form: _toFormData(merged),
      );
      return response.body;
    });
  }

  /// 재생 키 생성과 진행률 저장은 세션 갱신으로 다시 실행하지 않습니다.
  Future<String> postFormTextOnce(
    String path, {
    required Map<String, String> form,
  }) async {
    final response = await _transport.postFormText(path, form: form);
    return response.body;
  }

  /// 미디어 메타데이터를 KLAS 세션 쿠키 없이 조회합니다.
  Future<String> getPublicText(Uri uri) => _transport.getPublicText(uri);

  Future<Map<String, dynamic>> getJsonObject(
    String path, {
    Map<String, String>? query,
  }) {
    return _sessionCoordinator.withAutoRenewal(() async {
      final response = await _transport.getJson(path, query: query);
      return response.body;
    });
  }

  Future<String> getText(String path, {Map<String, String>? query}) {
    return _sessionCoordinator.withAutoRenewal(() async {
      final response = await _transport.getText(path, query: query);
      return response.body;
    });
  }

  Future<FilePayload> getBinary(String path, {Map<String, String>? query}) {
    return _sessionCoordinator.withAutoRenewal(() async {
      final response = await _transport.download(path, query: query);
      return response.body;
    });
  }

  Map<String, dynamic> _mergePayload(
    Map<String, dynamic>? payload, {
    required bool includeContext,
  }) {
    if (!includeContext) {
      return <String, dynamic>{if (payload != null) ...payload};
    }
    return _contextManager.mergeJson(payload);
  }

  Map<String, String> _toFormData(Map<String, dynamic> payload) {
    final form = <String, String>{};
    payload.forEach((key, value) {
      if (value == null) {
        return;
      }
      form[key] = value.toString();
    });
    return form;
  }

  Object? _decodeJsonString(String source) {
    try {
      return jsonDecode(source);
    } catch (error, stackTrace) {
      throw ParsingException(
        'Failed to parse JSON response from form request.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
