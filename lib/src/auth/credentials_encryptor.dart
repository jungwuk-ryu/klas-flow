import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/api.dart' show PublicKeyParameter;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/export.dart'
    show KeyParameter, ParametersWithRandom;
import 'package:pointycastle/random/fortuna_random.dart';

import '../exceptions/klas_exceptions.dart';
import '../models/login_security.dart';

/// 로그인 토큰을 RSA로 암호화합니다.
final class CredentialsEncryptor {
  /// 계정 정보를 암호화한 토큰을 반환합니다.
  String encryptLoginToken({
    required String id,
    required String password,
    required LoginSecurity security,
  }) {
    try {
      final modulus = _parseBigInt(security.publicKeyModulus);
      final exponent = _parseBigInt(security.publicKeyExponent);
      final publicKey = RSAPublicKey(modulus, exponent);

      final payload = utf8.encode('$id|$password|${security.loginToken}');
      final engine = PKCS1Encoding(RSAEngine())
        ..init(
          true,
          ParametersWithRandom(
            PublicKeyParameter<RSAPublicKey>(publicKey),
            _secureRandom(),
          ),
        );

      final encrypted = engine.process(Uint8List.fromList(payload));
      return base64Encode(encrypted);
    } catch (error, stackTrace) {
      throw ParsingException(
        'Failed to encrypt login token.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  BigInt _parseBigInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Cannot parse an empty string as BigInt.');
    }

    final isHex = RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed);
    if (isHex) {
      return BigInt.parse(trimmed, radix: 16);
    }
    if (trimmed.startsWith('0x')) {
      return BigInt.parse(trimmed.substring(2), radix: 16);
    }
    return BigInt.parse(trimmed);
  }

  FortunaRandom _secureRandom() {
    final random = FortunaRandom();
    final seed = Uint8List(32);
    final secure = Random.secure();
    for (var index = 0; index < seed.length; index++) {
      seed[index] = secure.nextInt(256);
    }
    random.seed(KeyParameter(seed));
    return random;
  }
}
