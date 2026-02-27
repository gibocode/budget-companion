import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/budget_item.dart';
import 'local_db.dart';

/// Stores all budget items (expected amounts per expense/income, per month or per pay period).
class BudgetStore extends ChangeNotifier {
  BudgetStore() {
    _loadFromDb();
  }

  final List<BudgetItem> _items = [];

  List<BudgetItem> get items => List.unmodifiable(_items);

  List<BudgetItem> forMonth(int year, int month) {
    return _items
        .where((b) => b.year == year && b.month == month && b.payPeriodIndex == null)
        .toList();
  }

  List<BudgetItem> forPeriod(int year, int month, int payPeriodIndex) {
    return _items
        .where((b) =>
            b.year == year &&
            b.month == month &&
            b.payPeriodIndex == payPeriodIndex)
        .toList();
  }

  /// All budgets for the month (whole-month + any period-specific by year/month).
  List<BudgetItem> allForMonth(int year, int month) {
    return _items.where((b) => b.year == year && b.month == month).toList();
  }

  /// Budgets for this month: those keyed by (year, month) or whose periodKey is in [periodKeys].
  List<BudgetItem> allForMonthWithPeriodKeys(
    int year,
    int month,
    Set<String> periodKeys,
  ) {
    return _items.where((b) {
      if (b.periodKey != null && periodKeys.contains(b.periodKey!)) return true;
      return b.year == year && b.month == month;
    }).toList();
  }

  /// Expected amount for a reference (expense/income) in a month (whole-month budget only).
  double expectedForMonth(String referenceId, BudgetType type, int year, int month) {
    final b = _items.where((x) =>
        x.referenceId == referenceId &&
        x.type == type &&
        x.year == year &&
        x.month == month &&
        x.payPeriodIndex == null);
    if (b.isEmpty) return 0;
    return b.first.expectedAmount;
  }

  /// Expected amount for a reference in a specific period.
  double expectedForPeriod(
      String referenceId, BudgetType type, int year, int month, int periodIndex) {
    final exact = _items.where((x) =>
        x.referenceId == referenceId &&
        x.type == type &&
        x.year == year &&
        x.month == month &&
        x.payPeriodIndex == periodIndex);
    if (exact.isNotEmpty) return exact.first.expectedAmount;
    return 0;
  }

  /// Sum of expected amounts from budget items assigned to [accountId] for pay period [periodKey].
  double totalExpectedForAccountPeriod(String accountId, String periodKey) {
    return _items.where((b) =>
        b.accountId == accountId && b.periodKey == periodKey).fold(
        0.0, (sum, b) => sum + b.expectedAmount);
  }

  /// Subtotal for [accountIds] in period [periodKey] (from budget assignments only).
  double periodSubtotalFromBudgets(List<String> accountIds, String periodKey) {
    return accountIds.fold(
        0.0, (s, id) => s + totalExpectedForAccountPeriod(id, periodKey));
  }

  /// Sum of expected amounts for the month for [type].
  double totalExpectedForMonthByType(
    int year,
    int month,
    Set<String> periodKeys,
    BudgetType type,
  ) {
    return _items.where((b) {
      if (b.type != type) return false;
      if (b.periodKey != null && periodKeys.contains(b.periodKey!)) return true;
      return b.year == year && b.month == month;
    }).fold(0.0, (s, b) => s + b.expectedAmount);
  }

  /// All budget items that belong to the given period (by periodKey or year/month/index).
  List<BudgetItem> budgetsForPeriod(
    int year,
    int month,
    String periodKey,
    int indexInMonth,
  ) {
    return _items.where((b) {
      if (b.periodKey == periodKey) return true;
      return b.year == year && b.month == month && b.payPeriodIndex == indexInMonth;
    }).toList();
  }

  /// Sum of expected amounts for the given period and [type].
  double totalExpectedForPeriodByType(
    int year,
    int month,
    String periodKey,
    int indexInMonth,
    BudgetType type,
  ) {
    return _items.where((b) {
      if (b.type != type) return false;
      if (b.periodKey == periodKey) return true;
      return b.year == year && b.month == month && b.payPeriodIndex == indexInMonth;
    }).fold(0.0, (s, b) => s + b.expectedAmount);
  }

