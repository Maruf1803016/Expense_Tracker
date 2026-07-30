import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/export_data.dart';
import '../../../../features/category/domain/entities/category.dart';

abstract class ExportService {
  /// Generates a CSV file for the provided data.
  Future<File> generateCSV(
    MonthlyExportData data, {
    required Map<String, String> categoryNames,
    required Map<String, String> accountNames,
  });

  /// Generates a PDF report for the provided data.
  Future<File> generatePDF(
    MonthlyExportData data, {
    required Map<String, String> categoryNames,
    required Map<String, String> accountNames,
    required Map<String, double> accountBalances,
  });
}

class ExportServiceImpl implements ExportService {
  @override
  Future<File> generateCSV(
    MonthlyExportData data, {
    required Map<String, String> categoryNames,
    required Map<String, String> accountNames,
  }) async {
    List<List<dynamic>> rows = [];

    // Header row
    rows.add(['Date', 'Title', 'Category', 'Subcategory', 'Account', 'Type', 'Amount', 'Note']);

    for (var expense in data.expenses) {
      final categoryName = categoryNames[expense.categoryId] ?? expense.categoryId;
      final accountName = accountNames[expense.accountId] ?? expense.accountId;
      final typeStr = expense.type == CategoryType.income ? 'Income' : 'Expense';
      
      rows.add([
        DateFormatter.format(expense.date),
        expense.title,
        categoryName,
        expense.subCategory ?? '',
        accountName,
        typeStr,
        expense.amount,
        expense.note,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/expense_report_${data.year}_${data.month}.csv');
    return await file.writeAsString(csv);
  }

  @override
  Future<File> generatePDF(
    MonthlyExportData data, {
    required Map<String, String> categoryNames,
    required Map<String, String> accountNames,
    required Map<String, double> accountBalances,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormatter.monthYear(DateTime(data.year, data.month));

    // Sort category breakdown High to Low
    final sortedBreakdown = data.summary.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Monthly Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(monthName, style: const pw.TextStyle(fontSize: 16)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary Section
          pw.Text('Financial Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Income', data.summary.totalIncome, PdfColors.green700),
                _buildSummaryItem('Expenses', data.summary.totalExpense, PdfColors.red700),
                _buildSummaryItem('Balance', data.summary.netBalance, data.summary.netBalance >= 0 ? PdfColors.blue700 : PdfColors.red900),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Account Balances Section
          pw.Text('Account Balances', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Account Name', 'Current Balance'],
            data: accountBalances.entries.map((entry) {
              final accountName = accountNames[entry.key] ?? entry.key;
              return [
                accountName,
                CurrencyFormatter.format(entry.value),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          // Category Breakdown Section
          if (sortedBreakdown.isNotEmpty) ...[
            pw.Text('Category Breakdown (Spending)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Category', 'Spent Amount', 'Percentage'],
              data: sortedBreakdown.map((entry) {
                final categoryName = categoryNames[entry.key] ?? entry.key;
                final percentage = data.summary.totalExpense > 0 
                    ? (entry.value / data.summary.totalExpense) * 100 
                    : 0.0;
                return [
                  categoryName,
                  CurrencyFormatter.format(entry.value),
                  '${percentage.toStringAsFixed(1)}%',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Detailed Transactions Section
          pw.Text('Detailed Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellHeight: 25,
            headers: ['Date', 'Title', 'Category', 'Account', 'Amount', 'Type'],
            data: data.expenses.map((e) {
              final categoryName = categoryNames[e.categoryId] ?? e.categoryId;
              final accountName = accountNames[e.accountId] ?? e.accountId;
              final typeStr = e.type == CategoryType.income ? 'Income' : 'Expense';
              return [
                DateFormatter.format(e.date),
                e.title,
                categoryName,
                accountName,
                CurrencyFormatter.format(e.amount),
                typeStr,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/expense_report_${data.year}_${data.month}.pdf');
    return await file.writeAsBytes(await pdf.save());
  }

  pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(
          CurrencyFormatter.format(amount),
          style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
