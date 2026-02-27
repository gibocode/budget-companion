/// Budget = expected amount for a given scope (month or pay period), for expense or income.
enum BudgetType { expense, income }

/// How this budget repeats (or one-time).
enum BudgetRecurrenceMode {
  /// Only this month (or this period).
  oneTimeMonth,
  /// Same amount every month.
  everyMonth,
  /// Same amount every pay period.
  everyPayPeriod,
  /// When advancing month/period, copy from previous month or previous period.
  copyFromPrevious,
}

class BudgetItem {
  const BudgetItem({
    required this.id,
    required this.type,
    required this.referenceId,
    required this.year,
    required this.month,
    this.payPeriodIndex,
    this.periodKey,
    required this.expectedAmount,
    this.recurrenceMode = BudgetRecurrenceMode.oneTimeMonth,
    this.copiesFromPrevious = false,
    this.recurrenceInterval = 1,
    this.recurrenceMaxCount,
    this.name,
    this.accountId,
  });

  final String id;
  final BudgetType type;
  /// expenseId when type==expense, incomeId when type==income
  final String referenceId;
  final int year;
  final int month;
  /// 1-based period within month; null = whole month.
  final int? payPeriodIndex;
  /// When set, this budget is for this period (same in any month that contains it). Format: yyyy-mm-dd of period start.
  final String? periodKey;
  final double expectedAmount;
  final BudgetRecurrenceMode recurrenceMode;
  final bool copiesFromPrevious;
  /// Recur every N pay periods (1 = every period, 2 = every 2 periods, etc.). Used when [recurrenceMode] is [BudgetRecurrenceMode.everyPayPeriod].
  final int recurrenceInterval;
  /// If set, recurrence stops after this many occurrences. Null = infinite.
  final int? recurrenceMaxCount;
  /// Optional custom label for this budget (overrides category name in UI).
  final String? name;
  /// When set, this budget is assigned to this account; Accounts screen shows it as planned payment for that account/period.
  final String? accountId;

  BudgetItem copyWith({
    String? id,
    BudgetType? type,
    String? referenceId,
    int? year,
    int? month,
    int? payPeriodIndex,
    String? periodKey,
    double? expectedAmount,
    BudgetRecurrenceMode? recurrenceMode,
    bool? copiesFromPrevious,
    int? recurrenceInterval,
    int? recurrenceMaxCount,
    String? name,
    String? accountId,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      year: year ?? this.year,
      month: month ?? this.month,
      payPeriodIndex: payPeriodIndex ?? this.payPeriodIndex,
      periodKey: periodKey ?? this.periodKey,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      recurrenceMode: recurrenceMode ?? this.recurrenceMode,
      copiesFromPrevious: copiesFromPrevious ?? this.copiesFromPrevious,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceMaxCount: recurrenceMaxCount ?? this.recurrenceMaxCount,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
    );
  }
}
