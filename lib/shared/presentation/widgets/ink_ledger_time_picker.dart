import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

/// Shows the custom Ink & Ledger time picker dialog or bottom sheet.
Future<TimeOfDay?> showInkLedgerTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  bool is24HourMode = false,
}) async {
  return showDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    builder: (context) => InkLedgerTimePickerDialog(
      initialTime: initialTime,
      is24HourMode: is24HourMode,
    ),
  );
}

class InkLedgerTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final bool is24HourMode;

  const InkLedgerTimePickerDialog({
    super.key,
    required this.initialTime,
    this.is24HourMode = false,
  });

  @override
  State<InkLedgerTimePickerDialog> createState() => _InkLedgerTimePickerDialogState();
}

class _InkLedgerTimePickerDialogState extends State<InkLedgerTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late String _selectedPeriod; // 'AM' or 'PM'
  bool _pickingHours = true; // true for hours, false for minutes

  late TextEditingController _hourController;
  late TextEditingController _minuteController;

  @override
  void initState() {
    super.initState();
    if (widget.is24HourMode) {
      _selectedHour = widget.initialTime.hour;
      _selectedPeriod = 'AM';
    } else {
      _selectedHour = widget.initialTime.hourOfPeriod == 0 ? 12 : widget.initialTime.hourOfPeriod;
      _selectedPeriod = widget.initialTime.period == DayPeriod.am ? 'AM' : 'PM';
    }
    _selectedMinute = widget.initialTime.minute;

    _hourController = TextEditingController(text: _selectedHour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: _selectedMinute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _hourController.text = _selectedHour.toString().padLeft(2, '0');
    _minuteController.text = _selectedMinute.toString().padLeft(2, '0');
  }

  TimeOfDay _buildResultTime() {
    int finalHour = _selectedHour;
    if (!widget.is24HourMode) {
      if (_selectedPeriod == 'AM') {
        finalHour = _selectedHour == 12 ? 0 : _selectedHour;
      } else {
        finalHour = _selectedHour == 12 ? 12 : _selectedHour + 12;
      }
    }
    return TimeOfDay(hour: finalHour, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxDialogHeight = screenSize.height * 0.85;

    return Dialog(
      backgroundColor: AppTheme.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: const BorderSide(color: AppTheme.line),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: maxDialogHeight,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECT TIME',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppTheme.muted,
                      ),
                    ),
                    Text(
                      widget.is24HourMode ? '24-Hour' : '12-Hour',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Digital Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hour Box
                    _buildTimeBox(
                      controller: _hourController,
                      isSelected: _pickingHours,
                      onTap: () {
                        setState(() {
                          _pickingHours = true;
                        });
                      },
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          if (widget.is24HourMode) {
                            if (parsed >= 0 && parsed <= 23) {
                              setState(() => _selectedHour = parsed);
                            }
                          } else {
                            if (parsed >= 1 && parsed <= 12) {
                              setState(() => _selectedHour = parsed);
                            }
                          }
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        ':',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    // Minute Box
                    _buildTimeBox(
                      controller: _minuteController,
                      isSelected: !_pickingHours,
                      onTap: () {
                        setState(() {
                          _pickingHours = false;
                        });
                      },
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed >= 0 && parsed <= 59) {
                          setState(() => _selectedMinute = parsed);
                        }
                      },
                    ),

                    if (!widget.is24HourMode) ...[
                      const SizedBox(width: 12),
                      // AM/PM Toggle Column
                      Column(
                        children: [
                          _buildAmPmButton('AM'),
                          const SizedBox(height: 4),
                          _buildAmPmButton('PM'),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Interactive Clock Dial
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dial background circle
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.paper2,
                          border: Border.all(color: AppTheme.line),
                        ),
                      ),
                      // Hand and center pin
                      CustomPaint(
                        size: const Size(200, 200),
                        painter: _ClockHandPainter(
                          value: _pickingHours
                              ? (widget.is24HourMode ? _selectedHour % 12 : _selectedHour % 12)
                              : _selectedMinute,
                          maxValue: _pickingHours ? 12 : 60,
                        ),
                      ),
                      // Numbers around dial
                      ..._buildDialNumbers(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_buildResultTime());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ink,
                        foregroundColor: AppTheme.goldSoft,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Set Time',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required TextEditingController controller,
    required bool isSelected,
    required VoidCallback onTap,
    required ValueChanged<String> onChanged,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.gold.withOpacity(0.15) : AppTheme.paperCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.gold : AppTheme.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.ink : AppTheme.textDark,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            filled: false,
          ),
          onTap: onTap,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAmPmButton(String label) {
    final isSelected = _selectedPeriod == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ink : AppTheme.paperCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.ink : AppTheme.line,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.goldSoft : AppTheme.muted,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDialNumbers() {
    final List<Widget> items = [];
    final int count = _pickingHours ? 12 : 12; // Show 12 points
    final double radius = 74.0;

    for (int i = 1; i <= count; i++) {
      final double angle = (i * 30 - 90) * (pi / 180);
      final double x = radius * cos(angle);
      final double y = radius * sin(angle);

      final displayVal = _pickingHours ? i : (i == 12 ? 0 : i * 5);
      final isCurrentSelected = _pickingHours
          ? (_selectedHour % 12 == (i == 12 ? 0 : i))
          : (_selectedMinute == displayVal);

      items.add(
        Transform.translate(
          offset: Offset(x, y),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_pickingHours) {
                  _selectedHour = widget.is24HourMode ? (i == 12 ? 0 : i) : i;
                  _pickingHours = false; // Auto switch to minutes
                } else {
                  _selectedMinute = displayVal;
                }
                _syncControllers();
              });
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentSelected ? AppTheme.gold : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Text(
                _pickingHours ? '$i' : (displayVal == 0 ? '00' : '$displayVal'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrentSelected ? Colors.white : AppTheme.textDark,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return items;
  }
}

class _ClockHandPainter extends CustomPainter {
  final int value;
  final int maxValue;

  _ClockHandPainter({required this.value, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppTheme.gold
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.gold
      ..style = PaintingStyle.fill;

    final angle = (value * (360 / maxValue) - 90) * (pi / 180);
    final handLength = size.width * 0.37;
    final endPoint = Offset(
      center.dx + handLength * cos(angle),
      center.dy + handLength * sin(angle),
    );

    // Draw hand line
    canvas.drawLine(center, endPoint, paint);

    // Draw center dot
    canvas.drawCircle(center, 4.0, dotPaint);

    // Draw end circle
    canvas.drawCircle(endPoint, 14.0, Paint()..color = AppTheme.gold.withOpacity(0.2));
  }

  @override
  bool shouldRepaint(covariant _ClockHandPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.maxValue != maxValue;
  }
}
