import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../models/vault_data.dart';

/// Independent portable backup. Nothing here contains the OS-bound vault key.
/// Encoded data is authenticated before a restore can overwrite any live data.
class PortableBackup {
  PortableBackup._();

  static const formatVersion = 1;
  static const iterations = 310000;
  static const maxEncodedLength = 10 * 1024 * 1024;
  static const minPasswordLength = 12;

  static final _cipher = AesGcm.with256bits();

  static Future<String> create(VaultData data, String password) async {
    if (password.runes.length < minPasswordLength) {
      throw const FormatException('اختر كلمة مرور من ١٢ حرفًا على الأقل.');
    }
    final secure = Random.secure();
    final salt = List<int>.generate(16, (_) => secure.nextInt(256));
    final key = await Pbkdf2.hmacSha256(iterations: iterations, bits: 256)
        .deriveKeyFromPassword(password: password, nonce: salt);
    final box = await _cipher.encrypt(utf8.encode(data.encode()), secretKey: key);
    return jsonEncode({
      'app': 'wasiyyati',
      'format': formatVersion,
      'kdf': 'pbkdf2-hmac-sha256',
      'rounds': iterations,
      'salt': base64Encode(salt),
      'alg': 'aes-256-gcm',
      'nonce': base64Encode(box.nonce),
      'cipher': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  static Future<VaultData> restore(String encoded, String password) async {
    if (encoded.length > maxEncodedLength) {
      throw const FormatException('حجم النسخة الاحتياطية أكبر من الحد المسموح.');
    }
    try {
      final data = jsonDecode(encoded);
      if (data is! Map<String, dynamic> ||
          data['app'] != 'wasiyyati' || data['format'] != formatVersion ||
          data['kdf'] != 'pbkdf2-hmac-sha256' ||
          data['rounds'] != iterations || data['alg'] != 'aes-256-gcm') {
        throw const FormatException('صيغة النسخة الاحتياطية غير مدعومة.');
      }
      final salt = base64Decode(data['salt'] as String);
      final nonce = base64Decode(data['nonce'] as String);
      final tag = base64Decode(data['mac'] as String);
      final cipher = base64Decode(data['cipher'] as String);
      if (salt.length != 16 || nonce.length != 12 || tag.length != 16 ||
          cipher.length > maxEncodedLength) {
        throw const FormatException('بيانات النسخة الاحتياطية غير صالحة.');
      }
      final key = await Pbkdf2.hmacSha256(iterations: iterations, bits: 256)
          .deriveKeyFromPassword(password: password, nonce: salt);
      final clear = await _cipher.decrypt(
        SecretBox(cipher, nonce: nonce, mac: Mac(tag)), secretKey: key);
      return VaultData.decode(utf8.decode(clear));
    } on FormatException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const FormatException('كلمة المرور غير صحيحة أو الملف تعرض للتعديل.');
    } catch (_) {
      throw const FormatException('تعذّر فتح النسخة. تحقق من الملف وكلمة المرور.');
    }
  }
}
