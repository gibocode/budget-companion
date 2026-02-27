import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/debt_item.dart';
import 'local_db.dart';

class DebtStore extends ChangeNotifier {
  DebtStore() {
    _loadFromDb();
  }

  List<DebtItem> _items = [];

  List<DebtItem> get items =>
      List.unmodifiable(_items..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  Future<bool> addDebt(DebtItem d) async {
    _items = [..._items, d];
    _items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    try {
      await _saveDebt(d);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateDebt(DebtItem d) async {
    final i = _items.indexWhere((x) => x.id == d.id);
    if (i < 0) return false;
    _items = [..._items];
    _items[i] = d;
    _items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    try {
      await _saveDebt(d);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteDebt(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
    _items = _items.where((d) => d.id != id).toList();
    notifyListeners();
  }

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    try {
      final rows = await db.query('debts');
      final loaded = rows.map(_fromRow).toList();
      // Merge loaded items with any in-memory items (e.g. newly added while load was in-flight),
      // preferring in-memory versions for matching ids.
      final Map<String, DebtItem> byId = {
        for (final d in loaded) d.id: d,
        for (final d in _items) d.id: d,
      };
      _items = byId.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (_) {
      _items = [];
    }
    notifyListeners();
  }

  Future<void> reload() => _loadFromDb();

  Future<void> _saveDebt(DebtItem d) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'debts',
      _toRow(d),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Map<String, Object?> _toRow(DebtItem d) {
    return {
      'id': d.id,
      'name': d.name,
      'category_id': d.categoryId,
      'monthly_amount': d.monthlyAmount,
      'months_remaining': d.monthsRemaining,
      'next_due_date': d.nextDueDate.toIso8601String(),
    };
  }

  static DebtItem _fromRow(Map<String, Object?> row) {
    final nextDueStr = row['next_due_date'] as String?;
    final nextDue = nextDueStr != null ? DateTime.tryParse(nextDueStr) ?? DateTime.now() : DateTime.now();
    return DebtItem(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryId: row['category_id'] as String?,
      monthlyAmount: (row['monthly_amount'] as num?)?.toDouble() ?? 0,
      monthsRemaining: (row['months_remaining'] as int?) ?? 0,
      nextDueDate: nextDue,
    );
  }
}

