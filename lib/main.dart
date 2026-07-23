import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/injection.dart';
import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/firebase_options.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_provider.dart';
import 'package:expense_tracker/features/analytics/presentation/providers/financial_insights_provider.dart';
import 'package:expense_tracker/features/alerts/presentation/providers/smart_alerts_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_search_provider.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initDependencies();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => sl<AuthProvider>()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<CategoryProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<ExpenseProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<ExportProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<FinancialInsightsProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<SmartAlertsProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<ExpenseSearchProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<SettingsProvider>()..loadSettings(),
        ),
      ],
      child: const App(),
    ),
  );
}
