import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import 'local_db.dart';

/// Mutable list of accounts. Persisted to DB; no mock or seeded data.
class AccountStore extends ChangeNotifier {
  AccountStore() {
    _loadFromDb();
  }

  List<Account> _accounts = [];

  List<Account> get accounts => List.unmodifiable(_accounts);

  void addAccount(Account account) {
    _accounts = [..._accounts, account];
    _accounts.sort((a, b) => a.order.compareTo(b.order));
    _saveAccount(account);
    notifyListeners();
  }

  void updateAccount(Account account) {
    final i = _accounts.indexWhere((a) => a.id == account.id);
    if (i < 0) return;
    _accounts = [..._accounts];
    _accounts[i] = account;
    _saveAccount(account);
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete('account_allocations', where: 'account_id = ?', whereArgs: [id]);
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
    _accounts = _accounts.where((a) => a.id != id).toList();
    notifyListeners();
  }

  Account? byId(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    final rows = await db.query('accounts', orderBy: 'sort_order ASC');
    _accounts = rows.map(_fromRow).toList();
    notifyListeners();
  }

  /// Reload accounts from the database (e.g. after a data reset).
  Future<void> reload() => _loadFromDb();

  Future<void> _saveAccount(Account a) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'accounts',
      {
        'id': a.id,
        'name': a.name,
        'sort_order': a.order,
        'icon_color_value': a.iconColorValue,
        'account_type': a.accountType.index,
        'amount': a.amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Account _fromRow(Map<String, Object?> row) {
    final typeIndex = row['account_type'] as int?;
    final accountType = typeIndex != null && typeIndex >= 0 && typeIndex < AccountType.values.length
        ? AccountType.values[typeIndex]
        : AccountType.online;
    return Account(
      id: row['id'] as String,
      name: row['name'] as String,
      order: (row['sort_order'] as int?) ?? 0,
      iconColorValue: row['icon_color_value'] as int?,
      accountType: accountType,
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
