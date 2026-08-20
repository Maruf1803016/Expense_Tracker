import 'package:expense_tracker/features/plan/domain/entities/trip_plan.dart';

abstract class TripPlanRepository {
  Stream<List<TripPlan>> getTripPlansStream();
  Future<void> addTripPlan(TripPlan tripPlan);
  Future<void> updateTripPlan(TripPlan tripPlan);
  Future<void> deleteTripPlan(String id);
}
