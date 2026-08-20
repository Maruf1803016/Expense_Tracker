import 'package:expense_tracker/features/work_routine/domain/entities/work_routine.dart';
import 'package:expense_tracker/features/work_routine/domain/repositories/work_routine_repository.dart';
import 'package:expense_tracker/features/work_routine/data/datasources/work_routine_remote_data_source.dart';
import 'package:expense_tracker/features/work_routine/data/models/work_routine_model.dart';

class WorkRoutineRepositoryImpl implements WorkRoutineRepository {
  final WorkRoutineRemoteDataSource remoteDataSource;

  WorkRoutineRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<WorkRoutine>> getWorkRoutinesStream() {
    return remoteDataSource.getWorkRoutines();
  }

  @override
  Future<void> addWorkRoutine(WorkRoutine routine) {
    return remoteDataSource.addWorkRoutine(WorkRoutineModel.fromEntity(routine));
  }

  @override
  Future<void> updateWorkRoutine(WorkRoutine routine) {
    return remoteDataSource.updateWorkRoutine(WorkRoutineModel.fromEntity(routine));
  }

  @override
  Future<void> deleteWorkRoutine(String id) {
    return remoteDataSource.deleteWorkRoutine(id);
  }

  @override
  Future<void> logAttendance(String routineId, AttendanceEntry entry) {
    return remoteDataSource.logAttendance(routineId, AttendanceEntryModel.fromEntity(entry));
  }

  @override
  Future<void> deleteAttendance(String routineId, String entryId) {
    return remoteDataSource.deleteAttendance(routineId, entryId);
  }
}
