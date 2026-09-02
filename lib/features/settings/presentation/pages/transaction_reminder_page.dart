import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_time_picker.dart';

class TransactionReminderPage extends StatelessWidget {
  const TransactionReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final is24Hour = settings.is24HourTime;
    final reminderTime = settings.reminderTime;

    String formattedTime;
    if (is24Hour) {
      final hour = reminderTime.hour.toString().padLeft(2, '0');
      final minute = reminderTime.minute.toString().padLeft(2, '0');
      formattedTime = '$hour:$minute';
    } else {
      final hour = reminderTime.hourOfPeriod == 0 ? 12 : reminderTime.hourOfPeriod;
      final minute = reminderTime.minute.toString().padLeft(2, '0');
      final period = reminderTime.period == DayPeriod.am ? 'AM' : 'PM';
      formattedTime = '$hour:$minute $period';
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text(
          'Transaction Reminder',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Kicker & Description
          Text(
            'HABIT & ACCOUNTABILITY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: context.gold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily Ledger Check-In',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Receive a quiet daily prompt to record unlogged expenses and keep your cash flow ledger accurate.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Main Toggle Card
          Container(
            padding: const EdgeInsets.all(16),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Reminder',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.isDailyReminderEnabled ? 'Active' : 'Off',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: settings.isDailyReminderEnabled ? context.emerald : context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: settings.isDailyReminderEnabled,
                      activeColor: context.gold,
                      activeTrackColor: context.gold.withValues(alpha: 0.3),
                      onChanged: (val) {
                        HapticsService.selection();
                        settings.toggleDailyReminder(val);
                      },
                    ),
                  ],
                ),
                if (settings.isDailyReminderEnabled) ...[
                  Divider(height: 24, color: context.line),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      HapticsService.selection();
                      final picked = await showInkLedgerTimePicker(
                        context: context,
                        initialTime: reminderTime,
                        is24HourMode: is24Hour,
                      );
                      if (picked != null) {
                        settings.setReminderTime(picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 18, color: context.gold),
                              const SizedBox(width: 10),
                              Text(
                                'Reminder Time',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                formattedTime,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 16, color: context.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Status / Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: context.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    settings.isDailyReminderEnabled
                        ? 'You will receive a notification every day at $formattedTime.'
                        : 'Enable reminders to get daily alerts at your preferred review hour.',
                    style: GoogleFonts.inter(fontSize: 12, color: context.textMuted, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
