class DebtItem {
  const DebtItem({
    required this.id,
    required this.name,
    this.categoryId,
    required this.monthlyAmount,
    required this.monthsRemaining,
    required this.nextDueDate,
  });

  final String id;
  final String name;
  /// Id of the category from CategoryStore. Null = uncategorized.
  final String? categoryId;
  final double monthlyAmount;
  final int monthsRemaining;
  /// Next due date for this debt (date of the upcoming payment).
  final DateTime nextDueDate;

  DateTime get expectedPaidOffDate {
    if (monthsRemaining <= 1) return nextDueDate;
    return DateTime(
      nextDueDate.year,
      nextDueDate.month + (monthsRemaining - 1),
      nextDueDate.day,
    );
  }

  double get remainingTotal => monthlyAmount * monthsRemaining;

  DebtItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? monthlyAmount,
    int? monthsRemaining,
    DateTime? nextDueDate,
  }) {
    return DebtItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      monthsRemaining: monthsRemaining ?? this.monthsRemaining,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }
}

