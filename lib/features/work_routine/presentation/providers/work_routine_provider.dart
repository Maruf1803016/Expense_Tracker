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
        if (list.isEmpty) {
          final now = DateTime.now();
          final sampleRoutine = WorkRoutine(
            id: 'routine_clinical_shift',
            title: 'Clinical Shift',
            workplace: 'General Hospital Dept',
            hourlyRate: 45.0,
            icon: Icons.badge_outlined,
            color: const Color(0xFF2E5A44),
            expectedDaysPerWeek: 5,
            createdAt: now,
            entries: [
              AttendanceEntry(
                id: 'att_1',
                date: DateTime(now.year, now.month, 1),
                checkIn: '08:00',
                checkOut: '16:30',
                durationHours: 8.5,
                shiftType: ShiftType.regular,
              ),
              AttendanceEntry(
                id: 'att_2',
                date: DateTime(now.year, now.month, 2),
                checkIn: '08:00',
                checkOut: '16:30',
                durationHours: 8.5,
                shiftType: ShiftType.regular,
              ),
              AttendanceEntry(
                id: 'att_3',
                date: DateTime(now.year, now.month, 3),
                checkIn: '08:15',
                checkOut: '16:15',
                durationHours: 8.0,
                shiftType: ShiftType.regular,
              ),
              AttendanceEntry(
                id: 'att_4',
                date: DateTime(now.year, now.month, 4),
                shiftType: ShiftType.attendanceOnly,
                durationHours: 0.0,
              ),
              AttendanceEntry(
                id: 'att_5',
                date: DateTime(now.year, now.month, 5),
                checkIn: '08:00',
                checkOut: '16:30',
                durationHours: 8.5,
                shiftType: ShiftType.regular,
              ),
            ],
          );
          repository.addWorkRoutine(sampleRoutine);
        }
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
