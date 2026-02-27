import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/category_store.dart';
import '../data/expense_store.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_colors.dart';
import 'expense_detail_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  bool _showVariableOnly = false;

  @override
  Widget build(BuildContext context) {
    var list = context.watch<ExpenseStore>().expenses;
    if (_showVariableOnly) {
      list = list.where((e) => e.budgetType == BudgetType.variable).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Variable only'),
              selected: _showVariableOnly,
              onSelected: (v) => setState(() => _showVariableOnly = v),
              selectedColor: AppTheme.warningContainer,
              checkmarkColor: AppTheme.warning,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final e = list[index];
          return _ExpenseListTile(
            expense: e,
            index: index,
            categoryName: context.watch<CategoryStore>().byId(e.categoryId)?.name,
            onDismissed: () => context.read<ExpenseStore>().removeExpense(e.id),
          );
        },
      ),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  const _ExpenseListTile({
    required this.expense,
    required this.index,
    this.categoryName,
    required this.onDismissed,
  });

  final Expense expense;
  final int index;
  final String? categoryName;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete expense?'),
            content: Text('Remove "${expense.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDismissed(),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(expense.id),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 280 + (index * 35)),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: Opacity(opacity: t, child: child),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseDetailScreen(expense: expense),
                  ),
                );
              },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconContainerColorForIndex(index),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconFor(expense.name),
                      size: 24,
                      color: colorForIndex(index),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (categoryName != null && categoryName!.isNotEmpty)
                              _Chip(label: categoryName!, variable: false),
                            const SizedBox(width: 6),
                            _Chip(label: expense.budgetType.label, variable: expense.budgetType == BudgetType.variable),
                            const SizedBox(width: 6),
                            _Chip(label: expense.scheduleType.label, variable: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatPeso(expense.monthlyTotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.variable});

  final String label;
  final bool variable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: variable ? AppTheme.warningContainer : AppTheme.outline.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: variable ? AppTheme.warning : AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

IconData _iconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('rent')) return Icons.home_rounded;
  if (n.contains('tithing') || n.contains('offering')) return Icons.volunteer_activism_rounded;
  if (n.contains('savings')) return Icons.savings_rounded;
  if (n.contains('power') || n.contains('bill')) return Icons.bolt_rounded;
  if (n.contains('grocer')) return Icons.shopping_basket_rounded;
  if (n.contains('internet')) return Icons.wifi_rounded;
  if (n.contains('credit')) return Icons.credit_card_rounded;
  return Icons.receipt_long_rounded;
}
