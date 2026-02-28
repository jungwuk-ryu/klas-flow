/// 로그인 세션 정보를 담는 모델입니다.
final class SessionInfo {
  /// 학번 또는 사용자 식별자입니다.
  final String? userId;

  /// 사용자 이름입니다.
  final String? userName;

  /// 세션 유효 여부입니다.
  final bool authenticated;

  /// 원본 응답 데이터입니다.
  final Map<String, dynamic> raw;

  const SessionInfo({
    required this.authenticated,
    required this.raw,
    this.userId,
    this.userName,
  });

  /// JSON으로부터 SessionInfo를 생성합니다.
  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    final normalized = _normalize(json);
    return SessionInfo(
      authenticated: _readBool(normalized, const [
        'authenticated',
        'isAuthenticated',
        'isLogin',
        'sessionAlive',
        'remainingTime',
        'logoutCountDownSec',
      ]),
      userId: _readString(normalized, const ['userId', 'id', 'studentNo']),
      userName: _readString(normalized, const ['userName', 'name', 'nm']),
      raw: json,
    );
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return json;
  }

  static bool _readBool(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase();
        if (normalized == 'true' || normalized == 'y' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == 'n' || normalized == 'no') {
          return false;
        }
        final numeric = num.tryParse(normalized);
        if (numeric != null) {
          return numeric != 0;
        }
      }
    }
    return false;
  }

  static String? _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
