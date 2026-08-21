import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/plan/domain/entities/trip_plan.dart';
import 'package:expense_tracker/features/plan/domain/repositories/trip_plan_repository.dart';

class TripPlanProvider with ChangeNotifier {
  final TripPlanRepository repository;

  List<TripPlan> _tripPlans = [];
  List<TripPlan> get tripPlans => _tripPlans;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<TripPlan>>? _tripPlansSubscription;

  TripPlanProvider({required this.repository});

  void init() {
    _isLoading = true;
    notifyListeners();

    _tripPlansSubscription?.cancel();
    _tripPlansSubscription = repository.getTripPlansStream().listen(
      (list) {
        if (list.isEmpty) {
          final sampleTrip = TripPlan(
            id: 'trip_cox_bazar',
            title: "Cox's Bazar Retreat",
            budgetAmount: 2500.0,
            startDate: DateTime(2026, 8, 1),
            endDate: DateTime(2026, 8, 5),
            createdAt: DateTime(2026, 7, 20),
          );
          repository.addTripPlan(sampleTrip);
        }
        _tripPlans = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[TripPlanProvider] Error loading trip plans: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> add(TripPlan tripPlan) async {
    try {
      await repository.addTripPlan(tripPlan);
    } catch (e) {
      debugPrint('[TripPlanProvider] Error adding trip plan: $e');
      rethrow;
    }
  }

  Future<void> update(TripPlan tripPlan) async {
    try {
      await repository.updateTripPlan(tripPlan);
    } catch (e) {
      debugPrint('[TripPlanProvider] Error updating trip plan: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.deleteTripPlan(id);
    } catch (e) {
      debugPrint('[TripPlanProvider] Error deleting trip plan: $e');
      rethrow;
    }
  }

  void clear() {
    _tripPlansSubscription?.cancel();
    _tripPlansSubscription = null;
    _tripPlans = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tripPlansSubscription?.cancel();
    super.dispose();
  }
}
