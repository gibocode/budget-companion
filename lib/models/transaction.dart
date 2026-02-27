/// Unified transaction for both expense and income actuals.
enum TransactionType {
  expense,
  income,
}

class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.referenceId,
    required this.date,
    required this.amount,
    this.notes,
    this.budgetId,
  });

  final String id;
  final TransactionType type;
  /// expenseId when type==expense, incomeId when type==income (or category id when from budget).
  final String referenceId;
  final DateTime date;
  final double amount;
  final String? notes;
  /// When set, this transaction is attributed to this budget (display name/icon and period actual).
  final String? budgetId;

  bool isInMonth(int year, int month) =>
      date.year == year && date.month == month;

  String get expenseId => type == TransactionType.expense ? referenceId : '';
  String get incomeId => type == TransactionType.income ? referenceId : '';

  Transaction copyWith({
    String? id,
    TransactionType? type,
    String? referenceId,
    DateTime? date,
    double? amount,
    String? notes,
    String? budgetId,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      budgetId: budgetId ?? this.budgetId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
