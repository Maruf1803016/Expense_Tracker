import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/plan/data/models/trip_plan_model.dart';

abstract class TripPlanRemoteDataSource {
  Stream<List<TripPlanModel>> getTripPlans();
  Future<void> addTripPlan(TripPlanModel tripPlan);
  Future<void> updateTripPlan(TripPlanModel tripPlan);
  Future<void> deleteTripPlan(String id);
}

class TripPlanRemoteDataSourceImpl implements TripPlanRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  TripPlanRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _tripPlanCollection {
    return _userDoc.collection('tripPlans');
  }

  Future<T> _executeWithRetry<T>(Future<T> Function(Duration timeout) operation) async {
    try {
      return await operation(const Duration(seconds: 8));
    } catch (e1) {
      debugPrint('[TripPlanRemoteDataSource] First attempt failed: $e1. Retrying in 1 second...');
      await Future.delayed(const Duration(seconds: 1));
      try {
        return await operation(const Duration(seconds: 8));
      } catch (e2) {
        if (e2 is TimeoutException) {
          throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          );
        }
        rethrow;
      }
    }
  }

  @override
  Stream<List<TripPlanModel>> getTripPlans() {
    return _tripPlanCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TripPlanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addTripPlan(TripPlanModel tripPlan) async {
    try {
      await _executeWithRetry((timeout) {
        return _tripPlanCollection.doc(tripPlan.id).set(tripPlan.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to add trip plan: $e');
    }
  }

  @override
  Future<void> updateTripPlan(TripPlanModel tripPlan) async {
    try {
      await _executeWithRetry((timeout) {
        return _tripPlanCollection.doc(tripPlan.id).update(tripPlan.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to update trip plan: $e');
    }
  }

  @override
  Future<void> deleteTripPlan(String id) async {
    try {
      await _executeWithRetry((timeout) {
        return _tripPlanCollection.doc(id).delete().timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to delete trip plan: $e');
    }
  }
}
