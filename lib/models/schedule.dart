/// Bi-weekly split: amount allocated to period 1 or 2 for an expense in a month.
class ScheduleAmount {
  const ScheduleAmount({
    required this.expenseId,
    required this.year,
    required this.month,
    required this.period,
    required this.amount,
  });

  final String expenseId;
  final int year;
  final int month;
  final int period; // 1 or 2
  final double amount;

  ScheduleAmount copyWith({
    String? expenseId,
    int? year,
    int? month,
    int? period,
    double? amount,
  }) {
    return ScheduleAmount(
      expenseId: expenseId ?? this.expenseId,
      year: year ?? this.year,
      month: month ?? this.month,
      period: period ?? this.period,
      amount: amount ?? this.amount,
    );
  }
}
