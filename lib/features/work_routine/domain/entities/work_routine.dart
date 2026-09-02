import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ShiftType {
  regular,
  short,
  afternoon,
  overnight,
  attendanceOnly,
}

class AttendanceEntry extends Equatable {
  final String id;
  final DateTime date;
  final String? checkIn; // e.g. "09:00 AM"
  final String? checkOut; // e.g. "05:00 PM"
  final double? durationHours;
  final ShiftType shiftType;
  final String? note;

  const AttendanceEntry({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.durationHours,
    this.shiftType = ShiftType.regular,
    this.note,
  });

  @override
  List<Object?> get props => [id, date, checkIn, checkOut, durationHours, shiftType, note];
}

class WorkRoutine extends Equatable {
  final String id;
  final String title;
  final String? workplace;
  final double? monthlySalary;
  final double? hourlyRate;
  final int expectedDaysPerWeek;
  final List<int> workingDays; // 1 = Monday ... 7 = Sunday
  final String? shiftStartTime;
  final String? shiftEndTime;
  final Color color;
  final IconData icon;
  final bool isAttendanceOnly;
  final DateTime createdAt;
  final List<AttendanceEntry> entries;

  const WorkRoutine({
    required this.id,
    required this.title,
    this.workplace,
    this.monthlySalary,
    this.hourlyRate,
    this.expectedDaysPerWeek = 5,
    this.workingDays = const [1, 2, 3, 4, 5],
    this.shiftStartTime,
    this.shiftEndTime,
    this.color = const Color(0xFFB08D3F),
    this.icon = Icons.work_outline_rounded,
    this.isAttendanceOnly = false,
    required this.createdAt,
    this.entries = const [],
  });

  int getMonthlyDays(int year, int month) {
    return entries.where((e) => e.date.year == year && e.date.month == month).length;
  }

  int getPlannedDays(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int planned = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (workingDays.contains(date.weekday)) {
        planned++;
      }
    }
    return planned;
  }

  int getAttendedDays(int year, int month) {
    return getMonthlyDays(year, month);
  }

  int getMissedDays(int year, int month) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int missed = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.isBefore(today)) {
        if (workingDays.contains(date.weekday)) {
          if (getEntryForDate(date) == null) {
            missed++;
          }
        }
      }
    }
    return missed;
  }

  int getUnscheduledDays(int year, int month) {
    return entries.where((e) =>
      e.date.year == year &&
      e.date.month == month &&
      !workingDays.contains(e.date.weekday)
    ).length;
  }

  double getMonthlyHours(int year, int month) {
    return entries
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (sum, e) => sum + (e.durationHours ?? 0.0));
  }

  AttendanceEntry? getEntryForDate(DateTime date) {
    return entries.where((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day).firstOrNull;
  }

  WorkRoutine copyWith({
    String? id,
    String? title,
    String? workplace,
    double? monthlySalary,
    double? hourlyRate,
    int? expectedDaysPerWeek,
    List<int>? workingDays,
    String? shiftStartTime,
    String? shiftEndTime,
    Color? color,
    IconData? icon,
    bool? isAttendanceOnly,
    DateTime? createdAt,
    List<AttendanceEntry>? entries,
  }) {
    return WorkRoutine(
      id: id ?? this.id,
      title: title ?? this.title,
      workplace: workplace ?? this.workplace,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      expectedDaysPerWeek: expectedDaysPerWeek ?? this.expectedDaysPerWeek,
      workingDays: workingDays ?? this.workingDays,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isAttendanceOnly: isAttendanceOnly ?? this.isAttendanceOnly,
      createdAt: createdAt ?? this.createdAt,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        workplace,
        monthlySalary,
        hourlyRate,
        expectedDaysPerWeek,
        workingDays,
        shiftStartTime,
        shiftEndTime,
        color,
        icon,
        isAttendanceOnly,
        createdAt,
        entries,
      ];
}
