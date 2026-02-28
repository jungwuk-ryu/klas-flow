import 'dart:typed_data';

/// 바이너리 파일 다운로드 결과다.
final class FilePayload {
  /// 파일 바이트다.
  final Uint8List bytes;

  /// MIME 타입이다.
  final String? contentType;

  /// 파일명이다.
  final String? fileName;

  const FilePayload({required this.bytes, this.contentType, this.fileName});
}
