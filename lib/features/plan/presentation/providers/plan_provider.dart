import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/plan/domain/repositories/plan_repository.dart';

class PlanProvider with ChangeNotifier {
  final PlanRepository repository;
  
  List<Plan> _plans = [];
  List<Plan> get plans => _plans;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<Plan>>? _plansSubscription;

  PlanProvider({required this.repository});

  void init() {
    _isLoading = true;
    notifyListeners();

    _plansSubscription?.cancel();
    _plansSubscription = repository.getPlansStream().listen(
      (list) {
        _plans = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[PlanProvider] Error loading plans: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> add(Plan plan) async {
    try {
      await repository.addPlan(plan);
    } catch (e) {
      debugPrint('[PlanProvider] Error adding plan: $e');
      rethrow;
    }
  }

  Future<void> update(Plan plan) async {
    try {
      await repository.updatePlan(plan);
    } catch (e) {
      debugPrint('[PlanProvider] Error updating plan: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.deletePlan(id);
    } catch (e) {
      debugPrint('[PlanProvider] Error deleting plan: $e');
      rethrow;
    }
  }

  void clear() {
    _plansSubscription?.cancel();
    _plansSubscription = null;
    _plans = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _plansSubscription?.cancel();
    super.dispose();
  }
}
