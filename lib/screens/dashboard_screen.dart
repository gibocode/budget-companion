import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/account_store.dart';
import '../data/budget_store.dart';
import '../data/category_store.dart';
import '../data/expense_store.dart';
import '../data/income_store.dart';
import '../data/pay_schedule_store.dart';
import '../models/pay_schedule_config.dart';
import '../models/budget_item.dart' as bi;
import '../data/transaction_store.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_colors.dart';
import '../models/account.dart';
import '../widgets/month_selector.dart';
import '../widgets/month_slide_transition.dart';
import '../widgets/month_swipe_detector.dart';
import '../widgets/dashboard_charts.dart';
import '../utils/reload_stores.dart';

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  static const int _tabCount = 3;
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _slideForward = true;
  bool _defaultMonthSet = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this, initialIndex: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultMonthSet) {
      _defaultMonthSet = true;
      final now = DateTime.now();
      if (mounted && (_selectedYear != now.year || _selectedMonth != now.month)) {
        setState(() {
          _selectedYear = now.year;
          _selectedMonth = now.month;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PayPeriod> _periodsFor(PayScheduleConfig config) {
    final policy = context.read<PayScheduleStore>().monthInclusionPolicy;
    if (config.startDate != null) {
      return config.periodsIncludedInMonth(_selectedYear, _selectedMonth, policy);
    }
    return config.periodsForMonth(_selectedYear, _selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<PayScheduleStore>().config;
    final policy = context.read<PayScheduleStore>().monthInclusionPolicy;
    final budgetStore = context.watch<BudgetStore>();
    final txStore = context.watch<TransactionStore>();
    final includedPeriods = config.startDate != null
        ? config.periodsIncludedInMonth(_selectedYear, _selectedMonth, policy)
        : config.periodsForMonth(_selectedYear, _selectedMonth);
    final periodKeys = includedPeriods.map((p) => p.periodKey).toSet();
    final totalBudgetedExpense = budgetStore.totalExpectedForMonthByType(
      _selectedYear,
      _selectedMonth,
      periodKeys,
      bi.BudgetType.expense,
    );
    final totalBudgetedIncome = budgetStore.totalExpectedForMonthByType(
      _selectedYear,
      _selectedMonth,
      periodKeys,
      bi.BudgetType.income,
    );
    final totalExpected = totalBudgetedExpense;
    final totalActual = config.startDate != null && includedPeriods.isNotEmpty
        ? txStore.totalActualForPeriodsByType(
            periodKeys,
            TransactionType.expense,
            config.periodLengthDays,
          )
        : txStore.totalActualForMonthByType(
            _selectedYear,
            _selectedMonth,
            TransactionType.expense,
          );
    final totalIncome = config.startDate != null && includedPeriods.isNotEmpty
        ? txStore.totalActualForPeriodsByType(
            periodKeys,
            TransactionType.income,
            config.periodLengthDays,
          )
        : txStore.totalActualForMonthByType(
            _selectedYear,
            _selectedMonth,
            TransactionType.income,
          );
    final remaining = totalExpected - totalActual;
    final periods = _periodsFor(config);
    final periodTotals = List.generate(
      periods.length,
      (i) => budgetStore.totalExpectedForPeriodByType(
        _selectedYear,
        _selectedMonth,
        periods[i].periodKey,
        periods[i].indexInMonth,
        bi.BudgetType.expense,
      ),
    );

    final bool isOverbudget = totalBudgetedExpense > totalBudgetedIncome;
    final bool isOverspent = totalActual > totalBudgetedExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget Companion',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
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
          }),
          onSwipePrevious: () => setState(() {
            _slideForward = false;
            var m = _selectedMonth - 1, y = _selectedYear;
            if (m < 1) { m = 12; y--; }
            _selectedYear = y;
            _selectedMonth = m;
          }),
            child: RefreshIndicator(
            onRefresh: () => reloadAllStores(context),
            child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
          SliverToBoxAdapter(
            child: MonthSelector(
              year: _selectedYear,
              month: _selectedMonth,
              onChanged: (y, m) => setState(() {
                _slideForward = y > _selectedYear || (y == _selectedYear && m > _selectedMonth);
                _selectedYear = y;
                _selectedMonth = m;
              }),
            ),
          ),
          if (isOverbudget || isOverspent)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isOverbudget)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: AppTheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your budgeted expenses are higher than your budgeted income for this month.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isOverbudget && isOverspent) const SizedBox(height: 6),
                    if (isOverspent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              size: 18,
                              color: AppTheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You\'ve spent more on expenses than you budgeted for this month.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SummaryCards(
                totalExpected: totalExpected,
                totalActual: totalActual,
                remaining: remaining,
                totalIncome: totalIncome,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: DashboardCharts(
              selectedYear: _selectedYear,
              selectedMonth: _selectedMonth,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.onSurfaceVariant,
                indicatorColor: AppTheme.primary,
                tabs: const [
                  Tab(text: 'Expenses'),
                  Tab(text: 'Budgeted'),
                  Tab(text: 'Incoming'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ExpensesTabContent(
                    year: _selectedYear,
                    month: _selectedMonth,
                    periods: periods,
                  ),
                  _BudgetsTabContent(
                    year: _selectedYear,
                    month: _selectedMonth,
                    config: config,
                    periods: periods,
                  ),
                  _AccountsTabContent(
                    year: _selectedYear,
                    month: _selectedMonth,
                    config: config,
                    periods: periods,
                    periodTotals: periodTotals,
                  ),
                ],
              ),
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

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.totalExpected,
    required this.totalActual,
    required this.remaining,
    required this.totalIncome,
  });

  final double totalExpected;
  final double totalActual;
  final double remaining;
  final double totalIncome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Expected Expenses',
                value: totalExpected,
                valueColor: AppTheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Actual Expenses',
                value: totalActual,
                valueColor: totalActual <= totalExpected ? AppTheme.success : AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Remaining Expenses',
                value: remaining,
                valueColor: remaining >= 0 ? AppTheme.success : AppTheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Actual Budget',
                value: totalIncome,
                valueColor: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final double value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Transform.scale(
          scale: t,
          child: Opacity(
            opacity: t,
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
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPeso(value),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExpensesTabContent extends StatelessWidget {
  const _ExpensesTabContent({
    required this.year,
    required this.month,
    required this.periods,
  });

  final int year;
  final int month;
  final List<PayPeriod> periods;

  /// Display name for an expense transaction: prefer budget name when [t.budgetId] is set.
  String _displayNameForTransaction(
    Transaction t,
    BudgetStore budgetStore,
    CategoryStore categoryStore,
    ExpenseStore expenseStore,
  ) {
    if (t.budgetId != null) {
      final b = budgetStore.byId(t.budgetId!);
      if (b != null) {
        if (b.name != null && b.name!.trim().isNotEmpty) return b.name!.trim();
        final category = categoryStore.byId(b.referenceId);
        if (category != null) return category.name;
        final exp = expenseStore.byId(b.referenceId);
        return exp?.name ?? t.notes ?? t.referenceId;
      }
    }
    return expenseStore.byId(t.referenceId)?.name ?? t.notes ?? t.referenceId;
  }

  @override
  Widget build(BuildContext context) {
    final txStore = context.watch<TransactionStore>();
    final expenseStore = context.watch<ExpenseStore>();
    final budgetStore = context.watch<BudgetStore>();
    final categoryStore = context.watch<CategoryStore>();

    // When there are defined pay periods, show expenses whose dates fall inside
    // those periods (respecting the pay schedule), regardless of calendar month.
    // Otherwise, fall back to simple month-based filtering.
    final allExpenses = txStore.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final monthTransactions = (periods.isNotEmpty
            ? allExpenses.where((t) => periods.any((p) => p.contains(t.date)))
            : txStore
                .forMonth(year, month)
                .where((t) => t.type == TransactionType.expense))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (periods.isEmpty) {
      final total = monthTransactions.fold(0.0, (s, t) => s + t.amount);
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            'No pay periods',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...monthTransactions.asMap().entries.map((entry) {
            final index = entry.key;
            final t = entry.value;
            final name =
                _displayNameForTransaction(t, budgetStore, categoryStore, expenseStore);
            final dotColor = colorForIndex(index);
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
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatPesoCompact(t.amount),
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
                formatPeso(total),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: total >= 0 ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: periods.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final periodTx = monthTransactions.where((t) => p.contains(t.date)).toList();
            final subtotal = periodTx.fold(0.0, (s, t) => s + t.amount);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < periods.length - 1 ? 8 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...periodTx.asMap().entries.map((e) {
                      final idx = e.key;
                      final t = e.value;
                      final name = _displayNameForTransaction(
                          t, budgetStore, categoryStore, expenseStore);
                      final dotColor = colorForIndex(idx);
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
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formatPesoCompact(t.amount),
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
                        Flexible(
                          child: Text(
                            formatPeso(subtotal),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: subtotal >= 0 ? AppTheme.success : AppTheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BudgetsTabContent extends StatelessWidget {
  const _BudgetsTabContent({
    required this.year,
    required this.month,
    required this.config,
    required this.periods,
  });

  final int year;
  final int month;
  final PayScheduleConfig config;
  final List<PayPeriod> periods;

  String _displayName(bi.BudgetItem item, CategoryStore categoryStore, ExpenseStore expenseStore, IncomeStore incomeStore) {
    if (item.name != null && item.name!.trim().isNotEmpty) return item.name!.trim();
    final category = categoryStore.byId(item.referenceId);
    if (category != null) return category.name;
    if (item.type == bi.BudgetType.expense) {
      return expenseStore.expenses
              .where((e) => e.id == item.referenceId)
              .map((e) => e.name)
              .firstOrNull ??
          item.referenceId;
    }
    return incomeStore.byId(item.referenceId)?.name ?? item.referenceId;
  }

  @override
  Widget build(BuildContext context) {
    final budgetStore = context.watch<BudgetStore>();
    final categoryStore = context.watch<CategoryStore>();
    final expenseStore = context.watch<ExpenseStore>();
    final incomeStore = context.watch<IncomeStore>();

    if (periods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No pay periods',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: periods.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final items = budgetStore.budgetsForPeriod(year, month, p.periodKey, p.indexInMonth);
            // Sort budgets: income first, then expense, each group alphabetically by display name.
            final sortedItems = [...items]..sort((a, b) {
              int rank(bi.BudgetItem x) =>
                  x.type == bi.BudgetType.income ? 0 : 1;
              final rA = rank(a);
              final rB = rank(b);
              if (rA != rB) return rA.compareTo(rB);
              final nameA = _displayName(a, categoryStore, expenseStore, incomeStore).toLowerCase();
              final nameB = _displayName(b, categoryStore, expenseStore, incomeStore).toLowerCase();
              return nameA.compareTo(nameB);
            });
            final subtotal = sortedItems.fold<double>(
              0.0,
              (s, b) => s +
                  (b.type == bi.BudgetType.expense
                      ? -b.expectedAmount
                      : b.expectedAmount),
            );
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < periods.length - 1 ? 8 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sortedItems.asMap().entries.map((e) {
                      final b = e.value;
                      final name = _displayName(b, categoryStore, expenseStore, incomeStore);
                      final category = categoryStore.byId(b.referenceId);
                      final dotColor = category != null
                          ? Color(category.colorValue)
                          : (b.type == bi.BudgetType.expense
                              ? AppTheme.error
                              : AppTheme.primary);
                      final amount = b.type == bi.BudgetType.expense
                          ? -b.expectedAmount
                          : b.expectedAmount;
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
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatPesoCompact(amount),
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
                        Flexible(
                          child: Text(
                            formatPeso(subtotal),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: subtotal >= 0 ? AppTheme.success : AppTheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AccountsTabContent extends StatelessWidget {
  const _AccountsTabContent({
    required this.year,
    required this.month,
    required this.config,
    required this.periods,
    required this.periodTotals,
  });

  final int year;
  final int month;
  final PayScheduleConfig config;
  final List<PayPeriod> periods;
  final List<double> periodTotals;

  @override
  Widget build(BuildContext context) {
    final accountStore = context.watch<AccountStore>();
    final budgetStore = context.watch<BudgetStore>();
    final txStore = context.watch<TransactionStore>();
    // Sort accounts alphabetically by name.
    final accounts = [...accountStore.accounts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final accountIds = accounts.map((a) => a.id).toList();

    if (periods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No pay periods',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    double remainingExpenseForAccountInPeriod(Account account, PayPeriod period) {
      // Use the same logic as Accounts screen: remaining expenses (budgeted - actual)
      // for expense budget items assigned to this account in the given period.
      final periodBudgets = budgetStore
          .budgetsForPeriod(
            year,
            month,
            period.periodKey,
            period.indexInMonth,
          )
          .where((b) => b.type == bi.BudgetType.expense && b.accountId == account.id)
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

    double subtotalForPeriod(PayPeriod period) {
      return accounts.fold<double>(
        0.0,
        (sum, a) => sum + remainingExpenseForAccountInPeriod(a, period),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: periods.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final pSubtotal = subtotalForPeriod(p);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < periods.length - 1 ? 8 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...accounts.asMap().entries.map((e) {
                      final a = e.value;
                      final amt = remainingExpenseForAccountInPeriod(a, p);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: a.iconColorValue != null
                                    ? colorFromValue(a.iconColorValue!)
                                    : colorForIndex(e.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a.name,
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
                        Flexible(
                          child: Text(
                            formatPeso(pSubtotal),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: pSubtotal >= 0 ? AppTheme.success : AppTheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
