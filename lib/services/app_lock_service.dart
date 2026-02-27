import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles app lock: PIN (stored hashed) and optional biometrics.
/// Biometrics use the device's built-in fingerprint or Face ID (same data as
/// unlocking your phone). The app does not store any biometric data; it only
/// asks the system to authenticate the user.
class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  static const _keyPinHash = 'app_lock_pin_hash';
  static const _keyLockEnabled = 'app_lock_enabled';
  static const _keyBiometricsEnabled = 'app_lock_biometrics';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final LocalAuthentication _auth = LocalAuthentication();

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> isLockEnabled() async {
    final v = await _storage.read(key: _keyLockEnabled);
    return v == 'true';
  }

  Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(key: _keyLockEnabled, value: enabled.toString());
    if (!enabled) {
      await _storage.delete(key: _keyPinHash);
      await setBiometricsEnabled(false);
    }
  }

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// Sets the PIN (enables lock if not already). PIN is stored hashed.
  Future<void> setPin(String pin) async {
    if (pin.length < 4) throw ArgumentError('PIN must be 4 digits');
    await _storage.write(key: _keyPinHash, value: _hashPin(pin));
    await _storage.write(key: _keyLockEnabled, value: 'true');
  }

  /// Verifies the given PIN. Returns true if correct.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _keyPinHash);
    if (stored == null) return false;
    return _hashPin(pin) == stored;
  }

  Future<bool> isBiometricsEnabled() async {
    final v = await _storage.read(key: _keyBiometricsEnabled);
    return v == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricsEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricsAvailable() async {
    try {
      if (!await _auth.canCheckBiometrics || !await _auth.isDeviceSupported()) {
        return false;
      }
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Returns a short label for the primary biometric (e.g. "Fingerprint" or "Face ID").
  Future<String> getBiometricLabel() async {
    final list = await getAvailableBiometrics();
    if (list.contains(BiometricType.face)) return 'Face ID';
    if (list.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (list.contains(BiometricType.iris)) return 'Iris';
    return 'Biometrics';
  }

  /// Authenticate with biometrics. Returns true if success.
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason ?? 'Unlock Budget Companion',
      );
    } catch (_) {
      return false;
    }
  }
}