  Future<void> upsertBudget(BudgetItem item) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'budgets',
      _toRow(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final i = _items.indexWhere((x) => x.id == item.id);
    if (i >= 0) {
      _items[i] = item;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  Future<void> removeBudget(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );

    _items.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  BudgetItem? byId(String id) {
    try {
      return _items.firstWhere((x) => x.id == id);
    } catch (_) {
      return null;
    }
  }

  /// True if a budget already exists for this reference and type in the target (year, month, payPeriodIndex).
  bool hasBudgetInTarget(String referenceId, BudgetType type, int year, int month, int? payPeriodIndex) {
    return _items.any((b) =>
        b.referenceId == referenceId &&
        b.type == type &&
        b.year == year &&
        b.month == month &&
        b.payPeriodIndex == payPeriodIndex);
  }

  /// Copy all whole-month budgets from (year, month - 1) into (year, month).
  Future<void> copyFromPreviousMonth(int year, int month) async {
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final toCopy = _items
        .where((b) =>
            b.year == prevYear &&
            b.month == prevMonth &&
            b.payPeriodIndex == null)
        .toList();
    for (final b in toCopy) {
      if (hasBudgetInTarget(b.referenceId, b.type, year, month, null)) continue;
      final newId = 'budget_${b.referenceId}_${year}_$month';
      await upsertBudget(b.copyWith(
        id: newId,
        year: year,
        month: month,
      ));
    }
    notifyListeners();
  }

  /// Copy period-specific budgets from previous period. Simplified: copy from period 1 to period 2 in same month, or from last period of prev month to period 1.
  Future<void> copyFromPreviousPeriod(int year, int month, int periodIndex) async {
    if (periodIndex <= 1) {
      final prevMonth = month == 1 ? 12 : month - 1;
      final prevYear = month == 1 ? year - 1 : year;
      final toCopy = _items
          .where((b) => b.year == prevYear && b.month == prevMonth)
          .toList();
      for (final b in toCopy) {
        if (hasBudgetInTarget(b.referenceId, b.type, year, month, periodIndex)) continue;
        final newId = 'budget_${b.referenceId}_${year}_${month}_$periodIndex';
        await upsertBudget(b.copyWith(
          id: newId,
          year: year,
          month: month,
          payPeriodIndex: periodIndex,
        ));
      }
    } else {
      final toCopy = _items
          .where((b) =>
              b.year == year &&
              b.month == month &&
              b.payPeriodIndex == periodIndex - 1)
          .toList();
      for (final b in toCopy) {
        if (hasBudgetInTarget(b.referenceId, b.type, year, month, periodIndex)) continue;
        final newId = 'budget_${b.referenceId}_${year}_${month}_$periodIndex';
        await upsertBudget(b.copyWith(
          id: newId,
          payPeriodIndex: periodIndex,
        ));
      }
    }
    notifyListeners();
  }

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    // Load budgets in insertion order so UI lists (e.g. Budgets screen)
    // reflect the order in which items were added, not any alphabetical sort.
    final rows = await db.query('budgets', orderBy: 'rowid ASC');
    _items
      ..clear()
      ..addAll(rows.map(_fromRow));
    notifyListeners();
  }

  /// Reload budgets from the database (e.g. after a data reset).
  Future<void> reload() => _loadFromDb();

  Map<String, Object?> _toRow(BudgetItem b) {
    return {
      'id': b.id,
      'type': b.type.index,
      'reference_id': b.referenceId,
      'year': b.year,
      'month': b.month,
      'pay_period_index': b.payPeriodIndex,
      'expected_amount': b.expectedAmount,
      'recurrence_mode': b.recurrenceMode.index,
      'copies_from_previous': b.copiesFromPrevious ? 1 : 0,
      'recurrence_interval': b.recurrenceInterval,
      'recurrence_max_count': b.recurrenceMaxCount,
      'name': b.name,
      'period_key': b.periodKey,
      'account_id': b.accountId,
    };
  }

  BudgetItem _fromRow(Map<String, Object?> row) {
    return BudgetItem(
      id: row['id'] as String,
      type: BudgetType.values[(row['type'] as int?) ?? 0],
      referenceId: row['reference_id'] as String,
      year: (row['year'] as int?) ?? 0,
      month: (row['month'] as int?) ?? 0,
      payPeriodIndex: row['pay_period_index'] as int?,
      expectedAmount: (row['expected_amount'] as num?)?.toDouble() ?? 0,
      recurrenceMode:
          BudgetRecurrenceMode.values[(row['recurrence_mode'] as int?) ?? 0],
      copiesFromPrevious: (row['copies_from_previous'] as int?) == 1,
      recurrenceInterval: (row['recurrence_interval'] as int?) ?? 1,
      recurrenceMaxCount: row['recurrence_max_count'] as int?,
      name: row['name'] as String?,
      periodKey: row['period_key'] as String?,
      accountId: row['account_id'] as String?,
    );
  }
}
