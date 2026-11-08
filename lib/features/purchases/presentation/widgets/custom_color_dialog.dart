import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

const _palette = <(String, String)>[
  ('Purple', '#8A2BE2'),
  ('Indigo', '#4B0082'),
  ('Cyan', '#00CED1'),
  ('Teal', '#008080'),
  ('Lime', '#32CD32'),
  ('Orange', '#FF8C00'),
  ('Coral', '#FF7F50'),
  ('Pink', '#FF69B4'),
  ('Magenta', '#FF00FF'),
  ('Gold', '#FFD700'),
  ('Maroon', '#800000'),
  ('Olive', '#808000'),
];

Future<(String, String)?> showCustomColorDialog(BuildContext context) {
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => const CustomColorDialog(),
  );
}

final class CustomColorDialog extends StatefulWidget {
  const CustomColorDialog({super.key});

  @override
  State<CustomColorDialog> createState() => _CustomColorDialogState();
}

final class _CustomColorDialogState extends State<CustomColorDialog> {
  final _nameController = TextEditingController();
  String _selectedHex = _palette.first.$2;

  @override
  void initState() {
    super.initState();
    _nameController.text = _palette.first.$1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onPaletteSelect(String name, String hex) {
    setState(() {
      _selectedHex = hex;
      if (_nameController.text.trim().isEmpty ||
          _palette.any((p) => p.$1 == _nameController.text.trim())) {
        _nameController.text = name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final intColor =
        int.tryParse(_selectedHex.replaceFirst('#', '0xFF')) ?? 0xFF000000;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: const Text('Add custom color'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Color name',
              controller: _nameController,
              hintText: 'e.g. Olive, Coral',
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(intColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 2),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  _selectedHex,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Select palette shade',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (name, hex) in _palette) ...[
                  InkWell(
                    onTap: () => _onPaletteSelect(name, hex),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedHex == hex
                              ? colors.primary
                              : colors.border,
                          width: _selectedHex == hex ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ],
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
          label: 'Add color',
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((name, _selectedHex));
          },
        ),
      ],
    );
  }
}
