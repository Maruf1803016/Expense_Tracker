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
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(
          'Preferences',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSectionHeader('Time & Date Display'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    '24-Hour Time Format',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  subtitle: Text(
                    settings.is24HourTime ? 'Display times in 24h format (e.g. 17:30)' : 'Display times in 12h format with AM/PM (e.g. 5:30 PM)',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
                  ),
                  value: settings.is24HourTime,
                  activeColor: AppTheme.gold,
                  onChanged: (val) => settings.toggleTimeFormat(val),
                ),
                const Divider(height: 1, color: AppTheme.line),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    'First Day of the Week',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  subtitle: Text(
                    'Calendar and week calculations start on ${weekdays[settings.startDayOfWeek - 1]}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
                  ),
                  trailing: DropdownButton<int>(
                    value: settings.startDayOfWeek,
                    underline: const SizedBox(),
                    dropdownColor: AppTheme.paperCard,
                    items: List.generate(7, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text(weekdays[i], style: GoogleFonts.inter(color: AppTheme.textDark)),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) settings.setStartDayOfWeek(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Accounting & Fiscal Year'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                'Financial Year Starts',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark),
              ),
              subtitle: Text(
                'Fiscal year resets every ${months[settings.financialYearStartMonth - 1]}',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
              ),
              trailing: DropdownButton<int>(
                value: settings.financialYearStartMonth,
                underline: const SizedBox(),
                dropdownColor: AppTheme.paperCard,
                items: List.generate(12, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(months[i], style: GoogleFonts.inter(color: AppTheme.textDark)),
                  );
                }),
                onChanged: (val) {
                  if (val != null) settings.setFinancialYearStartMonth(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.muted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
