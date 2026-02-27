import 'package:flutter/material.dart';
import '../data/category_store.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

/// Shows the same category selection bottom sheet used when adding a budget item.
/// Categories are sorted alphabetically by display name. No uncategorized option.
void showCategoryPickerSheet({
  required BuildContext context,
  required CategoryStore categoryStore,
  required List<Category> categories,
  required void Function(String categoryId) onSelected,
}) {
  final sorted = [...categories]
    ..sort((a, b) => categoryPickerDisplayName(a, categoryStore)
        .toLowerCase()
        .compareTo(categoryPickerDisplayName(b, categoryStore).toLowerCase()));

  const tileHeight = 64.0;
  const separatorHeight = 10.0;
  final itemCount = sorted.length;
  final maxH = MediaQuery.of(context).size.height * 0.78;
  final listHeight = (itemCount * tileHeight + (itemCount - 1).clamp(0, 999) * separatorHeight)
      .clamp(0.0, maxH - 80);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    isScrollControlled: true,
    builder: (ctx) => Container(
      height: listHeight + 80,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            height: listHeight,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = sorted[i];
                final displayName = categoryPickerDisplayName(c, categoryStore);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: CategoryPickerLeading(category: c),
                  title: Text(displayName),
                  onTap: () {
                    onSelected(c.id);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Display name for a category (with parent prefix when applicable).
String categoryPickerDisplayName(Category c, CategoryStore categoryStore) {
  final parent = c.parentId != null ? categoryStore.byId(c.parentId!) : null;
  return parent != null ? '${parent.name} · ${c.name}' : c.name;
}

/// Leading icon+color for category picker (same as budget screen).
class CategoryPickerLeading extends StatelessWidget {
  const CategoryPickerLeading({this.category});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.category_rounded,
          size: 18,
          color: AppTheme.onSurfaceVariant,
        ),
      );
    }
    final c = category!;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Color(c.colorValue).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        IconData(c.iconCodePoint, fontFamily: 'MaterialIcons'),
        size: 18,
        color: Color(c.colorValue),
      ),
    );
  }
}
