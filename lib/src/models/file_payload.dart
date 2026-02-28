import 'dart:typed_data';

/// 바이너리 파일 다운로드 결과입니다.
final class FilePayload {
  /// 파일 바이트입니다.
  final Uint8List bytes;

  /// MIME 타입입니다.
  final String? contentType;

  /// 파일명입니다.
  final String? fileName;

  const FilePayload({required this.bytes, this.contentType, this.fileName});
}
