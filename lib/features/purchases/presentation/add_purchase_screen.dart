import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/money_field.dart';

/// Categories and colors presets come from the DB seeds in Phase 3;
/// the values below mirror that seed for the design checkpoint.
const _presetCategories = [
  'T-shirts',
  'Shirts',
  'Hoodies',
  'Jackets',
  'Trousers',
  'Jeans',
  'Shorts',
  'Sweaters',
];

const _presetColors = <(String, int)>[
  ('Black', 0xFF000000),
  ('White', 0xFFFFFFFF),
  ('Gray', 0xFF808080),
  ('Blue', 0xFF2F5BFF),
  ('Navy', 0xFF0B1F4B),
  ('Red', 0xFFE53950),
  ('Green', 0xFF2E9E63),
  ('Brown', 0xFF7A4B2A),
  ('Beige', 0xFFD8C3A5),
  ('Yellow', 0xFFF2C94C),
];

/// Add / edit purchase screen (design checkpoint sample). In Phase 4 the
/// form gets validation, price memory hints, persistence and editing.
final class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

final class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _unitCost = TextEditingController();
  final _sellingPrice = TextEditingController();
  int _quantity = 1;

  String _category = _presetCategories.first;
  String _color = _presetColors.first.$1;

  @override
  void dispose() {
    _unitCost.dispose();
    _sellingPrice.dispose();
    super.dispose();
  }

  int get _totalCents {
    final unit = _tryParseCents(_unitCost.text);
    return unit == null ? 0 : unit * _quantity;
  }

  static int? _tryParseCents(String text) {
    try {
      return Money.parseCents(text);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: const Text('Add purchase')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final category in _presetCategories)
                  AppChip(
                    label: category,
                    selected: category == _category,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Text('Color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final (name, hex) in _presetColors)
                  AppChip(
                    label: name,
                    selected: name == _color,
                    dotColor: Color(hex),
                    onTap: () => setState(() => _color = name),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StepperButton(
                  icon: Icons.remove,
                  onTap: () => setState(
                    () => _quantity = _quantity > 1 ? _quantity - 1 : 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add,
                  onTap: () => setState(() => _quantity = _quantity + 1),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            MoneyField(
              label: 'Unit cost',
              controller: _unitCost,
              helperText: 'Last time: ETB 800 each',
            ),
            const SizedBox(height: AppSpacing.m),
            MoneyField(
              label: 'Selling price (optional)',
              controller: _sellingPrice,
            ),
            const SizedBox(height: AppSpacing.m),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      Money.etb(_totalCents),
                      key: ValueKey<int>(_totalCents),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'More details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              childrenPadding: EdgeInsets.zero,
              children: [
                const AppTextField(label: 'Supplier (optional)'),
                const SizedBox(height: AppSpacing.m),
                const AppTextField(label: 'Note (optional)', maxLines: 2),
                const SizedBox(height: AppSpacing.m),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.photo_outlined),
                  label: const Text('Add photo (optional)'),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Save purchase',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  void _save() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved (design checkpoint demo)')),
    );
    context.pop();
  }
}

final class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: colors.textPrimary),
        ),
      ),
    );
  }
}
