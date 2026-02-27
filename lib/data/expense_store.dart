import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/enums.dart';
import 'local_db.dart';

class ExpenseStore extends ChangeNotifier {
  ExpenseStore() {
    _loadFromDb();
  }

  List<Expense> _expenses = [];

  List<Expense> get expenses => List.unmodifiable(_expenses);

  Future<void> addExpense(Expense e) async {
    _expenses = [..._expenses, e];
    _expenses.sort((a, b) => a.order.compareTo(b.order));
    await _saveExpense(e);
    notifyListeners();
  }

  Future<void> updateExpense(Expense e) async {
    final i = _expenses.indexWhere((x) => x.id == e.id);
    if (i < 0) return;
    _expenses = [..._expenses];
    _expenses[i] = e;
    _expenses.sort((a, b) => a.order.compareTo(b.order));
    await _saveExpense(e);
    notifyListeners();
  }

  Future<void> removeExpense(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    _expenses = _expenses.where((e) => e.id != id).toList();
    notifyListeners();
  }

  Expense? byId(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    try {
      final rows = await db.query('expenses', orderBy: 'sort_order ASC');
      _expenses = rows.map(_fromRow).toList();
    } catch (_) {
      _expenses = [];
    }
    notifyListeners();
  }

  Future<void> reload() => _loadFromDb();

  Future<void> _saveExpense(Expense e) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'expenses',
      _toRow(e),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Map<String, Object?> _toRow(Expense e) {
    return {
      'id': e.id,
      'name': e.name,
      'category_id': e.categoryId,
      'amount': e.amount,
      'frequency': e.frequency.index,
      'schedule_type': e.scheduleType.index,
      'recurring_expected_amount': e.recurringExpectedAmount,
      'due_date': e.dueDate?.toIso8601String(),
      'budget_type': e.budgetType.index,
      'sort_order': e.order,
    };
  }

  static Expense _fromRow(Map<String, Object?> row) {
    final freqIndex = (row['frequency'] as int?) ?? 0;
    final schedIndex = (row['schedule_type'] as int?) ?? 0;
    final budgetIndex = (row['budget_type'] as int?) ?? 0;
    DateTime? dueDate;
    final dueStr = row['due_date'] as String?;
    if (dueStr != null) {
      dueDate = DateTime.tryParse(dueStr);
    }
    return Expense(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryId: row['category_id'] as String,
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      frequency: freqIndex < ExpenseFrequency.values.length
          ? ExpenseFrequency.values[freqIndex]
          : ExpenseFrequency.monthly,
      scheduleType: schedIndex < ScheduleType.values.length
          ? ScheduleType.values[schedIndex]
          : ScheduleType.everyPeriod,
      recurringExpectedAmount: (row['recurring_expected_amount'] as num?)?.toDouble(),
      dueDate: dueDate,
      budgetType: budgetIndex < BudgetType.values.length
          ? BudgetType.values[budgetIndex]
          : BudgetType.fixed,
      order: (row['sort_order'] as int?) ?? 0,
    );
  }
}
