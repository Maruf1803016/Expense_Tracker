import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:expense_tracker/features/auth/presentation/pages/register_page.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/analytics/presentation/providers/financial_insights_provider.dart';
import 'package:expense_tracker/features/alerts/presentation/providers/smart_alerts_provider.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_search_provider.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/shared/presentation/pages/home_page.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_indicator.dart';
import 'package:expense_tracker/core/utils/messenger_utils.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Root widget of the application.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>(); // Rebuild app on settings change
    
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scaffoldMessengerKey: scaffoldMessengerKey,
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
  bool? _isFirstTime;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/has_opened.txt');
      final exists = await file.exists();
      if (!exists) {
        await file.writeAsString('yes');
      }
      setState(() {
        _isFirstTime = !exists;
        if (_isFirstTime == true) {
          _showRegister = true;
        }
      });
    } catch (e) {
      setState(() {
        _isFirstTime = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // 1. Show Splash/Loading until auth state resolves or first-time check completes
    if (authProvider.isLoading || _isFirstTime == null) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Authenticating...'),
      );
    }

    // 2. If no user, show Login/Register and CLEAN UP background listeners
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
      if (_showRegister) {
        return RegisterPage(
          onToggle: () {
            setState(() {
              _showRegister = false;
            });
          },
        );
      } else {
        return LoginPage(
          onToggle: () {
            setState(() {
              _showRegister = true;
            });
          },
        );
      }
    }

    // 3. If user is logged in, show Home and initialize data if needed
    if (authProvider.user?.id != _lastUserId) {
      _lastUserId = authProvider.user?.id;
      // Initialize data for the new user context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ExpenseProvider>().init();
        context.read<SettingsProvider>().loadSettings();
      });
    }

    return const HomePage();
  }
}
