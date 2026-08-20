import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/work_routine/domain/entities/work_routine.dart';
import 'package:expense_tracker/features/work_routine/data/models/work_routine_model.dart';

void main() {
  group('WorkRoutine Domain & Logic Tests', () {
    test('WorkRoutine accurately calculates monthly days and hours', () {
      final entries = [
        AttendanceEntry(
          id: 'e1',
          date: DateTime(2026, 8, 3),
          checkIn: '09:00 AM',
          checkOut: '05:00 PM',
          durationHours: 8.0,
          shiftType: ShiftType.regular,
        ),
        AttendanceEntry(
          id: 'e2',
          date: DateTime(2026, 8, 4),
          checkIn: '09:00 AM',
          checkOut: '01:00 PM',
          durationHours: 4.0,
          shiftType: ShiftType.short,
        ),
        AttendanceEntry(
          id: 'e3',
          date: DateTime(2026, 7, 30),
          durationHours: 6.0,
          shiftType: ShiftType.regular,
        ),
      ];

      final routine = WorkRoutine(
        id: 'r1',
        title: 'Teaching',
        workplace: 'City High School',
        createdAt: DateTime(2026, 1, 1),
        entries: entries,
      );

      // In August 2026 (2 entries, 12 hours)
      expect(routine.getMonthlyDays(2026, 8), 2);
      expect(routine.getMonthlyHours(2026, 8), 12.0);

      // In July 2026 (1 entry, 6 hours)
      expect(routine.getMonthlyDays(2026, 7), 1);
      expect(routine.getMonthlyHours(2026, 7), 6.0);
    });

    test('WorkRoutineModel serialization round-trips cleanly', () {
      final now = DateTime(2026, 8, 20);
      final routine = WorkRoutine(
        id: 'r2',
        title: 'Medical Duty',
        workplace: 'General Hospital',
        isAttendanceOnly: false,
        createdAt: now,
        entries: [
          AttendanceEntry(
            id: 'e4',
            date: now,
            checkIn: '08:00 AM',
            checkOut: '04:00 PM',
            durationHours: 8.0,
            shiftType: ShiftType.regular,
            note: 'ER shift',
          ),
        ],
      );

      final model = WorkRoutineModel.fromEntity(routine);
      final map = model.toMap();

      expect(map['title'], 'Medical Duty');
      expect(map['workplace'], 'General Hospital');
      expect(map['entries'], isNotEmpty);

      final fromMap = WorkRoutineModel.fromMap(map, 'r2');
      expect(fromMap.id, 'r2');
      expect(fromMap.title, 'Medical Duty');
      expect(fromMap.entries.length, 1);
      expect(fromMap.entries.first.note, 'ER shift');
      expect(fromMap.entries.first.durationHours, 8.0);
    });
  });
}
