import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

/// Shows the custom Ink & Ledger time picker dialog.
/// Perfectly styled with the Editorial theme (Ink header, Ledger Gold accents, Warm Paper background).
Future<TimeOfDay?> showInkLedgerTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  bool is24HourMode = false,
}) async {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    initialEntryMode: TimePickerEntryMode.dial,
    builder: (context, child) {
      final isDark = context.isDark;
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: context.gold,
                  onPrimary: const Color(0xFF121C15),
                  surface: context.cardBg,
                  onSurface: context.textPrimary,
                  secondary: context.gold,
                  surfaceContainerHighest: context.surface2,
                )
              : ColorScheme.light(
                  primary: AppTheme.gold,
                  onPrimary: Colors.white,
                  surface: AppTheme.paperCard,
                  onSurface: AppTheme.textDark,
                  secondary: AppTheme.ink,
                  surfaceContainerHighest: AppTheme.paper2,
                ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: context.bg,
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: context.line),
            ),
            hourMinuteColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return context.gold.withValues(alpha: 0.18);
              }
              return context.cardBg;
            }),
            hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return context.gold;
              }
              return context.textPrimary;
            }),
            hourMinuteTextStyle: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            dayPeriodBorderSide: BorderSide(color: context.line),
            dayPeriodColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return context.gold;
              }
              return context.surface2;
            }),
            dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return isDark ? const Color(0xFF121C15) : Colors.white;
              }
              return context.textMuted;
            }),
            dayPeriodTextStyle: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            dialBackgroundColor: context.surface2,
            dialHandColor: context.gold,
            dialTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return isDark ? const Color(0xFF121C15) : Colors.white;
              }
              return context.textPrimary;
            }),
            dialTextStyle: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            entryModeIconColor: context.gold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(color: context.line),
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: context.textMuted,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            confirmButtonStyle: ElevatedButton.styleFrom(
              backgroundColor: context.gold,
              foregroundColor: isDark ? const Color(0xFF121C15) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: is24HourMode,
          ),
          child: child!,
        ),
      );
    },
  );
}
