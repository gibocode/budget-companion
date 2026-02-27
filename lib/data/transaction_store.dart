import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/transaction.dart';
import 'local_db.dart';

/// Unified store for all transactions (expense and income actuals). Persisted to DB.
class TransactionStore extends ChangeNotifier {
  TransactionStore() {
    _loadFromDb();
  }

  List<Transaction> _transactions = [];

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  /// All transactions in the given month, newest first.
  List<Transaction> forMonth(int year, int month) {
    int _creationTs(Transaction t) {
      final parts = t.id.split('_');
      if (parts.length >= 3) {
        final ts = int.tryParse(parts.last);
        if (ts != null) return ts;
      }
      return t.date.millisecondsSinceEpoch;
    }

    final list = _transactions.where((t) => t.isInMonth(year, month)).toList();
    list.sort((a, b) => _creationTs(b).compareTo(_creationTs(a)));
    return list;
  }

  List<Transaction> forExpenseInMonth(String expenseId, int year, int month) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.referenceId == expenseId &&
            t.isInMonth(year, month))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Transaction> forIncomeInMonth(String incomeId, int year, int month) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.referenceId == incomeId &&
            t.isInMonth(year, month))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double sumExpenseInMonth(String expenseId, int year, int month) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.referenceId == expenseId &&
            t.isInMonth(year, month))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double sumIncomeInMonth(String incomeId, int year, int month) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.referenceId == incomeId &&
            t.isInMonth(year, month))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double totalActualForMonth(int year, int month) {
    return _transactions
        .where((t) => t.isInMonth(year, month))
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Total transaction amount for the month filtered by [type] (expense or income).
  double totalActualForMonthByType(int year, int month, TransactionType type) {
    return _transactions
        .where((t) => t.isInMonth(year, month) && t.type == type)
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Total transaction amount for the given pay periods (identified by [periodKeys])
  /// filtered by [type] (expense or income). A transaction is counted if its date
  /// falls inside any of the periods.
  double totalActualForPeriodsByType(
    Set<String> periodKeys,
    TransactionType type,
    int periodLengthDays,
  ) {
    if (periodKeys.isEmpty) return 0;
    double total = 0.0;
    for (final key in periodKeys) {
      final start = _periodKeyToStart(key);
      if (start == null) continue;
      final end = start.add(Duration(days: periodLengthDays - 1));
      total += _transactions
          .where((t) =>
              t.type == type && _dateInRange(t.date, start, end))
          .fold(0.0, (s, t) => s + t.amount);
    }
    return total;
  }

  /// Sum of transaction amounts attributed to [budgetId] (or by [referenceId] when budgetId null)
  /// where the transaction date falls inside the pay period identified by [periodKey].
  double sumForBudgetInPeriod(
    String? budgetId,
    String referenceId,
    TransactionType type,
    String periodKey,
    int periodLengthDays,
  ) {
    final start = _periodKeyToStart(periodKey);
    if (start == null) return 0;
    final end = start.add(Duration(days: periodLengthDays - 1));
    return _transactions.where((t) {
      if (t.type != type) return false;
      final inRange = _dateInRange(t.date, start, end);
      if (t.budgetId != null) {
        return t.budgetId == budgetId && inRange;
      }
      return t.referenceId == referenceId && inRange;
    }).fold(0.0, (s, t) => s + t.amount);
  }

  /// Sum of transaction amounts for this budget in the given month (for budgets without periodKey).
  double sumForBudgetInMonth(
    String? budgetId,
    String referenceId,
    TransactionType type,
    int year,
    int month,
  ) {
    return _transactions.where((t) {
      if (!t.isInMonth(year, month)) return false;
      if (t.type != type) return false;
      if (t.budgetId != null) return t.budgetId == budgetId;
      return t.referenceId == referenceId;
    }).fold(0.0, (s, t) => s + t.amount);
  }

  static DateTime? _periodKeyToStart(String periodKey) {
    final parts = periodKey.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static bool _dateInRange(DateTime d, DateTime start, DateTime end) {
    final day = DateTime(d.year, d.month, d.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !day.isBefore(s) && !day.isAfter(e);
  }

  Future<void> addTransaction(Transaction t) async {
    _transactions = [..._transactions, t];
    await _saveTransaction(t);
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction t) async {
    final i = _transactions.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      _transactions = [..._transactions];
      _transactions[i] = t;
      await _saveTransaction(t);
      notifyListeners();
    }
  }

  Future<void> removeTransaction(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    _transactions = _transactions.where((t) => t.id != id).toList();
    notifyListeners();
  }

  Transaction? byId(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    try {
      final rows = await db.query('transactions');
      _transactions = rows.map(_fromRow).toList();
    } catch (_) {
      _transactions = [];
    }
    notifyListeners();
  }

  Future<void> reload() => _loadFromDb();

  Future<void> _saveTransaction(Transaction t) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'transactions',
      _toRow(t),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Map<String, Object?> _toRow(Transaction t) {
    return {
      'id': t.id,
      'type': t.type.index,
      'reference_id': t.referenceId,
      'date': t.date.toIso8601String(),
      'amount': t.amount,
      'notes': t.notes,
      'budget_id': t.budgetId,
    };
  }

  static Transaction _fromRow(Map<String, Object?> row) {
    final dateStr = row['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    return Transaction(
      id: row['id'] as String,
      type: TransactionType.values[(row['type'] as int?) ?? 0],
      referenceId: row['reference_id'] as String,
      date: date ?? DateTime.now(),
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      notes: row['notes'] as String?,
      budgetId: row['budget_id'] as String?,
    );
  }
}
