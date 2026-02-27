class Income {
  const Income({
    required this.id,
    required this.name,
    this.categoryId,
    this.recurringExpectedAmount,
  });

  final String id;
  final String name;
  /// Optional category.
  final String? categoryId;
  /// If set, expected amount is the same every month (recurring).
  final double? recurringExpectedAmount;

  Income copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? recurringExpectedAmount,
  }) {
    return Income(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      recurringExpectedAmount: recurringExpectedAmount ?? this.recurringExpectedAmount,
    );
  }
}

/// Expected/actual income for a given month.
class IncomeRecord {
  const IncomeRecord({
    required this.incomeId,
    required this.year,
    required this.month,
    required this.expectedAmount,
    required this.actualAmount,
  });

  final String incomeId;
  final int year;
  final int month;
  final double expectedAmount;
  final double actualAmount;

  IncomeRecord copyWith({
    String? incomeId,
    int? year,
    int? month,
    double? expectedAmount,
    double? actualAmount,
  }) {
    return IncomeRecord(
      incomeId: incomeId ?? this.incomeId,
      year: year ?? this.year,
      month: month ?? this.month,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
    );
  }
}
