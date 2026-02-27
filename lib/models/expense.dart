import 'enums.dart';

class Expense {
  const Expense({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.amount,
    required this.frequency,
    required this.scheduleType,
    this.recurringExpectedAmount,
    this.dueDate,
    required this.budgetType,
    this.order = 0,
  });

  final String id;
  final String name;
  final String categoryId;
  final double amount;
  final ExpenseFrequency frequency;
  /// Every period, first period only, or second period only.
  final ScheduleType scheduleType;
  /// If set, expected is this amount every month; else use amount.
  final double? recurringExpectedAmount;
  /// Optional due date (for future notifications).
  final DateTime? dueDate;
  final BudgetType budgetType;
  final int order;

  double get expectedAmount => recurringExpectedAmount ?? amount;

  /// Monthly total: for monthly = expectedAmount; for perPaycheck = expectedAmount * 2.
  double get monthlyTotal =>
      frequency == ExpenseFrequency.monthly ? expectedAmount : expectedAmount * 2;

  Expense copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? amount,
    ExpenseFrequency? frequency,
    ScheduleType? scheduleType,
    double? recurringExpectedAmount,
    DateTime? dueDate,
    BudgetType? budgetType,
    int? order,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      scheduleType: scheduleType ?? this.scheduleType,
      recurringExpectedAmount: recurringExpectedAmount ?? this.recurringExpectedAmount,
      dueDate: dueDate ?? this.dueDate,
      budgetType: budgetType ?? this.budgetType,
      order: order ?? this.order,
    );
  }
}
