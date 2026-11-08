import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/business_logic.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/money_field.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';

Future<bool?> showSellBottomSheet(
  BuildContext context,
  PurchaseOverview purchase,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SellBottomSheet(purchase: purchase),
  );
}

final class SellBottomSheet extends ConsumerStatefulWidget {
  const SellBottomSheet({super.key, required this.purchase});

  final PurchaseOverview purchase;

  @override
  ConsumerState<SellBottomSheet> createState() => _SellBottomSheetState();
}

final class _SellBottomSheetState extends ConsumerState<SellBottomSheet> {
  final _unitPrice = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _customerNameController = TextEditingController();

  int _quantity = 1;
  bool _isSaving = false;
  bool _isPartialPayment = false;
  String _selectedAccountId = 'acc_cash';

  @override
  void initState() {
    super.initState();
    final sellingPrice = widget.purchase.sellingPriceCents;
    if (sellingPrice != null && sellingPrice > 0) {
      _unitPrice.text = Money.amount(sellingPrice);
    } else {
      // 100% target profit default (2x cost)
      _unitPrice.text = Money.amount(widget.purchase.unitCostCents * 2);
    }
    _unitPrice.addListener(() => setState(() {}));
    _paidAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _unitPrice.dispose();
    _paidAmountController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  int? get _parsedPriceCents {
    try {
      return Money.parseCents(_unitPrice.text);
    } catch (_) {
      return null;
    }
  }

  int? get _parsedPaidAmountCents {
    try {
      if (_paidAmountController.text.trim().isEmpty) return null;
      return Money.parseCents(_paidAmountController.text);
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordSale() async {
    final priceCents = _parsedPriceCents;
    if (priceCents == null || priceCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid selling price')),
      );
      return;
    }
    if (_quantity > widget.purchase.stockLeft) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot sell more than stock left (${widget.purchase.stockLeft})',
          ),
        ),
      );
      return;
    }

    final totalRevenue = priceCents * _quantity;
    int? paidAmount;
    if (_isPartialPayment) {
      paidAmount = _parsedPaidAmountCents ?? 0;
      if (paidAmount > totalRevenue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paid amount cannot exceed total revenue'),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(purchaseRepositoryProvider);
      await repo.recordSale(
        SaleInput(
          purchaseId: widget.purchase.id,
          quantity: _quantity,
          unitPriceCents: priceCents,
          date: DateTime.now(),
          accountId: _selectedAccountId,
          paidAmountCents: paidAmount,
          customerName: _customerNameController.text.trim(),
        ),
      );

      await HapticFeedback.lightImpact();

      if (mounted) {
        final profit = ShopLogic.saleProfit(
          quantity: _quantity,
          unitPriceCents: priceCents,
          unitCostCents: widget.purchase.unitCostCents,
        );
        final profitStr = profit >= 0
            ? '+${Money.etb(profit)}'
            : Money.etb(profit);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPartialPayment && (paidAmount ?? totalRevenue) < totalRevenue
                  ? 'Sale recorded! Unpaid balance logged in Debts.'
                  : 'Sale recorded! ($profitStr profit)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error recording sale: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final purchase = widget.purchase;
    final priceCents = _parsedPriceCents;
    final hasPrice = priceCents != null && priceCents > 0;

    final profit = hasPrice
        ? ShopLogic.saleProfit(
            quantity: _quantity,
            unitPriceCents: priceCents,
            unitCostCents: purchase.unitCostCents,
          )
        : 0;

    final revenue = hasPrice ? priceCents * _quantity : 0;
    final paidAmount = _isPartialPayment
        ? (_parsedPaidAmountCents ?? 0)
        : revenue;
    final unpaidBalance = (revenue - paidAmount).clamp(0, revenue);
    final colorVal = purchase.colorHex;

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
                  Expanded(
                    child: Text(
                      'Record Sale',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: purchase.stockLeft > 0
                          ? colors.surfaceVariant
                          : colors.loss.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${purchase.stockLeft} in stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: purchase.stockLeft > 0
                            ? colors.profit
                            : colors.loss,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),

              // Item info row
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${purchase.categoryName} • ${purchase.colorName}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Cost: ${Money.etb(purchase.unitCostCents)}',
                        maxLines: 1,
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),

              // Quantity Stepper
              Text(
                'Quantity to sell',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  _StepperButton(
                    key: const ValueKey('sell_stepper_remove'),
                    icon: Icons.remove,
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
                  _StepperButton(
                    key: const ValueKey('sell_stepper_add'),
                    icon: Icons.add,
                    onPressed: _quantity < purchase.stockLeft
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                  const Spacer(),
                  if (_quantity == purchase.stockLeft)
                    Text(
                      'All in stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.warning,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),

              // Selling Price Field
              MoneyField(
                label: 'Selling price per piece',
                controller: _unitPrice,
                quantity: _quantity,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Pricing quick presets (Step 6)
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.bolt, size: 16),
                    label: const Text('100% Target (2x)'),
                    onPressed: () {
                      _unitPrice.text = Money.amount(
                        widget.purchase.unitCostCents * 2,
                      );
                    },
                  ),
                  ActionChip(
                    label: const Text('+50%'),
                    onPressed: () {
                      _unitPrice.text = Money.amount(
                        (widget.purchase.unitCostCents * 1.5).round(),
                      );
                    },
                  ),
                  ActionChip(
                    label: const Text('+75%'),
                    onPressed: () {
                      _unitPrice.text = Money.amount(
                        (widget.purchase.unitCostCents * 1.75).round(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              // Payment Account Selection
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Payment to:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    ChoiceChip(
                      label: const Text('Cash'),
                      selected: _selectedAccountId == 'acc_cash',
                      onSelected: (val) {
                        if (val) setState(() => _selectedAccountId = 'acc_cash');
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      label: const Text('Telebirr'),
                      selected: _selectedAccountId == 'acc_telebirr',
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedAccountId = 'acc_telebirr');
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      label: const Text('Bank'),
                      selected: _selectedAccountId == 'acc_bank',
                      onSelected: (val) {
                        if (val) setState(() => _selectedAccountId = 'acc_bank');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Partial Payment toggle
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Partial payment / Customer debt',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Unpaid balance will be recorded in Debts',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  value: _isPartialPayment,
                  onChanged: (val) {
                    setState(() {
                      _isPartialPayment = val;
                      if (val && _paidAmountController.text.isEmpty) {
                        _paidAmountController.text = Money.amount(revenue ~/ 2);
                      }
                    });
                  },
                ),
              ),

              if (_isPartialPayment) ...[
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer name',
                    hintText: 'e.g. Abebe',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                MoneyField(
                  label: 'Amount paid now',
                  controller: _paidAmountController,
                ),
                if (unpaidBalance > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 6),
                    child: Text(
                      'Customer will owe: ${Money.etb(unpaidBalance)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.loss,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.s),
              ],

              // Live Profit Card
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Total revenue',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              hasPrice ? Money.etb(revenue) : '—',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: colors.border, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Estimated profit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              hasPrice
                                  ? (profit >= 0
                                        ? '+${Money.etb(profit)}'
                                        : Money.etb(profit))
                                  : '—',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: !hasPrice
                                    ? colors.textMuted
                                    : (profit >= 0
                                          ? colors.profit
                                          : colors.loss),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              AppButton(
                label: _isSaving ? 'Recording...' : 'Confirm sale',
                onPressed: (purchase.stockLeft <= 0 || _isSaving)
                    ? () {}
                    : _recordSale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StepperButton extends StatelessWidget {
  const _StepperButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    return Material(
      color: enabled ? colors.surfaceVariant : colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: enabled ? colors.textPrimary : colors.textMuted,
          ),
        ),
      ),
    );
  }
}
