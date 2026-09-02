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
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_add_card.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class WorkRoutinePage extends StatefulWidget {
  final bool showAddCard;

  const WorkRoutinePage({super.key, this.showAddCard = true});

  @override
  State<WorkRoutinePage> createState() => _WorkRoutinePageState();
}

class _WorkRoutinePageState extends State<WorkRoutinePage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<WorkRoutineProvider>();
    final routines = routineProvider.routines;

    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    int totalAttended = 0;
    double totalHours = 0.0;
    for (final r in routines) {
      totalAttended += r.getAttendedDays(year, month);
      totalHours += r.getMonthlyHours(year, month);
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          widget.showAddCard ? 'Work & Routine' : 'Work & Routine Log',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
        ),
      ),
      body: routines.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Main Hero Summary Card (Always at Top)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: context.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.badge_outlined, color: context.gold, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Monthly Routine Overview',
                                style: GoogleFonts.fraunces(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.surface2,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              DateFormat('MMM yyyy').format(_selectedMonth),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: context.line),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ATTENDED SHIFTS',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: context.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalAttended days',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.emerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: context.line),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MONTHLY HOURS',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: context.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${totalHours.toStringAsFixed(1)} hrs',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Dedicated Add Work Routine Card (Under Main Card, only if showAddCard is true)
                if (widget.showAddCard)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkLedgerAddCard(
                      title: 'Add a work routine',
                      subtitle: 'Track clinical shifts, tuition, hourly, or office work',
                      icon: Icons.badge_outlined,
                      buttonText: 'Add',
                      onTap: () {
                        HapticsService.selection();
                        _showAddRoutineSheet(context);
                      },
                    ),
                  ),

                // Kicker Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
                  child: Text(
                    '${routines.length} ACTIVE ${routines.length == 1 ? 'ROUTINE' : 'ROUTINES'}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: context.textMuted,
                    ),
                  ),
                ),

                // Routine Cards List
                ...routines.map((routine) => _buildRoutineCard(context, routine)),
              ],
            ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, WorkRoutine routine) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final plannedDays = routine.getPlannedDays(year, month);
    final attendedDays = routine.getAttendedDays(year, month);
    final missedDays = routine.getMissedDays(year, month);
    final totalHours = routine.getMonthlyHours(year, month);

    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final scheduleStr = routine.workingDays.length == 7
        ? '7 days/week (Daily)'
        : routine.workingDays.length == 5 && routine.workingDays.contains(1) && routine.workingDays.contains(5)
            ? '5 days/week (Mon–Fri)'
            : '${routine.workingDays.length} days/week (${routine.workingDays.map((d) => weekdayNames[d - 1]).join(', ')})';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: InkWell(
        onTap: () {
          HapticsService.selection();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkRoutineDetailPage(
                routineId: routine.id,
                initialMonth: _selectedMonth,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon, Title, Workplace, Chevron
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: routine.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(routine.icon, size: 18, color: routine.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.title,
                          style: GoogleFonts.fraunces(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        if (routine.workplace != null && routine.workplace!.isNotEmpty)
                          Text(
                            routine.workplace!,
                            style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: context.gold),
                ],
              ),
              const SizedBox(height: 10),

              // Schedule description chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.line),
                ),
                child: Text(
                  scheduleStr,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: context.line),
              const SizedBox(height: 10),

              // Metrics Row: Planned, Attended, Missed, Total Hours
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCol('PLANNED', '$plannedDays d', context.textPrimary),
                  ),
                  Container(width: 1, height: 24, color: context.line),
                  Expanded(
                    child: _buildMetricCol('ATTENDED', '$attendedDays d', context.emerald),
                  ),
                  Container(width: 1, height: 24, color: context.line),
                  Expanded(
                    child: _buildMetricCol('MISSED', '$missedDays d', missedDays > 0 ? context.brick : context.textMuted),
                  ),
                  if (!routine.isAttendanceOnly) ...[
                    Container(width: 1, height: 24, color: context.line),
                    Expanded(
                      child: _buildMetricCol('HOURS', '${totalHours.toStringAsFixed(1)} h', context.gold),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
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
              decoration: BoxDecoration(
                color: context.cardBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.badge_outlined, size: 48, color: context.gold),
            ),
            const SizedBox(height: 20),
            Text(
              'No Work Routines Yet',
              style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Track clinical shifts, tuition, hourly jobs, or regular office work with flexible schedules.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticsService.selection();
                _showAddRoutineSheet(context);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Work Routine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRoutineSheet(BuildContext context) {
    final titleController = TextEditingController();
    final workplaceController = TextEditingController();
    bool isAttendanceOnly = false;
    List<int> selectedDays = [1, 2, 3, 4, 5]; // Mon - Fri

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

          return Container(
            decoration: BoxDecoration(
              color: ctx.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: ctx.line),
            ),
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
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: ctx.textPrimary),
                ),
                const SizedBox(height: 16),

                Text('Routine Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  style: GoogleFonts.inter(color: ctx.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Clinical Shift, Tuition BGB, Office Work',
                    hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                    filled: true,
                    fillColor: ctx.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Workplace / Organization (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: workplaceController,
                  style: GoogleFonts.inter(color: ctx.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. City Hospital, BGB Campus, Apex Corp',
                    hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                    filled: true,
                    fillColor: ctx.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Working Days Schedule (${selectedDays.length} days/week)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (idx) {
                    final dayNum = idx + 1;
                    final isSelected = selectedDays.contains(dayNum);
                    return InkWell(
                      onTap: () {
                        HapticsService.selection();
                        setModalState(() {
                          if (isSelected) {
                            if (selectedDays.length > 1) {
                              selectedDays.remove(dayNum);
                            }
                          } else {
                            selectedDays.add(dayNum);
                            selectedDays.sort();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected ? ctx.gold : ctx.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? ctx.gold : ctx.line,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          weekdayLabels[idx],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : ctx.textMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Attendance Only', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: ctx.textPrimary)),
                  subtitle: Text('Log presence without tracking shift hours', style: GoogleFonts.inter(fontSize: 11, color: ctx.textMuted)),
                  value: isAttendanceOnly,
                  activeThumbColor: ctx.gold,
                  onChanged: (val) {
                    HapticsService.selection();
                    setModalState(() => isAttendanceOnly = val);
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ctx.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      HapticsService.lightImpact();
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
                        workingDays: selectedDays,
                        expectedDaysPerWeek: selectedDays.length,
                        isAttendanceOnly: isAttendanceOnly,
                        createdAt: DateTime.now(),
                      );

                      await context.read<WorkRoutineProvider>().add(routine);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Work routine created'), backgroundColor: context.emerald),
                        );
                      }
                    },
                    child: const Text('Create Routine', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WorkRoutineDetailPage extends StatefulWidget {
  final String routineId;
  final DateTime initialMonth;

  const WorkRoutineDetailPage({
    super.key,
    required this.routineId,
    required this.initialMonth,
  });

  @override
  State<WorkRoutineDetailPage> createState() => _WorkRoutineDetailPageState();
}

class _WorkRoutineDetailPageState extends State<WorkRoutineDetailPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<WorkRoutineProvider>();
    final routine = routineProvider.routines.where((r) => r.id == widget.routineId).firstOrNull;

    if (routine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Routine Detail')),
        body: const Center(child: Text('Routine not found')),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(routine.title, style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: context.brick),
            tooltip: 'Delete Routine',
            onPressed: () async {
              HapticsService.lightImpact();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: ctx.cardBg,
                  title: Text('Delete Routine', style: TextStyle(color: ctx.textPrimary)),
                  content: Text('Delete "${routine.title}" and its attendance logs?', style: TextStyle(color: ctx.textMuted)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: ctx.textMuted))),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: ctx.brick),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await routineProvider.delete(routine.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoutineStatsHero(routine),
            const SizedBox(height: 16),
            _buildMonthSelector(),
            const SizedBox(height: 16),
            _buildCalendarGrid(routine),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineStatsHero(WorkRoutine routine) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final plannedDays = routine.getPlannedDays(year, month);
    final attendedDays = routine.getAttendedDays(year, month);
    final missedDays = routine.getMissedDays(year, month);
    final hoursWorked = routine.getMonthlyHours(year, month);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(routine.icon, color: context.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    routine.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              if (routine.workplace != null)
                Text(
                  routine.workplace!,
                  style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.line),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATTENDED / PLANNED',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$attendedDays / $plannedDays d',
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: context.gold),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: context.line),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MISSED DAYS',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$missedDays Days',
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: missedDays > 0 ? context.brick : context.textPrimary),
                    ),
                  ],
                ),
              ),
              if (!routine.isAttendanceOnly) ...[
                Container(width: 1, height: 30, color: context.line),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL HOURS',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${hoursWorked.toStringAsFixed(1)} h',
                        style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
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
          icon: Icon(Icons.chevron_left_rounded, color: context.textPrimary),
          onPressed: () {
            HapticsService.selection();
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
            });
          },
        ),
        Text(
          format.format(_selectedMonth),
          style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded, color: context.textPrimary),
          onPressed: () {
            HapticsService.selection();
            final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
            if (nextMonth.isBefore(DateTime.now().add(const Duration(days: 365)))) {
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) {
              return SizedBox(
                width: 32,
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

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
            itemBuilder: (ctx, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }
              final day = index - (firstWeekday - 1) + 1;
              final cellDate = DateTime(year, month, day);
              final isFuture = cellDate.isAfter(DateTime(now.year, now.month, now.day));
              final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
              final entry = routine.getEntryForDate(cellDate);
              final isAttended = entry != null;
              final isPlanned = routine.workingDays.contains(cellDate.weekday);

              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                        HapticsService.selection();
                        if (entry != null) {
                          _showAttendanceDetailSheet(context, routine, cellDate, entry);
                        } else {
                          _showLogShiftSheet(context, routine, cellDate, null);
                        }
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isAttended
                        ? routine.color.withValues(alpha: 0.18)
                        : (isToday ? ctx.surface2 : (isPlanned ? ctx.surface2.withValues(alpha: 0.5) : Colors.transparent)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAttended
                          ? routine.color
                          : (isToday ? ctx.gold : ctx.line),
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
                              ? ctx.textMuted.withValues(alpha: 0.3)
                              : (isAttended ? routine.color : ctx.textPrimary),
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

  void _showAttendanceDetailSheet(BuildContext context, WorkRoutine routine, DateTime date, AttendanceEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: ctx.line),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kicker
            Text(
              'ATTENDANCE DETAIL',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: ctx.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormatter.format(date),
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ctx.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: ctx.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: ctx.line),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(ctx, 'ROUTINE', routine.title),
                  Divider(color: ctx.line, height: 20),
                  _buildDetailRow(ctx, 'SHIFT TYPE', entry.shiftType.name.toUpperCase()),
                  if (entry.checkIn != null) ...[
                    Divider(color: ctx.line, height: 20),
                    _buildDetailRow(ctx, 'CHECK IN', entry.checkIn!),
                  ],
                  if (entry.checkOut != null) ...[
                    Divider(color: ctx.line, height: 20),
                    _buildDetailRow(ctx, 'CHECK OUT', entry.checkOut!),
                  ],
                  if (entry.durationHours != null) ...[
                    Divider(color: ctx.line, height: 20),
                    _buildDetailRow(ctx, 'DURATION', '${entry.durationHours!.toStringAsFixed(1)} hours'),
                  ],
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    Divider(color: ctx.line, height: 20),
                    _buildDetailRow(ctx, 'NOTES', entry.note!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Single Modify attendance button at the bottom
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Modify attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctx.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  HapticsService.selection();
                  Navigator.pop(ctx);
                  _showLogShiftSheet(context, routine, date, entry);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext ctx, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: ctx.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ctx.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showLogShiftSheet(BuildContext context, WorkRoutine routine, DateTime date, AttendanceEntry? existingEntry) {
    ShiftType shiftType = existingEntry?.shiftType ?? (routine.isAttendanceOnly ? ShiftType.attendanceOnly : ShiftType.regular);
    TimeOfDay checkInTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay checkOutTime = const TimeOfDay(hour: 17, minute: 0);
    
    if (existingEntry != null) {
      if (existingEntry.checkIn != null) {
        final parsedIn = _parseTimeOfDay(existingEntry.checkIn!);
        if (parsedIn != null) checkInTime = parsedIn;
      }
      if (existingEntry.checkOut != null) {
        final parsedOut = _parseTimeOfDay(existingEntry.checkOut!);
        if (parsedOut != null) checkOutTime = parsedOut;
      }
    }

    final noteController = TextEditingController(text: existingEntry?.note ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: ctx.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: ctx.line),
            ),
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
                  existingEntry == null ? 'Log Attendance' : 'Modify Attendance',
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: ctx.textPrimary),
                ),
                Text(
                  DateFormatter.format(date),
                  style: GoogleFonts.inter(fontSize: 13, color: ctx.textMuted),
                ),
                const SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildShiftPill(ctx, 'Full Day', ShiftType.regular, shiftType, (s) => setModalState(() => shiftType = s)),
                      _buildShiftPill(ctx, 'Short', ShiftType.short, shiftType, (s) => setModalState(() => shiftType = s)),
                      _buildShiftPill(ctx, 'Afternoon', ShiftType.afternoon, shiftType, (s) => setModalState(() => shiftType = s)),
                      _buildShiftPill(ctx, 'Overnight', ShiftType.overnight, shiftType, (s) => setModalState(() => shiftType = s)),
                      _buildShiftPill(ctx, 'Attended', ShiftType.attendanceOnly, shiftType, (s) => setModalState(() => shiftType = s)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (shiftType != ShiftType.attendanceOnly) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check In', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.textMuted)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () async {
                                HapticsService.selection();
                                final picked = await showInkLedgerTimePicker(
                                  context: ctx,
                                  initialTime: checkInTime,
                                );
                                if (picked != null) {
                                  setModalState(() => checkInTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: ctx.cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: ctx.line),
                                ),
                                child: Text(_formatTimeOfDay(checkInTime), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
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
                            Text('Check Out', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.textMuted)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () async {
                                HapticsService.selection();
                                final picked = await showInkLedgerTimePicker(
                                  context: ctx,
                                  initialTime: checkOutTime,
                                );
                                if (picked != null) {
                                  setModalState(() => checkOutTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: ctx.cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: ctx.line),
                                ),
                                child: Text(_formatTimeOfDay(checkOutTime), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                Text('Notes (Optional)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.textMuted)),
                const SizedBox(height: 4),
                TextField(
                  controller: noteController,
                  style: GoogleFonts.inter(color: ctx.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Covered extra shift, clinic duty',
                    hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                    filled: true,
                    fillColor: ctx.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ctx.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      HapticsService.lightImpact();
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
                        checkIn: shiftType != ShiftType.attendanceOnly ? _formatTimeOfDay(checkInTime) : null,
                        checkOut: shiftType != ShiftType.attendanceOnly ? _formatTimeOfDay(checkOutTime) : null,
                        durationHours: hours,
                        shiftType: shiftType,
                        note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                      );

                      await context.read<WorkRoutineProvider>().logAttendance(routine.id, entry);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Attendance saved'), backgroundColor: context.emerald),
                        );
                      }
                    },
                    child: Text(existingEntry == null ? 'Save Attendance' : 'Update Attendance', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String str) {
    try {
      final cleaned = str.trim().toUpperCase();
      final isPm = cleaned.contains('PM');
      final isAm = cleaned.contains('AM');
      final digits = cleaned.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digits.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Widget _buildShiftPill(BuildContext ctx, String label, ShiftType type, ShiftType selected, ValueChanged<ShiftType> onSelected) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () {
        HapticsService.selection();
        onSelected(type);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ctx.gold : ctx.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? ctx.gold : ctx.line),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : ctx.textMuted,
          ),
        ),
      ),
    );
  }
}

