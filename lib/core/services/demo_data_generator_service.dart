import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/goal.dart';
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/trip_plan.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/loan/domain/entities/loan.dart';
import 'package:expense_tracker/features/loan/presentation/providers/loan_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/features/work_routine/domain/entities/work_routine.dart';
import 'package:expense_tracker/features/work_routine/presentation/providers/work_routine_provider.dart';

class DemoDataGeneratorService {
  static final _uuid = const Uuid();
  static final _random = Random(42); // Deterministic seed

  /// Populates a comprehensive 1-year historical dataset (past 12 months up to current date).
  static Future<int> generateOneYearDemoData({
    required AccountProvider accountProvider,
    required CategoryProvider categoryProvider,
    required ExpenseProvider expenseProvider,
    required GoalProvider goalProvider,
    required TripPlanProvider tripPlanProvider,
    required LoanProvider loanProvider,
    required RecurringTransactionProvider recurringProvider,
    required WorkRoutineProvider workRoutineProvider,
  }) async {
    // 1. Resolve Canonical Categories
    final rawCats = categoryProvider.categories.isNotEmpty 
        ? categoryProvider.categories 
        : Category.defaultCategories;

    Category findCat(String name, CategoryType type) {
      return rawCats.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase() && c.type == type,
        orElse: () => rawCats.firstWhere(
          (c) => c.type == type,
          orElse: () => rawCats.first,
        ),
      );
    }

    final catFood = findCat('Food & Dining', CategoryType.expense);
    final catHome = findCat('Home', CategoryType.expense);
    final catBills = findCat('Bills & Utilities', CategoryType.expense);
    final catTransport = findCat('Transport & Travel', CategoryType.expense);
    final catShopping = findCat('Shopping', CategoryType.expense);
    final catHealth = findCat('Health & Personal Care', CategoryType.expense);
    final catEntertainment = findCat('Entertainment', CategoryType.expense);
    final catFinance = findCat('Finance & Other', CategoryType.expense);

    final catSalary = findCat('Salary', CategoryType.income);
    final catFreelance = findCat('Freelance', CategoryType.income);
    final catInvestment = findCat('Investment', CategoryType.income);

    // 2. Ensure Core Accounts
    Account chaseAcc;
    Account savingsAcc;
    Account amexAcc;
    Account cashAcc;

