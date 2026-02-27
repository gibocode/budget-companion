import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/account_store.dart';
import '../data/budget_store.dart';
import '../data/category_store.dart';
import '../data/expense_store.dart';
import '../models/category.dart';
import '../data/income_store.dart';
import '../data/pay_schedule_store.dart';
import '../data/transaction_store.dart';
import '../models/budget_item.dart';
import '../models/transaction.dart';
import '../models/enums.dart' as enums;
import '../models/expense.dart';
import '../models/pay_schedule_config.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_colors.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/animated_slide_tile.dart';
import '../widgets/month_selector.dart';
import '../widgets/month_slide_transition.dart';
import '../widgets/month_swipe_detector.dart';
import '../utils/reload_stores.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  PayPeriod? _selectedPeriod;
  bool _slideForward = true;
  BudgetType _budgetType = BudgetType.expense;
  bool _defaultMonthSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultMonthSet) {
      _defaultMonthSet = true;
      final store = context.read<PayScheduleStore>();
      final (y, m) = store.config.defaultMonthForDate(DateTime.now(), store.monthInclusionPolicy);
      if (mounted && (_year != y || _month != m)) {
        setState(() {
          _year = y;
          _month = m;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleStore = context.watch<PayScheduleStore>();
    final config = scheduleStore.config;
    final policy = scheduleStore.monthInclusionPolicy;
    final periodsIncluded = config.startDate != null
        ? config.periodsIncludedInMonth(_year, _month, policy)
        : <PayPeriod>[];

    if (periodsIncluded.isNotEmpty && _selectedPeriod == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedPeriod = periodsIncluded.first);
      });
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Budgets'),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy budgets from period',
              onPressed: () => _openCopyBudgets(context),
            ),
          ],
        ),
        body: MonthSlideTransition(
          slideForward: _slideForward,
          monthKey: ValueKey('$_year-$_month'),
          child: MonthSwipeDetector(
            onSwipeNext: () {
              var m = _month + 1, y = _year;
              if (m > 12) { m = 1; y++; }
              final periods = config.startDate != null
                  ? config.periodsIncludedInMonth(y, m, policy)
                  : <PayPeriod>[];
              setState(() {
                _slideForward = true;
                _year = y;
                _month = m;
                _selectedPeriod = periods.isNotEmpty ? periods.first : null;
              });
            },
            onSwipePrevious: () {
              var m = _month - 1, y = _year;
              if (m < 1) { m = 12; y--; }
              final periods = config.startDate != null
                  ? config.periodsIncludedInMonth(y, m, policy)
                  : <PayPeriod>[];
              setState(() {
                _slideForward = false;
                _year = y;
                _month = m;
                _selectedPeriod = periods.isNotEmpty ? periods.first : null;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonthSelector(
                  year: _year,
                  month: _month,
                  onChanged: (y, m) {
                    setState(() {
                      _slideForward = y > _year || (y == _year && m > _month);
                      _year = y;
                      _month = m;
                      final periods = config.startDate != null
                          ? config.periodsIncludedInMonth(y, m, policy)
                          : <PayPeriod>[];
                      _selectedPeriod = periods.isNotEmpty ? periods.first : null;
                    });
                  },
                ),
                if (periodsIncluded.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: _BudgetPeriodCardsRow(
                      periods: periodsIncluded,
                      config: config,
                      year: _year,
                      month: _month,
                      budgetType: _budgetType,
                      selectedPeriod: _selectedPeriod,
                      onPeriodTap: (p) {
                        setState(() {
                          if (_selectedPeriod?.periodKey == p.periodKey) {
                            _selectedPeriod = null;
                          } else {
                            _selectedPeriod = p;
                          }
                        });
                      },
                    ),
                  ),
                if (periodsIncluded.isNotEmpty)
                  const SizedBox(height: 4),
                Expanded(
                  child: _BudgetTabContent(
                    year: _year,
                    month: _month,
                    budgetType: _budgetType,
                    selectedPeriod: _selectedPeriod,
                    periodsIncluded: periodsIncluded,
                    showMonthSelector: false,
                    showPeriodCardsInContent: periodsIncluded.isEmpty,
                    onBudgetTypeChanged: (t) => setState(() => _budgetType = t),
                    onRefresh: () => reloadAllStores(context),
                    onMonthChanged: (y, m) {
                      setState(() {
                        _slideForward = y > _year || (y == _year && m > _month);
                        _year = y;
                        _month = m;
                        final periods = config.startDate != null
                            ? config.periodsIncludedInMonth(y, m, policy)
                            : <PayPeriod>[];
                        _selectedPeriod = periods.isNotEmpty ? periods.first : null;
                      });
                    },
                    onPeriodTap: (p) {
                      setState(() {
                        if (_selectedPeriod?.periodKey == p.periodKey) {
                          _selectedPeriod = null;
                        } else {
                          _selectedPeriod = p;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'budget_fab',
          onPressed: () => _openAddBudget(context),
          child: const Icon(Icons.add_rounded),
        ),
      );
  }

  void _openCopyBudgets(BuildContext context) {
    final scheduleStore = context.read<PayScheduleStore>();
    final config = scheduleStore.config;
    final policy = scheduleStore.monthInclusionPolicy;
    final targetPeriods = config.startDate != null
        ? config.periodsIncludedInMonth(_year, _month, policy)
        : config.periodsForMonth(_year, _month);
    final defaultTarget = _selectedPeriod ??
        (targetPeriods.isNotEmpty ? targetPeriods.first : null);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => _CopyBudgetsSheet(
        defaultTargetYear: _year,
        defaultTargetMonth: _month,
        defaultTargetPeriod: defaultTarget,
        onCopied: (count) {
          Navigator.pop(ctx);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(count == 0
                  ? 'No budgets to copy'
                  : 'Copied $count budget${count == 1 ? '' : 's'} to period'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddBudget(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      enableDrag: true,
      builder: (ctx) => _AddBudgetSheet(
        year: _year,
        month: _month,
        initialBudgetType: _budgetType,
        onSaved: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Budget added'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openEditBudget(BuildContext context, BudgetItem b) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      enableDrag: true,
      builder: (ctx) => _AddBudgetSheet(
        year: _year,
        month: _month,
        existing: b,
        onSaved: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Budget updated'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, BudgetStore store, BudgetItem b) {
    final displayName = (b.name != null && b.name!.trim().isNotEmpty)
        ? b.name!.trim()
        : 'this budget';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete budget?'),
        content: Text(
          'Are you sure you want to delete "$displayName"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await store.removeBudget(b.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Budget deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}

/// Sheet to copy all budgets from one pay period to another (creates new independent budget items).
class _CopyBudgetsSheet extends StatefulWidget {
  const _CopyBudgetsSheet({
    required this.defaultTargetYear,
    required this.defaultTargetMonth,
    required this.defaultTargetPeriod,
    required this.onCopied,
  });

  final int defaultTargetYear;
  final int defaultTargetMonth;
  final PayPeriod? defaultTargetPeriod;
  final void Function(int count) onCopied;

  @override
  State<_CopyBudgetsSheet> createState() => _CopyBudgetsSheetState();
}

class _CopyBudgetsSheetState extends State<_CopyBudgetsSheet> {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late int _sourceYear;
  late int _sourceMonth;
  late int _targetYear;
  late int _targetMonth;
  PayPeriod? _sourcePeriod;
  PayPeriod? _targetPeriod;
  bool _copying = false;
  bool _initialSyncDone = false;

  @override
  void initState() {
    super.initState();
    _targetYear = widget.defaultTargetYear;
    _targetMonth = widget.defaultTargetMonth;
    _targetPeriod = widget.defaultTargetPeriod;
    // Default source to previous month.
    _sourceYear = widget.defaultTargetYear;
    _sourceMonth = widget.defaultTargetMonth;
    if (_sourceMonth > 1) {
      _sourceMonth--;
    } else {
      _sourceYear--;
      _sourceMonth = 12;
    }
    _sourcePeriod = null;
  }

  List<PayPeriod> _periodsFor(int year, int month) {
    final store = context.read<PayScheduleStore>();
    final config = store.config;
    if (config.startDate == null) {
      return config.periodsForMonth(year, month);
    }
    return config.periodsIncludedInMonth(year, month, store.monthInclusionPolicy);
  }

  void _syncSourcePeriod() {
    final periods = _periodsFor(_sourceYear, _sourceMonth);
    if (periods.isEmpty) {
      if (_sourcePeriod != null) setState(() => _sourcePeriod = null);
      return;
    }
    if (_sourcePeriod == null || !periods.any((p) => p.periodKey == _sourcePeriod!.periodKey)) {
      setState(() => _sourcePeriod = periods.first);
    }
  }

  void _syncTargetPeriod() {
    final periods = _periodsFor(_targetYear, _targetMonth);
    if (periods.isEmpty) {
      if (_targetPeriod != null) setState(() => _targetPeriod = null);
      return;
    }
    if (_targetPeriod == null || !periods.any((p) => p.periodKey == _targetPeriod!.periodKey)) {
      setState(() {
        _targetPeriod = periods.first;
        if (_sourcePeriod != null && _sourcePeriod!.periodKey == _targetPeriod!.periodKey) {
          _targetPeriod = _nextTargetPeriodAfter(periods, periods.first);
        }
      });
    }
  }

  /// When source and target would be the same period, return the next period so we don't create duplicates.
  PayPeriod _nextTargetPeriodAfter(List<PayPeriod> targetPeriods, PayPeriod current) {
    final idx = targetPeriods.indexWhere((p) => p.periodKey == current.periodKey);
    if (idx >= 0 && idx + 1 < targetPeriods.length) return targetPeriods[idx + 1];
    var nextMonth = _targetMonth + 1;
    var nextYear = _targetYear;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    final nextPeriods = _periodsFor(nextYear, nextMonth);
    return nextPeriods.isNotEmpty ? nextPeriods.first : current;
  }

  PayPeriod? _effectiveTargetPeriod() {
    if (_sourcePeriod == null || _targetPeriod == null) return _targetPeriod;
    final targetPeriods = _periodsFor(_targetYear, _targetMonth);
    if (targetPeriods.isEmpty) return _targetPeriod;
    if (_sourcePeriod!.periodKey != _targetPeriod!.periodKey) return _targetPeriod;
    return _nextTargetPeriodAfter(targetPeriods, _targetPeriod!);
  }

  Future<void> _copy() async {
    if (_sourcePeriod == null || _targetPeriod == null) return;
    final effectiveTarget = _effectiveTargetPeriod()!;
    final store = context.read<BudgetStore>();
    final sourceList = store.budgetsForPeriod(
      _sourcePeriod!.start.year,
      _sourcePeriod!.start.month,
      _sourcePeriod!.periodKey,
      _sourcePeriod!.indexInMonth,
    );
    if (sourceList.isEmpty) {
      widget.onCopied(0);
      return;
    }
    final existingInTarget = store.budgetsForPeriod(
      effectiveTarget.start.year,
      effectiveTarget.start.month,
      effectiveTarget.periodKey,
      effectiveTarget.indexInMonth,
    );
    final existingNames = existingInTarget
        .where((b) => b.name != null && b.name!.trim().isNotEmpty)
        .map((b) => b.name!.trim())
        .toSet();

    setState(() => _copying = true);
    var copiedCount = 0;
    final ts = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < sourceList.length; i++) {
      final b = sourceList[i];
      final name = b.name != null && b.name!.trim().isNotEmpty ? b.name!.trim() : null;
      if (name != null && existingNames.contains(name)) continue;

      final newId = 'budget_${b.referenceId}_${effectiveTarget.periodKey}_${ts}_$i';
      final clone = BudgetItem(
        id: newId,
        type: b.type,
        referenceId: b.referenceId,
        year: effectiveTarget.start.year,
        month: effectiveTarget.start.month,
        payPeriodIndex: effectiveTarget.indexInMonth,
        periodKey: effectiveTarget.periodKey,
        expectedAmount: b.expectedAmount,
        recurrenceMode: b.recurrenceMode,
        copiesFromPrevious: b.copiesFromPrevious,
        recurrenceInterval: b.recurrenceInterval,
        recurrenceMaxCount: b.recurrenceMaxCount,
        name: b.name,
        accountId: b.accountId,
      );
      await store.upsertBudget(clone);
      copiedCount++;
      if (name != null) existingNames.add(name);
    }
    if (!mounted) return;
    setState(() => _copying = false);
    widget.onCopied(copiedCount);
  }

  @override
  Widget build(BuildContext context) {
    final scheduleStore = context.watch<PayScheduleStore>();
    final config = scheduleStore.config;
    final sourcePeriods = _periodsFor(_sourceYear, _sourceMonth);
    final targetPeriods = _periodsFor(_targetYear, _targetMonth);

    if (!_initialSyncDone && sourcePeriods.isNotEmpty && targetPeriods.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _initialSyncDone = true;
          if (_sourcePeriod == null || !sourcePeriods.any((p) => p.periodKey == _sourcePeriod!.periodKey)) {
            _sourcePeriod = sourcePeriods.first;
          }
          if (_targetPeriod == null || !targetPeriods.any((p) => p.periodKey == _targetPeriod!.periodKey)) {
            _targetPeriod = targetPeriods.first;
          }
          if (_sourcePeriod != null && _targetPeriod != null &&
              _sourcePeriod!.periodKey == _targetPeriod!.periodKey) {
            _targetPeriod = _nextTargetPeriodAfter(targetPeriods, _targetPeriod!);
          }
        });
      });
    }

    final now = DateTime.now();
    final years = [now.year, now.year - 1];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Copy budgets to period',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creates new budget items in the target period. They are independent of the source.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 24),
            const Text('From', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: _sourceYear,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _sourceYear = v);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _syncSourcePeriod());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: _sourceMonth,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _sourceMonth = v);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _syncSourcePeriod());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: sourcePeriods.isEmpty
                        ? null
                        : (sourcePeriods.any((p) => p.periodKey == _sourcePeriod?.periodKey)
                            ? _sourcePeriod!.periodKey
                            : sourcePeriods.first.periodKey),
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: sourcePeriods
                        .map((p) => DropdownMenuItem(
                              value: p.periodKey,
                              child: Text(
                                config.labelForPeriod(p),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    selectedItemBuilder: sourcePeriods.isEmpty
                        ? null
                        : (context) => sourcePeriods
                            .map((p) => Text(
                                  config.labelForPeriod(p),
                                  overflow: TextOverflow.ellipsis,
                                ))
                            .toList(),
                    onChanged: sourcePeriods.isEmpty ? null : (v) {
                      if (v != null) setState(() => _sourcePeriod = sourcePeriods.firstWhere((e) => e.periodKey == v));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('To', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: _targetYear,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _targetYear = v);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _syncTargetPeriod());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: _targetMonth,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _targetMonth = v);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _syncTargetPeriod());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: targetPeriods.isEmpty
                        ? null
                        : (targetPeriods.any((p) => p.periodKey == _targetPeriod?.periodKey)
                            ? _targetPeriod!.periodKey
                            : targetPeriods.first.periodKey),
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: targetPeriods
                        .map((p) => DropdownMenuItem(
                              value: p.periodKey,
                              child: Text(
                                config.labelForPeriod(p),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    selectedItemBuilder: targetPeriods.isEmpty
                        ? null
                        : (context) => targetPeriods
                            .map((p) => Text(
                                  config.labelForPeriod(p),
                                  overflow: TextOverflow.ellipsis,
                                ))
                            .toList(),
                    onChanged: targetPeriods.isEmpty ? null : (v) {
                      if (v == null) return;
                      setState(() {
                        _targetPeriod = targetPeriods.firstWhere((e) => e.periodKey == v);
                        if (_sourcePeriod != null && _sourcePeriod!.periodKey == _targetPeriod!.periodKey) {
                          _targetPeriod = _nextTargetPeriodAfter(targetPeriods, _targetPeriod!);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _copying || (_sourcePeriod == null || _targetPeriod == null)
                  ? null
                  : _copy,
              child: _copying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Copy budgets'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab's content: optionally month selector, total, period cards, and list of budget items.
class _BudgetTabContent extends StatelessWidget {
  const _BudgetTabContent({
    required this.year,
    required this.month,
    required this.budgetType,
    required this.selectedPeriod,
    required this.periodsIncluded,
    required this.onMonthChanged,
    required this.onPeriodTap,
    this.showMonthSelector = true,
    this.showPeriodCardsInContent = true,
    this.onBudgetTypeChanged,
    this.onRefresh,
  });

  final int year;
  final int month;
  final BudgetType budgetType;
  final PayPeriod? selectedPeriod;
  final List<PayPeriod> periodsIncluded;
  final void Function(int y, int m) onMonthChanged;
  final ValueChanged<PayPeriod> onPeriodTap;
  final bool showMonthSelector;
  /// When false, period cards are shown by the parent (Budgets screen); don't duplicate here.
  final bool showPeriodCardsInContent;
  final ValueChanged<BudgetType>? onBudgetTypeChanged;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final budgetStore = context.watch<BudgetStore>();
    final scheduleStore = context.watch<PayScheduleStore>();
    final config = scheduleStore.config;
    final categoryStore = context.watch<CategoryStore>();
    final txStore = context.watch<TransactionStore>();
    final expenses = context.watch<ExpenseStore>().expenses;
    final periodKeys = periodsIncluded.map((p) => p.periodKey).toSet();
    final monthTotal = budgetStore.totalExpectedForMonthByType(
      year,
      month,
      periodKeys,
      budgetType,
    );
    final allItems = budgetStore.allForMonthWithPeriodKeys(year, month, periodKeys);
    final itemsForType = allItems.where((b) => b.type == budgetType).toList();

    final listItems = itemsForType.where((b) {
      if (selectedPeriod == null) return true;
      if (b.periodKey == selectedPeriod!.periodKey) return true;
      return b.year == year && b.month == month && b.payPeriodIndex == selectedPeriod!.indexInMonth;
    }).toList();

    String displayNameForSort(BudgetItem b) {
      if (b.name != null && b.name!.trim().isNotEmpty) return b.name!.trim();
      final category = categoryStore.byId(b.referenceId);
      if (category != null) return category.name;
      if (b.type == BudgetType.expense) {
        return expenses.where((e) => e.id == b.referenceId).map((e) => e.name).firstOrNull ?? b.referenceId;
      }
      return context.read<IncomeStore>().byId(b.referenceId)?.name ?? b.referenceId;
    }
    listItems.sort((a, b) => displayNameForSort(a).toLowerCase().compareTo(displayNameForSort(b).toLowerCase()));

    final txType = budgetType == BudgetType.expense
        ? TransactionType.expense
        : TransactionType.income;

    double listActualTotal = 0;
    for (final b in listItems) {
      if (b.periodKey != null && config.startDate != null) {
        listActualTotal += txStore.sumForBudgetInPeriod(
          b.id,
          b.referenceId,
          txType,
          b.periodKey!,
          config.periodLengthDays,
        );
      } else {
        listActualTotal += txStore.sumForBudgetInMonth(
          b.id,
          b.referenceId,
          txType,
          year,
          month,
        );
      }
    }
    final listExpectedTotal =
        listItems.fold<double>(0, (s, b) => s + b.expectedAmount);
    final listRemainingTotal = listExpectedTotal - listActualTotal;

    double summaryTotalBudgeted;
    double summaryTotalRemaining;

    if (config.startDate != null && periodsIncluded.isNotEmpty) {
      double periodBudgetedSum = 0;
      double periodRemainingSum = 0;

      for (final p in periodsIncluded) {
        final periodBudgets = budgetStore
            .budgetsForPeriod(
              year,
              month,
              p.periodKey,
              p.indexInMonth,
            )
            .where((b) => b.type == budgetType)
            .toList();

        if (periodBudgets.isEmpty) continue;

        double periodExpected = 0;
        double periodActual = 0;

        for (final b in periodBudgets) {
          periodExpected += b.expectedAmount;
          if (b.periodKey != null && config.startDate != null) {
            periodActual += txStore.sumForBudgetInPeriod(
              b.id,
              b.referenceId,
              txType,
              b.periodKey!,
              config.periodLengthDays,
            );
          } else {
            periodActual += txStore.sumForBudgetInMonth(
              b.id,
              b.referenceId,
              txType,
              year,
              month,
            );
          }
        }

        periodBudgetedSum += periodExpected;
        periodRemainingSum += (periodExpected - periodActual);
      }

      summaryTotalBudgeted = periodBudgetedSum;
      summaryTotalRemaining = periodRemainingSum;
    } else {
      summaryTotalBudgeted = listExpectedTotal;
      summaryTotalRemaining = listRemainingTotal;
    }

    // For the Income tab, the primary summary should show total actual
    // income from transactions attributed to the visible pay periods
    // (respecting the pay schedule). For the Expenses tab, keep
    // showing the remaining budget (budgeted minus actual).
    double summaryPrimaryValue;
    if (budgetType == BudgetType.income) {
      if (config.startDate != null && periodsIncluded.isNotEmpty) {
        final allPeriods = periodsIncluded.map((p) => p.periodKey).toSet();
        summaryPrimaryValue = txStore.totalActualForPeriodsByType(
          allPeriods,
          TransactionType.income,
          config.periodLengthDays,
        );
      } else {
        summaryPrimaryValue = txStore.totalActualForMonthByType(
          year,
          month,
          TransactionType.income,
        );
      }
    } else {
      summaryPrimaryValue = summaryTotalRemaining;
    }

    final scrollView = CustomScrollView(
      physics: onRefresh != null ? const AlwaysScrollableScrollPhysics() : null,
      slivers: [
        if (showMonthSelector)
          SliverToBoxAdapter(
            child: MonthSelector(
              year: year,
              month: month,
              onChanged: onMonthChanged,
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onBudgetTypeChanged != null) ...[
                  Builder(
                    builder: (context) {
                      final budgetStore = context.watch<BudgetStore>();

                      // When viewing Expenses, show existing "budgeted expenses > income" alert.
                      if (budgetType == BudgetType.expense) {
                        final periodKeys = (config.startDate != null
                                ? periodsIncluded
                                : config.periodsForMonth(year, month))
                            .map((p) => p.periodKey)
                            .toSet();
                        final totalExpense = budgetStore.totalExpectedForMonthByType(
                          year,
                          month,
                          periodKeys,
                          BudgetType.expense,
                        );
                        final totalIncome = budgetStore.totalExpectedForMonthByType(
                          year,
                          month,
                          periodKeys,
                          BudgetType.income,
                        );
                        if (totalExpense <= totalIncome) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              const Expanded(
                                child: Text(
                                  'Your budgeted expenses are higher than your budgeted income for this month.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // When viewing Income, show alert if actual income for the
                      // selected pay period is less than budgeted income items.
                      if (budgetType == BudgetType.income &&
                          config.startDate != null &&
                          selectedPeriod != null) {
                        final period = selectedPeriod!;
                        final budgetedIncomeForPeriod =
                            budgetStore.totalExpectedForPeriodByType(
                          year,
                          month,
                          period.periodKey,
                          period.indexInMonth,
                          BudgetType.income,
                        );
                        final actualIncomeForPeriod =
                            txStore.totalActualForPeriodsByType(
                          {period.periodKey},
                          TransactionType.income,
                          config.periodLengthDays,
                        );
                        if (actualIncomeForPeriod >= budgetedIncomeForPeriod ||
                            budgetedIncomeForPeriod <= 0) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                Icons.info_rounded,
                                size: 18,
                                color: AppTheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your income for this pay period is lower than your budgeted income.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            budgetType == BudgetType.expense ? 'Total Remaining' : 'Total Income',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            formatPeso(summaryPrimaryValue),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: summaryPrimaryValue >= 0 ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total budgeted',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            formatPeso(summaryTotalBudgeted),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onBudgetTypeChanged != null) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<BudgetType>(
                    segments: const [
                      ButtonSegment<BudgetType>(
                        value: BudgetType.expense,
                        label: Text('Expenses'),
                        icon: Icon(Icons.receipt_long_rounded, size: 18),
                      ),
                      ButtonSegment<BudgetType>(
                        value: BudgetType.income,
                        label: Text('Income'),
                        icon: Icon(Icons.trending_up_rounded, size: 18),
                      ),
                    ],
                    selected: {budgetType},
                    onSelectionChanged: (Set<BudgetType> selected) {
                      onBudgetTypeChanged!(selected.first);
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primary.withValues(alpha: 0.08);
                        }
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primary;
                        }
                        return AppTheme.onSurfaceVariant;
                      }),
                      side: WidgetStateProperty.all(
                        BorderSide(color: AppTheme.outline.withValues(alpha: 0.4)),
                      ),
                      elevation: WidgetStateProperty.all(0),
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                  ),
                ],
                if (config.startDate == null || periodsIncluded.isEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.outline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Set pay period start date in Settings → Pay period to see budgets by period.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ] else if (showPeriodCardsInContent) ...[
                  const SizedBox(height: 16),
                  _BudgetPeriodCardsRow(
                    periods: periodsIncluded,
                    config: config,
                    year: year,
                    month: month,
                    budgetType: budgetType,
                    selectedPeriod: selectedPeriod,
                    onPeriodTap: onPeriodTap,
                    ),
                  if (monthTotal == 0 && listItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'These dates come from Settings → Pay period. Tap + to add budgets and see amounts here.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ] else if (!showPeriodCardsInContent) ...[
                  const SizedBox.shrink(),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  selectedPeriod != null
                      ? 'Budget items · ${config.labelForPeriod(selectedPeriod!)}'
                      : 'Budget items · All',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  (budgetType == BudgetType.income && selectedPeriod != null)
                      ? formatPeso(
                          txStore.totalActualForPeriodsByType(
                            {selectedPeriod!.periodKey},
                            TransactionType.income,
                            config.periodLengthDays,
                          ),
                        )
                      : formatPeso(listRemainingTotal),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: (budgetType == BudgetType.income && selectedPeriod != null)
                        ? AppTheme.success
                        : (listRemainingTotal >= 0
                            ? AppTheme.success
                            : AppTheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (listItems.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No budgets for this period.\nTap + to add.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final b = listItems[index];
                final txStore = context.watch<TransactionStore>();
                String? periodLabel;
                if (selectedPeriod == null) {
                  if (b.periodKey != null) {
                    final p = periodsIncluded
                        .where((e) => e.periodKey == b.periodKey)
                        .firstOrNull;
                    periodLabel = p != null ? config.labelForPeriod(p) : null;
                  } else {
                    periodLabel = 'Whole month';
                  }
                }
                return AnimatedSlideTile(
                  delay: Duration(milliseconds: (index * 40).clamp(0, 200)),
                  child: _BudgetItemTile(
                    item: b,
                    year: year,
                    month: month,
                    config: config,
                    categoryStore: categoryStore,
                    expenses: expenses,
                    incomeStore: context.watch<IncomeStore>(),
                    txStore: txStore,
                    periodLabel: periodLabel,
                    onTap: () {
                      final state = context.findAncestorStateOfType<_BudgetScreenState>();
                      state?._openEditBudget(context, b);
                    },
                    onLongPress: () {
                      final state = context.findAncestorStateOfType<_BudgetScreenState>();
                      if (state != null) {
                        state._confirmDelete(context, budgetStore, b);
                      }
                    },
                  ),
                );
              },
              childCount: listItems.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
    return onRefresh != null
        ? RefreshIndicator(onRefresh: onRefresh!, child: scrollView)
        : scrollView;
  }
}

/// Pinned header for "Budget items · <period>" row; sticks to top when scrolling.
class _BudgetItemsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _BudgetItemsHeaderDelegate({
    required this.label,
    required this.amountFormatted,
    required this.amountColor,
  });

  final String label;
  final String amountFormatted;
  final Color amountColor;
  static const double _height = 44;

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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              amountFormatted,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _BudgetItemsHeaderDelegate oldDelegate) {
    return oldDelegate.label != label ||
        oldDelegate.amountFormatted != amountFormatted ||
        oldDelegate.amountColor != amountColor;
  }
}

class _BudgetPeriodCardsRow extends StatelessWidget {
  const _BudgetPeriodCardsRow({
    required this.periods,
    required this.config,
    required this.year,
    required this.month,
    required this.budgetType,
    required this.selectedPeriod,
    required this.onPeriodTap,
  });

  final List<PayPeriod> periods;
  final PayScheduleConfig config;
  final int year;
  final int month;
  final BudgetType budgetType;
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
              child: _BudgetPeriodCard(
                dateLabel: config.labelForPeriod(periods[i]),
                selected: selectedPeriod?.periodKey == periods[i].periodKey,
                isExpense: budgetType == BudgetType.expense,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BudgetPeriodCard extends StatelessWidget {
  const _BudgetPeriodCard({
    required this.dateLabel,
    required this.selected,
    required this.isExpense,
  });

  final String dateLabel;
  final bool selected;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? (isExpense ? AppTheme.errorContainer : AppTheme.primaryContainer).withValues(alpha: 0.5)
            : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? (isExpense ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.4)
              : (isExpense ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.2),
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

/// Single budget item row: name, allocated amount, and progress bar with percentage.
class _BudgetItemTile extends StatelessWidget {
  const _BudgetItemTile({
    required this.item,
    required this.year,
    required this.month,
    required this.config,
    required this.categoryStore,
    required this.expenses,
    required this.incomeStore,
    required this.txStore,
    this.periodLabel,
    required this.onTap,
    required this.onLongPress,
  });

  final BudgetItem item;
  final int year;
  final int month;
  final PayScheduleConfig config;
  final CategoryStore categoryStore;
  final List<Expense> expenses;
  final IncomeStore incomeStore;
  final TransactionStore txStore;
  final String? periodLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  double _actualSpent(BudgetItem b) {
    final txType = b.type == BudgetType.expense
        ? TransactionType.expense
        : TransactionType.income;
    if (b.periodKey != null && config.startDate != null) {
      return txStore.sumForBudgetInPeriod(
        b.id,
        b.referenceId,
        txType,
        b.periodKey!,
        config.periodLengthDays,
      );
    }
    return txStore.sumForBudgetInMonth(
      b.id,
      b.referenceId,
      txType,
      year,
      month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryStore.byId(item.referenceId);
    String name;
    if (category != null) {
      name = category.name;
    } else if (item.type == BudgetType.expense) {
      name = expenses
              .where((e) => e.id == item.referenceId)
              .map((e) => e.name)
              .firstOrNull ??
          item.referenceId;
    } else {
      name = incomeStore.byId(item.referenceId)?.name ?? item.referenceId;
    }
    final displayName = (item.name != null && item.name!.trim().isNotEmpty)
        ? item.name!.trim()
        : name;

    final expected = item.expectedAmount;
    final actual = _actualSpent(item);
    // For expenses, show remaining (budgeted - actual).
    // For income, show actual income for this budget item.
    final value = item.type == BudgetType.expense
        ? (expected - actual)
        : actual;
    final pct = expected > 0 ? (actual / expected).clamp(0.0, double.infinity) : 0.0;
    final pctClamped = pct.clamp(0.0, 1.0);
    final pctText = expected > 0 ? '${(pct * 100).round()}%' : '0%';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              category != null
                  ? Container(
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
                    )
                  : Icon(
                      item.type == BudgetType.expense
                          ? Icons.receipt_long_rounded
                          : Icons.trending_up_rounded,
                      color: item.type == BudgetType.expense
                          ? AppTheme.error
                          : AppTheme.primary,
                      size: 24,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (periodLabel != null && periodLabel!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.outline.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                periodLabel!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          formatPesoCompact(value),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: item.type == BudgetType.income
                                ? (actual >= expected ? AppTheme.success : AppTheme.error)
                                : (value >= 0 ? AppTheme.success : AppTheme.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pctClamped,
                        minHeight: 6,
                        backgroundColor: AppTheme.outline.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.type == BudgetType.expense
                              ? (pct > 1.0 ? AppTheme.error : AppTheme.success)
                              : (actual >= expected ? AppTheme.success : AppTheme.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budgeted ${formatPesoCompact(expected)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          pctText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet({
    required this.year,
    required this.month,
    this.existing,
    this.initialBudgetType = BudgetType.expense,
    required this.onSaved,
  });

  final int year;
  final int month;
  final BudgetItem? existing;
  final BudgetType initialBudgetType;
  final VoidCallback onSaved;

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  late BudgetType _type;
  String? _referenceId;
  int _periodIndex = 1;
  String? _accountId;
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  String? _nameError;
  String? _categoryError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _type = widget.existing!.type;
      _referenceId = widget.existing!.referenceId;
      _periodIndex = widget.existing!.payPeriodIndex ?? 1;
      _accountId = widget.existing!.type == BudgetType.expense
          ? widget.existing!.accountId
          : null;
      _amountController.text = widget.existing!.expectedAmount.toStringAsFixed(2);
      _nameController.text = widget.existing!.name ?? '';
    } else {
      _type = widget.initialBudgetType;
      _periodIndex = 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scheduleStore = context.read<PayScheduleStore>();
      final config = scheduleStore.config;
      final periods = config.startDate != null
          ? config.periodsIncludedInMonth(
              widget.year,
              widget.month,
              scheduleStore.monthInclusionPolicy,
            )
          : config.periodsForMonth(widget.year, widget.month);
      if (periods.isNotEmpty) {
        final valid = periods.map((p) => p.indexInMonth).toSet();
        if (!valid.contains(_periodIndex)) {
          setState(() => _periodIndex = periods.first.indexInMonth);
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _openCategoryPicker(BuildContext context, List<Category> categories) {
    showCategoryPickerSheet(
      context: context,
      categoryStore: context.read<CategoryStore>(),
      categories: categories,
      onSelected: (id) {
        setState(() {
          _referenceId = id;
          _categoryError = null;
        });
      },
    );
  }

  void _openAccountPicker(BuildContext context, List<Account> accounts) {
    const tileHeight = 64.0;
    const separatorHeight = 10.0;
    final itemCount = 1 + accounts.length; // None + accounts
    final maxH = MediaQuery.of(context).size.height * 0.78;
    final listHeight = (itemCount * tileHeight + (itemCount - 1).clamp(0, 999) * separatorHeight)
        .clamp(0.0, maxH - 80);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: listHeight + 80,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Assign to account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              height: listHeight,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: 1 + accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: const SizedBox(width: 32, height: 32),
                      title: const Text('None (unassigned)'),
                      onTap: () {
                        setState(() => _accountId = null);
                        Navigator.pop(ctx);
                      },
                    );
                  }
                  final account = accounts[i - 1];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: _AccountDisplay(account: account, index: i - 1),
                    title: Text(account.name),
                    onTap: () {
                      setState(() => _accountId = account.id);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetStore = context.read<BudgetStore>();
    // Pay periods from persisted PayScheduleStore (Settings → Pay period).
    final scheduleStore = context.watch<PayScheduleStore>();
    final config = scheduleStore.config;
    final categoryStore = context.watch<CategoryStore>();
    final categoryType = _type == BudgetType.expense
        ? enums.CategoryType.expense
        : enums.CategoryType.income;
    final categories = categoryStore.categoriesForType(categoryType);

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
              widget.existing == null ? 'Add budget' : 'Edit budget',
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
                  selected: _type == BudgetType.expense,
                  onTap: () => setState(() {
                    _type = BudgetType.expense;
                    _referenceId = null;
                    _categoryError = null;
                  }),
                ),
                const SizedBox(width: 12),
                _Chip(
                  label: 'Income',
                  selected: _type == BudgetType.income,
                  onTap: () => setState(() {
                    _type = BudgetType.income;
                    _referenceId = null;
                    _categoryError = null;
                    _accountId = null; // Accounts are for expenses only
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Budget name',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Groceries – Pay period 1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Category',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            categories.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No categories yet. Add expense or income categories in Settings → Configuration → Categories.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : InkWell(
                    onTap: () => _openCategoryPicker(context, categories),
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      isFocused: false,
                      decoration: InputDecoration(
                        hintText: 'Select category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        errorText: _categoryError,
                      ),
                      child: Row(
                        children: [
                          if (_referenceId != null) ...[
                            Builder(
                              builder: (context) {
                                final cat = categoryStore.byId(_referenceId!);
                                if (cat == null) return const SizedBox.shrink();
                                return CategoryPickerLeading(category: cat);
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final cat = categoryStore.byId(_referenceId!);
                                  if (cat == null) return const SizedBox.shrink();
                                  return Text(
                                    categoryPickerDisplayName(cat, categoryStore),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ] else
                            const Expanded(
                              child: Text(
                                'Select category',
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
            Builder(
              builder: (context) {
                // Use same period list as main budget screen (respects month inclusion policy).
                final periods = config.startDate != null
                    ? config.periodsIncludedInMonth(
                        widget.year,
                        widget.month,
                        scheduleStore.monthInclusionPolicy,
                      )
                    : config.periodsForMonth(widget.year, widget.month);
                if (periods.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.outline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'No pay periods for this month. Set pay period start date and interval in Settings → Pay period.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final validIndices =
                    periods.map((p) => p.indexInMonth).toSet();
                final effectivePeriodIndex =
                    validIndices.contains(_periodIndex)
                        ? _periodIndex
                        : periods.first.indexInMonth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pay period',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: effectivePeriodIndex,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.outline),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: periods
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p.indexInMonth,
                              child: Text(config.labelForPeriod(p)),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() => _periodIndex = v);
                              }
                            },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'From your saved pay schedule (Settings → Pay period)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Expected amount (₱)',
                hintText: '0.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            // Assign to account: only for expense budgets (accounts are used for expenses, not income).
            if (_type == BudgetType.expense)
              Builder(
              builder: (context) {
                final periods = config.startDate != null
                    ? config.periodsIncludedInMonth(
                        widget.year,
                        widget.month,
                        scheduleStore.monthInclusionPolicy,
                      )
                    : config.periodsForMonth(widget.year, widget.month);
                final hasPeriod = periods.isNotEmpty && periods.any((p) => p.indexInMonth == _periodIndex);
                final accounts = [...context.watch<AccountStore>().accounts]
                  ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                if (!hasPeriod || accounts.isEmpty) return const SizedBox.shrink();
                final selectedAccount = _accountId != null
                    ? accounts.where((a) => a.id == _accountId).firstOrNull
                    : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign to account',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _openAccountPicker(context, accounts),
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        isFocused: false,
                        decoration: InputDecoration(
                          hintText: 'None (unassigned)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: Row(
                          children: [
                            if (selectedAccount != null) ...[
                              _AccountDisplay(
                                account: selectedAccount,
                                index: accounts.indexWhere((a) => a.id == selectedAccount.id),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedAccount.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else
                              const Expanded(
                                child: Text(
                                  'None (unassigned)',
                                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Shows as planned payment for this account on the Accounts screen.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (widget.existing != null) ...[
                  TextButton(
                    onPressed: _saving ? null : () => _confirmDeleteFromSheet(context, budgetStore),
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                  const Spacer(),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(budgetStore),
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    child: _saving
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
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

  void _confirmDeleteFromSheet(BuildContext context, BudgetStore store) {
    final existing = widget.existing!;
    final displayName = (existing.name != null && existing.name!.trim().isNotEmpty)
        ? existing.name!.trim()
        : 'this budget';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete budget?'),
        content: Text(
          'Are you sure you want to delete "$displayName"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await store.removeBudget(existing.id);
              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Budget deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BudgetStore store) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Budget name is required');
      return;
    }
    setState(() => _nameError = null);

    if (_referenceId == null) {
      setState(() => _categoryError = 'Please select a category');
      return;
    }
    setState(() => _categoryError = null);

    final scheduleStore = context.read<PayScheduleStore>();
    final config = scheduleStore.config;
    final periods = config.startDate != null
        ? config.periodsIncludedInMonth(
            widget.year,
            widget.month,
            scheduleStore.monthInclusionPolicy,
          )
        : config.periodsForMonth(widget.year, widget.month);
    final selectedPeriod = periods
        .where((p) => p.indexInMonth == _periodIndex)
        .firstOrNull;

    final existing = widget.existing;

    setState(() => _saving = true);
    try {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

      final String id;
      final int year;
      final int month;
      final int? payPeriodIndex;
      final String? periodKey;

      if (selectedPeriod != null) {
        final pk = selectedPeriod.periodKey;
        periodKey = pk;
        // Anchor period budgets to the visible month on the Budgets screen
        // instead of the calendar month of the period's start date, so they
        // don't also appear as belonging to the previous month.
        year = widget.year;
        month = widget.month;
        payPeriodIndex = selectedPeriod.indexInMonth;
        id = existing?.id ??
            'budget_${_referenceId}_${pk}_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        periodKey = null;
        year = widget.year;
        month = widget.month;
        payPeriodIndex = _periodIndex;
        id = existing?.id ??
            'budget_${_referenceId}_${widget.year}_${widget.month}_${_periodIndex}_${DateTime.now().millisecondsSinceEpoch}';
      }

      await store.upsertBudget(BudgetItem(
        id: id,
        type: _type,
        referenceId: _referenceId!,
        year: year,
        month: month,
        payPeriodIndex: payPeriodIndex,
        periodKey: periodKey,
        expectedAmount: amount,
        recurrenceMode: BudgetRecurrenceMode.oneTimeMonth,
        copiesFromPrevious: false,
        recurrenceInterval: 1,
        recurrenceMaxCount: null,
        name: name,
        accountId: _type == BudgetType.expense ? _accountId : null,
      ));
      if (!mounted) return;
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AccountDisplay extends StatelessWidget {
  const _AccountDisplay({required this.account, required this.index});
  final Account account;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = account.iconColorValue != null
        ? colorFromValue(account.iconColorValue!)
        : colorForIndex(index);
    final containerColor = account.iconColorValue != null
        ? color.withValues(alpha: 0.15)
        : iconContainerColorForIndex(index);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        size: 18,
        color: color,
      ),
    );
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
