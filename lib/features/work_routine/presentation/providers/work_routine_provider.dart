import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/work_routine/domain/entities/work_routine.dart';
import 'package:expense_tracker/features/work_routine/domain/repositories/work_routine_repository.dart';

class WorkRoutineProvider with ChangeNotifier {
  final WorkRoutineRepository repository;

  List<WorkRoutine> _routines = [];
  List<WorkRoutine> get routines => _routines;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<WorkRoutine>>? _routinesSubscription;

  WorkRoutineProvider({required this.repository});

  void init() {
    _isLoading = true;
    notifyListeners();

    _routinesSubscription?.cancel();
    _routinesSubscription = repository.getWorkRoutinesStream().listen(
      (list) {
        _routines = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[WorkRoutineProvider] Error loading work routines: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> add(WorkRoutine routine) async {
    try {
      await repository.addWorkRoutine(routine);
    } catch (e) {
      debugPrint('[WorkRoutineProvider] Error adding routine: $e');
      rethrow;
    }
  }

  Future<void> update(WorkRoutine routine) async {
    try {
      await repository.updateWorkRoutine(routine);
    } catch (e) {
      debugPrint('[WorkRoutineProvider] Error updating routine: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.deleteWorkRoutine(id);
    } catch (e) {
      debugPrint('[WorkRoutineProvider] Error deleting routine: $e');
      rethrow;
    }
  }

  Future<void> logAttendance(String routineId, AttendanceEntry entry) async {
    try {
      await repository.logAttendance(routineId, entry);
    } catch (e) {
      debugPrint('[WorkRoutineProvider] Error logging attendance: $e');
      rethrow;
    }
  }

  Future<void> deleteAttendance(String routineId, String entryId) async {
    try {
      await repository.deleteAttendance(routineId, entryId);
    } catch (e) {
      debugPrint('[WorkRoutineProvider] Error deleting attendance: $e');
      rethrow;
    }
  }

  void clear() {
    _routinesSubscription?.cancel();
    _routinesSubscription = null;
    _routines = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _routinesSubscription?.cancel();
    super.dispose();
  }
}
