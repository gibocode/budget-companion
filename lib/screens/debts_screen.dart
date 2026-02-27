import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/category_store.dart';
import '../data/debt_store.dart';
import '../models/category.dart' as cat;
import '../models/debt_item.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/category_picker_sheet.dart';
import '../utils/reload_stores.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DebtStore>();
    final categoryStore = context.watch<CategoryStore>();
    final items = store.items;

    String categoryDisplayName(String? categoryId) {
      if (categoryId == null || categoryId.isEmpty) return 'Uncategorized';
      return categoryStore.byId(categoryId)?.name ?? 'Uncategorized';
    }

    final byCategoryId = <String, List<DebtItem>>{};
    for (final d in items) {
      final key = d.categoryId ?? '';
      byCategoryId.putIfAbsent(key, () => []).add(d);
    }
    final sortedCategoryIds = byCategoryId.keys.toList()
      ..sort((a, b) => categoryDisplayName(a.isEmpty ? null : a)
          .toLowerCase()
          .compareTo(categoryDisplayName(b.isEmpty ? null : b).toLowerCase()));

    final totalMonthly = items.fold<double>(
      0,
      (sum, d) => sum + (d.monthsRemaining > 0 ? d.monthlyAmount : 0),
    );
    final totalRemaining = items.fold<double>(
      0,
      (sum, d) => sum + (d.monthsRemaining > 0 ? d.remainingTotal : 0),
    );
    final activeDebts = items.where((d) => d.monthsRemaining > 0).toList();
    final dateFullyOutOfDebt = activeDebts.isEmpty
        ? null
        : activeDebts
            .map((d) => d.expectedPaidOffDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts'),
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadAllStores(context),
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly total',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatPeso(totalMonthly),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total remaining',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatPeso(totalRemaining),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dateFullyOutOfDebt != null || activeDebts.isEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppTheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            dateFullyOutOfDebt != null
                                ? Icons.event_available_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                            color: dateFullyOutOfDebt != null
                                ? AppTheme.primary
                                : AppTheme.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFullyOutOfDebt != null
                                ? 'Fully out of debt by ${DateFormat.yMMMd().format(dateFullyOutOfDebt)}'
                                : 'You\'re debt-free',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: dateFullyOutOfDebt != null
                                  ? AppTheme.onSurface
                                  : AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (sortedCategoryIds.isEmpty) {
                  return const SizedBox.shrink();
                }
                final categoryId = sortedCategoryIds[index];
                final categoryIdOrNull = categoryId.isEmpty ? null : categoryId;
                final debts = byCategoryId[categoryId]!..sort(
                  (a, b) => b.remainingTotal.compareTo(a.remainingTotal),
                );
                final activeDebts =
                    debts.where((d) => d.monthsRemaining > 0).toList();
                final completedDebts =
                    debts.where((d) => d.monthsRemaining <= 0).toList();
                final categoryMonthly = debts.fold<double>(
                  0,
                  (sum, d) =>
                      sum + (d.monthsRemaining > 0 ? d.monthlyAmount : 0),
                );
                final categoryRemaining = debts.fold<double>(
                  0,
                  (sum, d) =>
                      sum + (d.monthsRemaining > 0 ? d.remainingTotal : 0),
                );
                final store = context.read<DebtStore>();
                final categoryStore = context.read<CategoryStore>();
                final category = categoryIdOrNull != null ? categoryStore.byId(categoryIdOrNull) : null;
                final categoryName = categoryDisplayName(categoryIdOrNull);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (category != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Color(category.colorValue).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                                      size: 18,
                                      color: Color(category.colorValue),
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.category_rounded,
                                      size: 18,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatPeso(categoryMonthly),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.error,
                                ),
                              ),
                              Text(
                                formatPeso(categoryRemaining),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...activeDebts.asMap().entries.map((entry) {
                        final d = entry.value;
                        return _DebtTile(
                          debt: d,
                          category: category,
                          index: entry.key,
                          onTap: () => _openDebtSheet(context, store, debt: d),
                          onMarkComplete: () => store.updateDebt(
                              d.copyWith(monthsRemaining: 0)),
                          onUnmarkComplete: null,
                          onMonthsAdjust: (delta) {
                            final next =
                                (d.monthsRemaining + delta).clamp(0, 999);
                            store.updateDebt(
                                d.copyWith(monthsRemaining: next));
                          },
                        );
                      }),
                      if (completedDebts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...completedDebts.asMap().entries.map((entry) {
                          final d = entry.value;
                          final tileIndex = activeDebts.length + entry.key;
                          return _DebtTile(
                            debt: d,
                            category: category,
                            index: tileIndex,
                            onTap: null,
                            onMarkComplete: null,
                            onUnmarkComplete: () => store.updateDebt(
                                d.copyWith(monthsRemaining: 1)),
                            onMonthsAdjust: null,
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
              childCount: sortedCategoryIds.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
        heroTag: 'debts_fab',
        onPressed: () => _openDebtSheet(context, context.read<DebtStore>()),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

void _openDebtSheet(
  BuildContext context,
  DebtStore store, {
  DebtItem? debt,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DebtSheetContent(
      store: store,
      debt: debt,
    ),
  );
}

class _DebtSheetContent extends StatefulWidget {
  const _DebtSheetContent({
    required this.store,
    this.debt,
  });

  final DebtStore store;
  final DebtItem? debt;

  @override
  State<_DebtSheetContent> createState() => _DebtSheetContentState();
}

class _DebtSheetContentState extends State<_DebtSheetContent> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _monthsController;
  late DateTime _nextDueDate;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _nameController = TextEditingController(text: d?.name ?? '');
    _selectedCategoryId = d?.categoryId;
    _amountController = TextEditingController(
      text: d != null && d.monthlyAmount != 0
          ? d.monthlyAmount.toStringAsFixed(2)
          : '',
    );
    _monthsController = TextEditingController(
      text: d?.monthsRemaining != null && d!.monthsRemaining > 0
          ? d.monthsRemaining.toString()
          : '',
    );
    _nextDueDate = d?.nextDueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final months = int.tryParse(_monthsController.text.trim()) ?? 0;

    final existing = widget.debt;
    bool saved;
    if (existing != null) {
      saved = await widget.store.updateDebt(
        existing.copyWith(
          name: name,
          categoryId: _selectedCategoryId,
          monthlyAmount: amount,
          monthsRemaining: months,
          nextDueDate: _nextDueDate,
        ),
      );
    } else {
      final id = 'd_${DateTime.now().millisecondsSinceEpoch}';
      saved = await widget.store.addDebt(
        DebtItem(
          id: id,
          name: name,
          categoryId: _selectedCategoryId,
          monthlyAmount: amount,
          monthsRemaining: months,
          nextDueDate: _nextDueDate,
        ),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debt may not have been saved to storage. Try again or check storage.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _delete() {
    final existing = widget.debt;
    if (existing == null) return;
    _confirmDeleteDebt(context, existing, () async {
      await widget.store.deleteDebt(existing.id);
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.debt != null;
    final categoryStore = context.watch<CategoryStore>();
    final categories = [...categoryStore.categories]
      ..sort((a, b) => categoryPickerDisplayName(a, categoryStore)
          .toLowerCase()
          .compareTo(categoryPickerDisplayName(b, categoryStore).toLowerCase()));
    final dateLabel = DateFormat.yMMMd().format(_nextDueDate);
    final selectedCategory = _selectedCategoryId != null
        ? categoryStore.byId(_selectedCategoryId!)
        : null;

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
                isEdit ? 'Edit debt' : 'Add debt',
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
                  labelText: 'Name',
                  hintText: 'e.g. Car loan, BNPL',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
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
                onTap: () => showCategoryPickerSheet(
                  context: context,
                  categoryStore: categoryStore,
                  categories: categories,
                  onSelected: (id) =>
                      setState(() => _selectedCategoryId = id),
                ),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  isFocused: false,
                  decoration: InputDecoration(
                    hintText: 'Select category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: Row(
                    children: [
                      if (selectedCategory != null) ...[
                        CategoryPickerLeading(category: selectedCategory),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          selectedCategory != null
                              ? categoryPickerDisplayName(
                                  selectedCategory, categoryStore)
                              : 'Select category',
                          style: TextStyle(
                            color: selectedCategory != null
                                ? AppTheme.onSurface
                                : AppTheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly amount (₱)',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _monthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Months remaining',
                  hintText: 'e.g. 12',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Next due date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _pickDate,
                child: Text(dateLabel),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isEdit) ...[
                    TextButton(
                      onPressed: _delete,
                      child: const Text(
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

void _confirmMarkDebtComplete(
  BuildContext context,
  DebtItem debt,
  VoidCallback onConfirmed,
) {
  final hasRemaining = debt.monthsRemaining > 0 || debt.remainingTotal > 0;
  final String content = hasRemaining
      ? 'This debt has ${debt.monthsRemaining} month${debt.monthsRemaining == 1 ? '' : 's'} and ${formatPeso(debt.remainingTotal)} remaining. Mark as complete anyway?'
      : 'Mark this debt as complete?';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Mark debt as complete?'),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirmed();
          },
          child: const Text('Mark complete'),
        ),
      ],
    ),
  );
}

void _confirmUnmarkDebtComplete(
  BuildContext context,
  DebtItem debt,
  VoidCallback onConfirmed,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Unmark as complete?'),
      content: Text(
        '\"${debt.name}\" will be moved back to active debts. You can edit and adjust months again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirmed();
          },
          child: const Text('Unmark'),
        ),
      ],
    ),
  );
}

void _confirmDeleteDebt(
  BuildContext context,
  DebtItem debt,
  VoidCallback onDeleted,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete debt?'),
      content: Text(
        'Are you sure you want to delete \"${debt.name}\"? This cannot be undone.',
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

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debt,
    this.category,
    required this.index,
    this.onTap,
    this.onMarkComplete,
    this.onUnmarkComplete,
    this.onMonthsAdjust,
  });

  final DebtItem debt;
  final cat.Category? category;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onUnmarkComplete;
  final void Function(int delta)? onMonthsAdjust;

  @override
  Widget build(BuildContext context) {
    final payoffDate = debt.expectedPaidOffDate;
    final dueLabel = DateFormat.yMMMd().format(debt.nextDueDate);
    final payoffLabel = DateFormat.yMMMd().format(payoffDate);
    final isPaidOff = debt.monthsRemaining <= 0;

    return TweenAnimationBuilder<double>(
      key: ValueKey(debt.id),
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
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: isPaidOff ? null : onTap,
          onLongPress: isPaidOff && onUnmarkComplete != null
              ? () => _confirmUnmarkDebtComplete(context, debt, onUnmarkComplete!)
              : onMarkComplete != null
                  ? () => _confirmMarkDebtComplete(context, debt, onMarkComplete!)
                  : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Opacity(
              opacity: isPaidOff ? 0.6 : 1,
              child: Row(
                children: [
                  if (category != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(category!.colorValue).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          IconData(category!.iconCodePoint, fontFamily: 'MaterialIcons'),
                          size: 22,
                          color: Color(category!.colorValue),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.category_rounded,
                          size: 22,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          debt.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isPaidOff
                                ? AppTheme.onSurfaceVariant
                                : AppTheme.onSurface,
                            decoration:
                                isPaidOff ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Due $dueLabel · Paid off by $payoffLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPeso(debt.monthlyAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${debt.monthsRemaining} mo · ${formatPeso(debt.remainingTotal)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      if (onMonthsAdjust != null && !isPaidOff) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: debt.monthsRemaining > 0
                                    ? () => onMonthsAdjust!(-1)
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.remove_circle_outline,
                                    size: 22,
                                    color: debt.monthsRemaining > 0
                                        ? AppTheme.onSurfaceVariant
                                        : AppTheme.onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '${debt.monthsRemaining}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onMonthsAdjust!(1),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.add_circle_outline,
                                    size: 22,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

