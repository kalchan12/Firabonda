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

final class ReconciliationScreen extends ConsumerStatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  ConsumerState<ReconciliationScreen> createState() =>
      _ReconciliationScreenState();
}

final class _ReconciliationScreenState
    extends ConsumerState<ReconciliationScreen> {
  final _countedCashController = TextEditingController();
  final _countedStockController = TextEditingController();
  final _noteController = TextEditingController();

  int _selectedTab = 0; // 0: Cash, 1: Stock
  bool _isSaving = false;
  int _expectedCash = 0;
  bool _isLoadingExpected = true;

  @override
  void initState() {
    super.initState();
    _loadExpectedCash();
    _countedCashController.addListener(() => setState(() {}));
    _countedStockController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _countedCashController.dispose();
    _countedStockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExpectedCash() async {
    setState(() => _isLoadingExpected = true);
    final repo = ref.read(inventoryRepositoryProvider);
    final expected = await repo.getExpectedCashBalance();
    if (mounted) {
      setState(() {
        _expectedCash = expected;
        _isLoadingExpected = false;
      });
    }
  }

  int? get _parsedCountedCash {
    try {
      return Money.parseCents(_countedCashController.text);
    } catch (_) {
      return null;
    }
  }

  int? get _parsedCountedStock {
    return int.tryParse(_countedStockController.text.trim());
  }

  Future<void> _saveReconciliation(int expected) async {
    final counted = _selectedTab == 0
        ? _parsedCountedCash
        : (_parsedCountedStock != null ? _parsedCountedStock! * 100 : null);

    if (counted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedTab == 0
                ? 'Please enter physical cash counted'
                : 'Please enter physical stock count',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.addReconciliation(
        ReconciliationInput(
          type: _selectedTab == 0 ? 'cash_account' : 'stock',
          accountId: _selectedTab == 0 ? 'acc_cash' : null,
          expectedCents: expected,
          countedCents: counted,
          date: DateTime.now(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );

      await HapticFeedback.lightImpact();

      if (mounted) {
        _countedCashController.clear();
        _countedStockController.clear();
        _noteController.clear();
        await _loadExpectedCash();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reconciliation logged successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reconciliation: $e')),
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
    final reconciliationsAsync = ref.watch(reconciliationsStreamProvider);

    final totalStockPieces = purchasesAsync.maybeWhen(
      data: (items) => items.fold<int>(0, (sum, i) => sum + i.stockLeft),
      orElse: () => 0,
    );

    final expectedVal = _selectedTab == 0 ? _expectedCash : (totalStockPieces * 100);
    final countedVal = _selectedTab == 0
        ? _parsedCountedCash
        : (_parsedCountedStock != null ? _parsedCountedStock! * 100 : null);
    final difference = countedVal != null ? (countedVal - expectedVal) : 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Reconciliation & Audit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Segmented tab: Cash / Stock
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Cash Reconciliation'),
                icon: Icon(Icons.point_of_sale_rounded),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Stock Count'),
                icon: Icon(Icons.inventory_2_rounded),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (set) {
              setState(() => _selectedTab = set.first);
            },
          ),
          const SizedBox(height: AppSpacing.l),

          // Count Form Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTab == 0
                          ? 'Expected Cash Balance'
                          : 'Expected Stock in Shop',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                    if (_isLoadingExpected && _selectedTab == 0)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        _selectedTab == 0
                            ? Money.etb(_expectedCash)
                            : '$totalStockPieces pieces',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Sora',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Divider(color: colors.border, height: 1),
                const SizedBox(height: AppSpacing.m),

                if (_selectedTab == 0)
                  MoneyField(
                    label: 'Physical cash counted in drawer',
                    controller: _countedCashController,
                  )
                else
                  TextField(
                    controller: _countedStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total physical pieces counted',
                      hintText: 'e.g. 142',
                    ),
                  ),

                if (countedVal != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: (difference == 0
                              ? colors.profit
                              : difference > 0
                                  ? colors.primary
                                  : colors.loss)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: (difference == 0
                                ? colors.profit
                                : difference > 0
                                    ? colors.primary
                                    : colors.loss)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          difference == 0
                              ? 'Count matches perfectly!'
                              : difference > 0
                                  ? 'Surplus (over):'
                                  : 'Deficit (shortage):',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: difference == 0
                                ? colors.profit
                                : difference > 0
                                    ? colors.primary
                                    : colors.loss,
                          ),
                        ),
                        Text(
                          _selectedTab == 0
                              ? (difference >= 0
                                  ? '+ ${Money.etb(difference)}'
                                  : Money.etb(difference))
                              : (difference >= 0
                                  ? '+${difference ~/ 100} pieces'
                                  : '${difference ~/ 100} pieces'),
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: difference == 0
                                ? colors.profit
                                : difference > 0
                                    ? colors.primary
                                    : colors.loss,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.m),

                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Reconciliation note (optional)',
                    hintText: 'e.g. Weekly audit',
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                AppButton(
                  label: _isSaving ? 'Logging...' : 'Save reconciliation',
                  onPressed: _isSaving ? () {} : () => _saveReconciliation(expectedVal),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Audit History
          Text(
            'Reconciliation History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.s),

          reconciliationsAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                  child: Center(
                    child: Text(
                      'No reconciliation records logged yet',
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
                itemBuilder: (context, index) {
                  final rec = records[index];
                  final isCash = rec.type == 'cash_account';
                  final isBalanced = rec.difference == 0;

                  return AppCard(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Row(
                      children: [
                        Icon(
                          isCash
                              ? Icons.point_of_sale_rounded
                              : Icons.inventory_2_rounded,
                          color: colors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCash
                                    ? 'Cash count'
                                    : 'Stock count',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                DateFormat.yMMMd().add_jm().format(rec.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                              if (rec.note != null && rec.note!.isNotEmpty)
                                Text(
                                  '"${rec.note}"',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: colors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isBalanced
                                  ? 'Balanced'
                                  : rec.difference > 0
                                      ? '+${isCash ? Money.etb(rec.difference) : '${rec.difference ~/ 100} pcs'}'
                                      : (isCash
                                          ? Money.etb(rec.difference)
                                          : '${rec.difference ~/ 100} pcs'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isBalanced
                                    ? colors.profit
                                    : rec.difference > 0
                                        ? colors.primary
                                        : colors.loss,
                              ),
                            ),
                            Text(
                              isCash
                                  ? 'Count: ${Money.etb(rec.counted)}'
                                  : 'Count: ${rec.counted ~/ 100} pcs',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Error: $err'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
