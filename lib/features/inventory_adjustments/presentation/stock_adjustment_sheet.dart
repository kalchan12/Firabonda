import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';

Future<bool?> showStockAdjustmentBottomSheet(
  BuildContext context, {
  PurchaseOverview? purchase,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => StockAdjustmentSheet(initialPurchase: purchase),
  );
}

final class StockAdjustmentSheet extends ConsumerStatefulWidget {
  const StockAdjustmentSheet({super.key, this.initialPurchase});

  final PurchaseOverview? initialPurchase;

  @override
  ConsumerState<StockAdjustmentSheet> createState() =>
      _StockAdjustmentSheetState();
}

final class _StockAdjustmentSheetState
    extends ConsumerState<StockAdjustmentSheet> {
  PurchaseOverview? _selectedPurchase;
  StockAdjustmentReason _reason = StockAdjustmentReason.damaged;
  int _quantity = 1;
  final _noteController = TextEditingController();
  final _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPurchase = widget.initialPurchase;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveAdjustment() async {
    final purchase = _selectedPurchase;
    if (purchase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item to adjust')),
      );
      return;
    }

    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be at least 1')),
      );
      return;
    }

    // Determine sign: returns and positive count corrections add stock (+), losses and supplier returns deduct stock (-)
    final isDeduction = _reason != StockAdjustmentReason.customerReturn;
    final quantityChange = isDeduction ? -_quantity : _quantity;
    final valueAtCost = _quantity * purchase.unitCostCents;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.addStockAdjustment(
        StockAdjustmentInput(
          purchaseId: purchase.id,
          categoryId: purchase.categoryId,
          quantityChange: quantityChange,
          reason: _reason,
          valueAtCostCents: valueAtCost,
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );

      await HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock adjustment saved (${_reason.label}: ${_quantity}x)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving adjustment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final purchasesAsync = ref.watch(purchaseOverviewsStreamProvider);
    final purchase = _selectedPurchase;
    final valueAtCost =
        purchase != null ? (_quantity * purchase.unitCostCents) : 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
          border: Border(top: BorderSide(color: colors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.m,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.m),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock Adjustment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),

              // Item Selector or Item Display
              if (purchase == null)
                purchasesAsync.when(
                  data: (items) {
                    final inStock =
                        items.where((i) => i.stockLeft > 0).toList();
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select item from stock',
                      ),
                      items: [
                        for (final item in inStock)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              '${item.categoryName} (${item.colorName}) - ${item.stockLeft} in stock',
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        setState(() {
                          _selectedPurchase =
                              inStock.firstWhere((i) => i.id == id);
                        });
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => Text('Error: $err'),
                )
              else
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(purchase.colorHex),
                          border: Border.all(color: colors.border),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${purchase.categoryName} • ${purchase.colorName}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${purchase.stockLeft} in stock • Cost: ${Money.etb(purchase.unitCostCents)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.initialPurchase == null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedPurchase = null),
                          child: const Text('Change'),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.l),

              // Reason Selector
              Text('Reason', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final r in StockAdjustmentReason.values)
                    ChoiceChip(
                      label: Text(r.label),
                      selected: _reason == r,
                      selectedColor: r.isLoss
                          ? colors.loss.withValues(alpha: 0.2)
                          : colors.primary.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) setState(() => _reason = r);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),

              // Quantity Stepper
              Text('Quantity', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                    ),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _quantity++),
                  ),
                  const Spacer(),
                  if (_reason.isLoss)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.loss.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Loss: ${Money.etb(valueAtCost)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.loss,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),

              // Optional Note
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Torn sleeve during unpacking',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save Button
              AppButton(
                label: _isSaving ? 'Saving...' : 'Confirm Adjustment',
                onPressed: _isSaving ? () {} : _saveAdjustment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
