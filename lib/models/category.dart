import 'enums.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    this.order = 0,
    this.iconCodePoint = 0xE8EF, // Icons.category_rounded
    this.colorValue = 0xFF2563EB,
    this.type = CategoryType.expense,
    this.parentId,
  });

  final String id;
  final String name;
  final int order;
  /// Material icon code point (e.g. Icons.category_rounded.codePoint).
  final int iconCodePoint;
  /// ARGB color value (e.g. 0xFF2563EB).
  final int colorValue;
  final CategoryType type;
  /// If set, this category is a subcategory of the given parent (one level only).
  final String? parentId;

  bool get isTopLevel => parentId == null || parentId!.isEmpty;

  Category copyWith({
    String? id,
    String? name,
    int? order,
    int? iconCodePoint,
    int? colorValue,
    CategoryType? type,
    String? parentId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      parentId: parentId != null ? (parentId.isEmpty ? null : parentId) : this.parentId,
    );
  }
}
