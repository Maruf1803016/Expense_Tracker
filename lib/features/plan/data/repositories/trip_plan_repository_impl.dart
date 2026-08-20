import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/core/error/failures.dart';
import 'package:expense_tracker/features/plan/data/datasources/trip_plan_remote_data_source.dart';
import 'package:expense_tracker/features/plan/data/models/trip_plan_model.dart';
import 'package:expense_tracker/features/plan/domain/entities/trip_plan.dart';
import 'package:expense_tracker/features/plan/domain/repositories/trip_plan_repository.dart';

class TripPlanRepositoryImpl implements TripPlanRepository {
  final TripPlanRemoteDataSource remoteDataSource;

  TripPlanRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<TripPlan>> getTripPlansStream() {
    return remoteDataSource.getTripPlans();
  }

  @override
  Future<void> addTripPlan(TripPlan tripPlan) async {
    try {
      await remoteDataSource.addTripPlan(TripPlanModel.fromEntity(tripPlan));
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while adding trip plan.');
    }
  }

  @override
  Future<void> updateTripPlan(TripPlan tripPlan) async {
    try {
      await remoteDataSource.updateTripPlan(TripPlanModel.fromEntity(tripPlan));
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while updating trip plan.');
    }
  }

  @override
  Future<void> deleteTripPlan(String id) async {
    try {
      await remoteDataSource.deleteTripPlan(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while deleting trip plan.');
    }
  }
}
