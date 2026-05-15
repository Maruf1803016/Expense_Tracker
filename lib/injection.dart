import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get_it/get_it.dart';

// --- Auth ---
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/domain/usecases/auth_usecases.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';

// --- Category ---
import 'package:expense_tracker/features/category/data/datasources/category_remote_data_source.dart';
import 'package:expense_tracker/features/category/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/category/domain/usecases/add_category.dart';
import 'package:expense_tracker/features/category/domain/usecases/delete_category.dart';
import 'package:expense_tracker/features/category/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/category/domain/usecases/seed_categories.dart';

// --- Expense ---
import 'package:expense_tracker/features/expense/data/datasources/expense_remote_data_source.dart';
import 'package:expense_tracker/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expense/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_monthly_summary.dart';
import 'package:expense_tracker/features/expense/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/expense/domain/Logic/expense_query_engine.dart';
import 'package:expense_tracker/features/expense/domain/usecases/search_expenses.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_search_provider.dart';

// --- Budget ---
import 'package:expense_tracker/features/budget/data/datasources/budget_remote_data_source.dart';
import 'package:expense_tracker/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budget/domain/usecases/get_budget_status.dart';
import 'package:expense_tracker/features/budget/domain/usecases/set_budget.dart';

// --- Analytics & Intelligence Core ---
import 'package:expense_tracker/features/analysis/domain/logic/expense_aggregator.dart';
import 'package:expense_tracker/features/analysis/domain/logic/trend_calculator.dart';
import 'package:expense_tracker/features/analysis/domain/logic/budget_calculator.dart';
import 'package:expense_tracker/features/analysis/domain/logic/anomaly_detector.dart';
import 'package:expense_tracker/features/analysis/domain/logic/financial_analysis_service.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_financial_insights.dart';
import 'package:expense_tracker/features/analytics/presentation/providers/financial_insights_provider.dart';

// --- Alerts ---
import 'package:expense_tracker/features/alerts/domain/usecases/get_smart_alerts.dart';
import 'package:expense_tracker/features/alerts/presentation/providers/smart_alerts_provider.dart';

// --- Export ---
import 'package:expense_tracker/features/export/data/services/export_service.dart';
import 'package:expense_tracker/features/export/domain/usecases/get_monthly_export_data.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_provider.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => firebase_auth.FirebaseAuth.instance);

  // Data Sources / Services
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(firebaseAuth: sl()));
  sl.registerLazySingleton<CategoryRemoteDataSource>(() => CategoryRemoteDataSourceImpl(firestore: sl(), authDataSource: sl()));
  sl.registerLazySingleton<ExpenseRemoteDataSource>(() => ExpenseRemoteDataSourceImpl(firestore: sl(), authDataSource: sl()));
  sl.registerLazySingleton<BudgetRemoteDataSource>(() => BudgetRemoteDataSourceImpl(firestore: sl(), authDataSource: sl()));
  sl.registerLazySingleton<ExportService>(() => ExportServiceImpl());

  // Logic Core (The Pure Math)
  sl.registerLazySingleton(() => ExpenseAggregator());
  sl.registerLazySingleton(() => TrendCalculator());
  sl.registerLazySingleton(() => BudgetCalculator());
  sl.registerLazySingleton(() => AnomalyDetector());
  sl.registerLazySingleton(() => ExpenseQueryEngine());
  sl.registerLazySingleton(() => FinancialAnalysisService(
    aggregator: sl(),
    trendCalculator: sl(),
    budgetCalculator: sl(),
    anomalyDetector: sl(),
  ));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<ExpenseRepository>(() => ExpenseRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(remoteDataSource: sl()));

  // Use Cases
  sl.registerLazySingleton(() => SignInUseCase(repository: sl()));
  sl.registerLazySingleton(() => SignUpUseCase(repository: sl()));
  sl.registerLazySingleton(() => SignOutUseCase(repository: sl()));
  sl.registerLazySingleton(() => AuthStateStreamUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetCurrentUserIdUseCase(repository: sl()));

  sl.registerLazySingleton(() => GetCategoriesStreamUseCase(repository: sl()));
  sl.registerLazySingleton(() => SeedCategoriesUseCase(repository: sl()));
  sl.registerLazySingleton(() => AddCategoryUseCase(repository: sl()));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(categoryRepository: sl(), expenseRepository: sl()));

  sl.registerLazySingleton(() => GetExpensesStreamUseCase(repository: sl()));
  sl.registerLazySingleton(() => AddExpenseUseCase(repository: sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(repository: sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(repository: sl()));
  sl.registerLazySingleton(() => SearchExpensesUseCase(queryEngine: sl()));
  sl.registerLazySingleton(() => GetMonthlySummaryUseCase(expenseRepository: sl(), categoryRepository: sl(), analysisService: sl()));

  sl.registerLazySingleton(() => SetBudgetUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetBudgetStatusStreamUseCase(categoryRepository: sl(), expenseRepository: sl(), budgetRepository: sl(), analysisService: sl()));

  sl.registerLazySingleton(() => GetMonthlyExportDataUseCase(getSummary: sl(), getBudgets: sl(), getExpenses: sl()));
  sl.registerLazySingleton(() => GetFinancialInsightsUseCase(getSummary: sl(), getBudgetStatus: sl(), analysisService: sl()));
  sl.registerLazySingleton(() => GetSmartAlertsStreamUseCase(getSummary: sl(), getBudgetStatus: sl(), getExpenses: sl(), analysisService: sl()));

  // Providers
  sl.registerFactory(() => AuthProvider(signIn: sl(), signUp: sl(), signOut: sl(), authStateStream: sl()));
  sl.registerFactory(() => ExpenseProvider(
    getCategoriesStream: sl(),
    seedCategories: sl(),
    getExpensesStream: sl(),
    addExpense: sl(),
    updateExpense: sl(),
    deleteExpense: sl(),
    getMonthlySummary: sl(),
    addCategory: sl(),
    deleteCategory: sl(),
    setBudget: sl(),
    getBudgetStatus: sl(),
  ));
  sl.registerFactory(() => ExportProvider(getExportData: sl(), exportService: sl()));
  sl.registerFactory(() => FinancialInsightsProvider(getFinancialInsights: sl()));
  sl.registerFactory(() => SmartAlertsProvider(getSmartAlerts: sl()));
  sl.registerFactory(() => ExpenseSearchProvider(searchExpenses: sl()));
}
