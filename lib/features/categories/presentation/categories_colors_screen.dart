import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/exceptions.dart';
import '../../../data/repositories/providers.dart';

enum _ManageTab { categories, colors }

final class CategoriesColorsScreen extends ConsumerStatefulWidget {
  const CategoriesColorsScreen({super.key});

  @override
  ConsumerState<CategoriesColorsScreen> createState() =>
      _CategoriesColorsScreenState();
}

class _CategoriesColorsScreenState
    extends ConsumerState<CategoriesColorsScreen> {
  _ManageTab _tab = _ManageTab.categories;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Categories & Colors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: _tab == _ManageTab.categories
                ? 'Add Category'
                : 'Add Color',
            onPressed: () {
              if (_tab == _ManageTab.categories) {
                _showAddCategoryDialog();
              } else {
                _showAddColorDialog();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<_ManageTab>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _ManageTab.categories,
                        label: Text('Categories'),
                      ),
                      ButtonSegment(
                        value: _ManageTab.colors,
                        label: Text('Colors'),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (set) =>
                        setState(() => _tab = set.first),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == _ManageTab.categories
                ? _CategoriesList(
                    onAdd: _showAddCategoryDialog,
                    onEdit: _showEditCategoryDialog,
                  )
                : _ColorsList(
                    onAdd: _showAddColorDialog,
                    onEdit: _showEditColorDialog,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tab == _ManageTab.categories) {
            _showAddCategoryDialog();
          } else {
            _showAddColorDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New Category'),
          content: AppTextField(
            label: 'Category name',
            hintText: 'e.g. Dresses, Cardigans',
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await ref
                    .read(categoryRepositoryProvider)
                    .add(name: name, icon: 'checkroom');
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(CategoryRow category) {
    final controller = TextEditingController(text: category.name);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rename Category'),
          content: AppTextField(
            label: 'Category name',
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await ref.read(categoryRepositoryProvider).rename(
                      category.id,
                      name: name,
                      icon: category.icon,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddColorDialog() {
    final nameController = TextEditingController();
    final hexController = TextEditingController(text: '#');
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New Color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Color name',
                hintText: 'e.g. Olive, Burgundy, Sky Blue',
                controller: nameController,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'Hex code',
                hintText: '#4A7C59',
                controller: hexController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                var hex = hexController.text.trim();
                if (name.isEmpty) return;
                if (!hex.startsWith('#')) hex = '#$hex';
                if (hex.length != 7) return;

                await ref.read(colorRepositoryProvider).add(
                      name: name,
                      hex: hex,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditColorDialog(ColorRow color) {
    final nameController = TextEditingController(text: color.name);
    final hexController = TextEditingController(text: color.hex);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Color name',
                controller: nameController,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'Hex code',
                controller: hexController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                var hex = hexController.text.trim();
                if (name.isEmpty) return;
                if (!hex.startsWith('#')) hex = '#$hex';
                if (hex.length != 7) return;

                await ref.read(colorRepositoryProvider).rename(
                      color.id,
                      name: name,
                      hex: hex,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

final class _CategoriesList extends ConsumerWidget {
  const _CategoriesList({required this.onAdd, required this.onEdit});

  final VoidCallback onAdd;
  final void Function(CategoryRow) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      data: (categories) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            for (final category in categories) ...[
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.checkroom,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: category.isArchived
                                  ? colors.textMuted
                                  : colors.textPrimary,
                            ),
                          ),
                          if (category.isPreset) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Preset category',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => onEdit(category),
                      tooltip: 'Rename',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        try {
                          await ref
                              .read(categoryRepositoryProvider)
                              .softDelete(category.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted ${category.name}')),
                            );
                          }
                        } on CategoryInUseException {
                          if (context.mounted) {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Category In Use'),
                                content: Text(
                                  '"${category.name}" cannot be deleted because purchases use it. You can archive it instead to hide it from new purchase pickers.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      await ref
                                          .read(categoryRepositoryProvider)
                                          .setArchived(
                                            category.id,
                                            archived: true,
                                          );
                                      if (ctx.mounted) Navigator.of(ctx).pop();
                                    },
                                    child: const Text('Archive Category'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
      loading: () => ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          for (var i = 0; i < 6; i++) ...[
            SkeletonLoader(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ],
      ),
      error: (err, _) => Center(
        child: Text(
          'Error loading categories: $err',
          style: TextStyle(color: colors.loss),
        ),
      ),
    );
  }
}

final class _ColorsList extends ConsumerWidget {
  const _ColorsList({required this.onAdd, required this.onEdit});

  final VoidCallback onAdd;
  final void Function(ColorRow) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final colorsAsync = ref.watch(colorsStreamProvider);

    return colorsAsync.when(
      data: (colorRows) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            for (final color in colorRows) ...[
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _parseColor(color.hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            color.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            color.hex,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => onEdit(color),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        try {
                          await ref
                              .read(colorRepositoryProvider)
                              .softDelete(color.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted ${color.name}')),
                            );
                          }
                        } on ColorInUseException {
                          if (context.mounted) {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Color In Use'),
                                content: Text(
                                  '"${color.name}" is used by existing purchases and cannot be deleted.',
                                ),
                                actions: [
                                  FilledButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
      loading: () => ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          for (var i = 0; i < 6; i++) ...[
            SkeletonLoader(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ],
      ),
      error: (err, _) => Center(
        child: Text(
          'Error loading colors: $err',
          style: TextStyle(color: colors.loss),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    final val = int.tryParse(clean, radix: 16) ?? 0xFF000000;
    return Color(0xFF000000 | val);
  }
}
