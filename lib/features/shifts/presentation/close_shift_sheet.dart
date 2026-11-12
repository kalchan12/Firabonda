import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';
import '../../dashboard/application/dashboard_controller.dart';

Future<bool?> showCloseShiftSheet(BuildContext context, ShiftRow shift) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CloseShiftSheet(shift: shift),
  );
}

final class CloseShiftSheet extends ConsumerStatefulWidget {
  const CloseShiftSheet({super.key, required this.shift});

  final ShiftRow shift;

  @override
  ConsumerState<CloseShiftSheet> createState() => _CloseShiftSheetState();
}

final class _CloseShiftSheetState extends ConsumerState<CloseShiftSheet> {
  final _actualCashController = TextEditingController();
  final _actualBankController = TextEditingController();
  final _actualDebitController = TextEditingController();

  ShiftSummaryData? _summary;
  int _expectedCash = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _actualCashController.addListener(() => setState(() {}));
    _actualBankController.addListener(() => setState(() {}));
    _actualDebitController.addListener(() => setState(() {}));
  }

  Future<void> _loadSummary() async {
    final repo = ref.read(shiftRepositoryProvider);
    final summary = await repo.getShiftSummary(widget.shift.id);
    if (mounted) {
      setState(() {
        _summary = summary;
        _expectedCash = summary.expectedCashCents;
        _isLoading = false;
        _actualCashController.text = summary.expectedCashCents > 0
            ? (summary.expectedCashCents % 100 == 0
                  ? '${summary.expectedCashCents ~/ 100}'
                  : Money.amount(summary.expectedCashCents))
            : '0';
      });
    }
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    _actualBankController.dispose();
    _actualDebitController.dispose();
    super.dispose();
  }

  int? get _parsedActualCashCents {
    try {
      final text = _actualCashController.text.trim();
      if (text.isEmpty) return null;
      return Money.parseCents(text);
    } catch (_) {
      return null;
    }
  }

  int? get _parsedBankCents {
    try {
      final text = _actualBankController.text.trim();
      if (text.isEmpty) return null;
      return Money.parseCents(text);
    } catch (_) {
      return null;
    }
  }

  int? get _parsedDebitCents {
    try {
      final text = _actualDebitController.text.trim();
      if (text.isEmpty) return null;
      return Money.parseCents(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmClose() async {
    final actual = _parsedActualCashCents ?? _expectedCash;
    final actualBank = _parsedBankCents;
    final actualDebit = _parsedDebitCents;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(shiftRepositoryProvider);
      await repo.closeShift(
        shiftId: widget.shift.id,
        actualCashCents: actual,
        actualBankCents: actualBank,
        actualDebitCents: actualDebit,
      );

      // Transition dashboard to show all today's activity now that shift is closed
      ref
          .read(todayShiftModeProvider.notifier)
          .setMode(TodayShiftMode.allToday);

      await HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.of(context).pop(true);
        final diff = actual - _expectedCash;
        final statusMsg = diff == 0
            ? 'Shift closed! Exact cash match.'
            : diff > 0
            ? 'Shift closed! +${Money.etb(diff)} extra cash.'
            : 'Shift closed! -${Money.etb(diff.abs())} cash short.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(statusMsg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error closing shift: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final summary = _summary;
    final actualCents = _parsedActualCashCents;
    final hasActual = actualCents != null;
    final diff = hasActual ? (actualCents - _expectedCash) : 0;
    final isExact = hasActual && diff == 0;
    final isExtra = hasActual && diff > 0;

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
              top: Radius.circular(AppRadius.sheet),
            ),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.m,
                  AppSpacing.screenPadding,
                  AppSpacing.s,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.m),
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                      ),
                    ),
                    Text(
                      'Close Shift',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: colors.border, height: 1),

              // Scrollable Body
              if (_isLoading || summary == null)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Automatically Tracked Money Earned Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Money Earned This Shift',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.profit.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      'Auto-tracked',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colors.profit,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  Money.etb(summary.totalEarnedCents),
                                  style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s),
                              Divider(color: colors.border, height: 1),
                              const SizedBox(height: AppSpacing.s),
                              Wrap(
                                spacing: AppSpacing.s,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  _AccountEarnedChip(
                                    label: 'Cash',
                                    amountCents: summary.cashSalesCents,
                                    icon: Icons.payments_outlined,
                                  ),
                                  _AccountEarnedChip(
                                    label: 'Bank',
                                    amountCents: summary.bankSalesCents,
                                    icon: Icons.account_balance_outlined,
                                  ),
                                  _AccountEarnedChip(
                                    label: 'Debit / Telebirr',
                                    amountCents: summary.debitSalesCents,
                                    icon: Icons.phone_android_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // If items purchased with credit that day, automatically display!
                        if (summary.hasCreditItems) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: colors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.card,
                              ),
                              border: Border.all(
                                color: colors.warning.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.credit_card_off_outlined,
                                      color: colors.warning,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.s),
                                    Expanded(
                                      child: Text(
                                        'Credit Items Today (${summary.creditItems.length})',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: colors.warning,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      Money.etb(summary.creditTotalCents),
                                      style: TextStyle(
                                        fontFamily: 'Sora',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: colors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s),
                                Text(
                                  'Items bought or sold on credit during this shift. Debts have been recorded automatically:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s),
                                for (final item in summary.creditItems) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.personName}: ${item.itemDescription}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.isSupplierCredit
                                              ? 'I owe ${Money.etb(item.creditAmountCents)}'
                                              : 'Owes ${Money.etb(item.creditAmountCents)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: item.isSupplierCredit
                                                ? colors.loss
                                                : colors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],

                        // Reconciliation section header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reconcile Money',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: colors.border),
                              ),
                              child: Text(
                                'All fields optional',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),

                        // 1. Cash Drawer Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                              color: isExact || isExtra
                                  ? colors.profit.withValues(alpha: 0.4)
                                  : colors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colors.profit.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppRadius.button),
                                    ),
                                    child: Icon(
                                      Icons.point_of_sale_rounded,
                                      color: colors.profit,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cash Drawer',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Expected drawer cash',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    Money.etb(_expectedCash),
                                    style: const TextStyle(
                                      fontFamily: 'Sora',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s),
                              TextField(
                                key: const ValueKey('count_cash_field'),
                                controller: _actualCashController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'ETB ',
                                  hintText: 'Leave as is or count drawer',
                                  filled: true,
                                  fillColor: colors.surfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                  suffixIcon: _actualCashController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 16),
                                          onPressed: _actualCashController.clear,
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                    borderSide: BorderSide(color: colors.border),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isExact || isExtra
                                      ? colors.profit.withValues(alpha: 0.12)
                                      : colors.loss.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.chip,
                                  ),
                                  border: Border.all(
                                    color: (isExact || isExtra
                                            ? colors.profit
                                            : colors.loss)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isExact
                                          ? Icons.check_circle_outline_rounded
                                          : isExtra
                                          ? Icons.add_circle_outline_rounded
                                          : Icons.warning_amber_rounded,
                                      color: isExact || isExtra
                                          ? colors.profit
                                          : colors.loss,
                                      size: 15,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        isExact
                                            ? 'Exact match'
                                            : isExtra
                                            ? '+${Money.etb(diff)} extra in drawer'
                                            : '-${Money.etb(diff.abs())} cash short',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isExact || isExtra
                                              ? colors.profit
                                              : colors.loss,
                                        ),
                                      ),
                                    ),
                                    if (!isExact && _expectedCash > 0)
                                      InkWell(
                                        onTap: () {
                                          _actualCashController.text =
                                              _expectedCash % 100 == 0
                                                  ? '${_expectedCash ~/ 100}'
                                                  : Money.amount(_expectedCash);
                                        },
                                        child: Text(
                                          'Reset',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: colors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // 2. Bank Account Card (Optional)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppRadius.button),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_rounded,
                                      color: colors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bank Account (Optional)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'CBE, Awash, or Other Bank',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      'Earned: ${Money.etb(summary.bankSalesCents)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s),
                              TextField(
                                controller: _actualBankController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'ETB ',
                                  hintText: 'Insert bank money (optional)',
                                  filled: true,
                                  fillColor: colors.surfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                  suffixIcon: summary.bankSalesCents > 0 &&
                                          _actualBankController.text.isEmpty
                                      ? TextButton(
                                          onPressed: () {
                                            _actualBankController.text =
                                                summary.bankSalesCents % 100 == 0
                                                    ? '${summary.bankSalesCents ~/ 100}'
                                                    : Money.amount(summary.bankSalesCents);
                                          },
                                          child: const Text('Use earned', style: TextStyle(fontSize: 11)),
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                    borderSide: BorderSide(color: colors.border),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // 3. Telebirr / Mobile Money Card (Optional)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppRadius.button),
                                    ),
                                    child: Icon(
                                      Icons.phone_android_rounded,
                                      color: colors.warning,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Debit / Telebirr (Optional)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Mobile money & debit cards',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      'Earned: ${Money.etb(summary.debitSalesCents)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s),
                              TextField(
                                controller: _actualDebitController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'ETB ',
                                  hintText: 'Insert mobile money / debit (optional)',
                                  filled: true,
                                  fillColor: colors.surfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                  suffixIcon: summary.debitSalesCents > 0 &&
                                          _actualDebitController.text.isEmpty
                                      ? TextButton(
                                          onPressed: () {
                                            _actualDebitController.text =
                                                summary.debitSalesCents % 100 == 0
                                                    ? '${summary.debitSalesCents ~/ 100}'
                                                    : Money.amount(summary.debitSalesCents);
                                          },
                                          child: const Text('Use earned', style: TextStyle(fontSize: 11)),
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                    borderSide: BorderSide(color: colors.border),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Action Footer
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
                  key: const ValueKey('confirm_close_shift_button'),
                  label: _isSaving ? 'Closing Shift...' : 'Close Shift',
                  onPressed: (_isLoading || _isSaving) ? null : _confirmClose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _AccountEarnedChip extends StatelessWidget {
  const _AccountEarnedChip({
    required this.label,
    required this.amountCents,
    required this.icon,
  });

  final String label;
  final int amountCents;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textMuted),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textMuted,
            ),
          ),
          Text(
            Money.etb(amountCents),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Sora',
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
