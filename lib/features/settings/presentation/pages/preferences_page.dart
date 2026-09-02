import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        title: Text(
          'Preferences',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w500,
            color: context.textPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          _buildSectionHeader(context, 'Time & Date Display'),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.line),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  title: Text(
                    '24-Hour Time Format',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    settings.is24HourTime ? 'Using 24h clock (e.g. 17:30)' : 'Using 12h clock (e.g. 5:30 PM)',
                    style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                  ),
                  trailing: GestureDetector(
                    onTap: () => settings.toggleTimeFormat(!settings.is24HourTime),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 28,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: settings.is24HourTime ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : context.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: settings.is24HourTime ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : context.line,
                          width: 1.2,
                        ),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: settings.is24HourTime ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: settings.is24HourTime
                                ? (context.isDark ? const Color(0xFF1B241E) : AppTheme.goldSoft)
                                : context.textMuted,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: context.line),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  title: Text(
                    'First Day of the Week',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Calendar starts on ${weekdays[settings.startDayOfWeek - 1]}',
                    style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.line),
                    ),
                    child: DropdownButton<int>(
                      value: settings.startDayOfWeek,
                      underline: const SizedBox(),
                      isDense: true,
                      dropdownColor: context.cardBg,
                      items: List.generate(7, (i) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text(
                            weekdays[i],
                            style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary),
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) settings.setStartDayOfWeek(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader(context, 'Interaction & Feedback'),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.line),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              title: Text(
                'Haptic Feedback',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: context.textPrimary,
                ),
              ),
              subtitle: Text(
                settings.hapticsEnabled ? 'Subtle tactile vibrations on button taps' : 'Haptics deactivated',
                style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
              ),
              trailing: GestureDetector(
                onTap: () {
                  settings.toggleHaptics(!settings.hapticsEnabled);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 28,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: settings.hapticsEnabled ? context.gold : context.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: settings.hapticsEnabled ? context.gold : context.line,
                      width: 1.2,
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: settings.hapticsEnabled ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: settings.hapticsEnabled ? Colors.white : context.textMuted,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader(context, 'Accounting & Fiscal Year'),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.line),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              title: Text(
                'Financial Year Starts',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: context.textPrimary,
                ),
              ),
              subtitle: Text(
                'Resets every ${months[settings.financialYearStartMonth - 1]}',
                style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.line),
                ),
                child: DropdownButton<int>(
                  value: settings.financialYearStartMonth,
                  underline: const SizedBox(),
                  isDense: true,
                  dropdownColor: context.cardBg,
                  items: List.generate(12, (i) {
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        months[i],
                        style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary),
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) settings.setFinancialYearStartMonth(val);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: context.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
