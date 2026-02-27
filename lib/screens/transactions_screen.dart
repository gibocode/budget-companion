import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/allocation_store.dart';
import '../data/budget_store.dart';
import '../data/category_store.dart';
import '../data/expense_store.dart';
import '../data/income_store.dart';
import '../data/pay_schedule_store.dart';
import '../data/transaction_store.dart';
import '../models/budget_item.dart';
import '../models/transaction.dart';
import '../models/pay_schedule_config.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import '../widgets/month_slide_transition.dart';
import '../widgets/month_swipe_detector.dart';
import '../utils/reload_stores.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  bool _slideForward = true;
  bool _defaultMonthSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultMonthSet) {
      _defaultMonthSet = true;
      final now = DateTime.now();
      if (mounted && (_year != now.year || _month != now.month)) {
        setState(() {
          _year = now.year;
          _month = now.month;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txStore = context.watch<TransactionStore>();
    final expenseStore = context.watch<ExpenseStore>();
    final budgetStore = context.watch<BudgetStore>();
    final categoryStore = context.watch<CategoryStore>();
    final transactions = txStore.forMonth(_year, _month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: MonthSlideTransition(
        slideForward: _slideForward,
        monthKey: ValueKey('$_year-$_month'),
        child: MonthSwipeDetector(
          onSwipeNext: () => setState(() {
            _slideForward = true;
            var m = _month + 1, y = _year;
            if (m > 12) { m = 1; y++; }
            _year = y;
            _month = m;
          }),
          onSwipePrevious: () => setState(() {
            _slideForward = false;
            var m = _month - 1, y = _year;
            if (m < 1) { m = 12; y--; }
            _year = y;
            _month = m;
          }),
          child: RefreshIndicator(
            onRefresh: () => reloadAllStores(context),
            child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: MonthSelector(
              year: _year,
              month: _month,
              onChanged: (y, m) => setState(() {
                _slideForward = y > _year || (y == _year && m > _month);
                _year = y;
                _month = m;
              }),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transactions.length} transaction${transactions.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _monthNet(transactions),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No transactions this month.',
                subtitle: 'Tap + to add.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final t = transactions[index];
                  final displayName = _displayName(t, expenseStore, budgetStore);
                  final leadingIcon = _leadingIcon(t, budgetStore, categoryStore);
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(t.id),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 280 + (index * 35)),
                    curve: Curves.easeOutCubic,
                    builder: (context, tVal, child) {
                      return Transform.translate(
                        offset: Offset(0, 12 * (1 - tVal)),
                        child: Opacity(
                          opacity: tVal,
                          child: child,
                        ),
                      );
                    },
                    child: _TransactionTile(
                      transaction: t,
                      displayName: displayName,
                      leadingIcon: leadingIcon,
                      onTap: () => _openEditTransaction(context, t),
                      onDismissed: () {
                        txStore.removeTransaction(t.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaction removed'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: transactions.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      ),
      ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions_fab',
        onPressed: () => _openAddTransaction(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _monthNet(List<Transaction> transactions) {
    double income = 0, expense = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    final net = income - expense;
    if (net >= 0) return '+${formatPeso(net)}';
    return '-${formatPeso(-net)}';
  }

  String _displayName(Transaction t, ExpenseStore expenseStore, BudgetStore budgetStore) {
    if (t.budgetId != null) {
      final b = budgetStore.byId(t.budgetId!);
      if (b != null) {
        if (b.name != null && b.name!.trim().isNotEmpty) return b.name!.trim();
        if (b.type == BudgetType.expense) {
          return expenseStore.byId(b.referenceId)?.name ?? b.referenceId;
        }
        final income = context.read<IncomeStore>().byId(b.referenceId);
        return income?.name ?? b.referenceId;
      }
    }
    if (t.type == TransactionType.expense) {
      return expenseStore.byId(t.referenceId)?.name ?? t.referenceId;
    }
    final income = context.read<IncomeStore>().byId(t.referenceId);
    return income?.name ?? t.referenceId;
  }

  Widget? _leadingIcon(Transaction t, BudgetStore budgetStore, CategoryStore categoryStore) {
    if (t.budgetId == null) return null;
    final b = budgetStore.byId(t.budgetId!);
    if (b == null) return null;
    final category = categoryStore.byId(b.referenceId);
    if (category != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(category.colorValue).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
          size: 22,
          color: Color(category.colorValue),
        ),
      );
    }
    final isExpense = b.type == BudgetType.expense;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isExpense ? AppTheme.error : AppTheme.success).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isExpense ? Icons.receipt_long_rounded : Icons.trending_up_rounded,
        size: 22,
        color: isExpense ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  void _openAddTransaction(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => _AddTransactionSheet(
        year: _year,
        month: _month,
        onSaved: () {
          Navigator.pop(ctx);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction added'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }

  void _openEditTransaction(BuildContext context, Transaction t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => _AddTransactionSheet(
        year: _year,
        month: _month,
        existing: t,
        onSaved: () {
          Navigator.pop(ctx);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction updated'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.displayName,
    this.leadingIcon,
    required this.onTap,
    required this.onDismissed,
  });

  final Transaction transaction;
  final String displayName;
  final Widget? leadingIcon;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 26),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Remove transaction?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDismissed(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                leadingIcon ??
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isExpense ? AppTheme.error : AppTheme.success).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 22,
                        color: isExpense ? AppTheme.error : AppTheme.success,
                      ),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, y').format(transaction.date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'}${formatPeso(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isExpense ? AppTheme.error : AppTheme.success,
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

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet({
    required this.year,
    required this.month,
    this.existing,
    required this.onSaved,
  });

  final int year;
  final int month;
  final Transaction? existing;
  final VoidCallback onSaved;

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  late TransactionType _type;
  String? _referenceId;
  String? _budgetItemId;
  late DateTime _date;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _amountError;
  String? _referenceError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _referenceId = existing.referenceId;
      _budgetItemId = existing.budgetId;
      _date = existing.date;
      _amountController.text = existing.amount.toStringAsFixed(2);
      _notesController.text = existing.notes ?? '';
      // Preselect matching budget when no budgetId (legacy transaction).
      if (_budgetItemId == null) {
        final budgetStore = context.read<BudgetStore>();
        final allBudgets = budgetStore.allForMonth(widget.year, widget.month);
        final targetType =
            _type == TransactionType.expense ? BudgetType.expense : BudgetType.income;
        final match = allBudgets
            .where((b) => b.type == targetType && b.referenceId == _referenceId)
            .firstOrNull;
        _budgetItemId = match?.id;
      }
    } else {
      _type = TransactionType.expense;
      _referenceId = null;
      _budgetItemId = null;
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetStore = context.watch<BudgetStore>();
    final categoryStore = context.watch<CategoryStore>();
    final scheduleStore = context.watch<PayScheduleStore>();
    final config = scheduleStore.config;
    final policy = scheduleStore.monthInclusionPolicy;

    // Determine which "budget month" and pay period this transaction date falls into,
    // respecting the month inclusion policy so periods that cross month boundaries work correctly.
    int budgetYear = _date.year;
    int budgetMonth = _date.month;
    Set<String> periodKeys = const {};
    PayPeriod? periodForDate;

    if (config.startDate != null) {
      final (y, m) = config.defaultMonthForDate(_date, policy);
      budgetYear = y;
      budgetMonth = m;
      final periodsIncluded = config.periodsIncludedInMonth(budgetYear, budgetMonth, policy);
      periodKeys = periodsIncluded.map((p) => p.periodKey).toSet();
      for (final p in periodsIncluded) {
        if (p.contains(_date)) {
          periodForDate = p;
          break;
        }
      }
    }

    final allBudgets = periodKeys.isNotEmpty
        ? budgetStore.allForMonthWithPeriodKeys(budgetYear, budgetMonth, periodKeys)
        : budgetStore.allForMonth(budgetYear, budgetMonth);

    final targetBudgetType =
        _type == TransactionType.expense ? BudgetType.expense : BudgetType.income;

    final budgets = allBudgets.where((b) {
      if (b.type != targetBudgetType) return false;

      // When no pay schedule is configured or the date doesn't fall into any defined period,
      // fall back to whole-month budgets for the resolved budget month.
      if (config.startDate == null || periodForDate == null) {
        return b.periodKey == null &&
            b.year == budgetYear &&
            b.month == budgetMonth &&
            b.payPeriodIndex == null;
      }

      // When a period is defined, match budgets assigned to that period:
      // - New-style budgets with periodKey
      // - Legacy budgets keyed by (year, month, payPeriodIndex)
      if (b.periodKey != null) {
        return b.periodKey == periodForDate!.periodKey;
      }
      return b.year == budgetYear &&
          b.month == budgetMonth &&
          b.payPeriodIndex == periodForDate!.indexInMonth;
    }).toList()
      ..sort((a, b) => _budgetLabel(context, a)
          .toLowerCase()
          .compareTo(_budgetLabel(context, b).toLowerCase()));
    final selectedBudget = budgets.where((b) => b.id == _budgetItemId).firstOrNull;
    final budgetLabel =
        selectedBudget != null ? _budgetLabel(context, selectedBudget) : null;
    final budgetLeadingIcon = selectedBudget != null
        ? _budgetLeadingIcon(context, selectedBudget, categoryStore)
        : null;

    if (selectedBudget == null && _budgetItemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _budgetItemId = null;
          _referenceId = null;
        });
      });
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add transaction' : 'Edit transaction',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                _Chip(
                  label: 'Expense',
                  selected: _type == TransactionType.expense,
                  onTap: () => setState(() {
                    _type = TransactionType.expense;
                    _referenceId = null;
                    _budgetItemId = null;
                    _referenceError = null;
                  }),
                ),
                const SizedBox(width: 12),
                _Chip(
                  label: 'Income',
                  selected: _type == TransactionType.income,
                  onTap: () => setState(() {
                    _type = TransactionType.income;
                    _referenceId = null;
                    _budgetItemId = null;
                    _referenceError = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                isFocused: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: Text(DateFormat('MMM d, y').format(_date)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Budget', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            budgets.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No budgets for this month. Add budgets in the Budgets screen.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                    ),
                  )
                : InkWell(
                    onTap: () => _openBudgetPicker(context, budgets, categoryStore),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      isFocused: false,
                      decoration: InputDecoration(
                        hintText: 'Select budget',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        errorText: _referenceError,
                      ),
                      child: Row(
                        children: [
                          if (budgetLeadingIcon != null) ...[
                            budgetLeadingIcon,
                            const SizedBox(width: 10),
                          ],
                          if (budgetLabel != null)
                            Expanded(child: Text(budgetLabel, overflow: TextOverflow.ellipsis))
                          else
                            const Expanded(
                              child: Text(
                                'Select budget',
                                style: TextStyle(color: AppTheme.onSurfaceVariant),
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (₱)',
                hintText: '0.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add a note',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(context),
                    style: FilledButton.styleFrom(shape: const StadiumBorder()),
                    child: _saving
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        : Text(widget.existing == null ? 'Add' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _budgetLabel(BuildContext context, BudgetItem b) {
    // Prefer custom budget name when set.
    if (b.name != null && b.name!.trim().isNotEmpty) return b.name!.trim();
    if (b.type == BudgetType.expense) {
      final expense = context.read<ExpenseStore>().byId(b.referenceId);
      if (expense != null) return expense.name;
    } else {
      final income = context.read<IncomeStore>().byId(b.referenceId);
      if (income != null) return income.name;
    }
    return b.referenceId;
  }

  Widget _budgetLeadingIcon(
    BuildContext context,
    BudgetItem b,
    CategoryStore categoryStore,
  ) {
    final category = categoryStore.byId(b.referenceId);
    if (category != null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(category.colorValue).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
          size: 18,
          color: Color(category.colorValue),
        ),
      );
    }
    final isExpense = b.type == BudgetType.expense;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: (isExpense ? AppTheme.error : AppTheme.success).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isExpense ? Icons.receipt_long_rounded : Icons.trending_up_rounded,
        size: 18,
        color: isExpense ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  void _openBudgetPicker(
    BuildContext context,
    List<BudgetItem> budgets,
    CategoryStore categoryStore,
  ) {
    final txStore = context.read<TransactionStore>();
    final scheduleStore = context.read<PayScheduleStore>();
    final config = scheduleStore.config;
    final periodLengthDays = config.periodLengthDays;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: budgets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final b = budgets[i];
            final txType = b.type == BudgetType.expense
                ? TransactionType.expense
                : TransactionType.income;
            final spent = b.periodKey != null
                ? txStore.sumForBudgetInPeriod(
                    b.id,
                    b.referenceId,
                    txType,
                    b.periodKey!,
                    periodLengthDays,
                  )
                : txStore.sumForBudgetInMonth(
                    b.id,
                    b.referenceId,
                    txType,
                    b.year,
                    b.month,
                  );
            final remaining = b.expectedAmount - spent;
            return ListTile(
              leading: _budgetLeadingIcon(context, b, categoryStore),
              title: Text(
                _budgetLabel(context, b),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Remaining budget ${formatPesoCompact(remaining)}',
                style: TextStyle(
                  fontSize: 12,
                  color: remaining >= 0 ? AppTheme.onSurfaceVariant : AppTheme.error,
                ),
              ),
              onTap: () {
                setState(() {
                  _budgetItemId = b.id;
                  _referenceId = b.referenceId;
                  _referenceError = null;
                });
                Navigator.pop(ctx);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid amount');
      return;
    }
    setState(() => _amountError = null);

    if (_referenceId == null) {
      setState(() => _referenceError = 'Please select a budget');
      return;
    }
    setState(() => _referenceError = null);

    final store = context.read<TransactionStore>();
    final existing = widget.existing;

    setState(() => _saving = true);
    try {
      final id = existing?.id ?? 'tx_${_referenceId}_${DateTime.now().millisecondsSinceEpoch}';
      final t = Transaction(
        id: id,
        type: _type,
        referenceId: _referenceId!,
        date: _date,
        amount: amount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        budgetId: _budgetItemId,
      );
      if (existing != null) {
        store.updateTransaction(t);
      } else {
        await store.addTransaction(t);
        if (t.type == TransactionType.expense && t.budgetId != null) {
          final budgetStore = context.read<BudgetStore>();
          final allocationStore = context.read<AllocationStore>();
          final config = context.read<PayScheduleStore>().config;
          final budget = budgetStore.byId(t.budgetId!);
          if (budget?.accountId != null) {
            final periods = config.periodsForMonth(t.date.year, t.date.month);
            final period = periods.where((p) => p.contains(t.date)).firstOrNull;
            if (period != null) {
              await allocationStore.deduct(budget!.accountId!, period.periodKey, t.amount);
            }
          }
        }
      }
      if (!context.mounted) return;
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
