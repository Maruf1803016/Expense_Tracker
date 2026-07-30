import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/features/export/data/services/export_service.dart';
import 'package:expense_tracker/features/export/domain/entities/export_data.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/monthly_summary.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.'; // Return local folder for temp directory
      },
    );
  });

  group('ExportServiceImpl', () {
    final exportService = ExportServiceImpl();

    final testData = MonthlyExportData(
      month: 7,
      year: 2026,
      summary: const MonthlySummary(
        totalIncome: 5000.0,
        totalExpense: 2000.0,
        netBalance: 3000.0,
        categoryBreakdown: {
          'cat1': 1200.0,
          'cat2': 800.0,
        },
      ),
      budgetStatuses: const [],
      expenses: [
        Expense(
          id: '1',
          title: 'Salary',
          amount: 5000.0,
          categoryId: 'income_cat',
          date: DateTime(2026, 7, 1),
          accountId: 'acc1',
          type: CategoryType.income,
          note: 'monthly salary',
        ),
        Expense(
          id: '2',
          title: 'Rent',
          amount: 1200.0,
          categoryId: 'cat1',
          date: DateTime(2026, 7, 2),
          accountId: 'acc1',
          type: CategoryType.expense,
          note: 'apartment rent',
        ),
        Expense(
          id: '3',
          title: 'Groceries',
          amount: 800.0,
          categoryId: 'cat2',
          date: DateTime(2026, 7, 3),
          accountId: 'acc2',
          type: CategoryType.expense,
          note: 'weekly food shopping',
        ),
      ],
    );

    final categoryNames = {
      'income_cat': 'Salary Category',
      'cat1': 'Housing',
      'cat2': 'Food',
    };

    final accountNames = {
      'acc1': 'Checking',
      'acc2': 'Credit Card',
    };

    final accountBalances = {
      'acc1': 3800.0,
      'acc2': -800.0,
    };

    test('generateCSV should construct a valid CSV format with resolved columns', () async {
      final file = await exportService.generateCSV(
        testData,
        categoryNames: categoryNames,
        accountNames: accountNames,
      );

      final content = await file.readAsString();
      expect(content, contains('Date,Title,Category,Subcategory,Account,Type,Amount,Note'));
      expect(content, contains('Salary,Salary Category,,Checking,Income,5000.0,monthly salary'));
      expect(content, contains('Rent,Housing,,Checking,Expense,1200.0,apartment rent'));
      expect(content, contains('Groceries,Food,,Credit Card,Expense,800.0,weekly food shopping'));
    });

    test('generatePDF should execute successfully and output PDF bytes', () async {
      final file = await exportService.generatePDF(
        testData,
        categoryNames: categoryNames,
        accountNames: accountNames,
        accountBalances: accountBalances,
      );

      final exists = await file.exists();
      expect(exists, isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, isPositive);
    });
  });
}
