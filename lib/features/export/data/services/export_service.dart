import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/export_data.dart';

abstract class ExportService {
  /// Generates a CSV file for the provided data.
  Future<File> generateCSV(MonthlyExportData data);

  /// Generates a PDF report for the provided data.
  Future<File> generatePDF(MonthlyExportData data);
}

class ExportServiceImpl implements ExportService {
  @override
  Future<File> generateCSV(MonthlyExportData data) async {
    List<List<dynamic>> rows = [];

    // --- Section 1: Expenses ---
    rows.add(['--- EXPENSES ---']);
    rows.add(['Date', 'Category', 'Amount', 'Note']);
    for (var expense in data.expenses) {
      rows.add([
        DateFormatter.format(expense.date),
        // We'd ideally have category name here; since we only have IDs in entity, 
        // the UseCase should ideally have resolved names.
        // For now, using ID as per entity.
        expense.categoryId, 
        expense.amount,
        expense.note,
      ]);
    }
    rows.add([]); // empty line

    // --- Section 2: Summary ---
    rows.add(['--- SUMMARY ---']);
    rows.add(['Metric', 'Amount']);
    rows.add(['Total Income', data.summary.totalIncome]);
    rows.add(['Total Expenses', data.summary.totalExpense]);
    rows.add(['Net Balance', data.summary.netBalance]);
    rows.add([]);

    // --- Section 3: Category Breakdown & Budgets ---
    rows.add(['--- BUDGETS & BREAKDOWN ---']);
    rows.add(['Category', 'Spent', 'Budget Limit', 'Remaining']);
    for (var status in data.budgetStatuses) {
      rows.add([
        status.categoryName,
        status.spent,
        status.limit,
        status.remaining,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/expense_report_${data.year}_${data.month}.csv');
    return await file.writeAsString(csv);
  }

  @override
  Future<File> generatePDF(MonthlyExportData data) async {
    final pdf = pw.Document();
    final monthName = DateFormatter.monthYear(DateTime(data.year, data.month));

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
          pw.SizedBox(height: 30),

          // Budget Section
          pw.Text('Budget Status', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Category', 'Spent', 'Limit', 'Status'],
            data: data.budgetStatuses.map((s) => [
              s.categoryName,
              CurrencyFormatter.format(s.spent),
              s.limit > 0 ? CurrencyFormatter.format(s.limit) : 'N/A',
              s.isExceeded ? 'EXCEEDED' : '${(s.percentageUsed * 100).toStringAsFixed(0)}%',
            ]).toList(),
          ),
          pw.SizedBox(height: 30),

          // Expenses Section
          pw.Text('Detailed Expenses', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellHeight: 25,
            headers: ['Date', 'Category ID', 'Amount', 'Note'],
            data: data.expenses.map((e) => [
              DateFormatter.format(e.date),
              e.categoryId,
              CurrencyFormatter.format(e.amount),
              e.note,
            ]).toList(),
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
