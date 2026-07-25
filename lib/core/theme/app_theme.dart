import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme configuration
class AppTheme {
  AppTheme._();

  // Constants
  static const double cardRadius = 16.0;

  // Colors
  static const Color primaryBackground = Color(0xFF0F1B2D);
  static const Color secondaryBackground = Color(0xFF1A2B42);
  static const Color emeraldGreen = Color(0xFF00C896);
  static const Color blueAccent = Color(0xFF0A84FF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A9BB0);
  static const Color errorRed = Color(0xFFFF4D6A);
  static const Color borderDivider = Color(0xFF243447);

  // Aliases for better semantics
  static const Color incomeColor = emeraldGreen;
  static const Color expenseColor = errorRed;

  static const List<Color> categoryPalette = [
    Color(0xFF3F8CFF), // Indigo/Blue
    Color(0xFFFF4D6A), // Rose/Pink
    Color(0xFF00C49F), // Teal/Green
    Color(0xFFFFBB28), // Yellow/Amber
    Color(0xFFFF8042), // Orange
    Color(0xFF8884D8), // Purple
  ];

  static Color getCategoryColor(String id, String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('food') || nameLower.contains('dining') || nameLower.contains('restaurant') || nameLower.contains('cafe') || nameLower.contains('groceries')) {
      return const Color(0xFFFFBB28); // Amber
    } else if (nameLower.contains('transport') || nameLower.contains('car') || nameLower.contains('travel') || nameLower.contains('taxi') || nameLower.contains('bus')) {
      return const Color(0xFF3F8CFF); // Indigo
    } else if (nameLower.contains('bill') || nameLower.contains('utilities') || nameLower.contains('rent') || nameLower.contains('subscription')) {
      return const Color(0xFFFF4D6A); // Rose
    } else if (nameLower.contains('shop') || nameLower.contains('clothes') || nameLower.contains('gadget')) {
      return const Color(0xFF8884D8); // Purple/Violet
    } else if (nameLower.contains('health') || nameLower.contains('medical') || nameLower.contains('pharmacy') || nameLower.contains('doctor')) {
      return const Color(0xFF00C49F); // Teal
    } else if (nameLower.contains('entertainment') || nameLower.contains('movie') || nameLower.contains('leisure') || nameLower.contains('fun')) {
      return const Color(0xFFFF8042); // Orange
    } else if (nameLower.contains('salary') || nameLower.contains('income') || nameLower.contains('business') || nameLower.contains('gift')) {
      return const Color(0xFF00C896); // Green/Emerald
    }
    // Fallback: deterministic selection from palette
    return categoryPalette[id.hashCode.abs() % categoryPalette.length];
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: emeraldGreen,
        secondary: blueAccent,
        surface: secondaryBackground,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBackground,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: secondaryBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: borderDivider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryBackground,
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: borderDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: borderDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: emeraldGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emeraldGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryBackground,
        selectedItemColor: emeraldGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primaryBackground,
        indicatorColor: emeraldGreen.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: emeraldGreen, fontWeight: FontWeight.bold);
          }
          return const TextStyle(color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: emeraldGreen);
          }
          return const IconThemeData(color: textSecondary);
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: emeraldGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          elevation: 2,
        ),
      ),
      textTheme: interTextTheme.copyWith(
        headlineLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: const TextStyle(color: textPrimary),
        bodyMedium: const TextStyle(color: textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDivider,
        thickness: 1,
      ),
    );
  }
}
