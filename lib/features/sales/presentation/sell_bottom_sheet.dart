import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
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
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
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
  late final TextEditingController _unitPrice;
  final _paidAmountController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _noteController = TextEditingController();

  int _quantity = 1;
  bool _isSaving = false;
  bool _isNotPaid = false;
  String _selectedAccountId = 'acc_cash';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final assumedPrice = widget.purchase.sellingPriceCents;
    if (assumedPrice != null && assumedPrice > 0) {
      final text = assumedPrice % 100 == 0
          ? '${assumedPrice ~/ 100}'
          : Money.amount(assumedPrice);
      _unitPrice = TextEditingController(text: text);
    } else {
      _unitPrice = TextEditingController(text: '');
    }
    _unitPrice.addListener(() => setState(() {}));
    _paidAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _unitPrice.dispose();
    _paidAmountController.dispose();
    _customerNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _parsedPriceCents {
    try {
      final text = _unitPrice.text.trim();
      if (text.isEmpty) return null;
      return Money.parseCents(text);
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
    if (_isNotPaid) {
      if (_customerNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter customer name for credit/unpaid sale'),
          ),
        );
        return;
      }
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
          costAtSaleCents: widget.purchase.unitCostCents,
          assumedPriceAtSaleCents: widget.purchase.sellingPriceCents,
          date: _selectedDate,
          accountId: _selectedAccountId,
          paidAmountCents: paidAmount,
          customerName: _customerNameController.text.trim(),
        ),
      );

      await HapticFeedback.lightImpact();

      if (mounted) {
        final profitResult = ProfitCalculator.calculate(
          costCents: widget.purchase.unitCostCents,
          assumedSellingPriceCents: widget.purchase.sellingPriceCents,
          actualSellingPriceCents: priceCents,
          quantity: _quantity,
        );
        final profitStr = profitResult.actualProfitCents >= 0
            ? '+${Money.etb(profitResult.actualProfitCents)}'
            : Money.etb(profitResult.actualProfitCents);

        Navigator.of(context).pop(true);
        final actualPaid = paidAmount ?? totalRevenue;
        final unpaid = totalRevenue - actualPaid;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isNotPaid && unpaid > 0
                  ? (actualPaid == 0
                        ? 'Sale recorded on credit! ${Money.etb(unpaid)} logged in Debts.'
                        : 'Sale recorded! ${Money.etb(unpaid)} unpaid balance logged in Debts.')
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

    final revenue = hasPrice ? priceCents * _quantity : 0;
    final paidAmount = _isNotPaid ? (_parsedPaidAmountCents ?? 0) : revenue;
    final unpaidBalance = (revenue - paidAmount).clamp(0, revenue);
    final colorVal = purchase.colorHex;

    final ProfitResult? profitResult = hasPrice
        ? ProfitCalculator.calculate(
            costCents: purchase.unitCostCents,
            assumedSellingPriceCents: purchase.sellingPriceCents,
            actualSellingPriceCents: priceCents,
            quantity: _quantity,
          )
        : null;

    final isLoss = profitResult?.status == ProfitStatus.loss;
    final isOver = profitResult?.status == ProfitStatus.overProfit;
    final isOnTarget = profitResult?.status == ProfitStatus.onTarget;
    final isUnder = profitResult?.status == ProfitStatus.underTarget;

    final (chipLabel, chipColor) = switch (profitResult?.status) {
      ProfitStatus.overProfit => (
        profitResult?.overProfitCents != null &&
                profitResult!.overProfitCents! > 0
            ? 'Over profit +${Money.etb(profitResult.overProfitCents!)}'
            : 'Over profit (${profitResult?.percentOfTarget ?? 100}%)',
        colors.profit,
      ),
      ProfitStatus.onTarget => ('On target (100%)', colors.profit),
      ProfitStatus.underTarget => (
        '${profitResult?.percentOfTarget}% of target',
        colors.warning,
      ),
      ProfitStatus.breakeven => ('Breakeven (0%)', colors.textMuted),
      ProfitStatus.loss => (
        'Loss -${Money.etb(profitResult?.actualProfitCents.abs() ?? 0)}',
        colors.loss,
      ),
      ProfitStatus.notAssumed => (
        'No target (+${Money.etb(profitResult?.actualProfitCents ?? 0)})',
        colors.textMuted,
      ),
      null => ('No target', colors.textMuted),
    };

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header: Category, Color, Stock left
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.m,
                  AppSpacing.screenPadding,
                  AppSpacing.s,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  ],
                ),
              ),

              Divider(color: colors.border, height: 1),

              // 2. Scrollable Middle Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.m,
                    AppSpacing.screenPadding,
                    AppSpacing.m,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big Quantity Stepper (- 1 +)
                      Text(
                        'Quantity',
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
                                fontFamily: 'Sora',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                fontFeatures: [FontFeature.tabularFigures()],
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
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Quick quantity chips: 1, 2, 3, 5, All
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final q in [1, 2, 3, 5])
                            if (q <= purchase.stockLeft)
                              ChoiceChip(
                                label: Text('$q'),
                                selected: _quantity == q,
                                onSelected: (_) =>
                                    setState(() => _quantity = q),
                              ),
                          if (purchase.stockLeft > 1 &&
                              ![1, 2, 3, 5].contains(purchase.stockLeft))
                            ChoiceChip(
                              label: Text('All (${purchase.stockLeft})'),
                              selected: _quantity == purchase.stockLeft,
                              onSelected: (_) => setState(
                                () => _quantity = purchase.stockLeft,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.l),

                      // Big Selling Price Per Piece
                      TextField(
                        key: const ValueKey('sell_price_field'),
                        controller: _unitPrice,
                        autofocus: purchase.sellingPriceCents == null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          labelText: 'Selling price per piece',
                          prefixText: 'ETB ',
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textMuted,
                          ),
                          suffixText: '/ pc',
                          hintText: '0.00',
                          filled: true,
                          fillColor: colors.surfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // 3. Live Result Card
                      AppCard(
                        gradient: isLoss
                            ? LinearGradient(
                                colors: [
                                  colors.surfaceVariant,
                                  colors.loss.withValues(alpha: 0.1),
                                ],
                              )
                            : (isOver || isOnTarget)
                            ? LinearGradient(
                                colors: [
                                  colors.surfaceVariant,
                                  colors.profit.withValues(alpha: 0.1),
                                ],
                              )
                            : isUnder
                            ? LinearGradient(
                                colors: [
                                  colors.surfaceVariant,
                                  colors.warning.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Total revenue',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
                                      style: const TextStyle(
                                        fontFamily: 'Sora',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Divider(color: colors.border, height: 1),
                            const SizedBox(height: AppSpacing.s),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    isLoss ? 'Net loss' : 'Profit preview',
                                    style: TextStyle(
                                      fontSize: 13,
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
                                          ? (isLoss
                                                ? Money.etb(
                                                    profitResult!
                                                        .actualProfitCents,
                                                  )
                                                : '+${Money.etb(profitResult!.actualProfitCents)}')
                                          : '—',
                                      style: TextStyle(
                                        fontFamily: 'Sora',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: !hasPrice
                                            ? colors.textMuted
                                            : (isLoss
                                                  ? colors.loss
                                                  : colors.profit),
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _quantity > 1
                                      ? 'Cost: ${Money.etb(purchase.unitCostCents * _quantity)} (${Money.etb(purchase.unitCostCents)}/pc) • Target: ${purchase.sellingPriceCents != null ? '${Money.etb(purchase.sellingPriceCents! * _quantity)} (${Money.etb(purchase.sellingPriceCents!)}/pc)' : 'Not set'}'
                                      : 'Cost: ${Money.etb(purchase.unitCostCents)}/pc • Target: ${purchase.sellingPriceCents != null ? '${Money.etb(purchase.sellingPriceCents!)}/pc' : 'Not set'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textMuted,
                                  ),
                                ),
                                if (hasPrice)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: chipColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: chipColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      chipLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: chipColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // 4. Payment status: "Not paid" toggle
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Not paid',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                _isNotPaid
                                    ? 'Sale on credit. Balance logged in Debts'
                                    : 'Turn on if the customer did not pay or paid partially',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isNotPaid
                                      ? colors.warning
                                      : colors.textMuted,
                                ),
                              ),
                              value: _isNotPaid,
                              activeThumbColor: colors.warning,
                              onChanged: (val) {
                                setState(() {
                                  _isNotPaid = val;
                                  if (val &&
                                      _paidAmountController.text.isEmpty) {
                                    _paidAmountController.text = '0';
                                  }
                                });
                              },
                            ),
                            if (_isNotPaid) ...[
                              const SizedBox(height: AppSpacing.xs),
                              TextField(
                                controller: _customerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Customer name *',
                                  hintText: 'e.g. Abebe',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s),
                              MoneyField(
                                label: 'Amount paid now',
                                controller: _paidAmountController,
                                helperText:
                                    'Enter 0 if the person did not pay at all',
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.chip,
                                  ),
                                  border: Border.all(
                                    color: colors.warning.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        paidAmount == 0
                                            ? 'Total logged to Debts:'
                                            : 'Customer owes (Debts):',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.warning,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          Money.etb(unpaidBalance),
                                          style: TextStyle(
                                            fontFamily: 'Sora',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: colors.warning,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // 5. Collapsed "More options" accordion
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          initiallyExpanded: false,
                          leading: const Icon(Icons.tune_rounded, size: 20),
                          title: const Text(
                            'More options',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Date, account, note',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                          children: [
                            // Date selector
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                              title: const Text(
                                'Sale date',
                                style: TextStyle(fontSize: 13),
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                                child: Text(
                                  DateFormat.yMMMd().format(_selectedDate),
                                ),
                              ),
                            ),

                            // Payment Account selection
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Text(
                                    'Account:',
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
                                      if (val) {
                                        setState(
                                          () => _selectedAccountId = 'acc_cash',
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  ChoiceChip(
                                    label: const Text('Telebirr'),
                                    selected:
                                        _selectedAccountId == 'acc_telebirr',
                                    onSelected: (val) {
                                      if (val) {
                                        setState(
                                          () => _selectedAccountId =
                                              'acc_telebirr',
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  ChoiceChip(
                                    label: const Text('Bank'),
                                    selected: _selectedAccountId == 'acc_bank',
                                    onSelected: (val) {
                                      if (val) {
                                        setState(
                                          () => _selectedAccountId = 'acc_bank',
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.m),

                            // Note field
                            TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                labelText: 'Note (optional)',
                                hintText: 'e.g. Discount given for friend',
                                prefixIcon: Icon(Icons.edit_note_outlined),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Fixed Action Footer
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.s,
                  AppSpacing.screenPadding,
                  AppSpacing.m,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: AppButton(
                  key: const ValueKey('confirm_sale_button'),
                  label: _isSaving ? 'Selling...' : 'Sell',
                  onPressed: (purchase.stockLeft <= 0 || _isSaving || !hasPrice)
                      ? null
                      : _recordSale,
                ),
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
