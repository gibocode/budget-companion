import 'package:flutter/foundation.dart';
import '../services/app_lock_service.dart';

/// In-memory state for app lock; persists to [AppLockService].
class AppLockStore extends ChangeNotifier {
  AppLockStore() {
    _load();
  }

  bool _lockEnabled = false;
  bool _biometricsEnabled = false;
  bool _loaded = false;

  bool get lockEnabled => _lockEnabled;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get isLoaded => _loaded;

  Future<void> _load() async {
    final svc = AppLockService.instance;
    _lockEnabled = await svc.isLockEnabled();
    _biometricsEnabled = await svc.isBiometricsEnabled();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLockEnabled(bool enabled) async {
    await AppLockService.instance.setLockEnabled(enabled);
    _lockEnabled = enabled;
    if (!enabled) _biometricsEnabled = false;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await AppLockService.instance.setPin(pin);
    _lockEnabled = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) => AppLockService.instance.verifyPin(pin);

  Future<void> setBiometricsEnabled(bool enabled) async {
    await AppLockService.instance.setBiometricsEnabled(enabled);
    _biometricsEnabled = enabled;
    notifyListeners();
  }

  Future<bool> isBiometricsAvailable() =>
      AppLockService.instance.isBiometricsAvailable();

  Future<String> getBiometricLabel() =>
      AppLockService.instance.getBiometricLabel();

  Future<bool> authenticateWithBiometrics({String? reason}) =>
      AppLockService.instance.authenticateWithBiometrics(reason: reason);

  Future<void> refresh() => _load();
}
