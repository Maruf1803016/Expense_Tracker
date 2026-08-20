import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/plan/domain/entities/goal.dart';
import 'package:expense_tracker/features/plan/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

class GoalProvider with ChangeNotifier {
  final GoalRepository repository;
  
  List<Goal> _plans = [];
  List<Goal> get plans => _plans;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<Goal>>? _plansSubscription;

  GoalProvider({required this.repository});

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
        debugPrint('[GoalProvider] Error loading goals: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> add(Goal plan) async {
    try {
      await repository.addPlan(plan);
    } catch (e) {
      debugPrint('[GoalProvider] Error adding goal: $e');
      rethrow;
    }
  }

  Future<void> addPlanWithExpenses(Goal plan, List<Expense> expenses) async {
    try {
      await repository.addPlanWithExpenses(plan, expenses);
    } catch (e) {
      debugPrint('[GoalProvider] Error adding goal with expenses: $e');
      rethrow;
    }
  }

  Future<void> update(Goal plan) async {
    try {
      await repository.updatePlan(plan);
    } catch (e) {
      debugPrint('[GoalProvider] Error updating goal: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.deletePlan(id);
    } catch (e) {
      debugPrint('[GoalProvider] Error deleting goal: $e');
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
