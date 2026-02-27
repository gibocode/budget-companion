import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/app_lock_service.dart';

/// Full-screen lock UI: PIN dots + keypad and optional biometrics button.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.title = 'Enter PIN',
    this.reason,
    this.autoTryBiometrics = true,
  });

  final VoidCallback onUnlocked;
  final String title;
  /// Reason shown for biometrics prompt.
  final String? reason;
  /// If true, automatically trigger biometric prompt once when shown (e.g. on app open).
  /// Set to false when re-locking after app went to background so the prompt doesn't stay visible.
  final bool autoTryBiometrics;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final List<String> _digits = [];
  static const int _pinLength = 4;
  String? _error;
  bool _checking = false;
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  String _biometricLabel = 'Biometrics';

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
    if (widget.autoTryBiometrics) {
      _tryBiometricsOnce();
    }
  }

  Future<void> _loadBiometrics() async {
    final svc = AppLockService.instance;
    final available = await svc.isBiometricsAvailable();
    final enabled = await svc.isBiometricsEnabled();
    final label = await svc.getBiometricLabel();
    if (!mounted) return;
    setState(() {
      _biometricsAvailable = available;
      _biometricsEnabled = enabled;
      _biometricLabel = label;
    });
  }

  Future<void> _tryBiometricsOnce() async {
    final svc = AppLockService.instance;
    final enabled = await svc.isBiometricsEnabled();
    if (!enabled) return;
    final ok = await svc.authenticateWithBiometrics(
      reason: widget.reason ?? 'Unlock Budget Companion',
    );
    if (!mounted) return;
    if (ok) widget.onUnlocked();
  }

  void _appendDigit(String d) {
    if (_checking || _digits.length >= _pinLength) return;
    setState(() {
      _error = null;
      _digits.add(d);
    });
    if (_digits.length == _pinLength) _verify();
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() {
      _error = null;
      _digits.removeLast();
    });
  }

  Future<void> _verify() async {
    if (_digits.length != _pinLength) return;
    setState(() => _checking = true);
    final pin = _digits.join();
    final ok = await AppLockService.instance.verifyPin(pin);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (ok) {
        widget.onUnlocked();
      } else {
        _error = 'Wrong PIN';
        _digits.clear();
        HapticFeedback.heavyImpact();
      }
    });
  }

  Future<void> _onBiometricsTap() async {
    if (!_biometricsEnabled || _checking) return;
    final ok = await AppLockService.instance.authenticateWithBiometrics(
      reason: widget.reason ?? 'Unlock Budget Companion',
    );
    if (!mounted) return;
    if (ok) widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 56,
                color: AppTheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _digits.length;
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? AppTheme.primary
                          : AppTheme.outline.withValues(alpha: 0.5),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              _buildKeypad(),
              if (_biometricsAvailable && _biometricsEnabled) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _checking ? null : _onBiometricsTap,
                  icon: Icon(
                    Icons.fingerprint_rounded,
                    size: 28,
                    color: AppTheme.primary,
                  ),
                  label: Text(_biometricLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              final isBack = key == 'back';
              final isEmpty = key.isEmpty;
              final width = 72.0;
              return SizedBox(
                width: width,
                child: isBack
                    ? IconButton(
                        onPressed: _checking ? null : _backspace,
                        icon: const Icon(Icons.backspace_outlined),
                        color: AppTheme.onSurfaceVariant,
                      )
                    : isEmpty
                        ? const SizedBox()
                        : Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _appendDigit(key),
                              borderRadius: BorderRadius.circular(width / 2),
                              child: Container(
                                width: width,
                                height: width,
                                alignment: Alignment.center,
                                child: Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
