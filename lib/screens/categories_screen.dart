import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/category_store.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';
import '../utils/icon_colors.dart';

void _openCategorySheet(BuildContext context, CategoryStore store,
    {Category? category, CategoryType? initialType}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CategorySheet(
      store: store,
      category: category,
      initialType: initialType,
    ),
  );
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => AppTheme.primary.withValues(alpha: 0.1),
                ),
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: const [
                  Tab(text: 'Expense'),
                  Tab(text: 'Income'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(type: CategoryType.expense),
            _CategoryList(type: CategoryType.income),
          ],
        ),
        floatingActionButton: Builder(
          builder: (fabContext) => FloatingActionButton(
            heroTag: 'categories_fab',
            onPressed: () {
              final store = fabContext.read<CategoryStore>();
              final controller = DefaultTabController.of(fabContext);
              final index = controller.index;
              _openCategorySheet(
                fabContext,
                store,
                initialType: index == 0 ? CategoryType.expense : CategoryType.income,
              );
            },
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ),
    );
  }
}

/// One tab's list: expense or income categories (top-level + subcategories).
class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.type});

  final CategoryType type;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CategoryStore>();
    final topLevel = [...store.topLevelCategoriesForType(type)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final List<Widget> children = [];
    for (final parent in topLevel) {
      children.add(_CategoryTile(
        category: parent,
        parentName: null,
        onTap: () => _openCategorySheet(context, store, category: parent),
        onDismissed: () => store.deleteCategory(parent.id),
      ));
      final subcategories = [...store.subcategoriesFor(parent.id)]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      for (final sub in subcategories) {
        children.add(_CategoryTile(
          category: sub,
          parentName: parent.name,
          onTap: () => _openCategorySheet(context, store, category: sub),
          onDismissed: () => store.deleteCategory(sub.id),
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: children,
    );
  }
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({required this.store, this.category, this.initialType});

  final CategoryStore store;
  final Category? category;
  /// When adding (category == null), preselect this type.
  final CategoryType? initialType;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final TextEditingController _nameController;
  late int _selectedIconCodePoint;
  late int _selectedColorValue;
  late CategoryType _selectedType;
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name ?? '');
    final icon = c?.iconCodePoint;
    final color = c?.colorValue;
    _selectedIconCodePoint = (icon != null && icon != 0) ? icon : categoryIconCodePoints.first;
    _selectedColorValue = (color != null && color != 0) ? color : iconColors.first.toARGB32();
    _selectedType = c?.type ?? widget.initialType ?? CategoryType.expense;
    _selectedParentId = c?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final store = widget.store;
    // Always show Expense/Income type selector in the sheet.
    final showTypeSelector = true;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                isEdit ? 'Edit category' : 'Add category',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        hintText: 'e.g. Housing, Utilities',
                      ),
                    ),
                    if (showTypeSelector) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<CategoryType>(
                        segments: const [
                          ButtonSegment<CategoryType>(
                            value: CategoryType.expense,
                            label: Text('Expense'),
                            icon: Icon(Icons.receipt_long_rounded, size: 20),
                          ),
                          ButtonSegment<CategoryType>(
                            value: CategoryType.income,
                            label: Text('Income'),
                            icon: Icon(Icons.trending_up_rounded, size: 20),
                          ),
                        ],
                        selected: {_selectedType},
                        onSelectionChanged: (s) =>
                            setState(() => _selectedType = s.first),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Subcategory of (optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final parentOptions = store
                            .topLevelCategoriesForType(_selectedType)
                            .where((p) => p.id != widget.category?.id)
                            .toList()
                          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                        final validParentIds =
                            parentOptions.map((p) => p.id).toSet();
                        final dropdownValue = _selectedParentId != null &&
                                validParentIds.contains(_selectedParentId)
                            ? _selectedParentId
                            : null;
                        return DropdownButtonFormField<String?>(
                          initialValue: dropdownValue,
                          decoration: const InputDecoration(
                            hintText: 'None (top-level category)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('None (top-level)'),
                            ),
                            ...parentOptions.map(
                              (p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text(p.name),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedParentId = v),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final totalWidth = constraints.maxWidth;
                        // 8 colors per row
                        final itemSize = (totalWidth - spacing * 7) / 8;
                        return Wrap(
                          alignment: WrapAlignment.start,
                          spacing: spacing,
                          runSpacing: spacing,
                          children: iconColors.map((color) {
                            final selected =
                                _selectedColorValue == color.toARGB32();
                            return GestureDetector(
                              onTap: () => setState(
                                  () => _selectedColorValue = color.toARGB32()),
                              child: Container(
                                width: itemSize,
                                height: itemSize,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: AppTheme.onSurface, width: 2)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Icon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.28,
                      ),
                      child: SingleChildScrollView(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 10.0;
                            const perRow = 7;
                            final totalWidth = constraints.maxWidth;
                            final itemSize =
                                (totalWidth - spacing * (perRow - 1)) / perRow;
                            final iconSize =
                                (itemSize * 0.6).clamp(20.0, 48.0);

                            return Wrap(
                              alignment: WrapAlignment.start,
                              runAlignment: WrapAlignment.start,
                              spacing: spacing,
                              runSpacing: spacing,
                              children: categoryIconCodePoints.map((codePoint) {
                                final selected =
                                    _selectedIconCodePoint == codePoint;
                                final color =
                                    colorFromValue(_selectedColorValue);
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedIconCodePoint = codePoint),
                                  child: Container(
                                    width: itemSize,
                                    height: itemSize,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: (selected
                                              ? color
                                              : AppTheme.surfaceContainer)
                                          .withValues(
                                              alpha: selected ? 0.25 : 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: selected
                                          ? Border.all(color: color, width: 2)
                                          : null,
                                    ),
                                    child: Icon(
                                      iconDataFromCodePoint(codePoint),
                                      color: selected
                                          ? color
                                          : AppTheme.onSurfaceVariant,
                                      size: iconSize,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (isEdit) ...[
                    TextButton(
                      onPressed: () {
                        store.deleteCategory(widget.category!.id);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => _saveCategory(store, isEdit),
                      child: const Text('Save'),
                    ),
                  ],
                  if (!isEdit) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _saveCategory(store, isEdit),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
  }

  void _saveCategory(CategoryStore store, bool isEdit) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final validParentIds = store
        .topLevelCategoriesForType(_selectedType)
        .where((p) => p.id != widget.category?.id)
        .map((p) => p.id)
        .toSet();
    final effectiveParentId = _selectedParentId != null &&
            validParentIds.contains(_selectedParentId)
        ? _selectedParentId
        : null;
    if (isEdit) {
      store.updateCategory(widget.category!.copyWith(
        name: name,
        iconCodePoint: _selectedIconCodePoint,
        colorValue: _selectedColorValue,
        type: _selectedType,
        parentId: effectiveParentId,
      ));
    } else {
      final order = effectiveParentId != null
          ? store.subcategoriesFor(effectiveParentId).length
          : store.topLevelCategoriesForType(_selectedType).length;
      store.addCategory(Category(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        order: order,
        iconCodePoint: _selectedIconCodePoint,
        colorValue: _selectedColorValue,
        type: _selectedType,
        parentId: effectiveParentId,
      ));
    }
    if (mounted) Navigator.pop(context);
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.parentName,
    required this.onTap,
    required this.onDismissed,
  });

  final Category category;
  final String? parentName;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  /// Safe reads for category fields that may be null at runtime (old data / deserialization).
  static int _safeColorValue(Category c) {
    try {
      final v = (c as dynamic).colorValue;
      return (v is int && v != 0) ? v : iconColors.first.toARGB32();
    } catch (_) {
      return iconColors.first.toARGB32();
    }
  }

  static int _safeIconCodePoint(Category c) {
    try {
      final v = (c as dynamic).iconCodePoint;
      return (v is int && v != 0) ? v : categoryIconCodePoints.first;
    } catch (_) {
      return categoryIconCodePoints.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int colorValue = _safeColorValue(category);
    final int iconCodePoint = _safeIconCodePoint(category);
    final color = colorFromValue(colorValue);
    final iconData = iconDataFromCodePoint(iconCodePoint);

    return Dismissible(
      key: ValueKey(category.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 28),
      ),
      confirmDismiss: (d) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete category?'),
            content: Text(
              'Remove "${category.name}"? Expenses in this category will need to be reassigned.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDismissed(),
      child: Card(
        margin: EdgeInsets.only(bottom: 6, left: parentName != null ? 20 : 0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: color, size: 24),
          ),
          title: Text(
            category.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          subtitle: parentName != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Subcategory of $parentName',
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9)),
                  ),
                )
              : null,
          trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7), size: 22),
          onTap: onTap,
        ),
      ),
    );
  }
}
