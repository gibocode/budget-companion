import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_lock_store.dart';
import '../data/pay_schedule_store.dart';
import '../screens/lock_screen.dart';
import '../screens/home_shell.dart';

/// Wraps [HomeShell] and shows [LockScreen] when app lock is enabled and not unlocked.
/// Re-locks when app goes to background and returns.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  bool _unlocked = true;
  bool _initialLockSynced = false;
  /// True when we re-locked because app went to background (don't auto-show biometrics).
  bool _reLockedFromBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only re-lock on PAUSED (app in background). Do NOT use INACTIVE - when the
    // biometric dialog is shown the app becomes inactive, which would re-lock and
    // remount the lock screen, then on resumed we'd trigger biometrics again → infinite loop.
    if (state == AppLifecycleState.paused) {
      final store = context.read<AppLockStore>();
      if (store.lockEnabled) {
        setState(() {
          _reLockedFromBackground = true;
          _unlocked = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // User returned to the app; show biometrics immediately if we're on the lock screen.
      if (context.read<AppLockStore>().lockEnabled && !_unlocked) {
        setState(() => _reLockedFromBackground = false);
      }
    }
  }

  void _onUnlocked() {
    setState(() {
      _unlocked = true;
      _reLockedFromBackground = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppLockStore>();
    if (!store.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (store.lockEnabled && !_initialLockSynced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {
          _initialLockSynced = true;
          _unlocked = false;
        });
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (store.lockEnabled && !_unlocked) {
      // Key forces LockScreen to remount when _reLockedFromBackground becomes false
      // (user returned to app), so initState runs again and biometrics are tried immediately.
      return KeyedSubtree(
        key: ValueKey('lock_$_reLockedFromBackground'),
        child: LockScreen(
          onUnlocked: _onUnlocked,
          autoTryBiometrics: !_reLockedFromBackground,
        ),
      );
    }
    return const _PostAuthBootstrap();
  }
}

/// Lightweight bootstrap step that runs immediately after the app is unlocked.
/// Ensures key stores (like [PayScheduleStore]) are loaded from the database
/// before showing the main shell, so initial month selection and other
/// derived values are correct without visible snapping.
class _PostAuthBootstrap extends StatefulWidget {
  const _PostAuthBootstrap();

  @override
  State<_PostAuthBootstrap> createState() => _PostAuthBootstrapState();
}

class _PostAuthBootstrapState extends State<_PostAuthBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Make sure the pay schedule is loaded before we build the main UI.
      final payScheduleStore = context.read<PayScheduleStore>();
      await payScheduleStore.reload();
      // If you decide later to ensure other stores are fresh, you can
      // trigger their reloads here as well.
    } finally {
      if (!mounted) return;
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomeShell();
  }
}
