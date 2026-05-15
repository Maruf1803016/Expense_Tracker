import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/analytics/presentation/providers/financial_insights_provider.dart';
import 'package:expense_tracker/features/alerts/presentation/providers/smart_alerts_provider.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_search_provider.dart';
import 'package:expense_tracker/shared/presentation/pages/home_page.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_indicator.dart';

/// Root widget of the application.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

/// A wrapper widget that manages top-level authentication state and navigation.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // 1. Show Splash/Loading until auth state resolves
    if (authProvider.isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Authenticating...'),
      );
    }

    // 2. If no user, show Login and CLEAN UP background listeners
    if (authProvider.user == null) {
      if (_lastUserId != null) {
        // 🕵️ System Hardening: Global Reset on Logout
        // Prevents User B from seeing User A's data or having active listeners.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<ExpenseProvider>().clear();
          context.read<FinancialInsightsProvider>().clear();
          context.read<SmartAlertsProvider>().clear();
          context.read<ExpenseSearchProvider>().clear();
          context.read<ExportProvider>().reset();
        });
        _lastUserId = null;
      }
      return const LoginPage();
    }

    // 3. If user is logged in, show Home and initialize data if needed
    if (authProvider.user?.id != _lastUserId) {
      _lastUserId = authProvider.user?.id;
      // Initialize data for the new user context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ExpenseProvider>().init();
      });
    }

    return const HomePage();
  }
}
