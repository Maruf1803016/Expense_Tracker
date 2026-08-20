import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/work_routine/domain/entities/work_routine.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

class AttendanceEntryModel extends AttendanceEntry {
  const AttendanceEntryModel({
    required super.id,
    required super.date,
    super.checkIn,
    super.checkOut,
    super.durationHours,
    super.shiftType,
    super.note,
  });

  factory AttendanceEntryModel.fromMap(Map<String, dynamic> map) {
    ShiftType shift = ShiftType.regular;
    if (map['shiftType'] == 'short') shift = ShiftType.short;
    if (map['shiftType'] == 'afternoon') shift = ShiftType.afternoon;
    if (map['shiftType'] == 'overnight') shift = ShiftType.overnight;
    if (map['shiftType'] == 'attendanceOnly') shift = ShiftType.attendanceOnly;

    return AttendanceEntryModel(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      checkIn: map['checkIn'] as String?,
      checkOut: map['checkOut'] as String?,
      durationHours: (map['durationHours'] as num?)?.toDouble(),
      shiftType: shift,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      if (checkIn != null) 'checkIn': checkIn,
      if (checkOut != null) 'checkOut': checkOut,
      if (durationHours != null) 'durationHours': durationHours,
      'shiftType': shiftType.name,
      if (note != null) 'note': note,
    };
  }

  factory AttendanceEntryModel.fromEntity(AttendanceEntry entity) {
    return AttendanceEntryModel(
      id: entity.id,
      date: entity.date,
      checkIn: entity.checkIn,
      checkOut: entity.checkOut,
      durationHours: entity.durationHours,
      shiftType: entity.shiftType,
      note: entity.note,
    );
  }
}

class WorkRoutineModel extends WorkRoutine {
  const WorkRoutineModel({
    required super.id,
    required super.title,
    super.workplace,
    super.monthlySalary,
    super.hourlyRate,
    super.expectedDaysPerWeek,
    super.color,
    super.icon,
    super.isAttendanceOnly,
    required super.createdAt,
    super.entries,
  });

  factory WorkRoutineModel.fromMap(Map<String, dynamic> map, String documentId) {
    final entriesList = (map['entries'] as List<dynamic>? ?? [])
        .map((e) => AttendanceEntryModel.fromMap(e as Map<String, dynamic>))
        .toList();

    return WorkRoutineModel(
      id: documentId,
      title: map['title'] ?? '',
      workplace: map['workplace'] as String?,
      monthlySalary: (map['monthlySalary'] as num?)?.toDouble(),
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble(),
      expectedDaysPerWeek: (map['expectedDaysPerWeek'] as num?)?.toInt() ?? 5,
      color: map['color'] != null ? Color(map['color'] as int) : const Color(0xFFB08D3F),
      icon: map['icon'] != null ? IconUtils.getIcon(map['icon'] as String) : Icons.work_outline_rounded,
      isAttendanceOnly: map['isAttendanceOnly'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      entries: entriesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'workplace': workplace,
      'monthlySalary': monthlySalary,
      'hourlyRate': hourlyRate,
      'expectedDaysPerWeek': expectedDaysPerWeek,
      'color': color.value,
      'icon': IconUtils.getIconName(icon),
      'isAttendanceOnly': isAttendanceOnly,
      'createdAt': Timestamp.fromDate(createdAt),
      'entries': entries.map((e) => AttendanceEntryModel.fromEntity(e).toMap()).toList(),
    };
  }

  factory WorkRoutineModel.fromEntity(WorkRoutine entity) {
    return WorkRoutineModel(
      id: entity.id,
      title: entity.title,
      workplace: entity.workplace,
      monthlySalary: entity.monthlySalary,
      hourlyRate: entity.hourlyRate,
      expectedDaysPerWeek: entity.expectedDaysPerWeek,
      color: entity.color,
      icon: entity.icon,
      isAttendanceOnly: entity.isAttendanceOnly,
      createdAt: entity.createdAt,
      entries: entity.entries,
    );
  }
}
