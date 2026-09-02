import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/expense_list_item.dart';

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<String> getCurrency() async => 'USD';
  @override
  Future<void> updateCurrency(String currencyCode) async {}
}

class FakeAccountProvider extends ChangeNotifier implements AccountProvider {
  @override
  List<Account> accounts = [
    Account(
      id: 'acc_main',
      name: 'Main Checking',
      icon: Icons.account_balance,
      color: Colors.blue,
      initialBalance: 1000.0,
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Account? getAccountById(String id) {
    return accounts.where((a) => a.id == id).firstOrNull;
  }

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAccountProvider fakeAccountProvider;
  late SettingsProvider fakeSettingsProvider;

  setUp(() {
    fakeAccountProvider = FakeAccountProvider();
    fakeSettingsProvider = SettingsProvider(repository: FakeSettingsRepository());
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccountProvider>.value(value: fakeAccountProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: fakeSettingsProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Transaction Detail Routing & Pending Badge Widget Tests', () {
    testWidgets('Pending badge is visible before amount for pending transactions', (tester) async {
      final pendingExpense = Expense(
        id: 'exp_pending',
        title: 'Dinner Bill',
        amount: 45.0,
        date: DateTime(2026, 8, 20),
        categoryId: 'cat_dining',
        accountId: 'acc_main',
        note: 'Team dinner',
        type: CategoryType.expense,
        paymentStatus: PaymentStatus.pending,
      );

      final category = const Category(
        id: 'cat_dining',
        name: 'Dining',
        type: CategoryType.expense,
        icon: Icons.restaurant,
        subCategories: [],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          ExpenseListItem(
            expense: pendingExpense,
            category: category,
          ),
        ),
      );

      // Verify PENDING badge text is present
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Dinner Bill'), findsOneWidget);
      expect(find.text('- \$45.00'), findsOneWidget);
    });

    testWidgets('Pending badge is hidden for settled transactions', (tester) async {
      final settledExpense = Expense(
        id: 'exp_settled',
        title: 'Grocery Store',
        amount: 60.0,
        date: DateTime(2026, 8, 20),
        categoryId: 'cat_groceries',
        accountId: 'acc_main',
        note: 'Weekly essentials',
        type: CategoryType.expense,
        paymentStatus: PaymentStatus.settled,
      );

      final category = const Category(
        id: 'cat_groceries',
        name: 'Groceries',
        type: CategoryType.expense,
        icon: Icons.shopping_basket,
        subCategories: [],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          ExpenseListItem(
            expense: settledExpense,
            category: category,
          ),
        ),
      );

      // Verify PENDING badge is not rendered
      expect(find.text('PENDING'), findsNothing);
      expect(find.text('Grocery Store'), findsOneWidget);
      expect(find.text('- \$60.00'), findsOneWidget);
    });

    testWidgets('Tapping ExpenseListItem invokes onTap callback to open details', (tester) async {
      final expense = Expense(
        id: 'exp_100',
        title: 'Electricity Bill',
        amount: 85.0,
        date: DateTime(2026, 8, 20),
        categoryId: 'cat_bills',
        accountId: 'acc_main',
        note: 'August utility bill',
        type: CategoryType.expense,
        paymentStatus: PaymentStatus.settled,
      );

      final category = const Category(
        id: 'cat_bills',
        name: 'Bills',
        type: CategoryType.expense,
        icon: Icons.bolt,
        subCategories: [],
      );

      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          ExpenseListItem(
            expense: expense,
            category: category,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(ExpenseListItem));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
