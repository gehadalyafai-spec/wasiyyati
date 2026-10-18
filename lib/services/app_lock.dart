import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Optional presentation lock using Android/iOS device authentication.
/// It is not a replacement for the at-rest encrypted vault.
class AppLock extends ChangeNotifier {
  AppLock({FlutterSecureStorage? storage, LocalAuthentication? auth})
      : _storage = storage ?? const FlutterSecureStorage(),
        _auth = auth ?? LocalAuthentication();

  static const _settingKey = 'wasiyyati_use_device_lock_v1';
  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  bool ready = false;
  bool enabled = false;
  bool locked = true;
  bool authenticating = false;
  bool _fatalInitializationError = false;
  String? error;

  Future<void> initialize() async {
    try {
      enabled = await _storage.read(key: _settingKey) == 'true';
      locked = enabled;
      error = null;
    } catch (_) {
      // Fail closed if OS secure storage is unavailable.
      locked = true;
      _fatalInitializationError = true;
      error = 'تعذّر قراءة إعدادات القفل الآمن. أعد فتح التطبيق بعد إصلاح المشكلة.';
    }
    ready = true;
    notifyListeners();
  }

  Future<bool> unlock() async {
    if (authenticating) return false;
    if (_fatalInitializationError || error != null) return false;
    if (!enabled) {
      locked = false;
      notifyListeners();
      return true;
    }
    authenticating = true;
    notifyListeners();
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'تحقق من هويتك لفتح وصيتي',
        biometricOnly: false,
        persistAcrossBackgrounding: false,
      );
      if (ok) locked = false;
      return ok;
    } catch (_) {
      error = 'تعذّر التحقق من هوية الجهاز. تأكد من إعداد قفل الشاشة.';
      return false;
    } finally {
      authenticating = false;
      notifyListeners();
    }
  }

  Future<bool> setEnabled(bool value) async {
    if (value == enabled) return true;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final verified = await _auth.authenticate(
        localizedReason: value ? 'تحقق لتفعيل حماية وصيتي' : 'تحقق لإيقاف حماية وصيتي',
        biometricOnly: false,
        persistAcrossBackgrounding: false,
      );
      if (!verified) return false;
      await _storage.write(key: _settingKey, value: value.toString());
      enabled = value;
      locked = false;
      error = null;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void lock() {
    if (enabled && !locked) {
      locked = true;
      notifyListeners();
    }
  }

  void clearTemporaryAuthError() {
    if (!_fatalInitializationError && error != null && ready) {
      error = null;
      notifyListeners();
    }
  }
}
