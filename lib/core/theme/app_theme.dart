import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme configuration in the Ink/Gold Editorial direction.
class AppTheme {
  AppTheme._();

  // Colors
  static const Color ink = Color(0xFF1B3A2B);       // primary deep archival ink
  static const Color ink2 = Color(0xFF12261C);      // secondary dark surface
  static const Color paper = Color(0xFFF8F4EC);     // main warm-paper background
  static const Color paperCard = Color(0xFFFFFFFF); // card background
  static const Color paper2 = Color(0xFFF1EDE4);    // subtle secondary surface / track / chip backgrounds
  static const Color gold = Color(0xFFB78A3D);      // primary Ledger Gold accent
  static const Color goldSoft = Color(0xFFE5D2A4);  // light gold for dark surfaces
  static const Color goldLine = Color(0x3DB78A3D);  // subtle gold divider / accent line
  static const Color textDark = Color(0xFF1C221D);  // primary text on light backgrounds
  static const Color muted = Color(0xFF5C635B);     // secondary/muted text with WCAG AA compliance
  static const Color line = Color(0xFFE2DDD1);      // hairline borders, fine low-contrast
  static const Color emerald = Color(0xFF1E6F55);   // income / positive
  static const Color brick = Color(0xFFA23B3B);     // expense / negative / over-budget

  // Aliases for backward compatibility
  static const Color primaryBackground = paper;
  static const Color secondaryBackground = paperCard;
  static const Color emeraldGreen = emerald;
  static const Color blueAccent = gold;
  static const Color textPrimary = textDark;
  static const Color textSecondary = muted;
  static const Color errorRed = brick;
  static const Color borderDivider = line;
  static const Color incomeColor = emerald;
  static const Color expenseColor = brick;

  static const double cardRadius = 14.0; // Restrained editorial radius

  // Category warm-toned muted palette
  static const List<Color> categoryPalette = [
    Color(0xFFB78A3D), // Food: Ledger gold
    Color(0xFF3B6EA5), // Transport: muted blue
    Color(0xFF8B5FA3), // Shopping: muted purple
    Color(0xFF4A7A6B), // Bills: muted teal-green
    Color(0xFFA2585F), // Entertainment: muted brick
    Color(0xFF6B7D4A), // Health: muted olive
    Color(0xFF7A6A4A), // Travel/Home: muted tan
  ];

  static Color getCategoryColor(String id, String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('food') || nameLower.contains('dining') || nameLower.contains('restaurant') || nameLower.contains('cafe') || nameLower.contains('groceries')) {
      return const Color(0xFFB78A3D); // Ledger gold
    } else if (nameLower.contains('transport') || nameLower.contains('car') || nameLower.contains('taxi') || nameLower.contains('bus')) {
      return const Color(0xFF3B6EA5); // Muted blue
    } else if (nameLower.contains('shop') || nameLower.contains('clothes') || nameLower.contains('gadget') || nameLower.contains('shopping')) {
      return const Color(0xFF8B5FA3); // Muted purple
    } else if (nameLower.contains('bill') || nameLower.contains('utilities') || nameLower.contains('rent') || nameLower.contains('subscription')) {
      return const Color(0xFF4A7A6B); // Muted teal-green
    } else if (nameLower.contains('entertainment') || nameLower.contains('movie') || nameLower.contains('leisure') || nameLower.contains('fun')) {
      return const Color(0xFFA2585F); // Muted brick
    } else if (nameLower.contains('health') || nameLower.contains('medical') || nameLower.contains('pharmacy') || nameLower.contains('doctor')) {
      return const Color(0xFF6B7D4A); // Muted olive
    } else if (nameLower.contains('travel') || nameLower.contains('home') || nameLower.contains('trip') || nameLower.contains('stay')) {
      return const Color(0xFF7A6A4A); // Muted tan
    } else if (nameLower.contains('salary') || nameLower.contains('income') || nameLower.contains('business') || nameLower.contains('gift') || nameLower.contains('interest') || nameLower.contains('dividend')) {
      return const Color(0xFF1E6F55); // Muted emerald green
    }
    // Fallback: deterministic selection from palette
    return categoryPalette[id.hashCode.abs() % categoryPalette.length];
  }

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        primary: gold,
        secondary: gold,
        surface: paperCard,
        error: brick,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.fraunces(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: paperCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: line, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper2,
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: goldSoft,
        elevation: 1,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: paperCard,
        selectedItemColor: ink,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textTheme: interTextTheme.copyWith(
        headlineLarge: GoogleFonts.fraunces(color: textDark, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.fraunces(color: textDark, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.fraunces(color: textDark, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: textDark),
        bodyMedium: const TextStyle(color: muted),
      ),
      dividerTheme: const DividerThemeData(
        color: line,
        thickness: 1,
      ),
    );
  }

  // Alias for compatibility
  static ThemeData get darkTheme => lightTheme;
}
