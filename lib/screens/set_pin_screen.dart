import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/app_lock_store.dart';
import '../theme/app_theme.dart';

/// Screen to set or change PIN. [changePin] = true asks for current PIN first.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key, this.changePin = false});

  final bool changePin;

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final List<String> _digits = [];
  static const int _pinLength = 4;
  String? _error;
  bool _verifying = false;
  bool _currentPinVerified = false;
  String? _firstPin;

  void _appendDigit(String d) {
    if (_verifying || _digits.length >= _pinLength) return;
    setState(() {
      _error = null;
      _digits.add(d);
    });
    if (_digits.length == _pinLength) _onPinComplete();
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() {
      _error = null;
      _digits.removeLast();
    });
  }

  Future<void> _onPinComplete() async {
    final pin = _digits.join();
    final store = context.read<AppLockStore>();

    if (widget.changePin && !_currentPinVerified) {
      setState(() => _verifying = true);
      final ok = await store.verifyPin(pin);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        if (ok) {
          _currentPinVerified = true;
          _digits.clear();
          _error = null;
        } else {
          _error = 'Wrong PIN';
          _digits.clear();
          HapticFeedback.heavyImpact();
        }
      });
      return;
    }

    if (_firstPin == null) {
      setState(() {
        _firstPin = pin;
        _digits.clear();
        _error = null;
      });
      return;
    }

    if (_firstPin != pin) {
      setState(() {
        _error = 'PINs do not match';
        _digits.clear();
        _firstPin = null;
        HapticFeedback.heavyImpact();
      });
      return;
    }

    await store.setPin(pin);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    if (widget.changePin && !_currentPinVerified) {
      title = 'Enter current PIN';
      subtitle = 'Enter your current PIN to continue';
    } else if (_firstPin == null) {
      title = widget.changePin ? 'Enter new PIN' : 'Set PIN';
      subtitle = widget.changePin
          ? 'Enter your new 4-digit PIN'
          : 'Choose a 4-digit PIN to lock the app';
    } else {
      title = 'Confirm PIN';
      subtitle = 'Enter your PIN again to confirm';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pin_rounded,
                size: 56,
                color: AppTheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
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
              const width = 72.0;
              return SizedBox(
                width: width,
                child: isBack
                    ? IconButton(
                        onPressed: _verifying ? null : _backspace,
                        icon: const Icon(Icons.backspace_outlined),
                        color: AppTheme.onSurfaceVariant,
                      )
                    : isEmpty
                        ? const SizedBox()
                        : Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _appendDigit(key),
                              borderRadius:
                                  BorderRadius.circular(width / 2),
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
