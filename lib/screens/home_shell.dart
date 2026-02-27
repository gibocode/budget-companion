import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budget_screen.dart';
import 'accounts_screen.dart';
import 'debts_screen.dart';
import 'settings_screen.dart';

/// Main shell: bottom nav as tabs (no push for main screens). One-handed friendly.
/// Categories are under Settings → Configuration.
/// Persists selected tab index when app goes to background so unlock returns to same tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const String _kLastTabIndexKey = 'shell_last_tab_index';
  int _index = 0;

  static const _tabs = [
    _TabData(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _TabData(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    _TabData(icon: Icons.account_balance_rounded, label: 'Budgets'),
    _TabData(icon: Icons.account_balance_wallet_rounded, label: 'Accounts'),
    _TabData(icon: Icons.request_quote_rounded, label: 'Debts'),
    _TabData(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreTabIndex();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _restoreTabIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kLastTabIndexKey);
    if (saved != null && saved >= 0 && saved < _tabs.length && mounted) {
      setState(() => _index = saved);
    }
  }

  Future<void> _persistTabIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastTabIndexKey, index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _persistTabIndex(_index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          TransactionsScreen(),
          BudgetScreen(),
          AccountsScreen(),
          DebtsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final selected = _index == i;
                return Expanded(
                  child: _TabItem(
                    icon: t.icon,
                    label: t.label,
                    selected: selected,
                    onTap: () => setState(() {
                      _index = i;
                      _persistTabIndex(i);
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final scale = 1.0 + (0.06 * t);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppTheme.primary.withValues(alpha: 0.12),
          highlightColor: AppTheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabData {
  const _TabData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
