import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/analytics/domain/entities/financial_insights.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_financial_insights.dart';

class FinancialInsightsProvider with ChangeNotifier {
  final GetFinancialInsightsUseCase _getFinancialInsights;

  FinancialInsightsProvider({
    required GetFinancialInsightsUseCase getFinancialInsights,
  }) : _getFinancialInsights = getFinancialInsights;

  FinancialInsights? _insights;
  FinancialInsights? get insights => _insights;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription<FinancialInsights>? _insightsSubscription;

  /// 🕵️ System Hardening: Correct Lifecycle Management
  /// Ensures any active subscription is killed before a new one starts.
  void init(int month, int year) {
    _insightsSubscription?.cancel();
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    _insightsSubscription = _getFinancialInsights(month, year).listen(
      (data) {
        // Guard: Prevent late stream events from updating disposed/inactive providers
        _insights = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load insights';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// 🔐 Memory Leak Prevention
  /// Fully clears memory and orphan listeners.
  void clear() {
    _insightsSubscription?.cancel();
    _insightsSubscription = null;
    _insights = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _insightsSubscription?.cancel();
    super.dispose();
  }
}
