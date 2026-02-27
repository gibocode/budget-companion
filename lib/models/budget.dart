class MonthlyBudget {
  const MonthlyBudget({
    required this.id,
    required this.year,
    required this.month,
    required this.budgetAmount,
  });

  final String id;
  final int year;
  final int month;
  final double budgetAmount;

  MonthlyBudget copyWith({
    String? id,
    int? year,
    int? month,
    double? budgetAmount,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      budgetAmount: budgetAmount ?? this.budgetAmount,
    );
  }
}
