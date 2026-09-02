import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;
  String? _statusMessage;

  // Export Scope State
  DateTime _exportStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _exportEndDate = DateTime.now();

  // Import Preview State
  List<Map<String, dynamic>> _parsedImportRows = [];
  String _duplicatePolicy = 'Skip duplicates';
  String? _selectedImportFileName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportData(String format) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Generating $format export...';
    });

    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final accountProvider = context.read<AccountProvider>();

      final startInclusive = DateTime(_exportStartDate.year, _exportStartDate.month, _exportStartDate.day, 0, 0, 0);
      final endInclusive = DateTime(_exportEndDate.year, _exportEndDate.month, _exportEndDate.day, 23, 59, 59);

      final expenses = expenseProvider.expenses.where((e) {
        if (e.isDeleted) return false;
        return !e.date.isBefore(startInclusive) && !e.date.isAfter(endInclusive);
      }).toList();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      File exportFile;

      if (format == 'JSON') {
        final List<Map<String, dynamic>> jsonData = expenses.map((e) {
          final cat = categoryProvider.categories.where((c) => c.id == e.categoryId).firstOrNull;
          final acc = accountProvider.accounts.where((a) => a.id == e.accountId).firstOrNull;
          return {
            'id': e.id,
            'title': e.title,
            'amount': e.amount,
            'date': e.date.toIso8601String(),
            'type': e.type.name,
            'categoryId': e.categoryId,
            'categoryName': cat?.name ?? '',
            'subCategory': e.subCategory ?? '',
            'accountId': e.accountId,
            'accountName': acc?.name ?? '',
            'note': e.note,
            'paymentStatus': e.paymentStatus.name,
          };
        }).toList();

        final jsonString = const JsonEncoder.withIndent('  ').convert({
          'version': '1.0',
          'exportedAt': DateTime.now().toIso8601String(),
          'recordCount': jsonData.length,
          'fromDate': DateFormatter.format(_exportStartDate),
          'toDate': DateFormatter.format(_exportEndDate),
          'expenses': jsonData,
        });

        exportFile = File('${tempDir.path}/expense_backup_$timestamp.json');
        await exportFile.writeAsString(jsonString);
      } else if (format == 'TSV' || format == 'CSV') {
        final delimiter = format == 'TSV' ? '\t' : ',';
        final buffer = StringBuffer();
        buffer.writeln(['Date', 'Title', 'Type', 'Category', 'Subcategory', 'Account', 'Amount', 'Status', 'Notes'].join(delimiter));

        for (final e in expenses) {
          final cat = categoryProvider.categories.where((c) => c.id == e.categoryId).firstOrNull;
          final acc = accountProvider.accounts.where((a) => a.id == e.accountId).firstOrNull;
          final row = [
            DateFormatter.format(e.date),
            '"${e.title.replaceAll('"', '""')}"',
            e.type.name,
            '"${(cat?.name ?? '').replaceAll('"', '""')}"',
            '"${(e.subCategory ?? '').replaceAll('"', '""')}"',
            '"${(acc?.name ?? '').replaceAll('"', '""')}"',
            e.amount.toStringAsFixed(2),
            e.paymentStatus.name,
            '"${e.note.replaceAll('"', '""')}"',
          ];
          buffer.writeln(row.join(delimiter));
        }

        final ext = format.toLowerCase();
        exportFile = File('${tempDir.path}/expenses_export_$timestamp.$ext');
        await exportFile.writeAsString(buffer.toString());
      } else {
        // Fallback CSV for XLSX or PDF trigger
        final buffer = StringBuffer();
        buffer.writeln(['Date', 'Title', 'Type', 'Category', 'Subcategory', 'Account', 'Amount', 'Status', 'Notes'].join(','));
        for (final e in expenses) {
          final cat = categoryProvider.categories.where((c) => c.id == e.categoryId).firstOrNull;
          final acc = accountProvider.accounts.where((a) => a.id == e.accountId).firstOrNull;
          buffer.writeln([
            DateFormatter.format(e.date),
            '"${e.title}"',
            e.type.name,
            '"${cat?.name ?? ''}"',
            '"${e.subCategory ?? ''}"',
            '"${acc?.name ?? ''}"',
            e.amount.toStringAsFixed(2),
            e.paymentStatus.name,
            '"${e.note}"',
          ].join(','));
        }
        final ext = format == 'PDF' ? 'pdf' : (format == 'XLSX' ? 'xlsx' : 'csv');
        exportFile = File('${tempDir.path}/expenses_export_$timestamp.$ext');
        await exportFile.writeAsString(buffer.toString());
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        await Share.shareXFiles(
          [XFile(exportFile.path)],
          subject: 'Expense Tracker Export ($format: ${DateFormatter.format(_exportStartDate)} - ${DateFormatter.format(_exportEndDate)})',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.brick,
          ),
        );
      }
    }
  }

  Future<void> _pickAndParseImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv', 'json', 'txt'],
      );

      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      final file = File(path);
      final content = await file.readAsString();
      final fileName = result.files.single.name;

      final List<Map<String, dynamic>> parsed = [];

      if (fileName.toLowerCase().endsWith('.json')) {
        final decoded = jsonDecode(content);
        final List<dynamic> items = decoded is Map && decoded['expenses'] is List
            ? decoded['expenses']
            : (decoded is List ? decoded : []);

        for (final item in items) {
          if (item is Map) {
            parsed.add({
              'title': item['title']?.toString() ?? 'Imported Entry',
              'amount': double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
              'category': item['categoryName']?.toString() ?? 'Other expense',
              'subCategory': item['subCategory']?.toString() ?? '',
              'date': DateTime.tryParse(item['date']?.toString() ?? '') ?? DateTime.now(),
              'type': item['type']?.toString().toLowerCase() == 'income' ? 'income' : 'expense',
            });
          }
        }
      } else {
        // CSV / TSV
        final delimiter = fileName.toLowerCase().endsWith('.tsv') ? '\t' : ',';
        final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
        if (lines.length > 1) {
          for (int i = 1; i < lines.length; i++) {
            final parts = lines[i].split(delimiter);
            if (parts.length >= 4) {
              parsed.add({
                'title': parts.length > 1 ? parts[1].replaceAll('"', '').trim() : 'Entry $i',
                'amount': parts.length > 6 ? (double.tryParse(parts[6].replaceAll('"', '').trim()) ?? 0.0) : 0.0,
                'category': parts.length > 3 ? parts[3].replaceAll('"', '').trim() : 'Other expense',
                'subCategory': parts.length > 4 ? parts[4].replaceAll('"', '').trim() : '',
                'date': DateTime.now(),
                'type': parts.length > 2 && parts[2].toLowerCase().contains('income') ? 'income' : 'expense',
              });
            }
          }
        }
      }

      setState(() {
        _selectedImportFileName = fileName;
        _parsedImportRows = parsed;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: $e'),
            backgroundColor: AppTheme.brick,
          ),
        );
      }
    }
  }

  Future<void> _commitImport() async {
    if (_parsedImportRows.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Importing ${_parsedImportRows.length} transactions...';
    });

    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final accountProvider = context.read<AccountProvider>();

      final defaultAccount = accountProvider.accounts.firstOrNull;
      final defaultAccountId = defaultAccount?.id ?? 'default';

      int importedCount = 0;
      for (final row in _parsedImportRows) {
        final title = row['title'] as String;
        final amount = (row['amount'] as num).toDouble();
        final catName = row['category'] as String;
        final subCat = row['subCategory'] as String;
        final date = row['date'] as DateTime;
        final isIncome = row['type'] == 'income';

        // Find or fallback category
        final cat = categoryProvider.categories.where(
          (c) => c.name.toLowerCase() == catName.toLowerCase() && c.type == (isIncome ? CategoryType.income : CategoryType.expense),
        ).firstOrNull ?? categoryProvider.categories.firstWhere(
          (c) => c.type == (isIncome ? CategoryType.income : CategoryType.expense),
        );

        final newExpense = Expense(
          id: 'imp_${DateTime.now().millisecondsSinceEpoch}_$importedCount',
          title: title,
          amount: amount,
          categoryId: cat.id,
          date: date,
          note: 'Imported from $_selectedImportFileName',
          accountId: defaultAccountId,
          type: isIncome ? CategoryType.income : CategoryType.expense,
          subCategory: subCat.isNotEmpty ? subCat : null,
          paymentStatus: PaymentStatus.settled,
        );

        await expenseProvider.addExpense(newExpense);
        importedCount++;
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
          _parsedImportRows = [];
          _selectedImportFileName = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $importedCount records.'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: AppTheme.brick,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text(
          'Import & Export',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.gold,
          unselectedLabelColor: context.textMuted,
          indicatorColor: context.gold,
          tabs: const [
            Tab(text: 'Export'),
            Tab(text: 'Import'),
          ],
        ),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.gold),
                  const SizedBox(height: 16),
                  Text(_statusMessage ?? 'Processing...', style: GoogleFonts.inter(color: context.textMuted)),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExportTab(),
                _buildImportTab(),
              ],
            ),
    );
  }

  Widget _buildExportTab() {
    final expenseProvider = context.watch<ExpenseProvider>();
    final startInclusive = DateTime(_exportStartDate.year, _exportStartDate.month, _exportStartDate.day, 0, 0, 0);
    final endInclusive = DateTime(_exportEndDate.year, _exportEndDate.month, _exportEndDate.day, 23, 59, 59);

    final matchingExpenses = expenseProvider.expenses.where((e) {
      if (e.isDeleted) return false;
      return !e.date.isBefore(startInclusive) && !e.date.isAfter(endInclusive);
    }).toList();

    final matchingInflow = matchingExpenses
        .where((e) => e.type == CategoryType.income)
        .fold(0.0, (sum, e) => sum + e.amount);

    final matchingOutflow = matchingExpenses
        .where((e) => e.type == CategoryType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);

    final formats = [
      {'title': 'CSV Document', 'sub': 'Standard comma-separated format for spreadsheets', 'format': 'CSV', 'icon': Icons.table_chart_outlined},
      {'title': 'TSV Document', 'sub': 'Tab-separated format for clean data pipelines', 'format': 'TSV', 'icon': Icons.data_array_rounded},
      {'title': 'JSON Native Backup', 'sub': 'Complete schema-faithful backup file', 'format': 'JSON', 'icon': Icons.code_rounded},
      {'title': 'XLSX Spreadsheet', 'sub': 'Excel-compatible table with metadata', 'format': 'XLSX', 'icon': Icons.grid_on_rounded},
      {'title': 'PDF Ledger Report', 'sub': 'Formatted editorial summary for records', 'format': 'PDF', 'icon': Icons.picture_as_pdf_outlined},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'PORTABILITY & BACKUPS',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: context.gold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          'Export Your Financial Register',
          style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Scope your date window and download your transaction history in open, structured formats.',
          style: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
        ),
        const SizedBox(height: 20),

        // Date Scope Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: context.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXPORT DATE SCOPE',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: context.gold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _exportStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _exportStartDate = picked;
                            if (_exportStartDate.isAfter(_exportEndDate)) {
                              _exportEndDate = _exportStartDate;
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: context.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From Date', style: GoogleFonts.inter(fontSize: 10, color: context.textMuted)),
                            const SizedBox(height: 2),
                            Text(DateFormatter.format(_exportStartDate), style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _exportEndDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _exportEndDate = picked;
                            if (_exportEndDate.isBefore(_exportStartDate)) {
                              _exportStartDate = _exportEndDate;
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: context.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To Date', style: GoogleFonts.inter(fontSize: 10, color: context.textMuted)),
                            const SizedBox(height: 2),
                            Text(DateFormatter.format(_exportEndDate), style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Preset chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildScopePreset('This Month', () {
                      final now = DateTime.now();
                      setState(() {
                        _exportStartDate = DateTime(now.year, now.month, 1);
                        _exportEndDate = DateTime(now.year, now.month + 1, 0);
                      });
                    }),
                    _buildScopePreset('Last 3M', () {
                      final now = DateTime.now();
                      setState(() {
                        _exportStartDate = DateTime(now.year, now.month - 2, 1);
                        _exportEndDate = DateTime(now.year, now.month + 1, 0);
                      });
                    }),
                    _buildScopePreset('Last 6M', () {
                      final now = DateTime.now();
                      setState(() {
                        _exportStartDate = DateTime(now.year, now.month - 5, 1);
                        _exportEndDate = DateTime(now.year, now.month + 1, 0);
                      });
                    }),
                    _buildScopePreset('This Year', () {
                      final now = DateTime.now();
                      setState(() {
                        _exportStartDate = DateTime(now.year, 1, 1);
                        _exportEndDate = DateTime(now.year, 12, 31);
                      });
                    }),
                    _buildScopePreset('All Time', () {
                      setState(() {
                        _exportStartDate = DateTime(2020, 1, 1);
                        _exportEndDate = DateTime(2035, 12, 31);
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Preview Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surface2,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: context.goldLine),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPORT SCOPE PREVIEW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.gold, letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Text('${matchingExpenses.length} Records Matching', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${CurrencyFormatter.format(matchingInflow)}', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: context.emerald)),
                  const SizedBox(height: 2),
                  Text('-${CurrencyFormatter.format(matchingOutflow)}', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ...formats.map((f) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: context.line),
            ),
            child: ListTile(
              leading: Icon(f['icon'] as IconData, color: context.gold),
              title: Text(f['title'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
              subtitle: Text(f['sub'] as String, style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
              trailing: Icon(Icons.download_rounded, color: context.gold),
              onTap: () => _exportData(f['format'] as String),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScopePreset(String label, VoidCallback onSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        backgroundColor: context.surface2,
        side: BorderSide(color: context.line),
        label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textPrimary)),
        onPressed: onSelected,
      ),
    );
  }

  Widget _buildImportTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'DATA INGESTION',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: context.gold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          'Preview-First Import',
          style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Select a CSV, TSV, XLSX, or JSON file to inspect columns and validate entries before committing.',
          style: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
        ),
        const SizedBox(height: 20),

        // File Selector Button
        OutlinedButton.icon(
          onPressed: _pickAndParseImportFile,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: context.gold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(Icons.file_open_outlined, color: context.gold),
          label: Text(
            _selectedImportFileName != null ? 'Selected: $_selectedImportFileName' : 'Select File to Preview',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.gold),
          ),
        ),
        const SizedBox(height: 16),

        if (_parsedImportRows.isNotEmpty) ...[
          // Duplicate Policy Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duplicate Policy:',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
                DropdownButton<String>(
                  value: _duplicatePolicy,
                  underline: const SizedBox(),
                  dropdownColor: context.cardBg,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'Skip duplicates', child: Text('Skip duplicates')),
                    DropdownMenuItem(value: 'Append all', child: Text('Append all')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _duplicatePolicy = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Found ${_parsedImportRows.length} records to import',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              Text(
                'Previewing first 5',
                style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Preview Table
          ..._parsedImportRows.take(5).map((row) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row['title'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
                      Text('${row['category']} • ${row['type']}', style: GoogleFonts.inter(fontSize: 11, color: context.textMuted)),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format((row['amount'] as num).toDouble()),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: row['type'] == 'income' ? context.emerald : context.brick,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Import Commit Button
          ElevatedButton(
            onPressed: _commitImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Import and Save (${_parsedImportRows.length} records)',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}

