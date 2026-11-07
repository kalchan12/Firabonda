import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/business_logic.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/providers.dart';
import '../application/export_service.dart';

final class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final purchasesAsync = ref.watch(purchaseOverviewsStreamProvider);
    final salesAsync = ref.watch(saleOverviewsStreamProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    final purchases = purchasesAsync.value ?? [];
    final sales = salesAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];

    final startOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).toUtc();
    final endOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).toUtc();

    final mPurchases = purchases.where((p) {
      final d = p.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    final mSales = sales.where((s) {
      final d = s.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    final mExpenses = expenses.where((e) {
      final d = e.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    var spentCents = 0;
    for (final p in mPurchases) {
      spentCents += p.totalCostCents;
    }
    var earnedCents = 0;
    var salesProfitCents = 0;
    for (final s in mSales) {
      earnedCents += s.unitPriceCents * s.quantity;
      salesProfitCents += s.profitCents;
    }
    var expenseCents = 0;
    for (final e in mExpenses) {
      expenseCents += e.amount;
    }
    final realProfit = ShopLogic.realProfit(
      salesProfitCents: salesProfitCents,
      expensesCents: expenseCents,
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Export Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            'Select Month',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            'Month Summary Preview',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          AppCard(
            child: Column(
              children: [
                _PreviewRow(label: 'Purchases (Spent)', value: Money.etb(spentCents)),
                const Divider(height: 16),
                _PreviewRow(label: 'Sales (Earned)', value: Money.etb(earnedCents)),
                const Divider(height: 16),
                _PreviewRow(label: 'Sales count', value: '${mSales.length} sales'),
                const Divider(height: 16),
                _PreviewRow(label: 'Expenses deducted', value: Money.etb(expenseCents)),
                const Divider(height: 16),
                _PreviewRow(
                  label: 'Real Net Profit',
                  value: Money.etb(realProfit),
                  isBold: true,
                  color: realProfit >= 0 ? colors.profit : colors.loss,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_isExporting)
            const Center(child: CircularProgressIndicator())
          else ...[
            AppButton(
              label: 'Export as PDF',
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _isExporting = true);
                try {
                  await ExportService.exportPdf(
                    month: _selectedMonth,
                    purchases: purchases,
                    sales: sales,
                    expenses: expenses,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to export PDF: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _isExporting = false);
                }
              },
            ),
            const SizedBox(height: AppSpacing.m),
            AppButton(
              label: 'Export as CSV (Excel)',
              icon: Icons.table_chart_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _isExporting = true);
                try {
                  await ExportService.exportCsv(
                    month: _selectedMonth,
                    purchases: purchases,
                    sales: sales,
                    expenses: expenses,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to export CSV: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _isExporting = false);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

final class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: colors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
