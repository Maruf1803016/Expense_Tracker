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
    this.color = const Color(0xFFB08D3F),
    this.icon = Icons.work_outline_rounded,
    this.isAttendanceOnly = false,
    required this.createdAt,
    this.entries = const [],
  });

  int getMonthlyDays(int year, int month) {
    return entries.where((e) => e.date.year == year && e.date.month == month).length;
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
        color,
        icon,
        isAttendanceOnly,
        createdAt,
        entries,
      ];
}
