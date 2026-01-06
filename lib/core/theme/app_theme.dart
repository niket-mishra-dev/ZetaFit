import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ===========================================================
  // BASE COLORS (Brand Palette - ZetaFit)
  // ===========================================================
  static const Color primaryNeon = Color(0xFF00E5FF);
  static const Color neonPink = Color(0xFFFF2ED1);
  static const Color accentPurple = Color(0xFFB388FF);

  static const Color darkBg = Color(0xFF0D0D0F);
  static const Color darkCard = Color(0xFF1A1A1E);

  static const Color lightBg = Color(0xFFF5F7FA);
  static const Color lightCard = Color(0xFFFFFFFF);

  // ===========================================================
  // LIGHT THEME
  // ===========================================================
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    scaffoldBackgroundColor: darkBg,
    primaryColor: primaryNeon,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNeon,
      brightness: Brightness.dark,
    ).copyWith(surface: darkCard, primary: primaryNeon, secondary: neonPink),

    appBarTheme: AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.michroma(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),

    textTheme: TextTheme(
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.92),
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.85),
      ),
      headlineMedium: GoogleFonts.michroma(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonPink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadowColor: neonPink.withValues(alpha: 0.4),
        elevation: 6,
      ),
    ),

    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );

  // ===========================================================
  // DARK THEME
  // ===========================================================
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    scaffoldBackgroundColor: darkBg,
    primaryColor: primaryNeon,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNeon,
      brightness: Brightness.dark,
    ).copyWith(surface: darkCard, primary: primaryNeon, secondary: neonPink),

    appBarTheme: AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.michroma(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),

    textTheme: TextTheme(
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.92),
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.85),
      ),
      headlineMedium: GoogleFonts.michroma(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonPink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadowColor: neonPink.withValues(alpha: 0.4),
        elevation: 6,
      ),
    ),

    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
