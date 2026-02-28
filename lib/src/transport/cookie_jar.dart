import 'package:http/http.dart' as http;

/// 세션 쿠키를 보관하고 요청 헤더로 직렬화한다.
final class CookieJar {
  final Map<String, String> _cookies = <String, String>{};

  /// 저장된 쿠키 헤더 문자열이다.
  String? get cookieHeader {
    if (_cookies.isEmpty) {
      return null;
    }
    return _cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  /// 응답의 Set-Cookie 값을 저장한다.
  void absorb(http.BaseResponse response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.trim().isEmpty) {
      return;
    }

    for (final cookieItem in _splitSetCookieHeader(setCookie)) {
      final pair = cookieItem.split(';').first.trim();
      if (pair.isEmpty || !pair.contains('=')) {
        continue;
      }
      final parts = pair.split('=');
      if (parts.isEmpty) {
        continue;
      }
      final name = parts.first.trim();
      final value = parts.sublist(1).join('=').trim();
      if (name.isEmpty) {
        continue;
      }

      if (value.isEmpty) {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
    }
  }

  /// 모든 쿠키를 비운다.
  void clear() => _cookies.clear();

  static List<String> _splitSetCookieHeader(String raw) {
    final items = <String>[];
    final buffer = StringBuffer();

    for (var index = 0; index < raw.length; index++) {
      final char = raw[index];
      if (char == ',' && _looksLikeCookieBoundary(raw, index)) {
        items.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }

    final tail = buffer.toString();
    if (tail.isNotEmpty) {
      items.add(tail);
    }
    return items;
  }

  static bool _looksLikeCookieBoundary(String value, int commaIndex) {
    final after = value.substring(commaIndex + 1).trimLeft();
    return after.contains('=') && !after.toLowerCase().startsWith('expires=');
  }
}
