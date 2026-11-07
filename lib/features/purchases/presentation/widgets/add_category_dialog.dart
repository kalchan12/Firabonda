import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

const _icons = [
  'tshirt',
  'shirt',
  'hoodie',
  'jacket',
  'trousers',
  'jeans',
  'shorts',
  'sweater',
  'tag',
  'shopping_bag',
];

Future<(String, String)?> showAddCategoryDialog(BuildContext context) {
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => const AddCategoryDialog(),
  );
}

final class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

final class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = _icons.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: const Text('Add category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Category name',
              controller: _nameController,
              hintText: 'e.g. Polos, Tracksuits',
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Icon',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final iconKey in _icons)
                  InkWell(
                    onTap: () => setState(() => _selectedIcon = iconKey),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedIcon == iconKey
                            ? colors.primary
                            : colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        iconKey,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedIcon == iconKey
                              ? colors.onPrimary
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Add category',
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((name, _selectedIcon));
          },
        ),
      ],
    );
  }
}
