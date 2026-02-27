import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account_allocation.dart';
import 'local_db.dart';

/// Account allocations per pay period. Keyed by (accountId, periodKey). Persisted to DB only; no mock or seeded data.
class AllocationStore extends ChangeNotifier {
  AllocationStore() {
    _loadFromDb();
  }

  List<AccountAllocation> _allocations = [];

  /// Amount allocated to [accountId] for the pay period identified by [periodKey] (yyyy-mm-dd of period start).
  double getAmount(String accountId, String periodKey) {
    return _allocations
        .where((a) => a.accountId == accountId && a.periodKey == periodKey)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  /// Set allocation for (accountId, periodKey). Persists to DB. Pass 0 to remove.
  Future<void> setAmount(String accountId, String periodKey, double amount) async {
    final i = _allocations.indexWhere(
        (a) => a.accountId == accountId && a.periodKey == periodKey);
    if (i >= 0) {
      if (amount == 0) {
        final db = await LocalDb.instance.database;
        await db.delete(
          'account_allocations',
          where: 'account_id = ? AND period_key = ?',
          whereArgs: [accountId, periodKey],
        );
        _allocations = _allocations.where((a) => a != _allocations[i]).toList();
      } else {
        _allocations = [..._allocations];
        _allocations[i] = _allocations[i].copyWith(amount: amount);
        await _upsert(_allocations[i]);
      }
    } else if (amount != 0) {
      final allocation = AccountAllocation(
        accountId: accountId,
        periodKey: periodKey,
        amount: amount,
      );
      _allocations = [..._allocations, allocation];
      await _upsert(allocation);
    }
    notifyListeners();
  }

  /// Reduce the allocation for (accountId, periodKey) by [amount]. No-op if account has no allocation or result would be negative (clamps to 0).
  Future<void> deduct(String accountId, String periodKey, double amount) async {
    final current = getAmount(accountId, periodKey);
    final newAmount = (current - amount).clamp(0.0, double.infinity);
    await setAmount(accountId, periodKey, newAmount);
  }

  /// Subtotal of allocations for [accountIds] in the pay period [periodKey].
  double periodSubtotal(List<String> accountIds, String periodKey) {
    return accountIds.fold(
        0.0, (s, id) => s + getAmount(id, periodKey));
  }

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    final rows = await db.query('account_allocations');
    _allocations = rows.map(_fromRow).toList();
    notifyListeners();
  }

  /// Reload allocations from the database (e.g. after a data reset).
  Future<void> reload() => _loadFromDb();

  Future<void> _upsert(AccountAllocation a) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'account_allocations',
      {
        'account_id': a.accountId,
        'period_key': a.periodKey,
        'amount': a.amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static AccountAllocation _fromRow(Map<String, Object?> row) {
    return AccountAllocation(
      accountId: row['account_id'] as String,
      periodKey: row['period_key'] as String,
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
