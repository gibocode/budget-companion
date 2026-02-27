import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/account_store.dart';
import '../data/app_lock_store.dart';
import '../data/budget_store.dart';
import '../data/debt_store.dart';
import '../data/expense_store.dart';
import '../data/income_store.dart';
import '../data/transaction_store.dart';
import '../services/google_drive_backup_service.dart';
import '../utils/reload_stores.dart';
import 'categories_screen.dart';
import 'lock_screen.dart';
import 'pay_period_settings_screen.dart';
import 'set_pin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadAllStores(context),
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsSection(
            title: 'Configuration',
            children: [
              ListTile(
                leading: _SettingsLeadingIcon(
                  icon: Icons.event_rounded,
                ),
                title: const Text('Pay period'),
                subtitle: const Text(
                  'Configure pay period start date and length.',
                  style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PayPeriodSettingsScreen()),
                ),
              ),
              ListTile(
                leading: _SettingsLeadingIcon(
                  icon: Icons.category_rounded,
                ),
                title: const Text('Categories'),
                subtitle: const Text(
                  'Manage categories, icons, colors, and subcategories.',
                  style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Security',
            children: [
              _AppLockSwitchTile(),
              _ChangePinTile(),
              _BiometricsSwitchTile(),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'General',
            children: [
              const ListTile(
                leading: Icon(Icons.attach_money_rounded, color: AppTheme.onSurfaceVariant, size: 24),
                title: Text('Currency'),
                subtitle: Text('Philippine Peso (₱)', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Data',
            children: [
              ListTile(
                leading: _SettingsLeadingIcon(
                  icon: Icons.cloud_sync_rounded,
                ),
                title: const Text('Google Drive backup'),
                subtitle: const Text(
                  'Link your Google account and back up or restore your data.',
                  style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                onTap: () => _openDriveBackupSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© Budget Companion · Gilbor Camporazo Jr.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  static Future<void> _openDriveBackupSheet(BuildContext context) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mediaQuery = MediaQuery.of(ctx);
        return Container(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.7,
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 24 + mediaQuery.viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: _DriveBackupContent(),
        );
      },
    );
  }
}

class _DriveBackupContent extends StatefulWidget {
  @override
  State<_DriveBackupContent> createState() => _DriveBackupContentState();
}

class _DriveBackupContentState extends State<_DriveBackupContent> {
  bool _busy = false;
  String? _status;
  DateTime? _lastBackup;
  DateTime? _lastRestore;

  @override
  void initState() {
    super.initState();
    _restoreLinkedAccount();
  }

  Future<void> _restoreLinkedAccount() async {
    final svc = GoogleDriveBackupService.instance;
    await svc.restorePreviousSignIn();
    _lastBackup = await svc.lastBackupTime();
    _lastRestore = await svc.lastRestoreTime();
    if (!mounted) return;
    setState(() {
      final user = svc.currentUser;
      if (user != null) {
        _status = 'Linked to ${user.email}';
      }
    });
  }

  Future<void> _linkAccount() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final user = await GoogleDriveBackupService.instance.signIn();
      if (!mounted) return;
      setState(() {
        _status = user != null ? 'Linked to ${user.email}' : 'Sign-in cancelled';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Failed to link account: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// If app lock is enabled, pushes PIN/biometrics screen. Returns true if auth succeeded or lock is off.
  Future<bool> _requireAuthForSensitiveAction(String action) async {
    final store = context.read<AppLockStore>();
    if (!store.lockEnabled) return true;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (ctx) => LockScreen(
          onUnlocked: () => Navigator.pop(ctx, true),
          title: 'Unlock to $action',
          reason: 'Authenticate to $action',
        ),
      ),
    );
    return result == true;
  }

  Future<void> _backupNow() async {
    final accountStore = context.read<AccountStore>();
    final transactionStore = context.read<TransactionStore>();
    final budgetStore = context.read<BudgetStore>();
    final debtStore = context.read<DebtStore>();
    final expenseStore = context.read<ExpenseStore>();
    final incomeStore = context.read<IncomeStore>();
    final hasData = accountStore.accounts.isNotEmpty ||
        transactionStore.transactions.isNotEmpty ||
        budgetStore.items.isNotEmpty ||
        debtStore.items.isNotEmpty ||
        expenseStore.expenses.isNotEmpty ||
        incomeStore.incomes.isNotEmpty;
    if (!hasData) {
      if (mounted) {
        setState(() => _status = 'No data to back up.');
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Back up to Google Drive?'),
        content: const Text(
          'This will upload your current budget data to Google Drive (app data folder).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Back up'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!await _requireAuthForSensitiveAction('back up')) return;

    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await GoogleDriveBackupService.instance.backupDatabase();
      if (!mounted) return;
      setState(() {
        _status = 'Backup completed to Google Drive.';
        _lastBackup = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Backup failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _restoreNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Google Drive?'),
        content: const Text(
          'This will overwrite your local data with the backup from Google Drive. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!await _requireAuthForSensitiveAction('restore')) return;

    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await GoogleDriveBackupService.instance.restoreDatabase();
      if (!mounted) return;
      setState(() {
        _status = 'Restore completed. Please restart the app to reload data.';
        _lastRestore = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Restore failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = GoogleDriveBackupService.instance.currentUser;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final accountStore = context.watch<AccountStore>();
    final transactionStore = context.watch<TransactionStore>();
    final budgetStore = context.watch<BudgetStore>();
    final debtStore = context.watch<DebtStore>();
    final expenseStore = context.watch<ExpenseStore>();
    final incomeStore = context.watch<IncomeStore>();
    final hasData = accountStore.accounts.isNotEmpty ||
        transactionStore.transactions.isNotEmpty ||
        budgetStore.items.isNotEmpty ||
        debtStore.items.isNotEmpty ||
        expenseStore.expenses.isNotEmpty ||
        incomeStore.incomes.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Google Drive backup',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Link your Google account to back up your budget data to Google Drive (app data folder). '
          'This is intended as a personal backup for this app only.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _linkAccount,
                icon: const Icon(Icons.account_circle_rounded),
                label: Text(user == null ? 'Link Google account' : 'Linked: ${user.email}'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      user == null ? AppTheme.primary : AppTheme.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lastBackup != null || _lastRestore != null) ...[
          if (_lastBackup != null)
            Text(
              'Last backup: ${dateFormat.format(_lastBackup!.toLocal())}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          if (_lastRestore != null)
            Text(
              'Last restore: ${dateFormat.format(_lastRestore!.toLocal())}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        if (!hasData)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No data to back up. Add accounts, transactions, or budgets first.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_busy || !hasData) ? null : _backupNow,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('Back up now'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _restoreNow,
                icon: const Icon(Icons.cloud_download_rounded),
                label: const Text('Restore'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_busy)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (_status != null) ...[
          const SizedBox(height: 8),
          Text(
            _status!,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }
}


class _AppLockSwitchTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppLockStore>();
    return SwitchListTile(
      secondary: _SettingsLeadingIcon(icon: Icons.lock_rounded),
      title: const Text('App lock'),
      subtitle: Text(
        store.lockEnabled ? 'PIN required to open app' : 'Lock app with PIN',
        style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
      ),
      value: store.lockEnabled,
      onChanged: (value) async {
        if (value) {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const SetPinScreen(changePin: false),
            ),
          );
          if (context.mounted) {
            context.read<AppLockStore>().refresh();
          }
        } else {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Disable app lock?'),
              content: const Text(
                'The app will no longer ask for a PIN when opening.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Disable'),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            final ok = await Navigator.push<bool>(
              context,
              MaterialPageRoute<bool>(
                builder: (authCtx) => LockScreen(
                  onUnlocked: () => Navigator.pop(authCtx, true),
                  title: 'Unlock to disable app lock',
                  reason: 'Authenticate to disable app lock',
                ),
              ),
            );
            if (ok == true && context.mounted) {
              await context.read<AppLockStore>().setLockEnabled(false);
            }
          }
        }
      },
    );
  }
}

class _ChangePinTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppLockStore>();
    if (!store.lockEnabled) return const SizedBox.shrink();
    return ListTile(
      leading: _SettingsLeadingIcon(icon: Icons.pin_rounded),
      title: const Text('Change PIN'),
      subtitle: const Text(
        'Set a new 4-digit PIN',
        style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SetPinScreen(changePin: true),
          ),
        );
      },
    );
  }
}

class _BiometricsSwitchTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<AppLockStore>().isBiometricsAvailable(),
      builder: (context, snapshot) {
        final store = context.watch<AppLockStore>();
        if (!snapshot.hasData || !snapshot.data! || !store.lockEnabled) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<String>(
          future: context.read<AppLockStore>().getBiometricLabel(),
          builder: (context, labelSnap) {
            final label = labelSnap.data ?? 'Biometrics';
            return SwitchListTile(
              secondary: _SettingsLeadingIcon(icon: Icons.fingerprint_rounded),
              title: const Text('Unlock with biometrics'),
              subtitle: Text(
                'Use device $label (same as unlocking your phone)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              value: store.biometricsEnabled,
              onChanged: (value) async {
                await context.read<AppLockStore>().setBiometricsEnabled(value);
              },
            );
          },
        );
      },
    );
  }
}

class _SettingsLeadingIcon extends StatelessWidget {
  const _SettingsLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 22),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