    if (accountProvider.accounts.isEmpty) {
      chaseAcc = Account(
        id: _uuid.v4(),
        name: 'Chase Checking',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF1B3A2B),
        initialBalance: 4850.0,
        isDefault: true,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        holderName: 'Alex Hunter',
        accountNumber: '4892',
      );
      savingsAcc = Account(
        id: _uuid.v4(),
        name: 'High-Yield Savings',
        icon: Icons.savings_rounded,
        color: const Color(0xFFB78A3D),
        initialBalance: 18500.0,
        isDefault: false,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        holderName: 'Alex Hunter',
        accountNumber: '7321',
      );
      amexAcc = Account(
        id: _uuid.v4(),
        name: 'Amex Gold Card',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFFD97706),
        initialBalance: 0.0,
        isDefault: false,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        holderName: 'Alex Hunter',
        accountNumber: '1008',
      );
      cashAcc = Account(
        id: _uuid.v4(),
        name: 'Cash Wallet',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF059669),
        initialBalance: 250.0,
        isDefault: false,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        holderName: 'Alex Hunter',
        accountNumber: 'Cash',
      );

      await accountProvider.add(chaseAcc);
      await accountProvider.add(savingsAcc);
      await accountProvider.add(amexAcc);
      await accountProvider.add(cashAcc);
    } else {
      chaseAcc = accountProvider.accounts.firstWhere((a) => a.isDefault, orElse: () => accountProvider.accounts.first);
      savingsAcc = accountProvider.accounts.firstWhere((a) => a.id != chaseAcc.id, orElse: () => chaseAcc);
      amexAcc = accountProvider.accounts.firstWhere((a) => a.id != chaseAcc.id && a.id != savingsAcc.id, orElse: () => chaseAcc);
      cashAcc = accountProvider.accounts.firstWhere((a) => a.id != chaseAcc.id && a.id != savingsAcc.id && a.id != amexAcc.id, orElse: () => chaseAcc);
    }

    final now = DateTime.now();
    int createdCount = 0;

    // 3. Generate 12 Months of Rich Historical Transactions (Past 365 Days)
    for (int monthOffset = 11; monthOffset >= 0; monthOffset--) {
      final targetMonth = DateTime(now.year, now.month - monthOffset, 1);
      final daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      final isCurrentMonth = targetMonth.year == now.year && targetMonth.month == now.month;
      final maxDay = isCurrentMonth ? now.day : daysInMonth;

      // A. Fixed Monthly Income
      // 1st of month: Primary Tech Corp Salary
      if (1 <= maxDay) {
        final salDate = DateTime(targetMonth.year, targetMonth.month, min(1, daysInMonth), 9, 30);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Tech Corp Monthly Salary',
          amount: 4250.00,
          date: salDate,
          type: CategoryType.income,
          categoryId: catSalary.id,
          subCategory: 'Salary',
          accountId: chaseAcc.id,
          note: 'Direct deposit payroll',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // 15th of month: Freelance Design Retainer
      if (15 <= maxDay) {
        final freeDate = DateTime(targetMonth.year, targetMonth.month, min(15, daysInMonth), 14, 0);
        final freeAmount = 650.0 + (_random.nextInt(6) * 100);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Studio Freelance Retainer',
          amount: freeAmount,
          date: freeDate,
          type: CategoryType.income,
          categoryId: catFreelance.id,
          subCategory: 'Client Work',
          accountId: chaseAcc.id,
          note: 'UI design deliverables',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // End of month: HYSA Interest
      if (28 <= maxDay) {
        final intDate = DateTime(targetMonth.year, targetMonth.month, min(28, daysInMonth), 23, 0);
        final intAmount = 68.0 + (_random.nextInt(150) / 10.0);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'HYSA Monthly Interest',
          amount: double.parse(intAmount.toStringAsFixed(2)),
          date: intDate,
          type: CategoryType.income,
          categoryId: catInvestment.id,
          subCategory: 'Interest & Dividends',
          accountId: savingsAcc.id,
          note: '4.75% APY yield payout',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // B. Fixed Monthly Expenses
      // 1st: Apartment Rent
      if (1 <= maxDay) {
        final rentDate = DateTime(targetMonth.year, targetMonth.month, min(1, daysInMonth), 10, 0);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Luxury Loft Apartment Rent',
          amount: 1450.00,
          date: rentDate,
          type: CategoryType.expense,
          categoryId: catHome.id,
          subCategory: 'Rent/Mortgage',
          accountId: chaseAcc.id,
          note: 'Monthly lease installment',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // 5th: Electricity & Grid
      if (5 <= maxDay) {
        final elecDate = DateTime(targetMonth.year, targetMonth.month, min(5, daysInMonth), 11, 30);
        final elecAmount = 115.0 + (_random.nextInt(45));
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'City Power & Utilities',
          amount: elecAmount,
          date: elecDate,
          type: CategoryType.expense,
          categoryId: catBills.id,
          subCategory: 'Electricity',
          accountId: chaseAcc.id,
          note: 'Power grid & gas statement',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // 10th: Fiber Internet
      if (10 <= maxDay) {
        final netDate = DateTime(targetMonth.year, targetMonth.month, min(10, daysInMonth), 8, 45);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Fiber Gigabit Internet',
          amount: 75.00,
          date: netDate,
          type: CategoryType.expense,
          categoryId: catBills.id,
          subCategory: 'Internet',
          accountId: chaseAcc.id,
          note: '1000 Mbps synchronous fiber',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // 12th: Mobile Phone Unlimited
      if (12 <= maxDay) {
        final phoneDate = DateTime(targetMonth.year, targetMonth.month, min(12, daysInMonth), 9, 15);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Mobile Phone Plan 5G',
          amount: 60.00,
          date: phoneDate,
          type: CategoryType.expense,
          categoryId: catBills.id,
          subCategory: 'Phone',
          accountId: amexAcc.id,
          note: 'Unlimited priority data',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // 14th: Digital Subscriptions
      if (14 <= maxDay) {
        final subDate = DateTime(targetMonth.year, targetMonth.month, min(14, daysInMonth), 12, 0);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Digital Cloud & Media Bundle',
          amount: 28.99,
          date: subDate,
          type: CategoryType.expense,
          categoryId: catEntertainment.id,
          subCategory: 'Subscriptions',
          accountId: amexAcc.id,
          note: 'Netflix, Spotify & iCloud',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // 18th: Gym & Fitness
      if (18 <= maxDay) {
        final gymDate = DateTime(targetMonth.year, targetMonth.month, min(18, daysInMonth), 7, 30);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Equinox Gym & Spa Pass',
          amount: 120.00,
          date: gymDate,
          type: CategoryType.expense,
          categoryId: catHealth.id,
          subCategory: 'Fitness & Wellbeing',
          accountId: amexAcc.id,
          note: 'Monthly wellness membership',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // 20th: Auto Savings Transfer
      if (20 <= maxDay) {
        final transDate = DateTime(targetMonth.year, targetMonth.month, min(20, daysInMonth), 10, 0);
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Monthly Liquidity Reserve Transfer',
          amount: 800.00,
          date: transDate,
          type: CategoryType.transfer,
          categoryId: catFinance.id,
          subCategory: 'Taxes',
          accountId: chaseAcc.id,
          toAccountId: savingsAcc.id,
          note: 'Automated transfer to high yield vault',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      // C. Variable Weekly Transactions (Groceries, Dining, Fuel, Shopping)
      final groceryDays = [3, 10, 17, 24];
      for (final gDay in groceryDays) {
        if (gDay <= maxDay) {
          final gDate = DateTime(targetMonth.year, targetMonth.month, gDay, 17, 30);
          final gAmount = 85.0 + (_random.nextInt(80));
          await expenseProvider.addExpense(Expense(
            id: _uuid.v4(),
            title: 'Whole Foods Market Provisions',
            amount: gAmount,
            date: gDate,
            type: CategoryType.expense,
            categoryId: catFood.id,
            subCategory: 'Groceries',
            accountId: amexAcc.id,
            note: 'Organic produce & household staples',
            paymentStatus: PaymentStatus.settled,
          ));
          createdCount++;
        }
      }

      final diningDays = [6, 13, 21, 27];
      for (final dDay in diningDays) {
        if (dDay <= maxDay) {
          final dDate = DateTime(targetMonth.year, targetMonth.month, dDay, 20, 15);
          final dAmount = 45.0 + (_random.nextInt(65));
          await expenseProvider.addExpense(Expense(
            id: _uuid.v4(),
            title: 'Artisan Bistro & Wine',
            amount: dAmount,
            date: dDate,
            type: CategoryType.expense,
            categoryId: catFood.id,
            subCategory: 'Restaurant',
            accountId: amexAcc.id,
            note: 'Dinner & evening hospitality',
            paymentStatus: PaymentStatus.settled,
          ));
          createdCount++;
        }
      }

      final fuelDays = [8, 22];
      for (final fDay in fuelDays) {
        if (fDay <= maxDay) {
          final fDate = DateTime(targetMonth.year, targetMonth.month, fDay, 8, 15);
          final fAmount = 48.0 + (_random.nextInt(25));
          await expenseProvider.addExpense(Expense(
            id: _uuid.v4(),
            title: 'Shell Fuel & Highway Toll',
            amount: fAmount,
            date: fDate,
            type: CategoryType.expense,
            categoryId: catTransport.id,
            subCategory: 'Fuel',
            accountId: chaseAcc.id,
            note: 'Full tank premium gasoline',
            paymentStatus: PaymentStatus.settled,
          ));
          createdCount++;
        }
      }

      // Occasional Shopping & Healthcare
      if (monthOffset % 2 == 0 && 16 <= maxDay) {
        final sDate = DateTime(targetMonth.year, targetMonth.month, min(16, daysInMonth), 15, 0);
        final sAmount = 135.0 + (_random.nextInt(150));
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'Nordstrom Wardrobe Essentials',
          amount: sAmount,
          date: sDate,
          type: CategoryType.expense,
          categoryId: catShopping.id,
          subCategory: 'Clothing',
          accountId: amexAcc.id,
          note: 'Seasonal apparel',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }

      if (monthOffset % 3 == 0 && 25 <= maxDay) {
        final cDate = DateTime(targetMonth.year, targetMonth.month, min(25, daysInMonth), 16, 30);
        final cAmount = 35.0 + (_random.nextInt(40));
        await expenseProvider.addExpense(Expense(
          id: _uuid.v4(),
          title: 'CVS Caremark Pharmacy & Care',
          amount: cAmount,
          date: cDate,
          type: CategoryType.expense,
          categoryId: catHealth.id,
          subCategory: 'Pharmacy',
          accountId: chaseAcc.id,
          note: 'Vitamins & wellness supplements',
          paymentStatus: PaymentStatus.settled,
        ));
        createdCount++;
      }
    }

    // 4. Create Realistic Goals
    if (goalProvider.plans.isEmpty) {
      await goalProvider.add(Goal(
        id: _uuid.v4(),
        title: 'Emergency Reserve Vault (6 Mo)',
        totalBudget: 25000.00,
        financedAmount: 18500.00,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
        note: '6 months full living expenses buffer in HYSA',
        createdAt: DateTime(now.year, 1, 1),
        categoryIds: [catHome.id, catBills.id, catFood.id],
      ));

      await goalProvider.add(Goal(
        id: _uuid.v4(),
        title: 'Tesla Model 3 Down Payment',
        totalBudget: 10000.00,
        financedAmount: 6800.00,
        startDate: DateTime(now.year, 3, 1),
        endDate: DateTime(now.year, 11, 30),
        note: 'Vehicle purchase capital allocation',
        createdAt: DateTime(now.year, 3, 1),
        categoryIds: [catTransport.id],
      ));
    }

    // 5. Create Realistic Trip Plans
    if (tripPlanProvider.tripPlans.isEmpty) {
      await tripPlanProvider.add(TripPlan(
        id: _uuid.v4(),
        title: 'Kyoto & Tokyo Autumn Journey',
        budgetAmount: 3800.00,
        startDate: DateTime(now.year, 10, 15),
        endDate: DateTime(now.year, 10, 28),
        createdAt: DateTime(now.year, 6, 1),
        categoryId: catTransport.id,
      ));

      await tripPlanProvider.add(TripPlan(
        id: _uuid.v4(),
        title: 'Swiss Alps Winter Retreat',
        budgetAmount: 2600.00,
        startDate: DateTime(now.year, 12, 18),
        endDate: DateTime(now.year, 12, 27),
        createdAt: DateTime(now.year, 7, 15),
        categoryId: catTransport.id,
      ));
    }

    // 6. Create Realistic Loans & Debts
    if (loanProvider.loans.isEmpty) {
      await loanProvider.add(Loan(
        id: _uuid.v4(),
        title: 'Family Home Improvement Support',
        counterparty: 'Grand Central Credit',
        type: LoanType.borrowed,
        originalAmount: 5000.00,
        paidAmount: 3500.00,
        dueDate: DateTime(now.year, 12, 15),
        notes: '0% interest home upgrade loan',
        createdAt: DateTime(now.year - 1, 12, 1),
        repayments: [
          LoanRepayment(
            id: _uuid.v4(),
            amount: 1500.0,
            date: DateTime(now.year, 2, 15),
            accountId: chaseAcc.id,
            note: 'First installment',
          ),
          LoanRepayment(
            id: _uuid.v4(),
            amount: 2000.0,
            date: DateTime(now.year, 5, 15),
            accountId: chaseAcc.id,
            note: 'Second installment',
          ),
        ],
      ));

      await loanProvider.add(Loan(
        id: _uuid.v4(),
        title: 'Personal Loan to Liam Vance',
        counterparty: 'Liam Vance',
        type: LoanType.lent,
        originalAmount: 1200.00,
        paidAmount: 800.00,
        dueDate: DateTime(now.year, 11, 20),
        notes: 'Bridge loan for studio camera equipment',
        createdAt: DateTime(now.year, 3, 10),
        repayments: [
          LoanRepayment(
            id: _uuid.v4(),
            amount: 800.0,
            date: DateTime(now.year, 6, 10),
            accountId: chaseAcc.id,
            note: 'Partial payback received',
          ),
        ],
      ));
    }

    // 7. Create Recurring Transaction Rules
    if (recurringProvider.sources.isEmpty) {
      await recurringProvider.addSource(RecurringTransactionSource(
        id: _uuid.v4(),
        name: 'Tech Corp Monthly Salary',
        expectedAmount: 4250.00,
        frequency: 'monthly',
        nextDueDate: DateTime(now.year, now.month + 1, 1),
        status: 'active',
        type: 'income',
        categoryId: catSalary.id,
        accountId: chaseAcc.id,
        createdAt: DateTime(now.year, 1, 1),
      ));

      await recurringProvider.addSource(RecurringTransactionSource(
        id: _uuid.v4(),
        name: 'Luxury Loft Apartment Rent',
        expectedAmount: 1450.00,
        frequency: 'monthly',
        nextDueDate: DateTime(now.year, now.month + 1, 1),
        status: 'active',
        type: 'expense',
        categoryId: catHome.id,
        accountId: chaseAcc.id,
        createdAt: DateTime(now.year, 1, 1),
      ));
    }

    // 8. Create Work & Routine
    if (workRoutineProvider.routines.isEmpty) {
      final List<AttendanceEntry> entries = [];
      for (int i = 1; i <= 20; i++) {
        entries.add(AttendanceEntry(
          id: _uuid.v4(),
          date: DateTime(now.year, now.month, i),
          checkIn: '09:00 AM',
          checkOut: '05:30 PM',
          durationHours: 8.5,
          shiftType: ShiftType.regular,
          note: 'Completed sprint deliverable',
        ));
      }

      await workRoutineProvider.add(WorkRoutine(
        id: _uuid.v4(),
        title: 'Principal UX Architect',
        workplace: 'Tech Corp Headquarters',
        monthlySalary: 7500.00,
        expectedDaysPerWeek: 5,
        workingDays: const [1, 2, 3, 4, 5],
        shiftStartTime: '09:00 AM',
        shiftEndTime: '05:30 PM',
        color: const Color(0xFF1B3A2B),
        icon: Icons.work_outline_rounded,
        createdAt: DateTime(now.year - 1, 9, 1),
        entries: entries,
      ));
    }

    return createdCount;
  }
}
