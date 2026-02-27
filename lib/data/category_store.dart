import 'package:flutter/foundation.dart' hide Category;
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/enums.dart';
import 'local_db.dart';

class CategoryStore extends ChangeNotifier {
  CategoryStore() {
    _loadFromDb();
  }

  List<Category> _categories = const [];

  List<Category> get categories => List.unmodifiable(_categories);

  static int _orderOf(Category c) {
    final o = (c as dynamic).order;
    return (o is int) ? o : 0;
  }

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    final rows = await db.query('categories', orderBy: 'sort_order ASC');
    _categories = rows.map(_fromRow).toList();
    notifyListeners();
  }

  /// Reload categories from the database (e.g. after a data reset).
  Future<void> reload() => _loadFromDb();

  Future<void> addCategory(Category c) async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'categories',
      _toRow(c),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _categories = [..._categories, c];
    _categories.sort((a, b) => _orderOf(a).compareTo(_orderOf(b)));
    notifyListeners();
  }

  Future<void> updateCategory(Category c) async {
    final db = await LocalDb.instance.database;
    await db.update(
      'categories',
      _toRow(c),
      where: 'id = ?',
      whereArgs: [c.id],
    );
    final i = _categories.indexWhere((x) => x.id == c.id);
    if (i < 0) return;
    _categories = [..._categories];
    _categories[i] = c;
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    _categories = _categories.where((c) => c.id != id).toList();
    notifyListeners();
  }

  Category? byId(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> _toRow(Category c) {
    return {
      'id': c.id,
      'name': c.name,
      'sort_order': _orderOf(c),
      'icon_code_point': c.iconCodePoint,
      'color_value': c.colorValue,
      'type': c.type.index,
      'parent_id': c.parentId,
    };
  }

  Category _fromRow(Map<String, Object?> row) {
    return Category(
      id: row['id'] as String,
      name: row['name'] as String,
      order: (row['sort_order'] as int?) ?? 0,
      iconCodePoint: (row['icon_code_point'] as int?) ?? 0xE8EF,
      colorValue: (row['color_value'] as int?) ?? 0xFF2563EB,
      type: CategoryType.values[(row['type'] as int?) ?? 0],
      parentId: row['parent_id'] as String?,
    );
  }

  /// Top-level categories only (no parent).
  List<Category> get topLevelCategories =>
      _categories.where((c) => c.isTopLevel).toList()
        ..sort((a, b) => _orderOf(a).compareTo(_orderOf(b)));

  /// Subcategories for a parent (one level only).
  List<Category> subcategoriesFor(String? parentId) {
    if (parentId == null || parentId.isEmpty) return [];
    return _categories.where((c) => c.parentId == parentId).toList()
      ..sort((a, b) => _orderOf(a).compareTo(_orderOf(b)));
  }

  /// All categories that can be chosen as parent (top-level only).
  List<Category> get possibleParents => topLevelCategories;

  /// Top-level categories of the given type (for Expense/Income tabs).
  List<Category> topLevelCategoriesForType(CategoryType type) {
    return _categories.where((c) {
      if (!c.isTopLevel) return false;
      try {
        return (c as dynamic).type == type;
      } catch (_) {
        return type == CategoryType.expense;
      }
    }).toList()
      ..sort((a, b) => _orderOf(a).compareTo(_orderOf(b)));
  }

  /// All categories of the given type for pickers: top-level first, then each parent's subcategories (in order).
  List<Category> categoriesForType(CategoryType type) {
    final top = topLevelCategoriesForType(type);
    final List<Category> result = [];
    for (final parent in top) {
      result.add(parent);
      result.addAll(subcategoriesFor(parent.id));
    }
    return result;
  }
}
