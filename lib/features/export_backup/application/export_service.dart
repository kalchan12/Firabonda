import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/business_logic.dart';
import '../../../core/utils/money.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/shop_models.dart';

final class ExportService {
  const ExportService._();

  /// Generates a CSV file containing Sales, Purchases, and Expenses for the given period,
  /// saves it to temporary storage, and triggers the share sheet.
  static Future<void> exportCsv({
    required DateTime month,
    required List<PurchaseOverview> purchases,
    required List<SaleOverview> sales,
    required List<ExpenseRow> expenses,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1).toUtc();
    final endOfMonth = DateTime(month.year, month.month + 1, 1).toUtc();

    final filteredPurchases = purchases.where((p) {
      final d = p.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    final filteredSales = sales.where((s) {
      final d = s.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    final filteredExpenses = expenses.where((e) {
      final d = e.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    final monthStr = DateFormat('yyyy-MM').format(month);
    final rows = <List<dynamic>>[];

    // 1. Report Title & Summary
    rows.add(['Fira Bonda Monthly Report', monthStr]);
    rows.add([]);

    var spentCents = 0;
    for (final p in filteredPurchases) {
      spentCents += p.totalCostCents;
    }
    var earnedCents = 0;
    var salesProfitCents = 0;
    for (final s in filteredSales) {
      earnedCents += s.unitPriceCents * s.quantity;
      salesProfitCents += s.profitCents;
    }
    var expenseCents = 0;
    for (final e in filteredExpenses) {
      expenseCents += e.amount;
    }
    final realProfit = ShopLogic.realProfit(
      salesProfitCents: salesProfitCents,
      expensesCents: expenseCents,
    );

    rows.add(['Summary Metric', 'Amount (ETB)']);
    rows.add(['Total Spent (Purchases)', Money.etb(spentCents)]);
    rows.add(['Total Earned (Sales)', Money.etb(earnedCents)]);
    rows.add(['Sales Profit', Money.etb(salesProfitCents)]);
    rows.add(['Expenses Deducted', Money.etb(expenseCents)]);
    rows.add(['Real Net Profit', Money.etb(realProfit)]);
    rows.add([]);

    // 2. Sales section
    rows.add(['SALES RECORDS']);
    rows.add([
      'Date',
      'Category',
      'Color',
      'Quantity',
      'Unit Cost',
      'Unit Price',
      'Profit',
    ]);
    for (final s in filteredSales) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(s.date.toLocal()),
        s.categoryName,
        s.colorName,
        s.quantity,
        Money.etb(s.unitCostCents),
        Money.etb(s.unitPriceCents),
        Money.etb(s.profitCents),
      ]);
    }
    rows.add([]);

    // 3. Purchases section
    rows.add(['PURCHASE RECORDS']);
    rows.add([
      'Date',
      'Category',
      'Color',
      'Quantity',
      'Unit Cost',
      'Total Cost',
      'Supplier',
    ]);
    for (final p in filteredPurchases) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(p.date.toLocal()),
        p.categoryName,
        p.colorName,
        p.quantity,
        Money.etb(p.unitCostCents),
        Money.etb(p.totalCostCents),
        p.supplierName ?? 'None',
      ]);
    }
    rows.add([]);

    // 4. Expenses section
    rows.add(['EXPENSES RECORDS']);
    rows.add(['Date', 'Title', 'Amount', 'Note']);
    for (final e in filteredExpenses) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(e.date.toLocal()),
        e.title,
        Money.etb(e.amount),
        e.note ?? '',
      ]);
    }

    final csvData = csv.encode(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/firabonda_report_$monthStr.csv');
    await file.writeAsString(csvData);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Fira Bonda Monthly Report ($monthStr)',
        subject: 'Fira Bonda Report $monthStr',
      ),
    );
  }

  /// Generates a PDF report document and opens share sheet.
  static Future<void> exportPdf({
    required DateTime month,
    required List<PurchaseOverview> purchases,
    required List<SaleOverview> sales,
    required List<ExpenseRow> expenses,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1).toUtc();
    final endOfMonth = DateTime(month.year, month.month + 1, 1).toUtc();

    final filteredPurchases = purchases.where((p) {
      final d = p.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    final filteredSales = sales.where((s) {
      final d = s.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    final filteredExpenses = expenses.where((e) {
      final d = e.date.toUtc();
      return !d.isBefore(startOfMonth) && d.isBefore(endOfMonth);
    }).toList();

    var spentCents = 0;
    for (final p in filteredPurchases) {
      spentCents += p.totalCostCents;
    }
    var earnedCents = 0;
    var salesProfitCents = 0;
    var unitsSold = 0;
    for (final s in filteredSales) {
      earnedCents += s.unitPriceCents * s.quantity;
      salesProfitCents += s.profitCents;
      unitsSold += s.quantity;
    }
    var expenseCents = 0;
    for (final e in filteredExpenses) {
      expenseCents += e.amount;
    }
    final realProfit = ShopLogic.realProfit(
      salesProfitCents: salesProfitCents,
      expensesCents: expenseCents,
    );

    final monthTitle = DateFormat('MMMM yyyy').format(month);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'FIRA BONDA',
                    style: const pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Monthly Report • $monthTitle',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Performance Summary',
              style: const pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Total Spent (Purchases)', Money.etb(spentCents)],
                ['Total Earned (Sales)', Money.etb(earnedCents)],
                ['Gross Sales Profit', Money.etb(salesProfitCents)],
                ['Shop Expenses', Money.etb(expenseCents)],
                ['Real Net Profit', Money.etb(realProfit)],
                ['Total Units Sold', '$unitsSold items'],
              ],
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Sales Breakdown (${filteredSales.length} records)',
              style: const pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (filteredSales.isEmpty)
              pw.Text(
                'No sales recorded this month.',
                style: const pw.TextStyle(color: PdfColors.grey600),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Item', 'Qty', 'Unit Price', 'Profit'],
                data: filteredSales
                    .map(
                      (s) => [
                        DateFormat('MM/dd').format(s.date.toLocal()),
                        '${s.categoryName} (${s.colorName})',
                        '${s.quantity}',
                        Money.etb(s.unitPriceCents),
                        Money.etb(s.profitCents),
                      ],
                    )
                    .toList(),
                headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 6,
                ),
              ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Expenses (${filteredExpenses.length} records)',
              style: const pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (filteredExpenses.isEmpty)
              pw.Text(
                'No expenses recorded this month.',
                style: const pw.TextStyle(color: PdfColors.grey600),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Title', 'Amount', 'Note'],
                data: filteredExpenses
                    .map(
                      (e) => [
                        DateFormat('MM/dd').format(e.date.toLocal()),
                        e.title,
                        Money.etb(e.amount),
                        e.note ?? '-',
                      ],
                    )
                    .toList(),
                headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 6,
                ),
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final monthStr = DateFormat('yyyy-MM').format(month);
    final file = File('${tempDir.path}/firabonda_report_$monthStr.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Fira Bonda Monthly Report ($monthTitle)',
        subject: 'Fira Bonda Report $monthTitle',
      ),
    );
  }
}
