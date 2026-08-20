import 'package:expense_tracker/features/work_routine/domain/entities/work_routine.dart';

abstract class WorkRoutineRepository {
  Stream<List<WorkRoutine>> getWorkRoutinesStream();
  Future<void> addWorkRoutine(WorkRoutine routine);
  Future<void> updateWorkRoutine(WorkRoutine routine);
  Future<void> deleteWorkRoutine(String id);
  Future<void> logAttendance(String routineId, AttendanceEntry entry);
  Future<void> deleteAttendance(String routineId, String entryId);
}
