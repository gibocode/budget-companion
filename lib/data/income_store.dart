import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/income.dart';
import 'local_db.dart';

/// Incomes list and expected amounts per month. Actuals come from TransactionStore.
class IncomeStore extends ChangeNotifier {
  IncomeStore() {
    _loadFromDb();
  }

  List<Income> _incomes = [];
  final Map<String, IncomeRecord> _overrides = {};
  final Map<String, double> _recurringExpected = {};

  List<Income> get incomes => List.unmodifiable(_incomes);

  String _key(String incomeId, int year, int month) =>
      '${incomeId}_${year}_$month';

  double getExpected(String incomeId, int year, int month) {
    if (_recurringExpected.containsKey(incomeId)) {
      return _recurringExpected[incomeId]!;
    }
    final k = _key(incomeId, year, month);
    if (_overrides.containsKey(k)) return _overrides[k]!.expectedAmount;
    return 0;
  }

  void setRecurringExpected(String incomeId, double amount) {
    if (amount == 0) {
      _recurringExpected.remove(incomeId);
    } else {
      _recurringExpected[incomeId] = amount;
    }
    notifyListeners();
  }

  bool isRecurring(String incomeId) => _recurringExpected.containsKey(incomeId);

  IncomeRecord getRecord(String incomeId, int year, int month, double actualSum) {
    final expected = getExpected(incomeId, year, month);
    return IncomeRecord(
      incomeId: incomeId,
      year: year,
      month: month,
      expectedAmount: expected,
      actualAmount: actualSum,
    );
  }

  Future<void> setRecord(String incomeId, int year, int month,
      {required double expectedAmount, required double actualAmount}) async {
    final r = IncomeRecord(
      incomeId: incomeId,
      year: year,
      month: month,
      expectedAmount: expectedAmount,
      actualAmount: actualAmount,
    );
    _overrides[_key(incomeId, year, month)] = r;
    await _saveIncomeRecord(r);
    notifyListeners();
  }

  Income? byId(String id) {
    try {
      return _incomes.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addIncome(Income i) async {
    _incomes = [..._incomes, i];
    _incomes.sort((a, b) => a.name.compareTo(b.name));
    await _saveIncome(i);
    notifyListeners();
  }

  Future<void> updateIncome(Income i) async {
    final idx = _incomes.indexWhere((x) => x.id == i.id);
    if (idx < 0) return;
    _incomes = [..._incomes];
    _incomes[idx] = i;
    _incomes.sort((a, b) => a.name.compareTo(b.name));
    await _saveIncome(i);
    notifyListeners();
  }

  Future<void> removeIncome(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete('income_records', where: 'income_id = ?', whereArgs: [id]);
    _incomes = _incomes.where((x) => x.id != id).toList();
    _overrides.removeWhere((k, _) => k.startsWith('${id}_'));
    _recurringExpected.remove(id);
    notifyListeners();
  }

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    try {
      final incomeRows = await db.query('incomes', orderBy: 'sort_order ASC');
      _incomes = incomeRows.map(_incomeFromRow).toList();
    } catch (_) {
      _incomes = [];
    }
    try {
      final recordRows = await db.query('income_records');
      for (final row in recordRows) {
        final r = _recordFromRow(row);
        _overrides[_key(r.incomeId, r.year, r.month)] = r;
      }
    } catch (_) {}
    for (final i in _incomes) {
      if (i.recurringExpectedAmount != null && i.recurringExpectedAmount! > 0) {
        _recurringExpected[i.id] = i.recurringExpectedAmount!;
      }
    }
    notifyListeners();
  }

  Future<void> reload() => _loadFromDb();

  Future<void> _saveIncome(Income i) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'incomes',
      _incomeToRow(i),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveIncomeRecord(IncomeRecord r) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'income_records',
      _recordToRow(r),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Map<String, Object?> _incomeToRow(Income i) {
    return {
      'id': i.id,
      'name': i.name,
      'category_id': i.categoryId,
      'recurring_expected_amount': i.recurringExpectedAmount,
      'sort_order': _incomeOrder(i),
    };
  }

  static int _incomeOrder(Income i) => 0;

  static Income _incomeFromRow(Map<String, Object?> row) {
    return Income(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryId: row['category_id'] as String?,
      recurringExpectedAmount: (row['recurring_expected_amount'] as num?)?.toDouble(),
    );
  }

  static Map<String, Object?> _recordToRow(IncomeRecord r) {
    return {
      'income_id': r.incomeId,
      'year': r.year,
      'month': r.month,
      'expected_amount': r.expectedAmount,
      'actual_amount': r.actualAmount,
    };
  }

  static IncomeRecord _recordFromRow(Map<String, Object?> row) {
    return IncomeRecord(
      incomeId: row['income_id'] as String,
      year: row['year'] as int,
      month: row['month'] as int,
      expectedAmount: (row['expected_amount'] as num?)?.toDouble() ?? 0,
      actualAmount: (row['actual_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
