/// Payment frequency for an expense.
enum ExpenseFrequency {
  monthly,
  perPaycheck,
}

/// How the expense is typically paid.
enum PaymentMode {
  online,
  cash,
  cashOnline,
}

/// Whether the category budget is fixed (hard to change) or variable (easier to adjust).
enum BudgetType {
  fixed,
  variable,
}

/// When the expense is scheduled: every period, first period only, or second period only.
enum ScheduleType {
  everyPeriod,
  period1Only,
  period2Only,
}

/// Whether a category is used for expense or income.
enum CategoryType {
  expense,
  income,
}

extension ExpenseFrequencyX on ExpenseFrequency {
  String get label => switch (this) {
        ExpenseFrequency.monthly => 'Monthly',
        ExpenseFrequency.perPaycheck => 'Per paycheck',
      };
}

extension PaymentModeX on PaymentMode {
  String get label => switch (this) {
        PaymentMode.online => 'Online',
        PaymentMode.cash => 'Cash',
        PaymentMode.cashOnline => 'Cash/Online',
      };
}

extension BudgetTypeX on BudgetType {
  String get label => switch (this) {
        BudgetType.fixed => 'Fixed',
        BudgetType.variable => 'Variable',
      };
}

extension ScheduleTypeX on ScheduleType {
  String get label => switch (this) {
        ScheduleType.everyPeriod => 'Every period',
        ScheduleType.period1Only => 'First period only',
        ScheduleType.period2Only => 'Second period only',
      };
}

extension CategoryTypeX on CategoryType {
  String get label => switch (this) {
        CategoryType.expense => 'Expense',
        CategoryType.income => 'Income',
      };
}
