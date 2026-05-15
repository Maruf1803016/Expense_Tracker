import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/alerts/domain/entities/smart_alert.dart';
import 'package:expense_tracker/features/alerts/domain/usecases/get_smart_alerts.dart';

class SmartAlertsProvider with ChangeNotifier {
  final GetSmartAlertsStreamUseCase _getSmartAlerts;

  SmartAlertsProvider({
    required GetSmartAlertsStreamUseCase getSmartAlerts,
  }) : _getSmartAlerts = getSmartAlerts;

  List<SmartAlert> _alerts = [];
  List<SmartAlert> get alerts => _alerts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<SmartAlert>>? _alertsSubscription;

  /// 🕵️ System Hardening: Correct Lifecycle Management
  /// Ensures any active subscription is killed before a new one starts.
  void init(int month, int year) {
    _alertsSubscription?.cancel();
    
    _isLoading = true;
    notifyListeners();

    _alertsSubscription = _getSmartAlerts(month, year).listen(
      (data) {
        _alerts = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// 🔐 Memory Leak Prevention
  /// Fully clears memory and orphan listeners on logout.
  void clear() {
    _alertsSubscription?.cancel();
    _alertsSubscription = null;
    _alerts = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
