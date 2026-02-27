import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/account_store.dart';
import '../data/budget_store.dart';
import '../data/pay_schedule_store.dart';
import '../data/transaction_store.dart';
import '../models/account.dart';
import '../models/pay_schedule_config.dart';
import '../models/budget_item.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_colors.dart';
import '../widgets/month_selector.dart';
import '../widgets/month_slide_transition.dart';
import '../widgets/month_swipe_detector.dart';
import '../utils/reload_stores.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  PayPeriod? _selectedPeriod;
  bool _slideForward = true;
  bool _defaultMonthSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultMonthSet) {
      _defaultMonthSet = true;
      final store = context.read<PayScheduleStore>();
      final (y, m) = store.config.defaultMonthForDate(DateTime.now(), store.monthInclusionPolicy);
      if (mounted && (_selectedYear != y || _selectedMonth != m)) {
        setState(() {
          _selectedYear = y;
          _selectedMonth = m;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AccountStore>();
    final budgetStore = context.watch<BudgetStore>();
    final scheduleStore = context.watch<PayScheduleStore>();
    final config = scheduleStore.config;
    final policy = scheduleStore.monthInclusionPolicy;

    // Initialize the visible month based on today's pay period and the
    // configured month-inclusion policy (Settings → Pay period), but only
    // after the pay schedule has been loaded (startDate != null).
    if (!_defaultMonthSet && scheduleStore.startDate != null) {
      final (y, m) = config.defaultMonthForDate(DateTime.now(), policy);
      if (_selectedYear != y || _selectedMonth != m) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedYear = y;
            _selectedMonth = m;
            _defaultMonthSet = true;
          });
        });
      } else {
        _defaultMonthSet = true;
      }
    }
    final accounts = [...store.accounts]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final accountIds = accounts.map((a) => a.id).toList();

    // Derive periods for this month from pay schedule; no calendar-month assumption.
    final periodsIncluded = config.startDate != null
        ? config.periodsIncludedInMonth(_selectedYear, _selectedMonth, policy)
        : <PayPeriod>[];
    final prorateWeights = policy == MonthInclusionPolicy.accrualProrated
        ? config.prorateWeightsForMonth(_selectedYear, _selectedMonth)
        : null;

    if (periodsIncluded.isNotEmpty && _selectedPeriod == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedPeriod = periodsIncluded.first);
      });
    }

    final txStore = context.watch<TransactionStore>();
    final periodLengthDays = config.periodLengthDays;

    // Total balance = sum of all account amounts.
    final double totalRemaining = accounts.fold<double>(
      0.0,
      (sum, a) => sum + a.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: MonthSlideTransition(
        slideForward: _slideForward,
        monthKey: ValueKey('$_selectedYear-$_selectedMonth'),
        child: MonthSwipeDetector(
          onSwipeNext: () => setState(() {
            _slideForward = true;
            var m = _selectedMonth + 1, y = _selectedYear;
            if (m > 12) { m = 1; y++; }
            _selectedYear = y;
            _selectedMonth = m;
            final periods = config.startDate != null
                ? config.periodsIncludedInMonth(y, m, policy)
                : <PayPeriod>[];
            _selectedPeriod = periods.isNotEmpty ? periods.first : null;
          }),
          onSwipePrevious: () => setState(() {
            _slideForward = false;
            var m = _selectedMonth - 1, y = _selectedYear;
            if (m < 1) { m = 12; y--; }
            _selectedYear = y;
            _selectedMonth = m;
            final periods = config.startDate != null
                ? config.periodsIncludedInMonth(y, m, policy)
                : <PayPeriod>[];
            _selectedPeriod = periods.isNotEmpty ? periods.first : null;
          }),
          child: RefreshIndicator(
            onRefresh: () => reloadAllStores(context),
            child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: MonthSelector(
              year: _selectedYear,
              month: _selectedMonth,
              onChanged: (y, m) {
                setState(() {
                  _slideForward = y > _selectedYear || (y == _selectedYear && m > _selectedMonth);
                  _selectedYear = y;
                  _selectedMonth = m;
                  final periods = config.startDate != null
                      ? config.periodsIncludedInMonth(y, m, policy)
                      : <PayPeriod>[];
                  _selectedPeriod = periods.isNotEmpty ? periods.first : null;
                });
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (config.startDate == null || periodsIncluded.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.outline.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        config.startDate == null
                            ? 'Set pay period start date in Settings → Pay period to see planned payments by period.'
                            : 'No pay periods fall in this month with the current reporting policy.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else ...[
                    _PeriodCardsRow(
                      periods: periodsIncluded,
                      config: config,
                      budgetStore: budgetStore,
                      txStore: txStore,
                      periodLengthDays: periodLengthDays,
                      accountIds: accountIds,
                      prorateWeights: prorateWeights,
                      policy: policy,
                      selectedPeriod: _selectedPeriod,
                      onPeriodTap: (p) {
                        setState(() {
                          // Tap again to clear and show all periods.
                          if (_selectedPeriod?.periodKey == p.periodKey) {
                            _selectedPeriod = null;
                          } else {
                            _selectedPeriod = p;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _IncomingBudgetSection(
                      year: _selectedYear,
                      month: _selectedMonth,
                      config: config,
                      accounts: accounts,
                      budgetStore: budgetStore,
                      txStore: txStore,
                      periodsIncluded: periodsIncluded,
                      selectedPeriod: _selectedPeriod,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TotalBalanceHeaderDelegate(
              totalFormatted: formatPeso(totalRemaining),
            ),
          ),
          if (periodsIncluded.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final account = accounts[index];
                  return _AccountTile(
                    account: account,
                    index: index,
                    onTap: () => _openEditAccount(context, store, account),
                    onDismissed: () => store.deleteAccount(account.id),
                  );
                },
                childCount: accounts.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      ),
      ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'accounts_fab',
        onPressed: () => _openAddAccount(context, store),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openAddAccount(BuildContext context, AccountStore store) {
    _openAccountSheet(context, store: store);
  }

  void _openEditAccount(BuildContext context, AccountStore store, Account account) {
    _openAccountSheet(context, store: store, account: account);
  }

  void _openAccountSheet(
    BuildContext context, {
    required AccountStore store,
    Account? account,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AccountSheetContent(
        store: store,
        account: account,
      ),
    );
  }
}

class _AccountSheetContent extends StatefulWidget {
  const _AccountSheetContent({
    required this.store,
    this.account,
  });

  final AccountStore store;
  final Account? account;

  @override
  State<_AccountSheetContent> createState() => _AccountSheetContentState();
}

class _AccountSheetContentState extends State<_AccountSheetContent> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  int? _selectedColorValue;
  late AccountType _accountType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    final amount = widget.account?.amount ?? 0.0;
    _amountController = TextEditingController(
      text: amount == 0 ? '' : amount.toStringAsFixed(2),
    );
    _selectedColorValue = widget.account?.iconColorValue;
    _accountType = widget.account?.accountType ?? AccountType.online;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final account = widget.account;
    if (account != null) {
      widget.store.updateAccount(account.copyWith(
        name: name,
        iconColorValue: _selectedColorValue,
        accountType: _accountType,
        amount: amount,
      ));
    } else {
      final id = 'a_${DateTime.now().millisecondsSinceEpoch}';
      widget.store.addAccount(Account(
        id: id,
        name: name,
        order: widget.store.accounts.length,
        iconColorValue: _selectedColorValue,
        accountType: _accountType,
        amount: amount,
      ));
    }
    Navigator.pop(context);
  }

  void _delete() {
    final account = widget.account;
    if (account == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete account?'),
        content: Text(
          'Are you sure you want to delete "${account.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.store.deleteAccount(account.id);
              if (mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit account' : 'Add account',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  hintText: 'e.g. BDO, GCash',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₱)',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: AccountType.values.map((type) {
                  final selected = _accountType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(type.label),
                      selected: selected,
                      onSelected: (v) => setState(() => _accountType = type),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Icon color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: iconColors.take(8).map((color) {
                  final value = color.toARGB32();
                  final selected = _selectedColorValue == value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = value),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppTheme.onSurface : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                    }).toList(),
                  ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isEdit) ...[
                    TextButton(
                      onPressed: _delete,
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                    const Spacer(),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Save' : 'Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinned header showing total balance; sticks to top when scrolling.
class _TotalBalanceHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TotalBalanceHeaderDelegate({required this.totalFormatted});

  final String totalFormatted;
  static const double _height = 72;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
              if (overlapsContent)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                totalFormatted,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TotalBalanceHeaderDelegate oldDelegate) {
    return oldDelegate.totalFormatted != totalFormatted;
  }
}

/// Section listing each account (alphabetically) with its incoming amount for the selected
/// period(s), based on remaining expense budgets assigned to that account.
class _IncomingBudgetSection extends StatelessWidget {
  const _IncomingBudgetSection({
    required this.year,
    required this.month,
    required this.config,
    required this.accounts,
    required this.budgetStore,
    required this.txStore,
    required this.periodsIncluded,
    required this.selectedPeriod,
  });

  final int year;
  final int month;
  final PayScheduleConfig config;
  final List<Account> accounts;
  final BudgetStore budgetStore;
  final TransactionStore txStore;
  final List<PayPeriod> periodsIncluded;
  final PayPeriod? selectedPeriod;

  double _remainingExpenseForAccountInPeriod(Account account, PayPeriod period) {
    // Get all budgets for this period, filtered to expense items assigned to this account.
    final periodBudgets = budgetStore
        .budgetsForPeriod(
          year,
          month,
          period.periodKey,
          period.indexInMonth,
        )
        .where((b) => b.type == BudgetType.expense && b.accountId == account.id)
        .toList();

    double remaining = 0.0;
    for (final b in periodBudgets) {
      final expected = b.expectedAmount;
      double actual;
      if (b.periodKey != null && config.startDate != null) {
        actual = txStore.sumForBudgetInPeriod(
          b.id,
          b.referenceId,
          TransactionType.expense,
          b.periodKey!,
          config.periodLengthDays,
        );
      } else {
        actual = txStore.sumForBudgetInMonth(
          b.id,
          b.referenceId,
          TransactionType.expense,
          year,
          month,
        );
      }
      remaining += (expected - actual);
    }
    return remaining;
  }

  double _incomingForAccount(Account account) {
    if (periodsIncluded.isEmpty) return 0.0;
    if (selectedPeriod != null) {
      return _remainingExpenseForAccountInPeriod(account, selectedPeriod!);
    }
    return periodsIncluded.fold<double>(
      0.0,
      (sum, p) => sum + _remainingExpenseForAccountInPeriod(account, p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cashAccounts =
        accounts.where((a) => a.accountType == AccountType.cash).toList();
    final onlineAccounts =
        accounts.where((a) => a.accountType == AccountType.online).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Budgeted amounts only; actual amounts added to accounts may vary.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurface.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
          child: Text(
            'Incoming budget amounts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (cashAccounts.isNotEmpty) ...[
          Text(
            'Cash accounts',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...cashAccounts.asMap().entries.map((e) {
            final account = e.value;
            final amt = _incomingForAccount(account);
            final dotColor = account.iconColorValue != null
                ? colorFromValue(account.iconColorValue!)
                : colorForIndex(accounts.indexOf(account));
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatPesoCompact(amt),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (onlineAccounts.isNotEmpty) ...[
          Text(
            'Online accounts',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...onlineAccounts.asMap().entries.map((e) {
            final account = e.value;
            final amt = _incomingForAccount(account);
            final dotColor = account.iconColorValue != null
                ? colorFromValue(account.iconColorValue!)
                : colorForIndex(accounts.indexOf(account));
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatPesoCompact(amt),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatPeso(onlineAccounts.fold<double>(
                    0.0, (sum, a) => sum + _incomingForAccount(a))),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Single horizontal row of pay period cards (dates above amount), matching Month View style.
/// Cards expand evenly to fill width.
class _PeriodCardsRow extends StatelessWidget {
  const _PeriodCardsRow({
    required this.periods,
    required this.config,
    required this.budgetStore,
    required this.txStore,
    required this.periodLengthDays,
    required this.accountIds,
    required this.prorateWeights,
    required this.policy,
    required this.selectedPeriod,
    required this.onPeriodTap,
  });

  final List<PayPeriod> periods;
  final PayScheduleConfig config;
  final BudgetStore budgetStore;
  final TransactionStore txStore;
  final int periodLengthDays;
  final List<String> accountIds;
  final Map<String, double>? prorateWeights;
  final MonthInclusionPolicy policy;
   final PayPeriod? selectedPeriod;
  final ValueChanged<PayPeriod> onPeriodTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < periods.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPeriodTap(periods[i]),
              child: _PeriodCard(
                dateLabel: config.labelForPeriod(periods[i]),
                selected: selectedPeriod?.periodKey == periods[i].periodKey,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.dateLabel,
    required this.selected,
  });

  final String dateLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryContainer.withValues(alpha: 0.5)
            : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Center(
        child: Text(
          dateLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

void _confirmDeleteAccount(
  BuildContext context,
  Account account,
  VoidCallback onDeleted,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete account?'),
      content: Text(
        'Are you sure you want to delete "${account.name}"? This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onDeleted();
          },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.index,
    required this.onTap,
    required this.onDismissed,
  });

  final Account account;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
        key: ValueKey(account.id),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 250 + (index * 35)),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: Opacity(opacity: t, child: child),
          );
        },
        child: Card(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: InkWell(
            onTap: onTap,
            onLongPress: () => _confirmDeleteAccount(context, account, onDismissed),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      final color = account.iconColorValue != null
                          ? colorFromValue(account.iconColorValue!)
                          : colorForIndex(index);
                      final containerColor = account.iconColorValue != null
                          ? color.withValues(alpha: 0.15)
                          : iconContainerColorForIndex(index);
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 24,
                          color: color,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: account.accountType == AccountType.cash
                                ? AppTheme.success.withValues(alpha: 0.18)
                                : AppTheme.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            account.accountType.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: account.accountType == AccountType.cash
                                  ? AppTheme.success
                                  : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatPeso(account.amount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: account.amount >= 0 ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant, size: 22),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
