import 'package:expense_tracker/features/work_routine/domain/entities/work_routine.dart';
import 'package:expense_tracker/features/work_routine/domain/repositories/work_routine_repository.dart';

class GetWorkRoutinesStreamUseCase {
  final WorkRoutineRepository repository;
  GetWorkRoutinesStreamUseCase(this.repository);

  Stream<List<WorkRoutine>> call() {
    return repository.getWorkRoutinesStream();
  }
}

class AddWorkRoutineUseCase {
  final WorkRoutineRepository repository;
  AddWorkRoutineUseCase(this.repository);

  Future<void> call(WorkRoutine routine) {
    return repository.addWorkRoutine(routine);
  }
}

class UpdateWorkRoutineUseCase {
  final WorkRoutineRepository repository;
  UpdateWorkRoutineUseCase(this.repository);

  Future<void> call(WorkRoutine routine) {
    return repository.updateWorkRoutine(routine);
  }
}

class DeleteWorkRoutineUseCase {
  final WorkRoutineRepository repository;
  DeleteWorkRoutineUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteWorkRoutine(id);
  }
}

class LogAttendanceUseCase {
  final WorkRoutineRepository repository;
  LogAttendanceUseCase(this.repository);

  Future<void> call(String routineId, AttendanceEntry entry) {
    return repository.logAttendance(routineId, entry);
  }
}

class DeleteAttendanceUseCase {
  final WorkRoutineRepository repository;
  DeleteAttendanceUseCase(this.repository);

  Future<void> call(String routineId, String entryId) {
    return repository.deleteAttendance(routineId, entryId);
  }
}
