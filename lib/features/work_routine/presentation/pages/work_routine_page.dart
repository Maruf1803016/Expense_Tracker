import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/work_routine/domain/entities/work_routine.dart';
import 'package:expense_tracker/features/work_routine/presentation/providers/work_routine_provider.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_time_picker.dart';

class WorkRoutinePage extends StatefulWidget {
  const WorkRoutinePage({super.key});

  @override
  State<WorkRoutinePage> createState() => _WorkRoutinePageState();
}

class _WorkRoutinePageState extends State<WorkRoutinePage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _selectedRoutineId;

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<WorkRoutineProvider>();
    final routines = routineProvider.routines;

    if (_selectedRoutineId == null && routines.isNotEmpty) {
      _selectedRoutineId = routines.first.id;
    } else if (_selectedRoutineId != null && !routines.any((r) => r.id == _selectedRoutineId)) {
      _selectedRoutineId = routines.isNotEmpty ? routines.first.id : null;
    }

    final currentRoutine = routines.where((r) => r.id == _selectedRoutineId).firstOrNull;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(
          'Work & Routine Log',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.textDark),
            tooltip: 'Add Routine',
            onPressed: () => _showAddRoutineSheet(context),
          ),
        ],
      ),
      body: routines.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Routine Selector Horizontal Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: routines.map((r) {
                        final isSelected = r.id == _selectedRoutineId;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRoutineId = r.id),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.ink : AppTheme.paperCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.ink : AppTheme.line,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(r.icon, size: 16, color: isSelected ? AppTheme.goldSoft : r.color),
                                const SizedBox(width: 8),
                                Text(
                                  r.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppTheme.goldSoft : AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (currentRoutine != null) ...[
                    // Monthly Hero Stats Card
                    _buildRoutineStatsHero(currentRoutine),
                    const SizedBox(height: 20),

                    // Month Navigation Bar
                    _buildMonthSelector(),
                    const SizedBox(height: 16),

                    // Calendar Grid View
                    _buildCalendarGrid(currentRoutine),
                    const SizedBox(height: 24),

                    // Logged Attendance List
                    _buildAttendanceList(currentRoutine),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.paper2,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge_outlined, size: 48, color: AppTheme.gold),
            ),
            const SizedBox(height: 20),
            Text(
              'No Work Routines Yet',
              style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your jobs, tuition, clinical shifts, or daily attendance in one organized fieldbook.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddRoutineSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Routine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.ink,
                foregroundColor: AppTheme.goldSoft,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineStatsHero(WorkRoutine routine) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysAttended = routine.getMonthlyDays(year, month);
    final hoursWorked = routine.getMonthlyHours(year, month);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.goldLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(routine.icon, color: AppTheme.goldSoft, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    routine.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (routine.workplace != null)
                Text(
                  routine.workplace!,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.goldSoft),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.goldLine),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAYS ATTENDED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.goldSoft.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$daysAttended Days',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (!routine.isAttendanceOnly) ...[
                Container(width: 1, height: 36, color: AppTheme.goldLine),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL HOURS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppTheme.goldSoft.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hoursWorked.toStringAsFixed(1)} hrs',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final format = DateFormat('MMMM yyyy');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
            });
          },
        ),
        Text(
          format.format(_selectedMonth),
          style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () {
            final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
            if (nextMonth.isBefore(DateTime.now().add(const Duration(days: 31)))) {
              setState(() {
                _selectedMonth = nextMonth;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(WorkRoutine routine) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Mon, 7 = Sun
    final now = DateTime.now();

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          // Weekday header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) {
              return SizedBox(
                width: 32,
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.muted),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Day Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: (firstWeekday - 1) + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink(); // Empty prefix cells
              }
              final day = index - (firstWeekday - 1) + 1;
              final cellDate = DateTime(year, month, day);
              final isFuture = cellDate.isAfter(DateTime(now.year, now.month, now.day));
              final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
              final entry = routine.getEntryForDate(cellDate);
              final isAttended = entry != null;

              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () => _showLogShiftSheet(context, routine, cellDate, entry),
                child: Container(
                  decoration: BoxDecoration(
                    color: isAttended
                        ? routine.color.withOpacity(0.18)
                        : (isToday ? AppTheme.paper2 : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAttended
                          ? routine.color
                          : (isToday ? AppTheme.gold : Colors.transparent),
                      width: isAttended || isToday ? 1.5 : 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: isAttended || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isFuture
                              ? AppTheme.muted.withOpacity(0.3)
                              : (isAttended ? routine.color : AppTheme.textDark),
                        ),
                      ),
                      if (isAttended)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: routine.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(WorkRoutine routine) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final monthlyEntries = routine.entries
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOGGED SHIFTS & ATTENDANCE',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(height: 12),

        if (monthlyEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
            ),
            alignment: Alignment.center,
            child: Text(
              'No attendance logged for this month. Tap any past day on the calendar to log.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 13),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthlyEntries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.line),
              itemBuilder: (context, idx) {
                final entry = monthlyEntries[idx];
                final shiftLabel = entry.shiftType == ShiftType.attendanceOnly
                    ? 'Attended'
                    : (entry.checkIn != null && entry.checkOut != null
                        ? '${entry.checkIn} – ${entry.checkOut}'
                        : '${entry.shiftType.name.toUpperCase()} SHIFT');

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Text(
                    DateFormatter.format(entry.date),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark),
                  ),
                  subtitle: Text(
                    '$shiftLabel${entry.durationHours != null ? ' (${entry.durationHours!.toStringAsFixed(1)} hrs)' : ''}${entry.note != null ? ' • ${entry.note}' : ''}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.brick),
                    onPressed: () async {
                      await context.read<WorkRoutineProvider>().deleteAttendance(routine.id, entry.id);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showLogShiftSheet(BuildContext context, WorkRoutine routine, DateTime date, AttendanceEntry? existingEntry) {
    ShiftType shiftType = existingEntry?.shiftType ?? (routine.isAttendanceOnly ? ShiftType.attendanceOnly : ShiftType.regular);
    TimeOfDay checkInTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay checkOutTime = const TimeOfDay(hour: 17, minute: 0);
    final noteController = TextEditingController(text: existingEntry?.note ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Attendance',
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                Text(
                  DateFormatter.format(date),
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted),
                ),
                const SizedBox(height: 20),

                // Shift Type Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildShiftPill('Full Day', ShiftType.regular, shiftType, (s) => setModalState(() => shiftType = s)),
                      _buildShiftPill('Short', ShiftType.short, shiftType, (s) => setModalState(() => shiftType = s)),
                      _buildShiftPill('Afternoon', ShiftType.afternoon, shiftType, (s) => setModalState(() => shiftType = s)),
                      _buildShiftPill('Overnight', ShiftType.overnight, shiftType, (s) => setModalState(() => shiftType = s)),
                      _buildShiftPill('Attended', ShiftType.attendanceOnly, shiftType, (s) => setModalState(() => shiftType = s)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (shiftType != ShiftType.attendanceOnly) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check In', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showInkLedgerTimePicker(
                                  context: ctx,
                                  initialTime: checkInTime,
                                );
                                if (picked != null) {
                                  setModalState(() => checkInTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.paper2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.line),
                                ),
                                child: Text(checkInTime.format(ctx), style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check Out', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showInkLedgerTimePicker(
                                  context: ctx,
                                  initialTime: checkOutTime,
                                );
                                if (picked != null) {
                                  setModalState(() => checkOutTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.paper2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.line),
                                ),
                                child: Text(checkOutTime.format(ctx), style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                Builder(
                  builder: (context) {
                    if (shiftType == ShiftType.attendanceOnly) return const SizedBox.shrink();
                    final double checkInDec = checkInTime.hour + checkInTime.minute / 60.0;
                    final double checkOutDec = checkOutTime.hour + checkOutTime.minute / 60.0;
                    double computedHours = checkOutDec >= checkInDec ? (checkOutDec - checkInDec) : (24.0 - checkInDec + checkOutDec);
                    if (computedHours > 16.0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.gold),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppTheme.gold, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Long shift notice · That is longer than sixteen hours (${computedHours.toStringAsFixed(1)} hrs). Please check the range.',
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                Text('Notes (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(hintText: 'e.g. Covered extra shift, clinic duty'),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    double? hours;
                    if (shiftType != ShiftType.attendanceOnly) {
                      final double checkInDec = checkInTime.hour + checkInTime.minute / 60.0;
                      final double checkOutDec = checkOutTime.hour + checkOutTime.minute / 60.0;
                      hours = checkOutDec >= checkInDec ? (checkOutDec - checkInDec) : (24.0 - checkInDec + checkOutDec);
                      if (hours <= 0) hours = 8.0;
                    }

                    final entry = AttendanceEntry(
                      id: existingEntry?.id ?? const Uuid().v4(),
                      date: date,
                      checkIn: shiftType != ShiftType.attendanceOnly ? checkInTime.format(ctx) : null,
                      checkOut: shiftType != ShiftType.attendanceOnly ? checkOutTime.format(ctx) : null,
                      durationHours: hours,
                      shiftType: shiftType,
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                    );

                    await context.read<WorkRoutineProvider>().logAttendance(routine.id, entry);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance recorded'), backgroundColor: AppTheme.emerald),
                      );
                    }
                  },
                  child: const Text('Save Attendance'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShiftPill(String label, ShiftType type, ShiftType selected, ValueChanged<ShiftType> onSelected) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () => onSelected(type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ink : AppTheme.paperCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.ink : AppTheme.line),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.goldSoft : AppTheme.muted,
          ),
        ),
      ),
    );
  }

  void _showAddRoutineSheet(BuildContext context) {
    final titleController = TextEditingController();
    final workplaceController = TextEditingController();
    bool isAttendanceOnly = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Work Routine',
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 16),

                Text('Routine Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: 'e.g. Software Job, Tuition, Clinic'),
                ),
                const SizedBox(height: 16),

                Text('Workplace / Organization (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: workplaceController,
                  decoration: const InputDecoration(hintText: 'e.g. Apex Corp, Hospital, Home'),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Attendance Only', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  subtitle: Text('Track presence without requiring shift hours', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
                  value: isAttendanceOnly,
                  activeThumbColor: AppTheme.gold,
                  onChanged: (val) => setModalState(() => isAttendanceOnly = val),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a routine name')),
                      );
                      return;
                    }

                    final routine = WorkRoutine(
                      id: const Uuid().v4(),
                      title: title,
                      workplace: workplaceController.text.trim().isNotEmpty ? workplaceController.text.trim() : null,
                      isAttendanceOnly: isAttendanceOnly,
                      createdAt: DateTime.now(),
                    );

                    await context.read<WorkRoutineProvider>().add(routine);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedRoutineId = routine.id;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Work routine created'), backgroundColor: AppTheme.emerald),
                      );
                    }
                  },
                  child: const Text('Create Routine'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
