import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/providers.dart';

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
  int _expectedCash = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExpectedCash();
    _actualCashController.addListener(() => setState(() {}));
  }

  Future<void> _loadExpectedCash() async {
    final repo = ref.read(shiftRepositoryProvider);
    final expected = await repo.computeExpectedCash(widget.shift.id);
    if (mounted) {
      setState(() {
        _expectedCash = expected;
        _isLoading = false;
        _actualCashController.text = expected > 0
            ? (expected % 100 == 0
                  ? '${expected ~/ 100}'
                  : Money.amount(expected))
            : '0';
      });
    }
  }

  @override
  void dispose() {
    _actualCashController.dispose();
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

  Future<void> _confirmClose() async {
    final actual = _parsedActualCashCents ?? 0;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(shiftRepositoryProvider);
      await repo.closeShift(shiftId: widget.shift.id, actualCashCents: actual);

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

              // Content
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expected cash row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Expected drawer cash',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textMuted,
                            ),
                          ),
                          Text(
                            Money.etb(_expectedCash),
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // Count cash input
                      Text(
                        'Count cash in drawer',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      TextField(
                        key: const ValueKey('count_cash_field'),
                        controller: _actualCashController,
                        autofocus: true,
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
                          prefixText: 'ETB ',
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
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // Difference indicator
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: isExact || isExtra
                              ? colors.profit.withValues(alpha: 0.12)
                              : colors.loss.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          border: Border.all(
                            color:
                                (isExact || isExtra
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
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: Text(
                                isExact
                                    ? 'Exact match'
                                    : isExtra
                                    ? '+${Money.etb(diff)} extra in drawer'
                                    : '-${Money.etb(diff.abs())} cash short',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isExact || isExtra
                                      ? colors.profit
                                      : colors.loss,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
