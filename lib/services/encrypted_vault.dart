import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/vault_data.dart';

/// AES-256-GCM, with a per-install random key kept by OS secure storage.
/// Local encrypted files are deliberately excluded from Android cloud backup.
class EncryptedVault {
  EncryptedVault({FlutterSecureStorage? secureStorage})
      : _storage = secureStorage ?? const FlutterSecureStorage();

  static const _keyName = 'wasiyyati_aes256_key_v1';
  final FlutterSecureStorage _storage;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}vault.enc');
  }

  Future<SecretKey> _key({required bool hasData}) async {
    final encoded = await _storage.read(key: _keyName);
    if (encoded != null) {
      final bytes = base64Decode(encoded);
      if (bytes.length != 32) throw const FormatException('مفتاح التشفير تالف');
      return SecretKey(bytes);
    }
    // Never quietly replace a lost encryption key for an existing vault.
    if (hasData) {
      throw FileSystemException(
        'مفتاح التشفير غير موجود. لن نستبدله حفاظًا على البيانات.',
      );
    }
    final generated = await _cipher.newSecretKey();
    await _storage.write(
      key: _keyName,
      value: base64Encode(await generated.extractBytes()),
    );
    return generated;
  }

  Future<VaultData> load() async {
    final file = await _file();
    final backup = File('${file.path}.bak');
    final hasData = await file.exists() || await backup.exists();
    final key = await _key(hasData: hasData);
    if (!hasData) return const VaultData();

    // An interrupted write can be recovered from the encrypted backup.
    Object? initialError;
    for (final candidate in [file, backup]) {
      if (!await candidate.exists()) continue;
      try {
        final envelope = jsonDecode(await candidate.readAsString()) as Map<String, dynamic>;
        if (envelope['v'] != 1) throw const FormatException('إصدار تشفير غير مدعوم');
        final box = SecretBox(
          base64Decode(envelope['cipher'] as String),
          nonce: base64Decode(envelope['nonce'] as String),
          mac: Mac(base64Decode(envelope['mac'] as String)),
        );
        final clear = await _cipher.decrypt(box, secretKey: key);
        return VaultData.decode(utf8.decode(clear));
      } catch (error) {
        initialError ??= error;
      }
    }
    throw StateError('تعذّر فك تشفير الخزنة أو استعادتها: $initialError');
  }

  Future<void> save(VaultData data) async {
    final file = await _file();
    final key = await _key(hasData: await file.exists());
    final encrypted = await _cipher.encrypt(utf8.encode(data.encode()), secretKey: key);
    final payload = jsonEncode({
      'v': 1,
      'nonce': base64Encode(encrypted.nonce),
      'cipher': base64Encode(encrypted.cipherText),
      'mac': base64Encode(encrypted.mac.bytes),
    });
    final temp = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temp.writeAsString(payload, flush: true);
    if (await file.exists()) {
      await file.copy(backup.path);
      await file.delete();
    }
    await temp.rename(file.path);
  }
}
