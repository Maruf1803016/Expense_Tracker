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

  // Dark Theme Palette Constants
  static const Color darkScaffold = Color(0xFF131A15);
  static const Color darkCard = Color(0xFF1B241E);
  static const Color darkSurface2 = Color(0xFF222E26);
  static const Color darkLine = Color(0xFF2E3D33);
  static const Color darkText = Color(0xFFEDE9DE);
  static const Color darkMuted = Color(0xFF9EABA1);

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
      scaffoldBackgroundColor: const Color(0xFFF8F4EC),
      colorScheme: const ColorScheme.light(
        primary: gold,
        secondary: gold,
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFA23B3B),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1C221D),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F4EC),
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.fraunces(
          color: const Color(0xFF1C221D),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1C221D)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: Color(0xFFE2DDD1), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1EDE4),
        hintStyle: const TextStyle(color: Color(0xFF5C635B)),
        labelStyle: const TextStyle(color: Color(0xFF5C635B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: Color(0xFFE2DDD1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: Color(0xFFE2DDD1)),
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
        backgroundColor: Color(0xFF1B3A2B),
        foregroundColor: goldSoft,
        elevation: 1,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF1B3A2B),
        unselectedItemColor: Color(0xFF5C635B),
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
        headlineLarge: GoogleFonts.fraunces(color: const Color(0xFF1C221D), fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.fraunces(color: const Color(0xFF1C221D), fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.fraunces(color: const Color(0xFF1C221D), fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: Color(0xFF1C221D)),
        bodyMedium: const TextStyle(color: Color(0xFF5C635B)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2DDD1),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: const Color(0xFF131A15),
      colorScheme: const ColorScheme.dark(
        primary: goldSoft,
        secondary: gold,
        surface: Color(0xFF1B241E),
        error: Color(0xFFE05656),
        onPrimary: Color(0xFF121C15),
        onSecondary: Color(0xFF121C15),
        onSurface: Color(0xFFEDE9DE),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF131A15),
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.fraunces(
          color: const Color(0xFFEDE9DE),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFEDE9DE)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B241E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: Color(0xFF2E3D33), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF222E26),
        hintStyle: const TextStyle(color: Color(0xFF9EABA1)),
        labelStyle: const TextStyle(color: Color(0xFF9EABA1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: Color(0xFF2E3D33)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: Color(0xFF2E3D33)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: goldSoft, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF14291E),
        foregroundColor: goldSoft,
        elevation: 1,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1B241E),
        selectedItemColor: goldSoft,
        unselectedItemColor: Color(0xFF9EABA1),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: goldSoft,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF121C15),
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
        headlineLarge: GoogleFonts.fraunces(color: const Color(0xFFEDE9DE), fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.fraunces(color: const Color(0xFFEDE9DE), fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.fraunces(color: const Color(0xFFEDE9DE), fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: Color(0xFFEDE9DE)),
        bodyMedium: const TextStyle(color: Color(0xFF9EABA1)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E3D33),
        thickness: 1,
      ),
    );
  }

  // Dynamic context-aware color helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? darkScaffold : paper;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkCard : paperCard;

  static Color surface2(BuildContext context) =>
      isDark(context) ? darkSurface2 : paper2;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkLine : line;

  static Color text(BuildContext context) =>
      isDark(context) ? darkText : textDark;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color inkColor(BuildContext context) =>
      isDark(context) ? goldSoft : ink;

  static Color goldColor(BuildContext context) =>
      isDark(context) ? goldSoft : gold;

  static Color emeraldColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF4EBA97) : emerald;

  static Color brickColor(BuildContext context) =>
      isDark(context) ? const Color(0xFFE57373) : brick;
}

/// Convenience extension on BuildContext for effortless, clean dark-mode reactive styling
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Surfaces & Backgrounds
  Color get bg => isDark ? AppTheme.darkScaffold : AppTheme.paper;
  Color get cardBg => isDark ? AppTheme.darkCard : AppTheme.paperCard;
  Color get surface2 => isDark ? AppTheme.darkSurface2 : AppTheme.paper2;

  // Lines & Borders
  Color get line => isDark ? AppTheme.darkLine : AppTheme.line;
  Color get goldLine => isDark ? const Color(0x55C5A880) : AppTheme.goldLine;

  // Typography
  Color get textPrimary => isDark ? AppTheme.darkText : AppTheme.textDark;
  Color get textMuted => isDark ? AppTheme.darkMuted : AppTheme.muted;
  Color get ink => isDark ? AppTheme.goldSoft : AppTheme.ink;
  Color get gold => isDark ? AppTheme.goldSoft : AppTheme.gold;

  // Category & Status
  Color get emerald => isDark ? const Color(0xFF4EBA97) : AppTheme.emerald;
  Color get brick => isDark ? const Color(0xFFE57373) : AppTheme.brick;
}

